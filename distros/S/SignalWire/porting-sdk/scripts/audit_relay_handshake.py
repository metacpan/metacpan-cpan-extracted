#!/usr/bin/env python3
"""
audit_relay_handshake.py — fail CI if a port's RELAY client doesn't
speak real WebSocket + JSON-RPC 2.0 against a local fixture.

Why this exists
---------------
The PHP, .NET, and Rust SDKs shipped with `Stub: production would open
WSS to wss://...` placeholders in their RELAY clients. The clients
built in-memory state and never connected. Unit tests passed because
they exercised the JSON-RPC dispatch logic above the transport with
the transport mocked away.

This audit closes the gap by standing up a local WebSocket fixture on
`127.0.0.1:0` (kernel-assigned ephemeral port; safe on a busy box)
that speaks the SignalWire RELAY handshake well enough to drive a
real client through the full happy-path:

  1. WSS upgrade arrives at the fixture (proves the client opened a
     real socket; a stub never gets here)
  2. JSON-RPC `signalwire.connect` request arrives with the documented
     `params.project`, `params.token`, optional `params.contexts`
     (proves auth/serialization)
  3. Fixture replies with a real-shape `result.authorization` blob
     including a fresh `authorization_state` token (the value the
     client should remember for fast-reconnect)
  4. Client subscribes to one of its contexts via
     `signalwire.subscribe`
  5. Fixture pushes a `signalwire.event` (e.g. `calling.call.state`
     for a fake inbound call) and the client must dispatch it to the
     callback the test set up
  6. Client cleanly closes / fixture observes the close frame

A port whose relay client never opens the socket fails at step 1
with "fixture saw no WSS upgrade." A port that opens but doesn't
send `signalwire.connect` fails at step 2. A port that connects but
ignores inbound events fails at step 5.

This audit does NOT require live SignalWire credentials — the fixture
stands in for the real RELAY service. The client must use the fixture
URL (set via env var `SIGNALWIRE_RELAY_HOST` on the port's RELAY
client) and any credentials accepted (the fixture doesn't validate).

Usage
-----
    python audit_relay_handshake.py --root <port-dir>
    python audit_relay_handshake.py --root <port-dir> --verbose

Per-language conventions are hard-coded in PORT_RUNNERS below.

Exit codes
----------
    0  — handshake completes end-to-end, event dispatched.
    1  — handshake incomplete (client never connected, never sent
         signalwire.connect, ignored inbound events, etc.).
    2  — usage error / language runtime not available / port not
         recognized.
    3  — port hasn't shipped a relay-handshake harness example we can
         drive.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import hashlib
import json
import os
import socket
import struct
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path

# Magic GUID per RFC 6455 — used in WS-Accept derivation.
_WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

# ---------------------------------------------------------------------------
# WebSocket fixture server
#
# We implement enough of WS + JSON-RPC 2.0 in-process to drive a real client
# without taking on tornado / aiohttp / websockets as deps in porting-sdk.
# ---------------------------------------------------------------------------


@dataclass
class FixtureState:
    upgrade_seen: bool = False
    connect_request: dict | None = None
    subscribe_seen: list[str] = field(default_factory=list)
    event_dispatched: bool = False
    close_received: bool = False
    raw_messages: list[str] = field(default_factory=list)
    error: str | None = None


def _ws_accept(client_key: str) -> str:
    h = hashlib.sha1((client_key + _WS_MAGIC).encode()).digest()
    return base64.b64encode(h).decode()


def _decode_ws_frame(buf: bytearray) -> tuple[str | None, int]:
    """Decode one WebSocket text frame from buf, return (payload, bytes_consumed)
    or (None, 0) if the buffer doesn't yet contain a complete frame."""
    if len(buf) < 2:
        return None, 0
    b0, b1 = buf[0], buf[1]
    opcode = b0 & 0x0F
    masked = (b1 & 0x80) != 0
    plen = b1 & 0x7F
    idx = 2
    if plen == 126:
        if len(buf) < idx + 2:
            return None, 0
        plen = struct.unpack(">H", buf[idx:idx + 2])[0]
        idx += 2
    elif plen == 127:
        if len(buf) < idx + 8:
            return None, 0
        plen = struct.unpack(">Q", buf[idx:idx + 8])[0]
        idx += 8
    if masked:
        if len(buf) < idx + 4:
            return None, 0
        mask = buf[idx:idx + 4]
        idx += 4
    if len(buf) < idx + plen:
        return None, 0
    payload = buf[idx:idx + plen]
    if masked:
        payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    consumed = idx + plen
    if opcode == 0x8:  # close
        return "__CLOSE__", consumed
    if opcode == 0x1:  # text
        return payload.decode("utf-8", errors="replace"), consumed
    # Other opcodes (binary/ping/pong) — ignore for our protocol
    return "", consumed


