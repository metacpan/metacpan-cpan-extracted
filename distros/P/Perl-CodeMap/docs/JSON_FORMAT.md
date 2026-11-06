# JSON export format (version 1)

`--json PATH` writes UTF-8 JSON that has the same structure embedded in the
report. The `format` key is `1` for releases that include it. Older prototype
exports without that key may still be rendered with `--from-json`.

Top-level fields:

| Field | Type | Meaning |
|---|---|---|
| `format` | integer | Format revision (`1`) |
| `name` | string | Display name |
| `module` | string | Scanned source path (may be an absolute private path) |
| `parser` | string | `ppi` or `lite` |
| `scanned_files` | integer | Unique scanned files |
| `source` | string | Optional browser URL prefix |
| `rev` | string | Optional Git commit SHA |
| `pkgs` | array | Package records |
| `sources` | object | Map of relative file path to source text when embedded |
| `warnings` | array | Non-fatal warnings |

Each `pkgs[]` entry has `path` (namespace), `dir`, `doc`, `imports`
(array of local namespace names), and `files` (array). Each `files[]` entry has
`path`, `name`, `lines`, and `funcs`. Each `funcs[]` has:

- `n`: declaration name
- `l`: 1-based start line
- `s`: source-line count
- `k`: `sub` or `method`
- `e`: boolean; true when the name does not begin with `_` (not an Exporter flag)
- `d`: preceding comment description

Example (synthetic):

```json
{
  "format": 1,
  "name": "Demo",
  "module": "./examples/sample/lib",
  "parser": "ppi",
  "scanned_files": 1,
  "source": "",
  "rev": "",
  "pkgs": [{
    "path": "Demo::Config", "dir": "Demo", "doc": "", "imports": [],
    "files": [{ "path": "Demo/Config.pm", "name": "Config.pm", "lines": 5,
      "funcs": [{"n":"get","l":3,"s":2,"k":"sub","e":true,"d":""}] }]
  }],
  "sources": {},
  "warnings": []
}
```

**Privacy:** JSON generated with default settings contains source code. Even
when embedding is disabled, file names and paths may expose confidential
architecture information. Public examples must be synthetic.
