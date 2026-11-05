# Publishing the Perl Core

## Status

Source tag `perl/v0.1.1` maps to CPAN distribution `Praxo-Core` version
`0.1.1`. The distribution provides the root package `Praxo::Core` and the
`Praxo::Agent` modules. The release workflow is
`.github/workflows/perl-release.yml`.

## Build

From `language/perl/`:

```bash
perl Makefile.PL
make
make test
make dist
```

The distribution tarball is written to `language/perl/`.

## Release workflow

The `build` job verifies `VERSION`, `Makefile.PL`, and the `perl/v*` tag, then
runs the native gates and `make dist`. The `publish` job skips an already
published version, otherwise uploads with `cpan-upload`.

## Credentials

- Configure the GitHub environment `cpan` and repository secrets `PAUSE_USER`
  and `PAUSE_PASSWORD`.
- Use the PAUSE account that owns `Praxo-Core`.
- Do not store the password in `Makefile.PL`, documentation, or the repository.

## Verify

```bash
cpanm Praxo::Core
perl -MPraxo::Core -e 'print Praxo::Core::version(), "\n"'
```

The MetaCPAN release page and a clean install are the publication evidence.
