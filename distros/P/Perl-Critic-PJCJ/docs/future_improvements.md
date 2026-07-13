# Future Improvements

Potential improvements that have been analysed but not yet implemented.

## Cache `would_interpolate` results

**Area:** Performance **Policy:** RequireConsistentQuoting

### Problem

`would_interpolate()` creates a new `PPI::Document` for every call by wrapping
the string in double quotes and parsing it. When processing use statements,
`_is_in_use_statement()` is called for every quoted token and re-checks all
arguments in the enclosing use statement. This causes heavy duplication.

### Benchmark data (February 2026)

A test input with 20 use statements (3 arguments each), 30 double-quoted
strings, and 10 single-quoted strings produced:

- 250 calls to `would_interpolate`, each creating a PPI document
- Only 13 unique strings - 237 calls (95%) were duplicates
- The three argument strings were each checked 80 times

Micro-benchmarking showed a 2x throughput improvement when each string was
checked twice instead of once (the simplest duplication case). With 80x
duplication the savings would be larger.

### Why not implemented

This is lint-time cost on a per-file basis. For a typical module with a handful
of use statements, the absolute time saved is milliseconds. The cache would add
complexity (a hash attribute, invalidation between files) to solve a problem
nobody has reported. Worth revisiting if profiling shows it matters on large
codebases.

### Implementation sketch

Add a hash attribute `_interpolation_cache` to the policy object, keyed on
string content. Clear it in `prepare_to_scan_document` (called by Perl::Critic
before each file). Look up before calling `PPI::Document->new`.

## Add coverage reporting to CI

**Area:** CI

### Problem

Coverage is only available locally via `make cover-compilation`. Adding
Coveralls or Codecov integration would show coverage trends over time and catch
regressions in pull requests.

### Why not implemented

Low priority - the coverage baseline is already high (97%+) and the project has
few contributors. Worth adding if the contributor base grows.

## Make rules individually configurable

**Area:** Feature **Policy:** RequireConsistentQuoting

### Problem

The policy has zero `supported_parameters`. Users cannot choose their preferred
quote style, exclude specific token types, or enable/disable individual rules
(reduce punctuation, prefer interpolated, delimiter preference).

### Why not implemented

The current opinionated approach is intentional - the policy enforces a single
consistent style. Adding configurability would increase complexity and the
amount of testing needed. Worth considering if users request specific
customisation.

## Add `pre-commit run --all-files` to CI

**Area:** CI

### Problem

Pre-commit checks (including perlcritic, perltidy, markdownlint, typos) only run
locally. CI does not verify that all hooks pass.

### Why not implemented

Low priority - the existing CI runs `dzil test` which covers correctness.
Pre-commit enforcement would catch formatting and style regressions but is not
blocking.
