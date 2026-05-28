#!/usr/bin/env python3
"""
audit_http_swml.py — fail CI if a port's swmlservice example doesn't
actually serve real SWML over HTTP and dispatch a real handler.

Why this exists
---------------
The Rust SDK shipped with `handle_swaig_request` returning a canned
`[]` for every POST regardless of input, and `handle_swml_request`
returning a fixed document. Unit tests passed (they tested the runtime
registry directly, not the HTTP path). audit_stubs.py would have
caught it in retrospect via the silent-canned-data pattern, but only
after we knew to look. This audit is the runtime check: stand up the
example service, hit it over a real socket, assert the documented
behavior actually happens.

It targets the `swmlservice_swaig_standalone` example in each port
because that's the simplest service-level contract — a SWMLService
that registers `lookup_competitor` and serves it on `/swaig`. The
contract is:

  GET  <route>          → 200 + JSON SWML doc with `sections.main` array
  POST <route>/swaig    → 200 + JSON {"response": "<text>"} containing
                          the registered handler's real output, NOT a
                          canned `[]` / `{}` / fixed string.

Any port whose example fails either probe fails this audit.

Usage
-----
    python audit_http_swml.py --root <port-dir>
    python audit_http_swml.py --root <port-dir> --verbose

The audit picks an ephemeral port (kernel-assigned via 0-binding when
the language allows; otherwise picks a high port and retries) so it's
safe on a busy box. It cleans up the spawned example process even on
failure.

Per-language conventions are hard-coded in PORT_RUNNERS below — one
canonical home, no per-port manifests.

Exit codes
----------
    0  — example runs, GET /<route> returns valid SWML, POST /<route>/swaig
         returns a real handler response, port is clean.
    1  — at least one probe failed (example didn't start, GET returned
         non-SWML, POST didn't dispatch to the registered handler).
    2  — usage error / port directory invalid / language not supported.
    3  — example file not found in the expected location (port hasn't
         shipped the swmlservice_swaig_standalone example).
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from base64 import b64encode
from dataclasses import dataclass
from pathlib import Path

# The known set of languages we know how to drive. Extend by adding to
# PORT_RUNNERS below.
@dataclass
class PortRunner:
    name: str
    detect: callable                 # (root: Path) -> bool
    example_path: callable           # (root: Path) -> Path | None
    build_cmd: callable              # (root: Path, port: int) -> list[str] | None  (None = no separate build step)
    run_cmd: callable                # (root: Path, port: int) -> list[str]
    route: str = "/standalone"
    auth_user: str = "u"
    auth_pass: str = "p"


def _ephemeral_port() -> int:
    """Ask the kernel for a free TCP port. Bind with SO_REUSEADDR set, so
    the port is immediately reusable when we close the socket."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


# ---------------------------------------------------------------------------
# Per-language runners.
# ---------------------------------------------------------------------------

def _python_run(root: Path, port: int) -> list[str]:
    return [
        sys.executable,
        str(root / "examples" / "swmlservice_swaig_standalone.py"),
    ]

def _ts_run(root: Path, port: int) -> list[str]:
    # Run via tsx (the repo uses native ESM Node + tsx for .ts examples).
    return ["npx", "tsx", str(root / "examples" / "swmlservice_swaig_standalone.ts")]

def _php_run(root: Path, port: int) -> list[str]:
    return ["php", str(root / "examples" / "SwmlServiceSwaigStandalone.php")]

def _ruby_run(root: Path, port: int) -> list[str]:
    return ["bundle", "exec", "ruby", str(root / "examples" / "swmlservice_swaig_standalone.rb")]

def _perl_run(root: Path, port: int) -> list[str]:
    return ["perl", "-Ilib", str(root / "examples" / "swmlservice_swaig_standalone.pl")]

def _go_build(root: Path, port: int) -> list[str] | None:
    return ["go", "build", "-o", str(root / "_audit_swmlservice"), "./examples/swmlservice_swaig_standalone"]

def _go_run(root: Path, port: int) -> list[str]:
    return [str(root / "_audit_swmlservice")]

def _rust_build(root: Path, port: int) -> list[str] | None:
    return ["cargo", "build", "--release", "--example", "swmlservice_swaig_standalone"]

def _rust_run(root: Path, port: int) -> list[str]:
    return [str(root / "target" / "release" / "examples" / "swmlservice_swaig_standalone")]

