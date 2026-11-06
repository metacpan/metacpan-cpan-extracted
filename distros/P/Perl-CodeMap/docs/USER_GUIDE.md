# User guide

## Installation paths

The published [Perl::CodeMap](https://metacpan.org/pod/Perl::CodeMap)
distribution is available on [CPAN](https://metacpan.org/dist/Perl-CodeMap)
under PAUSE author [MULLER](https://metacpan.org/author/MULLER).

Install on Perl 5.20 or newer:

```sh
cpanm Perl::CodeMap
cpanm PPI  # strongly recommended for accurate parsing
perl-codemap --version
```

For development, run directly from the checkout with
`perl bin/perl-codemap`, or build from source using
`perl Makefile.PL && make && make test && make install`.


The `auto` parser uses PPI when installed, otherwise the lite parser. To require
PPI explicitly, pass `--parser ppi`; the command fails clearly if unavailable.

## Embedded CLI and Perl API manuals

Perl CodeMap ships complete embedded Perl POD, available immediately after
installation from CPAN:

```sh
perl-codemap --help              # CLI synopsis and all options
perl-codemap --man               # full manual, examples, exit statuses
perldoc perl-codemap             # installed executable's POD
perldoc Perl::CodeMap            # documented Perl library API
man perl-codemap                 # Unix section 1 man page
```

The CLI manual is embedded in `bin/perl-codemap`; the library manual is
embedded in `lib/Perl/CodeMap.pm`, which MetaCPAN renders as the primary
[Perl::CodeMap documentation](https://metacpan.org/pod/Perl::CodeMap).
These are the canonical references, rather than the table below.

## CLI reference

| Option | Description | Default |
|---|---|---|
| `--root DIR` | Source directory; with `--from-json` can hydrate source | current directory |
| `-o`, `--output FILE` | Self-contained HTML output | `perl-code-map.html` |
| `--json FILE` | Optional JSON export | none |
| `--from-json FILE` | Render a previously generated CodeMap JSON | none |
| `--parser auto\|ppi\|lite` | Static parser | `auto` |
| `--embed-source` | Include source in HTML/JSON | enabled |
| `--no-embed-source` | Omit embedded sources | disabled |
| `--max-source-bytes N` | Maximum bytes to embed per source file | `2000000` |
| `--include-tests` | Scan `.t` tests and `t/`, `xt/`, `tests/` directories | off |
| `--source-base URL` | Repository URL prefix for relative paths | GitHub auto-detection when possible |
| `--name TITLE` | Report name | scanned root basename |
| `--version` | Print version | — |
| `--help` | Display usage and option descriptions from POD | — |
| `--man` | Display the complete embedded CLI manual | — |

A report contains all discovered *internal* package dependencies; standard
library and CPAN packages are not drawn as graph nodes unless they exist in the
scanned tree.

## Source browsing

Selecting a package shows its files and functions. Selecting a function or
**view code** opens a source viewer with line numbers and Perl syntax
highlighting. The viewer embeds Prism's Perl grammar within the HTML, so it
also works with airplane mode and local `file://` URLs.

The source viewer renders 160 lines at a time, with Previous/Next controls,
Go to line, and deep-link hashes (`#source=...&line=...`). The target line is
highlighted. This bounds DOM usage for large source files.

### Linking to source on GitHub or GitLab

Add `--source-base` when scanning a subdirectory (for example `lib/`) and
supply the **URL of that subdirectory**, ending in `/`:

```sh
perl-codemap --root ./lib \
  --source-base 'https://gitlab.example.org/team/project/-/blob/COMMIT/lib/' \
  --output architecture.html
```

Each file's relative path and line anchor (`#L123`) will be appended. This is
an example placeholder; substitute the correct repository and immutable commit
SHA. GitHub `origin` remotes are auto-detected for a matching local checkout.

## Large trees

The top-level graph groups namespaces when the set would exceed 32 nodes.
Click a namespace to drill down, then select a package to see a focused set of
its direct dependencies and dependents. Use the page controls to see other
groups in a large scope. Search remains global even when the graph shows a
limited view.

## CI integration

The HTML can be uploaded as an ordinary build artifact. For a private
repository, keep the artifact private, set a short retention period, and avoid
public Pages publishing:

```yaml
perl-codemap:
  image: perl:5.40
  script:
    - cpanm --notest Perl::CodeMap PPI
    - perl-codemap --parser ppi --root . --output map.html --json map.json
  artifacts:
    paths: [map.html, map.json]
    expire_in: 7 days
```

This example installs CodeMap from CPAN and assumes CPAN access from CI.
For reproducibility, pin the distribution version or install a verified
release archive; never publish reports generated from private source trees.

## Troubleshooting

**Blank report:** Check that JavaScript is enabled and review the browser
console. The bundled report has no network dependencies. A malformed report or
unsupported browser may still prevent rendering.

**Missing source:** The JSON was generated with `--no-embed-source`, the
original file was over the embedding limit, or the file is absent. Rescan or
rehydrate it with `--from-json … --root ORIGINAL_SOURCE`.

**No packages:** Verify `--root` points to the actual Perl source tree. Only
`.pm`, `.pl`, `.psgi`, optional `.t`, and extensionless Perl-shebang files are
scanned. Hidden, vendor, and build directories are skipped.

**Unexpected graph edges:** Dependency detection is intentionally static and
limited to recognized package imports and inheritance. Use `--parser ppi` for
higher-quality declarations, but not for complete runtime call graphs.
