# STRling Perl adapter

STRling 4.0.3 public installation requires the separately authorized release.
Check the release certificate for public availability and independent acceptance.
Candidate tests use staged artifacts; certification alone does not prove publication.
See the [support matrix](../../docs/support-matrix.md) for exact supported scopes.

This distribution is a thin Perl projection of the canonical STRling compiler. `FFI::Platypus` carries strict JSON over a caller-selected `strling.c-abi` version 1 library. The distribution no longer owns parsing, semantics, validation, target selection, or regex emission.

The adapter is a provisional Preview candidate during the Fourth Edition migration. This is not a publication or permanent support-tier promise.

## Requirements

-   Perl `>= 5.10, < 6.0`
-   `FFI::Platypus >= 2.10` and `JSON::PP >= 4.00`
-   a compatible native STRling library chosen by the application

## Use

Pass the authenticated absolute native-library path as the first program argument.
The example requires an installed package and its declared dependencies.

```perl
use STRling qw(load_native source_compile_request simply_builder_request email);

my $client = load_native($ARGV[0] // die 'pass the authenticated absolute native path');
my $result = $client->compile(source_compile_request('semantic strling 1.0; case sensitive; pattern text "hello";'));

die 'canonical compile failed' unless $result->{outcome} eq 'succeeded';

my $builder = simply_builder_request([email('root')], 'root');
my $simply_result = $client->simply_compile($builder);

die 'Simply compile failed' unless $simply_result->{status} eq 'success'
    && $simply_result->{compile_result}{outcome} eq 'succeeded';
$client->close();
```

Generated helpers are lexical-shape recipes, not semantic validators. Native loading is absolute and explicit; ABI, symbol, encoding, JSON, duplicate-property, size, ownership, and closed-client failures stop execution. No ambient lookup or alternate compiler route exists.

See the [canonical interop contract](../../spec/interop/1.0/README.md) and the [migration record](../../docs/migration/dynamic-language-adapter-migration.md).

## Proposed public installation

After separately authorized publication, the exact proposed coordinate is:

```bash
cpanm STRling@4.0.3
```

The exact approved PAUSE owner and release archive must be reconciled in the protected publication handoff. Dependency-locking limits remain Preview.