def _encode_ws_frame(payload: str) -> bytes:
    data = payload.encode("utf-8")
    out = bytearray([0x81])  # FIN + text
    n = len(data)
    if n < 126:
        out.append(n)
    elif n < 0x10000:
        out.append(126)
        out += struct.pack(">H", n)
    else:
        out.append(127)
        out += struct.pack(">Q", n)
    out += data
    return bytes(out)


def _serve_one_relay_session(conn: socket.socket, state: FixtureState) -> None:
    """Drive one WS connection through the documented RELAY handshake."""
    try:
        # 1) Read HTTP upgrade.
        req = b""
        while b"\r\n\r\n" not in req and len(req) < 8192:
            chunk = conn.recv(4096)
            if not chunk:
                state.error = "client closed before sending HTTP request"
                return
            req += chunk
        head = req.split(b"\r\n\r\n", 1)[0].decode("latin-1", "replace")
        lines = head.split("\r\n")
        if not lines or "GET" not in lines[0]:
            state.error = f"first line is not a GET: {lines[0] if lines else '<empty>'}"
            return
        headers = {}
        for line in lines[1:]:
            if ":" in line:
                k, v = line.split(":", 1)
                headers[k.strip().lower()] = v.strip()
        if headers.get("upgrade", "").lower() != "websocket":
            state.error = "no Upgrade: websocket header — client did not send a WS upgrade"
            return
        client_key = headers.get("sec-websocket-key", "")
        accept = _ws_accept(client_key)
        resp = (
            "HTTP/1.1 101 Switching Protocols\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Accept: {accept}\r\n\r\n"
        )
        conn.sendall(resp.encode())
        state.upgrade_seen = True

        # 2) Read JSON-RPC frames from client; reply per protocol.
        buf = bytearray()
        deadline = time.time() + 8.0
        sent_event = False
        while time.time() < deadline:
            conn.settimeout(0.5)
            try:
                chunk = conn.recv(8192)
            except socket.timeout:
                if not sent_event and state.connect_request and state.subscribe_seen:
                    # Push an event the client must dispatch.
                    event = {
                        "jsonrpc": "2.0",
                        "method": "signalwire.event",
                        "params": {
                            "event_type": "calling.call.state",
                            "params": {
                                "call_id": "audit-call-1",
                                "node_id": "audit-node",
                                "tag": "audit-tag",
                                "call_state": "ringing",
                                "direction": "inbound",
                                "type": "phone",
                                "from_number": "+15551112222",
                                "to_number": "+15553334444",
                            },
                        },
                    }
                    conn.sendall(_encode_ws_frame(json.dumps(event)))
                    sent_event = True
                continue
            except OSError:
                break
            if not chunk:
                break
            buf.extend(chunk)
            while True:
                msg, consumed = _decode_ws_frame(buf)
                if consumed == 0:
                    break
                del buf[:consumed]
                if msg == "__CLOSE__":
                    state.close_received = True
                    return
                if not msg:
                    continue
                state.raw_messages.append(msg)
                try:
                    obj = json.loads(msg)
                except json.JSONDecodeError:
                    state.error = f"non-JSON frame from client: {msg[:200]}"
                    return
                method = obj.get("method", "")
                if method == "signalwire.connect":
                    state.connect_request = obj
                    reply = {
                        "jsonrpc": "2.0",
                        "id": obj.get("id", "0"),
                        "result": {
                            "authorization": {
                                "authorization_state": "audit-auth-state-token-x" * 2,
                                "expires_at": int(time.time()) + 3600,
                                "project": obj.get("params", {}).get("project", ""),
                            },
                            "protocol": "signalwire-relay-2-audit",
                        },
                    }
                    conn.sendall(_encode_ws_frame(json.dumps(reply)))
                elif method in ("signalwire.subscribe", "signalwire.receive"):
                    # Python's reference SDK uses `signalwire.receive`
                    # (relay/client.py:484, constants.py:12). We accept
                    # both names because earlier ports / docs occasionally
                    # used `signalwire.subscribe` and the audit's job is
                    # "did the client ask to listen on a context?", not
                    # "did it use exactly the new method name?".
                    contexts = obj.get("params", {}).get("contexts", [])
                    state.subscribe_seen.extend(contexts)
                    reply = {
                        "jsonrpc": "2.0",
                        "id": obj.get("id", "0"),
                        "result": {"contexts": contexts},
                    }
                    conn.sendall(_encode_ws_frame(json.dumps(reply)))
                elif method == "signalwire.event":
                    # Client ACKs an event we sent; mark dispatched.
                    state.event_dispatched = True
                else:
                    # Unknown method — reply with empty success so the
                    # client doesn't stall.
                    reply = {
                        "jsonrpc": "2.0",
                        "id": obj.get("id", "0"),
                        "result": {},
                    }
                    conn.sendall(_encode_ws_frame(json.dumps(reply)))
    except Exception as e:  # noqa: BLE001
        state.error = f"fixture error: {type(e).__name__}: {e}"
    finally:
        try:
            conn.close()
        except OSError:
            pass


