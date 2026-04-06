# Contributing

## Hacking

1. Clone the repository and install dependencies, for example:

   ```bash
   cpanm --installdeps .
   ```

   or `cpanm --installdeps .` after `perl Makefile.PL` if you prefer `Makefile.PL`
   resolution.

2. Run the test suite before submitting changes:

   ```bash
   rm -rf blib cover_db
   prove -lr t
   ```

   (`-r` includes `t/unit/`.) The same set runs as `make test` after
   `perl Makefile.PL`. If a **`blib/`** directory is present from a previous
   `make`, Perl may load outdated modules from it instead of **`lib/`** — remove
   **`blib/`** before testing or coverage.

3. **Fixtures** live under **`t/data/`** (e.g. **`minimal.json`** for the JSON
   loader, **`schema_kitchen_sink.yaml`** for diverse model properties).
   Focused **unit tests** are in **`t/unit/`** (`Writer`, `Spec`, …). Add more
   fixtures to widen integration tests; add mocks only where isolating one
   layer is clearer than another YAML.

4. Optional: check POD syntax:

   ```bash
   prove -l t/06-pod.t
   ```

## Preparing a CPAN release (maintainers)

1. Update **`Changes`**, bump **`$VERSION`** in **`lib/Modern/OpenAPI/Generator.pm`**
   if needed.

2. Update **`Makefile.PL`** `META_MERGE` repository / bugtracker URLs if the
   GitHub location changes.

3. Clean and verify:

   ```bash
   rm -rf blib cover_db
   perl Makefile.PL
   make
   make test
   make manifest   # refresh MANIFEST from MANIFEST.SKIP
   make distcheck
   ```

4. Build the tarball:

   ```bash
   make dist
   ```

5. Upload the **`Modern-OpenAPI-Generator-*.tar.gz`** to PAUSE.

6. Tag the release in git (version matching **`$VERSION`**).
