#!/usr/bin/env python3
"""audit_cross_port_consistency.py — catch adapter drift across ports.

Phase 6 of the cross-language signature audit (see SIGNATURE_AUDIT_PLAN.md).

The trust model already includes:
  - Schema validation (boundary structural check)
  - Golden tests per adapter (lock translation cases)
  - Loud failure on unknown types (forces a documented decision)

This adds the **cross-port** check: take every fully-qualified method
that exists in ≥2 ports' port_signatures.json files, normalize the
canonical signatures (sort union members, strip whitespace), and assert
they're byte-identical. If TS's adapter starts emitting ``string`` while
.NET's emits ``String`` for the same method, this fires the day it
happens — independent of the per-adapter goldens.

Inputs (each --port-signatures argument):
    /path/to/signalwire-XX/port_signatures.json

Each path contributes one port to the comparison set. The script doesn't
care which port is "right"; it cares that they all agree. Most ports
will already have documented divergences in their own
PORT_SIGNATURE_OMISSIONS.md; this audit is for catching adapter bugs
that aren't documented divergences.

Usage:
    python3 audit_cross_port_consistency.py \\
        --port dotnet=/home/devuser/src/signalwire-dotnet/port_signatures.json \\
        --port go=/home/devuser/src/signalwire-go/port_signatures.json \\
        ...

    python3 audit_cross_port_consistency.py --auto      # autodiscover
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from collections import defaultdict, Counter

HERE = Path(__file__).resolve().parent
PSDK = HERE.parent

# Default port locations (autodiscovery)
DEFAULT_PORT_SIGNATURES = {
    "python":     "/usr/local/home/devuser/src/porting-sdk/python_signatures.json",
    "dotnet":     "/home/devuser/src/signalwire-dotnet/port_signatures.json",
    "go":         "/home/devuser/src/signalwire-go/port_signatures.json",
    "typescript": "/home/devuser/src/signalwire-typescript/port_signatures.json",
    "java":       "/home/devuser/src/signalwire-java/port_signatures.json",
    "php":        "/home/devuser/src/signalwire-php/port_signatures.json",
    "rust":       "/home/devuser/src/signalwire-rust/port_signatures.json",
    "ruby":       "/home/devuser/src/signalwire-ruby/port_signatures.json",
    "perl":       "/home/devuser/src/signalwire-perl/port_signatures.json",
    "cpp":        "/home/devuser/src/signalwire-cpp/port_signatures.json",
}


# ---------------------------------------------------------------------------
# Index helpers (mirror diff_port_signatures.py)
# ---------------------------------------------------------------------------


def index_signatures(inv: dict) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for mod, mod_entry in inv.get("modules", {}).items():
        for cls, cls_entry in mod_entry.get("classes", {}).items():
            for m, sig in cls_entry.get("methods", {}).items():
                out[f"{mod}.{cls}.{m}"] = sig
        for fn, sig in mod_entry.get("functions", {}).items():
            out[f"{mod}.{fn}"] = sig
    return out


def normalize_type(t: str) -> str:
    if t is None:
        return "any"
    t = t.replace(" ", "")
    if t.startswith("union<") and t.endswith(">"):
        inner = t[len("union<"):-1]
        parts = sorted(normalize_type(p) for p in _split_top_commas(inner))
        return "union<" + ",".join(parts) + ">"
    if "<" in t and t.endswith(">"):
        idx = t.index("<")
        head = t[:idx]
        inner = t[idx + 1:-1]
        parts = _split_top_commas(inner)
        return head + "<" + ",".join(normalize_type(p) for p in parts) + ">"
    return t


def _split_top_commas(s: str) -> list[str]:
    out, buf, depth = [], [], 0
    for ch in s:
        if ch == "<":
            depth += 1
        elif ch == ">":
            depth -= 1
        if ch == "," and depth == 0:
            out.append("".join(buf))
            buf.clear()
            continue
        buf.append(ch)
    if buf:
        out.append("".join(buf))
    return [p.strip() for p in out]


def normalize_signature(sig: dict) -> str:
    """Render a canonical signature into a normalized string form for
    byte comparison across ports. Strips defaults (since Python's optional
    convention differs from Go/Rust's no-default convention) and keeps
    only the structural shape: param name + kind + normalized type +
    return type."""
    params: list[str] = []
    for p in sig.get("params", []):
        if p.get("kind") in ("self", "cls"):
            params.append(f"{p.get('kind')}")
            continue
        kind = p.get("kind", "positional")
        name = p.get("name", "")
        ptype = normalize_type(p.get("type", "any"))
        required = p.get("required", True)
        params.append(f"{kind}:{name}:{ptype}:{'required' if required else 'optional'}")
    returns = normalize_type(sig.get("returns", "any"))
    return "|".join(params) + " -> " + returns


# ---------------------------------------------------------------------------
# Cross-port comparison
# ---------------------------------------------------------------------------


def compare(ports: dict[str, dict]) -> tuple[list[dict], dict]:
    """Compare every method present in ≥2 ports.

    Returns (drift_records, summary)."""
    indexed = {p: index_signatures(d) for p, d in ports.items()}
    method_to_ports: dict[str, dict[str, str]] = defaultdict(dict)
    for port, idx in indexed.items():
        for sym, sig in idx.items():
            method_to_ports[sym][port] = normalize_signature(sig)

    drift: list[dict] = []
    consistent = 0
    multi_port_total = 0
    for sym, by_port in method_to_ports.items():
        if len(by_port) < 2:
            continue
        multi_port_total += 1
        unique_norms = set(by_port.values())
        if len(unique_norms) == 1:
            consistent += 1
            continue
        # Drift: cluster ports by normalized form
        clusters: dict[str, list[str]] = defaultdict(list)
        for port, norm in by_port.items():
            clusters[norm].append(port)
        drift.append({
            "symbol": sym,
            "clusters": [
                {"normalized_signature": k, "ports": sorted(v)}
                for k, v in sorted(clusters.items(), key=lambda kv: -len(kv[1]))
            ],
        })

    summary = {
        "total_methods_in_2plus_ports": multi_port_total,
        "byte_identical_methods": consistent,
        "drift_methods": len(drift),
        "consistency_pct": round(consistent / multi_port_total * 100, 2) if multi_port_total else 0.0,
    }
    return drift, summary


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--port", action="append", default=[],
        help="<name>=<path/to/port_signatures.json>; repeat to add ports.",
    )
    parser.add_argument(
        "--auto", action="store_true",
        help="Discover ports from default locations.",
    )
    parser.add_argument(
        "--head", type=int, default=20,
        help="Show first N drift entries in text output (default 20).",
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Emit drift report as JSON instead of text.",
    )
    parser.add_argument(
        "--max-drift-pct", type=float, default=None,
        help="Fail if drift % exceeds this. Without this, the script "
             "reports drift but always exits 0 (the cross-port probe is "
             "informational until the adapters mature).",
    )
    args = parser.parse_args()

    ports: dict[str, dict] = {}
    if args.auto:
        for name, path in DEFAULT_PORT_SIGNATURES.items():
            p = Path(path)
            if not p.is_file():
                print(f"  skipping {name}: no signatures at {p}", file=sys.stderr)
                continue
            ports[name] = json.loads(p.read_text(encoding="utf-8"))
    for spec in args.port:
        if "=" not in spec:
            print(f"--port must be NAME=PATH, got {spec!r}", file=sys.stderr)
            return 2
        name, path = spec.split("=", 1)
        ports[name] = json.loads(Path(path).read_text(encoding="utf-8"))

    if len(ports) < 2:
        print("audit_cross_port_consistency: need ≥2 ports to compare", file=sys.stderr)
        return 2

    drift, summary = compare(ports)

    if args.json:
        print(json.dumps({"summary": summary, "drift": drift}, indent=2))
        return 0

    print(
        f"audit_cross_port_consistency: {summary['consistency_pct']:.2f}% "
        f"byte-identical ({summary['byte_identical_methods']} of "
        f"{summary['total_methods_in_2plus_ports']} methods present in ≥2 ports)"
    )
    if drift:
        print(f"\n{len(drift)} method(s) with drift:\n")
        for entry in drift[: args.head]:
            print(f"  {entry['symbol']}:")
            for c in entry["clusters"]:
                ports_str = ", ".join(c["ports"])
                print(f"    [{ports_str}]")
                print(f"        {c['normalized_signature']}")
            print()
        if len(drift) > args.head:
            print(f"  ... ({len(drift) - args.head} more; use --json for full report)")

        # Per-port "most often involved in drift" heatmap
        port_drift_count: Counter = Counter()
        for entry in drift:
            for c in entry["clusters"]:
                # Count "outlier" ports as those in the smaller cluster
                if len(c["ports"]) < max(len(c2["ports"]) for c2 in entry["clusters"]):
                    for p in c["ports"]:
                        port_drift_count[p] += 1
        if port_drift_count:
            print("\nPer-port outlier count (smaller-cluster member in drift):")
            for p, n in port_drift_count.most_common():
                print(f"  {p}: {n}")

    if args.max_drift_pct is not None:
        actual_pct = 100 - summary["consistency_pct"]
        if actual_pct > args.max_drift_pct:
            print(
                f"\n\033[31m✗\033[0m drift {actual_pct:.2f}% > "
                f"--max-drift-pct {args.max_drift_pct:.2f}%",
                file=sys.stderr,
            )
            return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