def _start_fixture() -> tuple[int, FixtureState, threading.Thread]:
    state = FixtureState()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("127.0.0.1", 0))
    sock.listen(1)
    port = sock.getsockname()[1]

    def serve():
        try:
            sock.settimeout(20.0)
            conn, _ = sock.accept()
            _serve_one_relay_session(conn, state)
        except socket.timeout:
            state.error = state.error or "fixture timed out waiting for client connection"
        finally:
            sock.close()

    th = threading.Thread(target=serve, daemon=True)
    th.start()
    return port, state, th


# ---------------------------------------------------------------------------
# Per-language harness — each port needs to ship a tiny example that
# constructs its RelayClient pointed at $SIGNALWIRE_RELAY_HOST and exits
# after (a) connect (b) subscribe to "audit_ctx" (c) receiving one event.
#
# The harness binary lives at examples/relay_audit_harness.{ext}. Ports
# that haven't shipped it yet fail this audit with exit code 3.
# ---------------------------------------------------------------------------


@dataclass
class PortRunner:
    name: str
    detect: callable
    harness_path: callable
    build_cmd: callable
    run_cmd: callable


def _python_harness_path(r):
    return r / "examples" / "relay_audit_harness.py"

def _python_run(r, port):
    return [sys.executable, str(_python_harness_path(r))]

def _ts_run(r, port):
    return ["npx", "tsx", str(r / "examples" / "relay_audit_harness.ts")]

def _php_run(r, port):
    return ["php", str(r / "examples" / "RelayAuditHarness.php")]

def _ruby_run(r, port):
    return ["bundle", "exec", "ruby", str(r / "examples" / "relay_audit_harness.rb")]

def _perl_run(r, port):
    return ["perl", "-Ilib", str(r / "examples" / "relay_audit_harness.pl")]

def _go_build(r, port):
    return ["go", "build", "-o", str(r / "_audit_relay"), "./examples/relay_audit_harness"]

def _go_run(r, port):
    return [str(r / "_audit_relay")]

def _rust_build(r, port):
    return ["cargo", "build", "--release", "--example", "relay_audit_harness"]

def _rust_run(r, port):
    return [str(r / "target" / "release" / "examples" / "relay_audit_harness")]

def _cpp_build(r, port):
    return ["cmake", "--build", str(r / "build"), "--target", "example_relay_audit_harness"]

def _cpp_run(r, port):
    return [str(r / "build" / "example_relay_audit_harness")]


def _java_runtime_classpath(root):
    """Same shape as audit_http_swml's java classpath helper."""
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
    return ["java", "-cp", cp, "RelayAuditHarness"]


def _dotnet_build(r, port):
    return ["dotnet", "build", str(r / "examples" / "RelayAuditHarness.csproj")]


