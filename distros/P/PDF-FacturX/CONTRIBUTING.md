# Contributing to PDF::FacturX

Thank you for your interest! This module aims to be a clean, well-tested
Factur-X / ZUGFeRD generator for the Perl ecosystem.

## Development setup

```sh
git clone https://github.com/huguesmax/PDF-FacturX.git
cd PDF-FacturX
cpanm --installdeps .
perl Makefile.PL
make
```

## Running tests

```sh
prove -lv t/
```

The test suite runs against:

- **Pure XML tests** (00–09): no external dependencies beyond `XML::LibXML`
- **Embed tests** (10–19): require `gs` (Ghostscript) in `PATH`. They
  `skip_all` gracefully if it is missing.

## Adding a test case

1. Add a new `.t` file under `t/` following the existing numbering scheme.
2. For XML-only tests, use `XML::LibXML::XPathContext` to assert structure.
3. For end-to-end tests, use `PDF::Builder->open` to inspect the produced
   PDF/A-3 (do **not** grep raw bytes — PDF::Builder may compress the
   streams it writes).

## Manual end-to-end validation

After making changes that affect XML or PDF structure, validate a sample
output against the official online validator:

  https://services.fnfe-mpe.org/

Or against the Mustang CLI (Java) for an offline check:

  https://www.mustangproject.org/

## Code style

- 4-space indentation, no tabs
- Avoid speculative abstractions
- Comments explain *why*, not *what* — names should already say *what*
- French is acceptable for internal comments and validation error messages
  (audience is mostly francophone given Factur-X's primary market)

## Submitting changes

1. Open an issue first for non-trivial changes
2. Fork → branch → PR
3. Include or update tests
4. `prove -lv t/` must pass with Ghostscript installed
