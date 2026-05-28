#!/usr/bin/env python3
"""diff_port_surface.py — compare a port's public API against the Python reference.

This is language-agnostic: each port ships its own enumerator that emits a JSON
file in the same shape as ``python_surface.json``. This script compares the two
and applies ``PORT_OMISSIONS.md`` / ``PORT_ADDITIONS.md`` exemptions before
reporting drift.

Port enumerator JSON shape (see ``enumerate_python.py`` for the reference)::

    {
      "version": "1",
      "modules": {
        "signalwire.core.agent_base": {
          "classes": {
            "AgentBase": ["__init__", "set_prompt", ...]
          },
          "functions": [...]
        }
      }
    }

Symbol naming: ports MUST translate their native names to the Python
reference's dotted module + snake_case name at enumeration time. Otherwise
diffs don't line up. Example: TypeScript's ``setPromptText`` must be emitted
as ``set_prompt_text`` under module ``signalwire.core.agent_base``, class
``AgentBase``.

PORT_OMISSIONS.md / PORT_ADDITIONS.md format (one symbol per line)::

    # Comment lines begin with '#' and are ignored
    signalwire.core.fabric.GenericResources.assign_phone_route: Java ships only the good path — see phone-binding.md
    signalwire.core.fabric.SwmlWebhooksResource.create: auto-materialized by phone_numbers.set_swml_webhook

Exit 0 if clean, 1 if drift exists (unexcused missing or extra symbols).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def load_json(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit(f"error: {path} not found")
    return json.loads(path.read_text(encoding="utf-8"))


def flatten_symbols(surface: dict) -> set[str]:
    """Return fully-qualified symbol names in the Python dotted form.

    Module-level functions:  <module>.<function>
    Class:                   <module>.<Class>
    Class method:            <module>.<Class>.<method>
    """
    symbols: set[str] = set()
    for mod, entry in surface.get("modules", {}).items():
        for fn in entry.get("functions", []):
            symbols.add(f"{mod}.{fn}")
        for cls, methods in entry.get("classes", {}).items():
            symbols.add(f"{mod}.{cls}")
            for method in methods:
                symbols.add(f"{mod}.{cls}.{method}")
    return symbols


def parse_exemption_file(path: Path) -> dict[str, str]:
    """Read an omissions/additions markdown file.

    Returns {symbol: rationale}. Skips blank lines, header lines (``#``),
    and any ``- [ ]`` checklist-like noise.

    Symbol grammar: a dotted path of identifiers. Each segment is
    ``[A-Za-z_]\\w*``; the **last** segment may end in ``?`` or ``!`` to
    accommodate Ruby-style predicate/bang names (``has_skill?``,
    ``reset!``). Python-port symbols never contain those characters, so
    the extension is purely additive.
    """
    if not path.is_file():
        return {}
    exemptions: dict[str, str] = {}
    line_pattern = re.compile(
        r"^\s*(?P<symbol>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*[?!]?)\s*:\s*"
        r"(?P<why>.+?)\s*$"
    )
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        m = line_pattern.match(raw)
        if m:
            exemptions[m["symbol"]] = m["why"]
    return exemptions


def diff(
    reference: set[str], port: set[str],
    omissions: dict[str, str], additions: dict[str, str],
) -> tuple[list[str], list[str]]:
    """Return (unexcused_missing, unexcused_extra)."""
    missing = sorted(reference - port)
    extra = sorted(port - reference)
    unexcused_missing = [s for s in missing if s not in omissions]
    unexcused_extra = [s for s in extra if s not in additions]
    return unexcused_missing, unexcused_extra


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reference", type=Path, required=True,
        help="Python reference surface JSON (porting-sdk/python_surface.json)",
    )
    parser.add_argument(
        "--port-surface", type=Path, required=True,
        help="Port's JSON in the same shape",
    )
    parser.add_argument(
        "--omissions", type=Path, default=None,
        help="Path to PORT_OMISSIONS.md (deliberate non-implementations)",
    )
    parser.add_argument(
        "--additions", type=Path, default=None,
        help="Path to PORT_ADDITIONS.md (port-only extensions)",
    )
    parser.add_argument(
        "--port-additions-actual", type=Path, default=None,
        help="Path to port_additions_actual.json — the inventory the "
             "port's enumerator emits of every public symbol that has no "
             "Python-canonical counterpart. When supplied, every entry "
             "must also appear in --additions (PORT_ADDITIONS.md) or the "
             "audit fails. Closes the silent-drop gap (cmd/enumerate-"
             "surface/main.go:1452+ for Go).",
    )
    parser.add_argument("--json", action="store_true", help="Emit JSON report")
    args = parser.parse_args(argv)

    ref_symbols = flatten_symbols(load_json(args.reference))
    port_symbols = flatten_symbols(load_json(args.port_surface))
    omissions = parse_exemption_file(args.omissions) if args.omissions else {}
    additions = parse_exemption_file(args.additions) if args.additions else {}

    missing, extra = diff(ref_symbols, port_symbols, omissions, additions)

    # PORT_ADDITIONS.md enforcement: every symbol the enumerator dropped on
    # the floor (because it has no Python-canonical mapping) must also be
    # explicitly recorded in --additions. Adapters that silently drop
    # symbols mask drift; this gate makes additions visible.
    #
    # Match is strict: the exact key emitted in port_additions_actual.json
    # (Go-native short form, e.g. ``agent.WithSTT``) must appear verbatim
    # in PORT_ADDITIONS.md. We don't fuzzy-match across packages — that
    # would let ``livewire.WithSTT`` excuse ``agent.WithSTT`` despite them
    # being different functions in different packages.
    unrecorded_additions: list[str] = []
    if args.port_additions_actual:
        actual_doc = load_json(args.port_additions_actual)
        actual_keys = (
            list(actual_doc.get("structs", []))
            + list(actual_doc.get("functions", []))
        )
        addition_keys = set(additions.keys())
        unrecorded_additions = sorted(
            k for k in actual_keys if k not in addition_keys
        )

    if args.json:
        payload = {
            "drift": bool(missing or extra or unrecorded_additions),
            "unexcused_missing": missing,
            "unexcused_extra": extra,
            "unrecorded_additions": unrecorded_additions,
            "excused_omissions": sorted(
                s for s in (ref_symbols - port_symbols) if s in omissions
            ),
            "excused_additions": sorted(
                s for s in (port_symbols - ref_symbols) if s in additions
            ),
        }
        print(json.dumps(payload, indent=2))
    else:
        if missing:
            print(f"\033[31m✗\033[0m {len(missing)} Python symbol(s) missing from port "
                  f"(and not in PORT_OMISSIONS.md):")
            for s in missing:
                print(f"    - {s}")
        if extra:
            print(f"\033[31m✗\033[0m {len(extra)} port symbol(s) not in Python reference "
                  f"(and not in PORT_ADDITIONS.md):")
            for s in extra:
                print(f"    + {s}")
        if unrecorded_additions:
            print(f"\033[31m✗\033[0m {len(unrecorded_additions)} port symbol(s) "
                  f"silently dropped by the enumerator (not in PORT_ADDITIONS.md):")
            for s in unrecorded_additions:
                print(f"    + {s}")
        if not missing and not extra and not unrecorded_additions:
            print(f"\033[32m✓\033[0m port matches Python reference "
                  f"({len(port_symbols)} symbols; "
                  f"{len(omissions)} excused omissions, "
                  f"{len(additions)} excused additions)")

    return 1 if (missing or extra or unrecorded_additions) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