def _cpp_build(root: Path, port: int) -> list[str] | None:
    return ["cmake", "--build", str(root / "build"), "--target", "example_swmlservice_swaig_standalone"]

def _cpp_run(root: Path, port: int) -> list[str]:
    return [str(root / "build" / "example_swmlservice_swaig_standalone")]

def _java_runtime_classpath(root: Path) -> str:
    """Build a classpath for running an example by combining the SDK's compiled
    classes and every runtime jar Gradle has downloaded. We compile the example
    ahead of `_java_run`; the same classpath drives compile and run."""
    parts = [
        str(root / "build" / "classes" / "java" / "main"),
        str(root / "_audit_examples"),
    ]
    # Gradle stashes resolved deps under ~/.gradle/caches/modules-2/files-2.1/<group>/<artifact>/<ver>/<sha>/<jar>.
    # The build only declares 2 implementation deps (gson, Java-WebSocket) plus
    # transitive slf4j-api. Add every jar we find for those coordinates.
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


def _java_build(root: Path, port: int) -> list[str] | None:
    """Compile every .java file under examples/ into _audit_examples/ using
    the SDK classes and resolved runtime deps. Each file is in the default
    package (no `package` declaration), so the FQCN is the bare class name."""
    out_dir = root / "_audit_examples"
    out_dir.mkdir(exist_ok=True)
    classpath = _java_runtime_classpath(root)
    example_dir = root / "examples"
    java_files = sorted(str(p) for p in example_dir.glob("*.java"))
    if not java_files:
        return None
    return [
        "javac",
        "-cp",
        classpath,
        "-d",
        str(out_dir),
        *java_files,
    ]

def _java_run(root: Path, port: int) -> list[str]:
    cp = _java_runtime_classpath(root)
    return ["java", "-cp", cp, "SwmlServiceSwaigStandalone"]

def _dotnet_build(root: Path, port: int) -> list[str] | None:
    # .NET SDK isn't installed on this host (per prior session notes).
    # We document the build step for users who do have dotnet.
    return ["dotnet", "build", str(root / "examples" / "SwmlServiceSwaigStandalone.csproj")]

def _dotnet_run(root: Path, port: int) -> list[str]:
    return [
        "dotnet",
        "run",
        "--project",
        str(root / "examples" / "SwmlServiceSwaigStandalone.csproj"),
    ]


PORT_RUNNERS: list[PortRunner] = [
    PortRunner(
        name="python",
        detect=lambda r: (r / "signalwire" / "signalwire" / "core" / "swml_service.py").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.py",
        build_cmd=lambda r, p: None,
        run_cmd=_python_run,
    ),
    PortRunner(
        name="typescript",
        detect=lambda r: (r / "src" / "SWMLService.ts").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.ts",
        build_cmd=lambda r, p: None,
        run_cmd=_ts_run,
    ),
    PortRunner(
        name="php",
        detect=lambda r: (r / "src" / "SignalWire" / "SWML" / "Service.php").exists(),
        example_path=lambda r: r / "examples" / "SwmlServiceSwaigStandalone.php",
        build_cmd=lambda r, p: None,
        run_cmd=_php_run,
    ),
    PortRunner(
        name="ruby",
        detect=lambda r: (r / "lib" / "signalwire" / "swml" / "service.rb").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.rb",
        build_cmd=lambda r, p: None,
        run_cmd=_ruby_run,
    ),
    PortRunner(
        name="perl",
        detect=lambda r: (r / "lib" / "SignalWire" / "SWML" / "Service.pm").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.pl",
        build_cmd=lambda r, p: None,
        run_cmd=_perl_run,
    ),
    PortRunner(
        name="go",
        detect=lambda r: (r / "pkg" / "swml" / "service.go").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone" / "main.go",
        build_cmd=_go_build,
        run_cmd=_go_run,
    ),
    PortRunner(
        name="rust",
        detect=lambda r: (r / "src" / "swml" / "service.rs").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.rs",
        build_cmd=_rust_build,
        run_cmd=_rust_run,
    ),
    PortRunner(
        name="cpp",
        detect=lambda r: (r / "include" / "signalwire" / "swml" / "service.hpp").exists(),
        example_path=lambda r: r / "examples" / "swmlservice_swaig_standalone.cpp",
        build_cmd=_cpp_build,
        run_cmd=_cpp_run,
    ),
    PortRunner(
        name="java",
        detect=lambda r: (r / "src" / "main" / "java" / "com" / "signalwire" / "sdk" / "swml" / "Service.java").exists(),
        example_path=lambda r: r / "examples" / "SwmlServiceSwaigStandalone.java",
        build_cmd=_java_build,
        run_cmd=_java_run,
    ),
    PortRunner(
        name="dotnet",
        detect=lambda r: (r / "src" / "SignalWire" / "SWML" / "Service.cs").exists(),
        example_path=lambda r: r / "examples" / "SwmlServiceSwaigStandalone.cs",
        build_cmd=_dotnet_build,
        run_cmd=_dotnet_run,
    ),
]


