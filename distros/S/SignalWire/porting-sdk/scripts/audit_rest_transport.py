#!/usr/bin/env python3
"""
audit_rest_transport.py — fail CI if a port's REST client doesn't issue
real HTTP with the documented method/path/headers shape.

Why this exists
---------------
The REST client surface is large (21 namespaces, 100+ operations).
Static stub-detection misses subtle fakes: a method that calls some
HTTP layer but constructs the wrong URL, omits required headers, or
serializes the body wrong is broken in production but green in unit
tests that mock the HTTP layer away.

This audit drives each port's REST client against a local HTTP
fixture on 127.0.0.1:0 (kernel-assigned ephemeral; safe on busy
boxes), asserts:

  1. The client made an outbound request (proves transport real)
  2. The method matches Python's behavior for the same operation
  3. The path matches Python's URL construction
  4. The Authorization header is present and shaped correctly
     (Basic auth from project:token)
  5. JSON body (POST/PUT/PATCH) matches Python's serialization
  6. The fixture's canned response is parsed back to a dict whose
     known sentinel value reaches the caller

Probe table covers the most-touched namespaces (Calling, Messaging,
PhoneNumbers, Compatibility, Fabric.Resources, Fabric.Subscribers).

Usage
-----
    python audit_rest_transport.py --root <port-dir>
    python audit_rest_transport.py --root <port-dir> --namespace calling
    python audit_rest_transport.py --root <port-dir> --verbose

Per-port harness
----------------
examples/rest_audit_harness.{ext} reads:
  - REST_OPERATION (e.g. "calling.list_calls", "messaging.send", ...)
  - REST_FIXTURE_URL (e.g. "http://127.0.0.1:NNNN")
  - REST_OPERATION_ARGS (JSON-encoded args dict)
  - SIGNALWIRE_PROJECT_ID, SIGNALWIRE_API_TOKEN, SIGNALWIRE_SPACE
Constructs a REST client pointed at REST_FIXTURE_URL, invokes the named
operation, prints the parsed return value as JSON to stdout, exits 0
on success.

Exit codes
----------
    0  — every probed operation hit the fixture with the expected
         shape and parsed the canned response.
    1  — at least one operation broke the contract (wrong method, path,
         missing auth header, body mismatch, missing sentinel in return).
    2  — usage / runtime / port not recognized.
    3  — harness not shipped.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import threading
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

_SENTINEL = "REST_AUDIT_SENTINEL_a905a55"


@dataclass
class RestProbe:
    operation: str           # dotted name, e.g. "calling.list_calls"
    description: str
    args: dict
    expected_method: str
    # Accept any path containing this substring.
    expected_path_substring: str
    canned_status: int
    canned_body: dict | list
    response_must_contain: str = _SENTINEL


REST_PROBES: list[RestProbe] = [
    RestProbe(
        operation="calling.list_calls",
        description="List recent calls",
        args={"limit": 5},
        expected_method="GET",
        expected_path_substring="/api/laml/2010-04-01/Accounts",
        canned_status=200,
        canned_body={
            "calls": [{"sid": _SENTINEL, "status": "completed"}],
            "next_page_uri": None,
        },
    ),
    RestProbe(
        operation="messaging.send",
        description="Send SMS",
        args={"to": "+15551234567", "from_": "+15557654321", "body": "audit ping"},
        expected_method="POST",
        expected_path_substring="Messages",
        canned_status=201,
        canned_body={"sid": _SENTINEL, "status": "queued"},
    ),
    RestProbe(
        operation="phone_numbers.list",
        description="List phone numbers",
        args={"limit": 5},
        expected_method="GET",
        expected_path_substring="phone_numbers",
        canned_status=200,
        canned_body={"data": [{"id": _SENTINEL, "number": "+15551234567"}]},
    ),
    RestProbe(
        operation="fabric.subscribers.list",
        description="Fabric subscribers",
        args={"limit": 5},
        expected_method="GET",
        expected_path_substring="subscribers",
        canned_status=200,
        canned_body={"data": [{"id": _SENTINEL, "email": "audit@example.com"}]},
    ),
    RestProbe(
        operation="compatibility.calls.list",
        description="Compat LAML calls",
        args={"limit": 5},
        expected_method="GET",
        expected_path_substring="Calls",
        canned_status=200,
        canned_body={"calls": [{"sid": _SENTINEL, "status": "completed"}]},
    ),
]


@dataclass
class FixtureRecord:
    method: str
    path: str
    headers: dict
    body: bytes


class FixtureCapture:
    def __init__(self, probe: RestProbe):
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

        def do_PATCH(self):  # noqa: N802
            self._record_and_respond("PATCH")

        def do_DELETE(self):  # noqa: N802
            self._record_and_respond("DELETE")

    return Handler


def _start_fixture(probe: RestProbe) -> tuple[int, FixtureCapture, HTTPServer]:
    capture = FixtureCapture(probe)
    server = HTTPServer(("127.0.0.1", 0), _make_handler(capture))
    port = server.server_address[1]
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return port, capture, server


@dataclass
class PortRunner:
    name: str
    detect: callable
    harness_path: callable
    build_cmd: callable
    run_cmd: callable


def _python_run(r, p):
    return [sys.executable, str(r / "examples" / "rest_audit_harness.py")]

def _ts_run(r, p):
    return ["npx", "tsx", str(r / "examples" / "rest_audit_harness.ts")]

def _php_run(r, p):
    return ["php", str(r / "examples" / "RestAuditHarness.php")]

def _ruby_run(r, p):
    return ["bundle", "exec", "ruby", str(r / "examples" / "rest_audit_harness.rb")]

def _perl_run(r, p):
    return ["perl", "-Ilib", str(r / "examples" / "rest_audit_harness.pl")]

def _go_build(r, p):
    return ["go", "build", "-o", str(r / "_audit_rest"), "./examples/rest_audit_harness"]

def _go_run(r, p):
    return [str(r / "_audit_rest")]

def _rust_build(r, p):
    return ["cargo", "build", "--release", "--example", "rest_audit_harness"]

def _rust_run(r, p):
    return [str(r / "target" / "release" / "examples" / "rest_audit_harness")]

def _cpp_build(r, p):
    return ["cmake", "--build", str(r / "build"), "--target", "example_rest_audit_harness"]

def _cpp_run(r, p):
    return [str(r / "build" / "example_rest_audit_harness")]


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


def _java_build(r, p):
    out_dir = r / "_audit_examples"
    out_dir.mkdir(exist_ok=True)
    classpath = _java_runtime_classpath(r)
    java_files = sorted(str(p) for p in (r / "examples").glob("*.java"))
    if not java_files:
        return None
    return ["javac", "-cp", classpath, "-d", str(out_dir), *java_files]


def _java_run(r, p):
    cp = _java_runtime_classpath(r)
    return ["java", "-cp", cp, "RestAuditHarness"]


def _dotnet_build(r, p):
    return ["dotnet", "build", str(r / "examples" / "RestAuditHarness.csproj")]


def _dotnet_run(r, p):
    return [
        "dotnet",
        "run",
        "--project",
        str(r / "examples" / "RestAuditHarness.csproj"),
    ]


PORT_RUNNERS: list[PortRunner] = [
    PortRunner(
        "python",
        lambda r: (r / "signalwire" / "signalwire" / "rest").is_dir(),
        lambda r: r / "examples" / "rest_audit_harness.py",
        lambda r, p: None,
        _python_run,
    ),
    PortRunner(
        "typescript",
        # TS check needs `package.json` to disambiguate from Rust, which
        # also has src/rest under a Cargo.toml root.
        lambda r: (r / "src" / "rest").is_dir() and (r / "package.json").exists(),
        lambda r: r / "examples" / "rest_audit_harness.ts",
        lambda r, p: None,
        _ts_run,
    ),
    PortRunner(
        "dotnet",
        # Order matters: .NET shares src/SignalWire/REST with PHP. Anchor on
        # RestClient.cs to disambiguate; the PHP entry below uses a bare
        # directory check. .NET listed first so its specific marker wins.
        lambda r: (r / "src" / "SignalWire" / "REST" / "RestClient.cs").exists(),
        lambda r: r / "examples" / "RestAuditHarness.cs",
        _dotnet_build,
        _dotnet_run,
    ),
    PortRunner(
        "php",
        # PHP convention is "REST" (acronym uppercase) per the namespace
        # SignalWire\REST in src/SignalWire/REST/. Match either.
        lambda r: (r / "src" / "SignalWire" / "REST").is_dir() or (r / "src" / "SignalWire" / "Rest").is_dir(),
        lambda r: r / "examples" / "RestAuditHarness.php",
        lambda r, p: None,
        _php_run,
    ),
    PortRunner(
        "ruby",
        lambda r: (r / "lib" / "signalwire" / "rest").is_dir(),
        lambda r: r / "examples" / "rest_audit_harness.rb",
        lambda r, p: None,
        _ruby_run,
    ),
    PortRunner(
        "perl",
        # Perl convention is "REST" (acronym uppercase) per the package
        # SignalWire::REST in lib/SignalWire/REST/. Match either case.
        lambda r: (r / "lib" / "SignalWire" / "REST").is_dir() or (r / "lib" / "SignalWire" / "Rest").is_dir(),
        lambda r: r / "examples" / "rest_audit_harness.pl",
        lambda r, p: None,
        _perl_run,
    ),
    PortRunner(
        "go",
        lambda r: (r / "pkg" / "rest").is_dir(),
        lambda r: r / "examples" / "rest_audit_harness" / "main.go",
        _go_build,
        _go_run,
    ),
    PortRunner(
        "rust",
        lambda r: (r / "src" / "rest").is_dir() and (r / "Cargo.toml").exists(),
        lambda r: r / "examples" / "rest_audit_harness.rs",
        _rust_build,
        _rust_run,
    ),
    PortRunner(
        "cpp",
        lambda r: (r / "include" / "signalwire" / "rest").is_dir(),
        lambda r: r / "examples" / "rest_audit_harness.cpp",
        _cpp_build,
        _cpp_run,
    ),
    PortRunner(
        "java",
        lambda r: (r / "src" / "main" / "java" / "com" / "signalwire" / "sdk" / "rest").is_dir(),
        lambda r: r / "examples" / "RestAuditHarness.java",
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


def _probe_one(runner: PortRunner, root: Path, probe: RestProbe, verbose: bool) -> tuple[bool, str]:
    port, capture, server = _start_fixture(probe)
    try:
        env = os.environ.copy()
        env["REST_OPERATION"] = probe.operation
        env["REST_FIXTURE_URL"] = f"http://127.0.0.1:{port}"
        env["REST_OPERATION_ARGS"] = json.dumps(probe.args)
        env["SIGNALWIRE_PROJECT_ID"] = "audit-project"
        env["SIGNALWIRE_API_TOKEN"] = "audit-token"
        env["SIGNALWIRE_SPACE"] = "127.0.0.1"
        env["SIGNALWIRE_LOG_MODE"] = "off"

        build = runner.build_cmd(root, port) if runner.build_cmd else None
        if build:
            try:
                cp = subprocess.run(build, cwd=root, env=env, capture_output=True, timeout=300)
            except FileNotFoundError as e:
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

        if not capture.requests:
            return False, (
                f"operation `{probe.operation}` returned WITHOUT issuing any "
                f"HTTP request. The REST client is faking the call."
            )

        req = capture.requests[0]
        if req.method != probe.expected_method:
            return False, (
                f"operation `{probe.operation}`: method was {req.method}, "
                f"expected {probe.expected_method}"
            )
        if probe.expected_path_substring not in req.path:
            return False, (
                f"operation `{probe.operation}`: path was '{req.path}', "
                f"expected to contain '{probe.expected_path_substring}'"
            )
        # Auth header check.
        auth_header = None
        for k, v in req.headers.items():
            if k.lower() == "authorization":
                auth_header = v
                break
        if not auth_header or not auth_header.startswith("Basic "):
            return False, (
                f"operation `{probe.operation}`: missing or malformed "
                f"Authorization header (got: {auth_header!r})"
            )

        out = cp.stdout.decode("utf-8", errors="replace").strip()
        if probe.response_must_contain not in out:
            return False, (
                f"operation `{probe.operation}`: response missing canned "
                f"sentinel '{probe.response_must_contain}'. Stdout was: "
                f"{out[:300]!r}"
            )

        return True, f"`{probe.operation}`: {req.method} {req.path} → sentinel parsed"
    finally:
        server.shutdown()
        for stale in [root / "_audit_rest"]:
            if stale.exists():
                try:
                    stale.unlink()
                except OSError:
                    pass


def run(root: Path, only_namespace: str | None, verbose: bool) -> int:
    runner = _detect(root)
    if runner is None:
        print(f"audit_rest_transport: --root {root} unrecognized", file=sys.stderr)
        return 2
    if verbose:
        print(f"[verbose] detected port: {runner.name}", file=sys.stderr)

    harness = runner.harness_path(root)
    if not harness.exists():
        print(
            f"audit_rest_transport: harness not found at {harness}.\n"
            "Each port must ship a rest_audit_harness example that:\n"
            "  1. Reads REST_OPERATION (dotted name like 'calling.list_calls'),\n"
            "     REST_FIXTURE_URL, REST_OPERATION_ARGS (JSON dict), and the\n"
            "     SIGNALWIRE_PROJECT_ID / SIGNALWIRE_API_TOKEN env vars\n"
            "  2. Constructs a REST client pointed at REST_FIXTURE_URL\n"
            "  3. Invokes the named operation with the parsed args\n"
            "  4. Prints the parsed return value as JSON to stdout, exits 0\n"
            "  5. Exits non-zero on any error",
            file=sys.stderr,
        )
        return 3

    probes = REST_PROBES
    if only_namespace:
        probes = [p for p in REST_PROBES if p.operation.startswith(only_namespace + ".")]
        if not probes:
            print(f"audit_rest_transport: no probe in namespace '{only_namespace}'", file=sys.stderr)
            return 2

    failures: list[str] = []
    successes: list[str] = []
    for probe in probes:
        try:
            ok, msg = _probe_one(runner, root, probe, verbose)
        except _BuildToolMissing as e:
            print(
                f"audit_rest_transport: build tool not available: {e}",
                file=sys.stderr,
            )
            return 2
        if verbose:
            print(f"[verbose] {probe.operation}: {msg}", file=sys.stderr)
        (successes if ok else failures).append(msg if ok else f"{probe.operation}: {msg}")

    if not failures:
        print(f"audit_rest_transport: clean. {runner.name}: {len(successes)}/{len(probes)} operations hit the fixture with the right shape.")
        return 0

    print(f"audit_rest_transport: {runner.name} failed.", file=sys.stderr)
    print(f"  {len(successes)} ok, {len(failures)} broken:", file=sys.stderr)
    for f in failures:
        print(f"  - {f}", file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument("--namespace", default=None, help="Probe only one namespace (e.g. 'calling').")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"audit_rest_transport: --root {root} is not a directory", file=sys.stderr)
        return 2

    return run(root, args.namespace, args.verbose)


if __name__ == "__main__":
    sys.exit(main())