def _dotnet_run(r, port):
    return [
        "dotnet",
        "run",
        "--project",
        str(r / "examples" / "RelayAuditHarness.csproj"),
    ]


PORT_RUNNERS: list[PortRunner] = [
    PortRunner(
        "python",
        lambda r: (r / "signalwire" / "signalwire" / "relay" / "client.py").exists(),
        _python_harness_path,
        lambda r, p: None,
        _python_run,
    ),
    PortRunner(
        "typescript",
        lambda r: (r / "src" / "relay" / "RelayClient.ts").exists(),
        lambda r: r / "examples" / "relay_audit_harness.ts",
        lambda r, p: None,
        _ts_run,
    ),
    PortRunner(
        "php",
        lambda r: (r / "src" / "SignalWire" / "Relay" / "Client.php").exists(),
        lambda r: r / "examples" / "RelayAuditHarness.php",
        lambda r, p: None,
        _php_run,
    ),
    PortRunner(
        "ruby",
        lambda r: (r / "lib" / "signalwire" / "relay" / "client.rb").exists(),
        lambda r: r / "examples" / "relay_audit_harness.rb",
        lambda r, p: None,
        _ruby_run,
    ),
    PortRunner(
        "perl",
        lambda r: (r / "lib" / "SignalWire" / "Relay" / "Client.pm").exists(),
        lambda r: r / "examples" / "relay_audit_harness.pl",
        lambda r, p: None,
        _perl_run,
    ),
    PortRunner(
        "go",
        lambda r: (r / "pkg" / "relay" / "client.go").exists(),
        lambda r: r / "examples" / "relay_audit_harness" / "main.go",
        _go_build,
        _go_run,
    ),
    PortRunner(
        "rust",
        lambda r: (r / "src" / "relay" / "client.rs").exists(),
        lambda r: r / "examples" / "relay_audit_harness.rs",
        _rust_build,
        _rust_run,
    ),
    PortRunner(
        "cpp",
        lambda r: (r / "src" / "relay" / "client.cpp").exists(),
        lambda r: r / "examples" / "relay_audit_harness.cpp",
        _cpp_build,
        _cpp_run,
    ),
    PortRunner(
        "java",
        lambda r: (r / "src" / "main" / "java" / "com" / "signalwire" / "sdk" / "relay" / "RelayClient.java").exists(),
        lambda r: r / "examples" / "RelayAuditHarness.java",
        _java_build,
        _java_run,
    ),
    PortRunner(
        "dotnet",
        # .NET conventions: src/SignalWire/Relay/Client.cs (PascalCase
        # filename, capital REST/Relay namespace dirs).
        lambda r: (r / "src" / "SignalWire" / "Relay" / "Client.cs").exists(),
        lambda r: r / "examples" / "RelayAuditHarness.cs",
        _dotnet_build,
        _dotnet_run,
    ),
]


def _detect(root: Path) -> PortRunner | None:
    for r in PORT_RUNNERS:
        if r.detect(root):
            return r
    return None