def _detect_port_runner(root: Path) -> PortRunner | None:
    for r in PORT_RUNNERS:
        if r.detect(root):
            return r
    return None


# ---------------------------------------------------------------------------
# HTTP probes
# ---------------------------------------------------------------------------

def _wait_for_listen(port: int, timeout: float = 15.0) -> bool:
    """Spin-poll until something is bound to 127.0.0.1:port or timeout."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                return True
        except (ConnectionRefusedError, OSError):
            time.sleep(0.2)
    return False


def _basic_auth(user: str, password: str) -> str:
    raw = f"{user}:{password}".encode()
    return "Basic " + b64encode(raw).decode()


def _http_get(url: str, auth: str, timeout: float = 5.0) -> tuple[int, bytes]:
    req = urllib.request.Request(url, method="GET")
    req.add_header("Authorization", auth)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def _http_post(url: str, auth: str, body: dict, timeout: float = 5.0) -> tuple[int, bytes]:
    req = urllib.request.Request(
        url,
        method="POST",
        data=json.dumps(body).encode(),
    )
    req.add_header("Authorization", auth)
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


# ---------------------------------------------------------------------------
# Probe contract
# ---------------------------------------------------------------------------

def _probe_get_swml(host: str, port: int, route: str, auth: str) -> tuple[bool, str]:
    """GET <route> must return 200 + JSON object with `sections.main` array."""
    url = f"http://{host}:{port}{route}"
    try:
        status, body = _http_get(url, auth)
    except Exception as e:
        return False, f"GET {url}: connection error: {e}"
    if status != 200:
        return False, f"GET {url}: status {status} (expected 200)"
    try:
        doc = json.loads(body)
    except json.JSONDecodeError as e:
        return False, f"GET {url}: response is not JSON: {e}"
    if not isinstance(doc, dict):
        return False, f"GET {url}: response is not a JSON object: {type(doc).__name__}"
    if "sections" not in doc:
        return False, f"GET {url}: response has no `sections` key (not a SWML doc)"
    sections = doc["sections"]
    if not isinstance(sections, dict) or "main" not in sections:
        return False, f"GET {url}: `sections.main` is missing"
    if not isinstance(sections["main"], list):
        return False, f"GET {url}: `sections.main` is not an array"
    return True, f"GET {url}: 200 with valid SWML doc ({len(sections['main'])} verbs in main)"


def _probe_post_swaig(host: str, port: int, route: str, auth: str) -> tuple[bool, str]:
    """POST <route>/swaig with a real function call must dispatch to the
    registered `lookup_competitor` handler and return its real response.

    The example's contract: handler returns "ACME pricing is $99/seat;
    we're $79/seat." for `competitor=ACME`. We assert the response
    contains "ACME" AND "$79" — strings only present in the real
    handler's output, NOT in any plausible canned stub return.
    """
    url = f"http://{host}:{port}{route}/swaig"
    body = {
        "function": "lookup_competitor",
        "argument": {"parsed": [{"competitor": "ACME"}]},
    }
    try:
        status, raw = _http_post(url, auth, body)
    except Exception as e:
        return False, f"POST {url}: connection error: {e}"
    if status != 200:
        return False, f"POST {url}: status {status} (expected 200): body={raw[:200]!r}"
    try:
        resp = json.loads(raw)
    except json.JSONDecodeError as e:
        return False, f"POST {url}: response is not JSON: {e}: body={raw[:200]!r}"
    if isinstance(resp, list) and not resp:
        return False, (
            f"POST {url}: response is `[]` — looks like the silent canned-data "
            "stub. Dispatcher is ignoring the request body."
        )
    if not isinstance(resp, dict):
        return False, f"POST {url}: response is not a JSON object: {type(resp).__name__}"
    text = json.dumps(resp)
    if "ACME" not in text or "$79" not in text:
        return False, (
            f"POST {url}: response does not contain the registered handler's "
            f"real output (expected 'ACME' and '$79' in the response). "
            f"Response was: {text[:300]}"
        )
    return True, f"POST {url}: handler dispatched, response contains ACME pricing"


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

def run(root: Path, verbose: bool) -> int:
    runner = _detect_port_runner(root)
    if runner is None:
        print(f"audit_http_swml: --root {root} doesn't look like a recognized SDK port", file=sys.stderr)
        return 2
    if verbose:
        print(f"[verbose] detected port: {runner.name}", file=sys.stderr)

    example = runner.example_path(root)
    if not example.exists():
        print(
            f"audit_http_swml: example not found at {example}. "
            "Port hasn't shipped the swmlservice_swaig_standalone example.",
            file=sys.stderr,
        )
        return 3

    port = _ephemeral_port()
    env = os.environ.copy()
    env["SWML_BASIC_AUTH_USER"] = runner.auth_user
    env["SWML_BASIC_AUTH_PASSWORD"] = runner.auth_pass
    env["PORT"] = str(port)
    env["SIGNALWIRE_LOG_MODE"] = "off"

    # Build step (per-language).
    build = runner.build_cmd(root, port) if runner.build_cmd else None
    if build:
        if verbose:
            print(f"[verbose] build: {' '.join(build)}", file=sys.stderr)
        try:
            cp = subprocess.run(build, cwd=root, env=env, capture_output=True, timeout=300)
        except subprocess.TimeoutExpired:
            print("audit_http_swml: build timed out (>5min)", file=sys.stderr)
            return 1
        except FileNotFoundError as e:
            print(f"audit_http_swml: build tool not available: {e}", file=sys.stderr)
            return 2
        if cp.returncode != 0:
            print("audit_http_swml: build failed:", file=sys.stderr)
            sys.stderr.write(cp.stderr.decode(errors="replace"))
            return 1

    cmd = runner.run_cmd(root, port)
    if verbose:
        print(f"[verbose] running: {' '.join(cmd)} (port={port})", file=sys.stderr)
    try:
        proc = subprocess.Popen(
            cmd,
            cwd=root,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError as e:
        print(f"audit_http_swml: language runtime not available: {e}", file=sys.stderr)
        return 2

    try:
        if not _wait_for_listen(port, timeout=20.0):
            stdout = b""
            stderr = b""
            try:
                stdout, stderr = proc.communicate(timeout=1)
            except Exception:
                pass
            print(
                f"audit_http_swml: example never bound to 127.0.0.1:{port}. "
                "Process stdout/stderr below:",
                file=sys.stderr,
            )
            sys.stderr.write(stdout.decode(errors="replace")[:2000])
            sys.stderr.write(stderr.decode(errors="replace")[:2000])
            return 1

        auth = _basic_auth(runner.auth_user, runner.auth_pass)
        ok_get, msg_get = _probe_get_swml("127.0.0.1", port, runner.route, auth)
        ok_post, msg_post = _probe_post_swaig("127.0.0.1", port, runner.route, auth)

        if verbose:
            print(f"[verbose] {msg_get}", file=sys.stderr)
            print(f"[verbose] {msg_post}", file=sys.stderr)

        if ok_get and ok_post:
            print(f"audit_http_swml: clean. {runner.name}: GET ok, POST dispatched real handler.")
            return 0

        print(f"audit_http_swml: {runner.name} failed.", file=sys.stderr)
        if not ok_get:
            print(f"  {msg_get}", file=sys.stderr)
        if not ok_post:
            print(f"  {msg_post}", file=sys.stderr)
        return 1
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=3)
        # Cleanup helper artifacts.
        for stale in [root / "_audit_swmlservice"]:
            if stale.exists():
                try:
                    stale.unlink()
                except OSError:
                    pass


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--root", required=True, help="Path to the port repo.")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"audit_http_swml: --root {root} is not a directory", file=sys.stderr)
        return 2

    return run(root, args.verbose)


if __name__ == "__main__":
    sys.exit(main())
