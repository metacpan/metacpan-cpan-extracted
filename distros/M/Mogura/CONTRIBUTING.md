# Contributing

Report bugs and suggest changes in [GitHub Issues](https://github.com/viasnake/mogura/issues). For a bug, include the Mogura version or commit, host OS, steps to reproduce, and the expected and actual behavior. [Report security issues privately](SECURITY.md).

For a pull request, describe the problem, the change, and its impact. Include the checks you ran when they help reviewers assess the change.

## Develop

Run from the repository root on x86_64 or aarch64 Linux with 64-bit Perl, mise, and `build-essential` installed.
`Makefile.PL` stops on unsupported platforms with the `OS unsupported` diagnostic recognized by CPAN Testers as NA. Test failures on supported Linux builds are bugs to investigate and fix.

```sh
mise trust
mise install
mise run setup
mise run test
mise run format:check
```

Use indentation to show nesting. Across languages, use a single space wherever
spacing is needed between tokens. Avoid padding keys, assignments, or comments
to line up with neighboring lines.

Use Node.js 22 or later to rebuild the bundled stylesheet after changing utility classes and to run the Chromium tests.

```sh
npm ci
npm run build:css
npx playwright install chromium
mise run test:results
```

## Build a distribution

Set the distribution version in `lib/Mogura.pm` and describe the user-visible changes under the same version in `Changes`. Build from a clean checkout after completing the development setup.

```sh
mise exec -- perl -I "$PWD/.tools/carton/lib/perl5" .tools/carton/bin/carton exec sh -eu <<'SH'
perl Makefile.PL
make disttest
make dist
SH
```

Set `MOGURA_TEST_SYFT` to a Syft executable to exercise exclusion rules on temporary fixtures. The normal test suite uses local HTTP and simulated disk operations.

Install the archive in an empty prefix and start it outside the checkout. Use the version you just built.

```sh
archive="$PWD/Mogura-0.02.tar.gz"
stage=$(mktemp -d)
cd "$stage"
env -u PERL5LIB -u PERL5OPT cpanm --local-lib-contained "$stage/prefix" "$archive"
env -u PERL5LIB -u PERL5OPT "$stage/prefix/bin/mogura" --version
env -u PERL5LIB -u PERL5OPT "$stage/prefix/bin/mogura" server --state "$stage/state" --listen http://127.0.0.1:8082
```

Open the web interface, switch languages, and check that the stylesheet loads. Stop the server with Ctrl-C and record the archive checksum with `sha256sum "$archive"`.
