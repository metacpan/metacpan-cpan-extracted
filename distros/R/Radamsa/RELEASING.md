# Releasing Radamsa

This distribution is a classic `ExtUtils::MakeMaker` XS release uploaded to
CPAN through PAUSE.

## Before You Start

- Ensure you can build XS modules locally.
- Ensure you have a PAUSE account.
- Ensure your working tree only contains intentional changes.

Useful local prerequisites:

```bash
cpan ExtUtils::MakeMaker Test::More
```

The module itself only declares core runtime dependencies:

- `Carp`
- `Exporter`
- `XSLoader`

## Release Steps

1. Update the version in `lib/Radamsa.pm`.
2. Review `README.md` and examples if the public API changed.
3. Refresh `MANIFEST` if you added or removed files:

```bash
perl Makefile.PL
make manifest
```

4. Run the local build and test flow:

```bash
perl Makefile.PL
make
make test
make disttest
```

5. Build the release tarball:

```bash
make dist
```

6. Inspect the generated archive contents:

```bash
tar -tf Radamsa-*.tar.gz
```

7. Commit and tag the release:

```bash
git add lib/Radamsa.pm Makefile.PL README.md MANIFEST RELEASING.md
git commit -m "Release vX.YY"
git tag vX.YY
```

8. Upload the generated tarball to PAUSE.

## Dependency Notes

`cpan` and other CPAN clients read dependency metadata from the generated
`META.*` files. For this distribution, that means:

- Configure dependency: `ExtUtils::MakeMaker`
- Test dependency: `Test::More`
- Runtime dependencies: `Carp`, `Exporter`, `XSLoader`

On normal Perl installations these runtime modules are core, so CPAN usually
will not need to fetch anything extra besides the standard toolchain.

## Recommended Verification After Upload

- Confirm the new version appears on MetaCPAN and CPAN.
- Check CPAN Testers results for the uploaded version.
- If you tagged the release locally, push the tag after the upload succeeds.
