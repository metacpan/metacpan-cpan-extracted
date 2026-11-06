# Contributing to Perl CodeMap

**Maintainer:** Scott Muller <scott@21h.io>.

Issues, bug reports, documentation improvements and pull requests are welcome.

For a bug report, include Perl version, PPI version (if installed), OS,
command-line flags, the warning/error, and a **small synthetic source example**
that reproduces it. **Do not paste proprietary application code or private
source JSON into a public issue.**

Before submitting a change, run `prove -Ilib t`, check JavaScript syntax with
`node --check lib/Perl/CodeMap/assets/app.js`, and run
`node t/browser-smoke.js`. If changing public API or CLI behavior, update
the embedded POD, run `prove -Ilib t/60-pod.t`, and optionally run
`cpanm Test::Pod Test::Pod::Coverage && prove -Ilib xt/author/pod.t`. Use synthetic fixtures for parser changes and
browser regression tests for visualization changes.

Keep new runtime dependencies minimal; report files must remain standalone and
work offline. Respect both the project's MIT license and the included Prism
component license. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed
release and testing instructions.

By contributing, you agree your changes may be distributed under the project's
MIT License. A DCO/sign-off or CLA is **not** currently required.
