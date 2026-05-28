# PORT_EXAMPLE_OMISSIONS

<!--
  Lists Python examples that are intentionally NOT ported to Perl.
  Format: `- <python-stem>: <one-line rationale>` (matches the parser
  in porting-sdk/scripts/audit_example_parity.py).

  The default skip pattern in audit_example_parity catches names that
  start with `bedrock_`, `search_`, `pgvector_`, `sigmond_` or
  `datasphere_serverless_`. Examples that contain those tokens but
  don't START with them slip through and have to be listed here.
-->

## Search-related examples (Python-only feature)

- `local_search_agent`: search-related — Python ships a vector-search /
  knowledge-base feature whose `search_` skill is in the documented skip
  list (PORTING_GUIDE Phase 11). Perl follows the existing parity rule
  that excludes the search subsystem; this example exercises that
  subsystem and so is omitted alongside the rest of `*_search*` /
  `*_pgvector*` examples.
