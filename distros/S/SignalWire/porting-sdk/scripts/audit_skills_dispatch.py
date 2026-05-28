#!/usr/bin/env python3
"""
audit_skills_dispatch.py — fail CI if a port's network skills don't
issue real outbound HTTP requests.

Why this exists
---------------
PHP shipped 8 skill stubs that returned hardcoded fake data instead of
calling their named upstreams (Google CSE, Wikipedia, DataSphere, MCP
gateway, Spider, ClaudeSkills, NativeVectorSearch). Static stub-marker
audits caught those because the agent left a `// Stub: in production`
comment behind. A more careful stubber would write canned data with
no comment marker and pass every static check.

This audit closes that gap by driving each skill's handler against a
local HTTP fixture and asserting:

  1. The skill issued a real outbound HTTP request to the fixture
     (proves real transport, not canned data)
  2. The request shape (method, path, headers, body) matches what the
     real upstream would receive (proves serialization is real)
  3. The fixture's recorded real-shape response is parsed correctly
     (proves deserialization is real)

This audit does NOT require live credentials for Google / Wikipedia /
DataSphere etc. The fixture stands in for those upstreams. The
skill's implementation must be pointed at the fixture URL (every
skill that names an upstream service exposes an env-var or
constructor option for the upstream URL — match Python's behavior).

Per-skill contract
------------------
For each network skill, this audit exercises a "happy-path" probe
documented in SKILL_PROBES below. The probe specifies:
  - upstream_env_var: the env var the skill reads to override the
    upstream URL (e.g. `WEB_SEARCH_BASE_URL`).
  - request_shape: method, path, query string, headers we expect.
  - canned_response: a recorded real-shape response the fixture
    serves.
  - assertion: a check on the parsed return value of the skill
    handler (e.g. it contains a value that's only present in the
    canned response, not in any plausible stubbed default).

Harness
-------
Like audit_relay_handshake, each port ships
examples/skills_audit_harness.{ext} that:
  - Reads SKILL_NAME and SKILL_FIXTURE_URL env vars
  - Loads the named skill, configures it to point at the fixture URL
  - Invokes the skill's handler with documented arguments
  - Prints the parsed response to stdout (one JSON object) and exits 0
  - Exits non-zero on any error

Usage
-----
    python audit_skills_dispatch.py --root <port-dir>
    python audit_skills_dispatch.py --root <port-dir> --skill web_search
    python audit_skills_dispatch.py --root <port-dir> --verbose

Exit codes
----------
    0  — every probed skill made a real HTTP call AND parsed the
         canned response correctly.
    1  — at least one skill's handler returned a value that doesn't
         require having hit the fixture (likely canned data).
    2  — usage / runtime / port not recognized.
    3  — skills_audit_harness not shipped by the port.
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import threading
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


# ---------------------------------------------------------------------------
# Skill probe table
# ---------------------------------------------------------------------------
#
# For each network skill, what we expect the request to look like and
# what canned response the fixture should serve. The assertion is a
# substring that must appear in the skill's parsed return value — and
# that substring is something the real upstream's response would
# include, but a canned/stubbed default would NOT include (we use
# unique markers like "AUDIT_SENTINEL_<UUID>").

@dataclass
class SkillProbe:
    name: str
    description: str
    # Env var the skill reads to override its upstream URL. Match Python
    # convention exactly per the parity rule.
    upstream_env_var: str
    # Args passed to the skill handler (forwarded by the harness).
    handler_args: dict
    # Expected request shape on the fixture side.
    expected_method: str
    expected_path_substring: str    # path or path+query the skill is expected to hit
    # Canned response the fixture serves.
    canned_status: int
    canned_body: dict
    # Substring in the skill's parsed return value that must appear iff
    # the skill actually hit the fixture and parsed the canned body.
    response_must_contain: str
    # Required env vars the harness needs (e.g. fake API keys).
    extra_env: dict = field(default_factory=dict)


_SENTINEL = "AUDIT_SENTINEL_4ea8143"

SKILL_PROBES: list[SkillProbe] = [
    SkillProbe(
        name="web_search",
        description="Google CSE",
        upstream_env_var="WEB_SEARCH_BASE_URL",
        handler_args={"query": "what time is it"},
        expected_method="GET",
        expected_path_substring="customsearch",
        canned_status=200,
        canned_body={
            "items": [
                {
                    "title": f"Result {_SENTINEL}",
                    "link": "https://example.com/audit",
                    "snippet": f"Snippet {_SENTINEL}",
                }
            ]
        },
        response_must_contain=_SENTINEL,
        extra_env={
            "GOOGLE_API_KEY": "audit-fake-key",
            "GOOGLE_CSE_ID": "audit-fake-cse",
        },
    ),
    SkillProbe(
        name="wikipedia_search",
        description="Wikipedia REST API",
        upstream_env_var="WIKIPEDIA_BASE_URL",
        handler_args={"query": "Anthropic Claude"},
        expected_method="GET",
        # Real Wikipedia API path is /w/api.php — host carries the
        # "wikipedia" identifier, not the path. Match the API entry
        # point instead of the brand name so the audit checks the
        # bytes the SDK actually emits.
        expected_path_substring="api.php",
        canned_status=200,
        # The SDK makes TWO API calls: action=query&list=search (returns
        # `query.search[]` with titles) followed by action=query&prop=extracts
        # (returns `query.pages.{pageid}.extract`). The fixture serves the
        # same body for both — populate both sub-trees so each call parses
        # successfully. Only the `extract` text reaches the SDK's response.
        canned_body={
            "query": {
                "search": [
                    {
                        "title": "Audit Topic",
                        "snippet": f"Wikipedia snippet {_SENTINEL}",
                    }
                ],
                "pages": {
                    "1": {
                        "title": "Audit Topic",
                        "extract": f"Wikipedia article extract {_SENTINEL}",
                    }
                },
            }
        },
        response_must_contain=_SENTINEL,
    ),
    SkillProbe(
        name="api_ninjas_trivia",
        description="API Ninjas trivia",
        upstream_env_var="API_NINJAS_BASE_URL",
        handler_args={},
        expected_method="GET",
        expected_path_substring="trivia",
        canned_status=200,
        canned_body=[{"question": f"Question {_SENTINEL}", "answer": "yes"}],
        response_must_contain=_SENTINEL,
        extra_env={"API_NINJAS_KEY": "audit-fake-key"},
    ),
    SkillProbe(
        name="weather_api",
        description="WeatherAPI.com",
        upstream_env_var="WEATHER_API_BASE_URL",
        handler_args={"location": "Seattle"},
        expected_method="GET",
        # WeatherAPI.com path is /v1/current.json — match the
        # real endpoint, not the brand name (the brand is in the
        # host: api.weatherapi.com).
        expected_path_substring="current.json",
        canned_status=200,
        canned_body={
            "location": {"name": "Audit City"},
            "current": {"temp_f": 72, "condition": {"text": f"Sunny {_SENTINEL}"}},
        },
        response_must_contain=_SENTINEL,
        extra_env={"WEATHER_API_KEY": "audit-fake-key"},
    ),
    SkillProbe(
        name="datasphere",
        description="SignalWire DataSphere",
        upstream_env_var="DATASPHERE_BASE_URL",
        handler_args={"query": "policy lookup"},
        expected_method="POST",
        expected_path_substring="datasphere",
        canned_status=200,
        # Real DataSphere response shape (per signalwire/skills/datasphere/
        # skill.py:226 and the dashboard) is `chunks: [{text: ...}]`,
        # not `results`. The audit returns the real shape so the SDK
        # parses successfully; a fake-data stub would not contain the
        # AUDIT_SENTINEL.
        canned_body={"chunks": [{"text": f"DataSphere result {_SENTINEL}", "score": 0.99}]},
        response_must_contain=_SENTINEL,
        extra_env={"DATASPHERE_TOKEN": "audit-fake-token"},
    ),
    SkillProbe(
        name="spider",
        description="HTML scrape",
        upstream_env_var="SPIDER_BASE_URL",
        handler_args={"url": "https://audit.example/page"},
        expected_method="GET",
        expected_path_substring="page",
        canned_status=200,
        canned_body={"_raw_html": f"<html><body>Page text {_SENTINEL}</body></html>"},
        response_must_contain=_SENTINEL,
    ),
]


# ---------------------------------------------------------------------------
# Local HTTP fixture
# ---------------------------------------------------------------------------


@dataclass
class FixtureRecord:
    method: str
    path: str
    headers: dict
    body: bytes


class FixtureCapture:
    def __init__(self, probe: SkillProbe):
        self.probe = probe
        self.requests: list[FixtureRecord] = []


def _make_handler(capture: FixtureCapture) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):  # noqa: ARG002
            pass

        def _record_and_respond(self, method: str):
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length) if length > 0 else b""
            capture.requests.append(
                FixtureRecord(method, self.path, dict(self.headers), body)
            )
            self.send_response(capture.probe.canned_status)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(capture.probe.canned_body).encode())

        def do_GET(self):  # noqa: N802
            self._record_and_respond("GET")

        def do_POST(self):  # noqa: N802
            self._record_and_respond("POST")

        def do_PUT(self):  # noqa: N802
            self._record_and_respond("PUT")

    return Handler


def _start_fixture(probe: SkillProbe) -> tuple[int, FixtureCapture, threading.Thread, HTTPServer]:
    capture = FixtureCapture(probe)
    server = HTTPServer(("127.0.0.1", 0), _make_handler(capture))
    port = server.server_address[1]
    th = threading.Thread(target=server.serve_forever, daemon=True)
    th.start()
    return port, capture, th, server


# ---------------------------------------------------------------------------
# Per-language harness
# ---------------------------------------------------------------------------


@dataclass
class PortRunner:
    name: str
    detect: callable
    harness_path: callable
    build_cmd: callable
    run_cmd: callable


def _python_run(r, port):
    return [sys.executable, str(r / "examples" / "skills_audit_harness.py")]

def _ts_run(r, port):
    return ["npx", "tsx", str(r / "examples" / "skills_audit_harness.ts")]

def _php_run(r, port):
    return ["php", str(r / "examples" / "SkillsAuditHarness.php")]

def _ruby_run(r, port):
    return ["bundle", "exec", "ruby", str(r / "examples" / "skills_audit_harness.rb")]

def _perl_run(r, port):
    return ["perl", "-Ilib", str(r / "examples" / "skills_audit_harness.pl")]

def _go_build(r, port):
    return ["go", "build", "-o", str(r / "_audit_skills"), "./examples/skills_audit_harness"]

def _go_run(r, port):
    return [str(r / "_audit_skills")]

def _rust_build(r, port):
    return ["cargo", "build", "--release", "--example", "skills_audit_harness"]

def _rust_run(r, port):
    return [str(r / "target" / "release" / "examples" / "skills_audit_harness")]

def _cpp_build(r, port):
    return ["cmake", "--build", str(r / "build"), "--target", "example_skills_audit_harness"]

def _cpp_run(r, port):
    return [str(r / "build" / "example_skills_audit_harness")]


def _java_runtime_classpath(root):
    parts = [
        str(root / "build" / "classes" / "java" / "main"),
        str(root / "_audit_examples"),
    ]
    needed = [
        ("com.google.code.gson", "gson"),
        ("org.java-websocket", "Java-WebSocket"),
        ("org.slf4j", "slf4j-api"),
    ]
    cache = Path.home() / ".gradle" / "caches" / "modules-2" / "files-2.1"
    for group, artifact in needed:
        coord = cache / group / artifact
        if coord.is_dir():
            for jar in coord.rglob("*.jar"):
                parts.append(str(jar))
    return ":".join(parts)


def _java_build(r, port):
    out_dir = r / "_audit_examples"
    out_dir.mkdir(exist_ok=True)
    classpath = _java_runtime_classpath(r)
    java_files = sorted(str(p) for p in (r / "examples").glob("*.java"))
    if not java_files:
        return None
    return ["javac", "-cp", classpath, "-d", str(out_dir), *java_files]


def _java_run(r, port):
    cp = _java_runtime_classpath(r)
    return ["java", "-cp", cp, "SkillsAuditHarness"]


def _dotnet_build(r, port):
    return ["dotnet", "build", str(r / "examples" / "SkillsAuditHarness.csproj")]


def _dotnet_run(r, port):
    return [
        "dotnet",
        "run",
        "--project",
        str(r / "examples" / "SkillsAuditHarness.csproj"),
    ]


PORT_RUNNERS: list[PortRunner] = [
    PortRunner(
        "python",
        lambda r: (r / "signalwire" / "signalwire" / "skills").is_dir(),
        lambda r: r / "examples" / "skills_audit_harness.py",
        lambda r, p: None,
        _python_run,
    ),
    PortRunner(
        "typescript",
        # TS port has both package.json and src/skills. Without the
        # package.json check this detection greedily matches Rust too
        # (which also uses src/skills under a Cargo.toml root).
        lambda r: (r / "src" / "skills").is_dir() and (r / "package.json").exists(),
        lambda r: r / "examples" / "skills_audit_harness.ts",
        lambda r, p: None,
        _ts_run,
    ),
    PortRunner(
        "dotnet",
        # Order matters: .NET shares src/SignalWire/Skills with PHP. Anchor on
        # SkillBase.cs to disambiguate; the PHP entry below uses the bare
        # directory check. .NET listed first so its specific marker wins.
        lambda r: (r / "src" / "SignalWire" / "Skills" / "SkillBase.cs").exists(),
        lambda r: r / "examples" / "SkillsAuditHarness.cs",
        _dotnet_build,
        _dotnet_run,
    ),
    PortRunner(
        "php",
        lambda r: (r / "src" / "SignalWire" / "Skills").is_dir(),
        lambda r: r / "examples" / "SkillsAuditHarness.php",
        lambda r, p: None,
        _php_run,
    ),
    PortRunner(
        "ruby",
        lambda r: (r / "lib" / "signalwire" / "skills").is_dir(),
        lambda r: r / "examples" / "skills_audit_harness.rb",
        lambda r, p: None,
        _ruby_run,
    ),
    PortRunner(
        "perl",
        lambda r: (r / "lib" / "SignalWire" / "Skills").is_dir(),
        lambda r: r / "examples" / "skills_audit_harness.pl",
        lambda r, p: None,
        _perl_run,
    ),
    PortRunner(
        "go",
        lambda r: (r / "pkg" / "skills").is_dir(),
        lambda r: r / "examples" / "skills_audit_harness" / "main.go",
        _go_build,
        _go_run,
    ),
    PortRunner(
        "rust",
        lambda r: (r / "src" / "skills").is_dir() and (r / "Cargo.toml").exists(),
        lambda r: r / "examples" / "skills_audit_harness.rs",
        _rust_build,
        _rust_run,
    ),
    PortRunner(
        "cpp",
        lambda r: (r / "include" / "signalwire" / "skills").is_dir(),
        lambda r: r / "examples" / "skills_audit_harness.cpp",
        _cpp_build,
        _cpp_run,
    ),
    PortRunner(
        "java",
        lambda r: (r / "src" / "main" / "java" / "com" / "signalwire" / "sdk" / "skills").is_dir(),
        lambda r: r / "examples" / "SkillsAuditHarness.java",
        _java_build,
        _java_run,
    ),
]


class _BuildToolMissing(Exception):
    """Raised when the per-port build/run binary (dotnet, cargo, javac,
    php, etc.) isn't on PATH. The audit treats this as exit 2 (runtime
    not available), not exit 1 (a real failure)."""


def _detect(root: Path) -> PortRunner | None:
    for r in PORT_RUNNERS:
        if r.detect(root):
            return r
    return None


def _probe_one(runner: PortRunner, root: Path, probe: SkillProbe, verbose: bool) -> tuple[bool, str]:
    port, capture, _th, server = _start_fixture(probe)
    try:
        env = os.environ.copy()
        env["SKILL_NAME"] = probe.name
        env["SKILL_FIXTURE_URL"] = f"http://127.0.0.1:{port}"
        env[probe.upstream_env_var] = f"http://127.0.0.1:{port}"
        env["SKILL_HANDLER_ARGS"] = json.dumps(probe.handler_args)
        env["SIGNALWIRE_LOG_MODE"] = "off"
        for k, v in probe.extra_env.items():
            env[k] = v

        build = runner.build_cmd(root, port) if runner.build_cmd else None
        if build:
            try:
                cp = subprocess.run(build, cwd=root, env=env, capture_output=True, timeout=300)
            except FileNotFoundError as e:
                # Build tool (dotnet, cargo, javac, ...) is not installed
                # on this host; treat as a runtime gap, not a logic failure.
                raise _BuildToolMissing(str(e)) from e
            if cp.returncode != 0:
                return False, f"build failed: {cp.stderr.decode(errors='replace')[:300]}"
        cmd = runner.run_cmd(root, port)
        try:
            cp = subprocess.run(cmd, cwd=root, env=env, capture_output=True, timeout=15)
        except FileNotFoundError as e:
            raise _BuildToolMissing(str(e)) from e
        except subprocess.TimeoutExpired:
            return False, "harness timed out (>15s)"

        if cp.returncode != 0:
            return False, (
                f"harness exited {cp.returncode}: "
                f"{cp.stderr.decode(errors='replace')[:300]}"
            )

        # 1) Did the skill actually contact the fixture?
        if not capture.requests:
            return False, (
                f"skill `{probe.name}` returned WITHOUT issuing any HTTP request "
                f"to the fixture. The handler is returning canned data instead "
                f"of calling its upstream."
            )

        # 2) Method + path shape match?
        req = capture.requests[0]
        if req.method != probe.expected_method:
            return False, (
                f"skill `{probe.name}` issued {req.method} but expected "
                f"{probe.expected_method}"
            )
        if probe.expected_path_substring not in req.path:
            return False, (
                f"skill `{probe.name}` hit path '{req.path}', expected to "
                f"contain '{probe.expected_path_substring}'"
            )

        # 3) Did the skill parse the canned response correctly?
        out = cp.stdout.decode("utf-8", errors="replace").strip()
        if probe.response_must_contain not in out:
            return False, (
                f"skill `{probe.name}` returned a value missing the canned "
                f"sentinel '{probe.response_must_contain}'. Either the skill "
                f"didn't parse the fixture's response or the handler returned "
                f"hardcoded data. Harness stdout was: {out[:300]!r}"
            )

        return True, f"skill `{probe.name}`: {req.method} {req.path} → fixture sentinel reached"
    finally:
        server.shutdown()
        for stale in [root / "_audit_skills"]:
            if stale.exists():
                try:
                    stale.unlink()
                except OSError:
                    pass


def run(root: Path, only_skill: str | None, verbose: bool) -> int:
    runner = _detect(root)
    if runner is None:
        print(f"audit_skills_dispatch: --root {root} unrecognized", file=sys.stderr)
        return 2
    if verbose:
        print(f"[verbose] detected port: {runner.name}", file=sys.stderr)

    harness = runner.harness_path(root)
    if not harness.exists():
        print(
            f"audit_skills_dispatch: harness not found at {harness}.\n"
            "Each port must ship a skills_audit_harness example that:\n"
            "  1. Reads SKILL_NAME, SKILL_FIXTURE_URL, the per-skill upstream\n"
            "     env var, SKILL_HANDLER_ARGS, plus any per-skill credential\n"
            "     env vars listed in audit_skills_dispatch.py SKILL_PROBES\n"
            "  2. Loads the named skill, configures it to point at\n"
            "     SKILL_FIXTURE_URL\n"
            "  3. Invokes the skill's handler with the parsed args\n"
            "  4. Prints the parsed return value as JSON to stdout, exits 0\n"
            "  5. Exits non-zero on any error",
            file=sys.stderr,
        )
        return 3

    probes = SKILL_PROBES
    if only_skill:
        probes = [p for p in SKILL_PROBES if p.name == only_skill]
        if not probes:
            print(f"audit_skills_dispatch: no probe defined for skill '{only_skill}'", file=sys.stderr)
            return 2

    failures: list[str] = []
    successes: list[str] = []
    for probe in probes:
        try:
            ok, msg = _probe_one(runner, root, probe, verbose)
        except _BuildToolMissing as e:
            print(
                f"audit_skills_dispatch: build tool not available: {e}",
                file=sys.stderr,
            )
            return 2
        if verbose:
            print(f"[verbose] {probe.name}: {msg}", file=sys.stderr)
        if ok:
            successes.append(msg)
        else:
            failures.append(f"{probe.name}: {msg}")

    if not failures:
        print(f"audit_skills_dispatch: clean. {runner.name}: {len(successes)}/{len(probes)} skills hit the fixture and parsed the canned response.")
        return 0

    print(f"audit_skills_dispatch: {runner.name} failed.", file=sys.stderr)
    print(f"  {len(successes)} skill(s) ok, {len(failures)} broken:", file=sys.stderr)
    for f in failures:
        print(f"  - {f}", file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument("--skill", default=None, help="Probe only one skill by name.")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"audit_skills_dispatch: --root {root} is not a directory", file=sys.stderr)
        return 2

    return run(root, args.skill, args.verbose)


if __name__ == "__main__":
    sys.exit(main())