def run(root: Path, verbose: bool) -> int:
    runner = _detect(root)
    if runner is None:
        print(f"audit_relay_handshake: --root {root} unrecognized", file=sys.stderr)
        return 2
    if verbose:
        print(f"[verbose] detected port: {runner.name}", file=sys.stderr)

    harness = runner.harness_path(root)
    if not harness.exists():
        print(
            f"audit_relay_handshake: harness not found at {harness}.\n"
            "Each port must ship a relay_audit_harness example that:\n"
            "  1. Reads SIGNALWIRE_RELAY_HOST env var (e.g. '127.0.0.1:NNNN')\n"
            "  2. Constructs a RelayClient pointed at ws://<host>/api/relay/ws\n"
            "     (or wss:// — the audit fixture serves plain ws:// for simplicity)\n"
            "  3. Calls connect() with project='audit', token='audit', contexts=['audit_ctx']\n"
            "  4. Subscribes to 'audit_ctx'\n"
            "  5. Waits up to 5 seconds for one inbound event, dispatches it, exits 0\n"
            "  6. Exits non-zero on any error",
            file=sys.stderr,
        )
        return 3

    fixture_port, state, _th = _start_fixture()
    if verbose:
        print(f"[verbose] fixture listening on 127.0.0.1:{fixture_port}", file=sys.stderr)

    env = os.environ.copy()
    env["SIGNALWIRE_RELAY_HOST"] = f"127.0.0.1:{fixture_port}"
    env["SIGNALWIRE_RELAY_SCHEME"] = "ws"
    env["SIGNALWIRE_PROJECT_ID"] = "audit"
    env["SIGNALWIRE_API_TOKEN"] = "audit"
    env["SIGNALWIRE_CONTEXTS"] = "audit_ctx"
    env["SIGNALWIRE_LOG_MODE"] = "off"

    build = runner.build_cmd(root, fixture_port) if runner.build_cmd else None
    if build:
        if verbose:
            print(f"[verbose] build: {' '.join(build)}", file=sys.stderr)
        try:
            cp = subprocess.run(build, cwd=root, env=env, capture_output=True, timeout=300)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            print(f"audit_relay_handshake: build error: {e}", file=sys.stderr)
            return 2
        if cp.returncode != 0:
            print("audit_relay_handshake: build failed:", file=sys.stderr)
            sys.stderr.write(cp.stderr.decode(errors="replace"))
            return 1

    cmd = runner.run_cmd(root, fixture_port)
    if verbose:
        print(f"[verbose] running harness: {' '.join(cmd)}", file=sys.stderr)
    try:
        proc = subprocess.Popen(cmd, cwd=root, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError as e:
        print(f"audit_relay_handshake: runtime not available: {e}", file=sys.stderr)
        return 2

    try:
        try:
            stdout, stderr = proc.communicate(timeout=20)
        except subprocess.TimeoutExpired:
            proc.kill()
            stdout, stderr = proc.communicate(timeout=3)
            print("audit_relay_handshake: harness timed out (>20s)", file=sys.stderr)
            sys.stderr.write(stderr.decode(errors="replace")[:1000])
            return 1

        if verbose:
            sys.stderr.write("[verbose] harness stdout:\n" + stdout.decode(errors="replace")[:1000] + "\n")
            sys.stderr.write("[verbose] harness stderr:\n" + stderr.decode(errors="replace")[:1000] + "\n")

        # Evaluate fixture state.
        problems = []
        if not state.upgrade_seen:
            problems.append(
                "fixture saw no WSS upgrade — RelayClient never opened a real "
                "socket (likely a stub transport)."
            )
        if not state.connect_request:
            problems.append("fixture saw no `signalwire.connect` request — handshake didn't start.")
        else:
            # Python (signalwire/relay/client.py:260-269) nests credentials
            # under `params.authentication`. Older drafts placed `project`
            # at top-level params. Accept either.
            params = state.connect_request.get("params", {})
            top_project = params.get("project")
            auth = params.get("authentication", {}) if isinstance(params.get("authentication"), dict) else {}
            nested_project = auth.get("project") if isinstance(auth, dict) else None
            nested_jwt = auth.get("jwt_token") if isinstance(auth, dict) else None
            if not (top_project or nested_project or nested_jwt):
                problems.append(
                    "signalwire.connect was missing project credentials in either "
                    f"`params.project` or `params.authentication.{{project,jwt_token}}`: {params}"
                )
        if not state.subscribe_seen:
            problems.append(
                "fixture saw no `signalwire.subscribe` — client connected but never subscribed."
            )
        if not state.event_dispatched and state.upgrade_seen and state.subscribe_seen:
            # Event-dispatch is only checked if subscribe happened (otherwise
            # the client was never going to be able to receive).
            problems.append(
                "client never ACKed the inbound `signalwire.event` we pushed — "
                "either the dispatch path is broken or the client closed early."
            )
        if state.error:
            problems.append(f"fixture error: {state.error}")
        if proc.returncode != 0:
            problems.append(f"harness exited non-zero: {proc.returncode}")

        if not problems:
            print(
                f"audit_relay_handshake: clean. {runner.name}: WS upgraded, "
                f"connect+subscribe sent, event ACKed, exit 0."
            )
            return 0

        print(f"audit_relay_handshake: {runner.name} failed.", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=3)
        for stale in [root / "_audit_relay"]:
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
        print(f"audit_relay_handshake: --root {root} is not a directory", file=sys.stderr)
        return 2

    return run(root, args.verbose)


if __name__ == "__main__":
    sys.exit(main())
