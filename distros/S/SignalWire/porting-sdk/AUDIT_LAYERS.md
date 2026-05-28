# Audit layers — what each program in `scripts/` actually catches

The porting-sdk ships eleven audits and one diff tool. Together they guard
against drift between the Python reference SDK (`signalwire-python`) and
the nine ports (.NET, Java, TypeScript, Rust, Go, Ruby, PHP, Perl, C++).
This file is the canonical answer to "what does the audit suite catch?" —
read this before claiming a coverage gap exists.

## The programs

| Program | What it catches | What it does NOT catch |
| --- | --- | --- |
| `diff_port_surface.py` | Names-only API drift: a public Python symbol missing from the port (or vice versa) and not excused via `PORT_OMISSIONS.md` / `PORT_ADDITIONS.md`. | Method signatures, types, defaults, returns. (See `diff_port_signatures.py` once Phase 1 of the signature-audit plan ships.) |
| `audit_stubs.py` | Stub markers in shipped code: comment patterns like `// stub`, `// in production this would …`, canned-data placeholders. | Stubs that omit the comment marker and ship believable canned data. (Caught instead by the behavioral audits below.) |
| `audit_no_cheat_tests.py` | Tests that pass without exercising real behavior — `assert True`, nullness-only assertions, mocking the very thing under test. | Tests that exercise real behavior on the wrong contract. |
| `audit_http_swml.py` | The SDK's `SWMLService` actually binds an HTTP listener, accepts GET → SWML doc, accepts POST → real handler dispatch. | Whether the SWML it returns is *correct*; only that the transport works end-to-end. |
| `audit_relay_handshake.py` | The SDK opens a real WebSocket, sends `signalwire.connect` + `signalwire.subscribe`, ACKs an event, exits 0. | Higher-level RELAY semantics; only that the wire layer is real. |
| `audit_skills_dispatch.py` | Each network skill issues a real outbound HTTP request to a fixture, with the right method/path/headers/body, and parses the canned response correctly. | Skills exercised but not covered by `SKILL_PROBES`. |
| `audit_rest_transport.py` | Each REST operation makes a real HTTP request to the fixture with the right shape (method, path, auth, body). | Response-parsing correctness for fields the audit doesn't sentinel-check. |
| `audit_example_parity.py` | Every Python example has a matching example in the port (or is excused via `PORT_EXAMPLE_OMISSIONS.md`). | Whether the port's example actually does the same thing. |
| `audit_test_parity.py` | Every Python test has a matching test in the port (or is excused via `PORT_TEST_OMISSIONS.md`). | Whether the port's test actually verifies the same property. |
| `audit_docs.py` | Phantom API references in `docs/` and `examples/` — method names mentioned in fenced code blocks that don't exist in `port_surface.json`. | Doc text that's wrong but doesn't reference a method (e.g. wrong parameter description). |
| `audit_checklist.py` | The reference Python checklists (skills, prefabs, REST namespaces, agent/REST/relay docs and examples) match the actual filesystem state. | Drift outside the directories the checklist enumerates. |

## What none of the audits catch (yet)

- **Method signature drift** — see `SIGNATURE_AUDIT_PLAN.md`. The new
  `diff_port_signatures.py` (Phase 1) closes this once shipped.
- **Behavior parity for methods outside the behavioral fixtures** — e.g.
  a getter that returns `self.name` is not exercised by any audit. The
  Phase 5 coverage map quantifies this gap and ratchets via CI; closing
  it (writing more fixtures) is a separate program.
- **Architectural drift in non-public internals** — by design. The
  audits target the public API surface that ports promise to keep aligned.

## Where to add new audits

If you find a class of drift that none of the eleven audits above
catches, the bar for adding a new audit is:

1. Reproduce the drift with a runnable program (one of the existing
   audit scripts is a good template).
2. Confirm at least one of the existing audits *should* have caught it
   and didn't — i.e. it's a gap, not a duplicate.
3. Add the new audit script to `scripts/`, hook it into
   `audit_checklist.py` if it produces a checklist signal, document it
   here.

If you cannot do step 1 — i.e. the drift is hypothetical or you can only
describe how it might manifest — the right move is to write a follow-up
issue, not a new audit. The audit suite catches what programs prove,
not what reviewers worry about.
