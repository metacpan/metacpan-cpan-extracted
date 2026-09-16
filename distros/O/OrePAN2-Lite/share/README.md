# OrePAN2::Lite

A dependency-light fork of [OrePAN2](https://metacpan.org/pod/OrePAN2) — a
DarkPAN manager for hosting private Perl module archives — trimmed for use in
environments where install footprint matters: AWS Lambda and minimal containers.

`OrePAN2::Lite` keeps the parts of OrePAN2 that matter for a private DarkPAN —
**injection** and **indexing** — and removes the heavy dependencies and the
sub-commands that pulled them in.

## What is a DarkPAN?

A DarkPAN is a private, CPAN-compatible mirror. It holds tarballs you've built
yourself — internal distributions, forks of CPAN modules, or anything you want
to install with `cpanm`/`cpm` without publishing to CPAN. `cpanm` and `cpm` can
be pointed at a DarkPAN the same way they talk to CPAN.

## What changed in 2.0.0

2.0.0 is a substantial diet. The goal is a **foundational** tool with a small,
predictable dependency tree — because a tool that sits in the bootstrap/install
path imposes its dependencies on everything downstream.

### Removed features

- **`orepan2-audit` / `OrePAN2::Auditor`** — removed. Comparing a DarkPAN
  against CPAN is better expressed as a query than as a bundled sub-command,
  and it pulled `MooX::Options` and `List::Compare`.
- **All command-line scripts** (`orepan2-inject`, `orepan2-indexer`,
  `orepan2-gc`, `orepan2-merge-index`, `orepan2-audit`) — removed.
  `OrePAN2::Lite` is now a **library**: drive it from your own code (a Lambda
  handler, a build script, a wrapper CLI). Dropping the CLIs removed the entire
  `MooX::Options` option-parsing tree.
- **MetaCPAN provides-optimization in the indexer** — removed. The indexer no
  longer consults MetaCPAN to shortcut package scanning; it always scans the
  local tarball. This dropped `MetaCPAN::Client` (and its large tree). For a
  private DarkPAN the optimization never applied anyway — MetaCPAN doesn't know
  your private distributions.
- **`OrePAN2::Index::merge` and `write_gzip`** — removed. Index merging went
  with `orepan2-merge-index`; gzip writing is handled by
  `OrePAN2::Indexer`.

### Removed dependencies

`Moo`, `Moo::Role`, `MooX::Options`, `MetaCPAN::Client`, `Archive::Extract`,
`List::Compare`, `namespace::clean`, `Type::Params`, `Types::Standard`,
`Types::Common::Numeric`, `Types::Path::Tiny`, `Types::Self`, and (from 1.x)
`LWP::UserAgent`.

- **Moo + the Type::Tiny stack → `Class::Accessor::Fast`.** The classes used
  none of Moo's harder features (no lazy attributes to speak of, one method
  modifier, one delegation). Accessors are now `Class::Accessor::Fast`; runtime
  type constraints are gone. For a tool whose inputs are operator-controlled,
  type constraints were a perpetual runtime/install cost guarding against
  one-time development bugs — that job belongs to the test suite, which runs at
  build time and ships nothing.
- **`Archive::Extract` → `Archive::Tar`.** Distributions are `.tar.gz`;
  `Archive::Extract`'s multi-format generality wasn't used.
- **`MetaCPAN::Client` → `HTTP::Tiny` + `JSON::PP`.** Inject-by-name (below) is
  still supported — it now resolves the download URL with a single HTTP call to
  MetaCPAN's `download_url` API instead of the full client.

### Current dependencies

    CPAN::Meta
    Class::Accessor::Fast
    File::pushd
    HTTP::Tiny
    IO::File::AtomicChange
    JSON::PP
    Parse::LocalDistribution
    Path::Tiny
    Role::Tiny
    autodie

## Usage

`OrePAN2::Lite` is a library. Drive it from Perl:

### Inject a distribution

```perl
use OrePAN2::Injector ();

my $injector = OrePAN2::Injector->new( directory => '/path/to/darkpan' );

# from a local file
$injector->inject('/path/to/MyModule-1.0.0.tar.gz');

# from a URL
$injector->inject(
    'https://cpan.metacpan.org/authors/id/A/AU/AUTHOR/Module-1.0.tar.gz' );

# from a git repository
$injector->inject('git://github.com/you/My-Module.git@1.0.0');

# by module name (resolved via MetaCPAN's download_url API)
$injector->inject('Some::Module');
```

### Rebuild the index

```perl
use OrePAN2::Repository ();

my $repo = OrePAN2::Repository->new( directory => '/path/to/darkpan' );
$repo->make_index;
```

### Install from your DarkPAN

```bash
# cpanm, latest version only
cpanm --mirror-only --mirror=file:///path/to/darkpan/ MyModule

# cpm, e.g. an S3/CloudFront-hosted DarkPAN
cpm install --resolver 02packages,https://your-darkpan.example.com/ MyModule
```

## Why a library, not a CLI?

The distributions this is used to build (an S3/SQS Lambda indexing pipeline,
for one) call the library directly — nothing shells out to the old
`orepan2-*` scripts. Removing the CLIs removed the entire option-parsing
dependency tree for zero loss to those consumers. If you want a command-line
front end, a thin wrapper over the library — for example on
[CLI::Simple](https://metacpan.org/pod/CLI::Simple) — is a few lines and keeps
the dependency footprint under your control.

## Why fork rather than patch upstream?

`OrePAN2` is a well-maintained, widely-used module, and its dependency choices
are reasonable defaults for a general-purpose CLI tool. This fork optimizes for
a different case: a **foundational, library-only** tool for footprint-sensitive
environments (Lambda, minimal containers, no C compilation). Rather than push
changes that wouldn't suit all users, `OrePAN2::Lite` is a leaner alternative
for consumers who care about the difference.

## See Also

- [OrePAN2](https://metacpan.org/pod/OrePAN2) — the upstream distribution
- [OrePAN2::S3](https://github.com/rlauer6/orepan2-s3) — S3/SQS-backed DarkPAN
  indexing for AWS Lambda, which motivated this fork

## License

Copyright (C) tokuhirom (upstream OrePAN2).

Same terms as Perl / OrePAN2: this library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.
