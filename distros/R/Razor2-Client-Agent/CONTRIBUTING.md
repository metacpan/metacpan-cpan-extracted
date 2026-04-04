# Contributing to Razor2-Client-Agent

Thank you for considering contributing to Razor2-Client-Agent!

## Getting started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a topic branch from `main`
4. Make your changes
5. Run the test suite: `prove -l t/`
6. Commit with a clear message
7. Push to your fork and open a pull request

## Building from source

```bash
perl Makefile.PL
make
make test
```

Note: The XS extension requires a C compiler.

## Reporting bugs

Please open an issue at https://github.com/toddr/Razor2-Client-Agent/issues
with:

- Perl version (`perl -v`)
- Operating system
- Steps to reproduce
- Expected vs actual behavior

## Code style

- Use `perltidy` with the project's `.perltidyrc`
- Add `use strict` and `use warnings` to all modules
- Write tests for new functionality

## License

By contributing, you agree that your contributions will be licensed under the
same terms as Perl itself (Artistic License 1.0 and/or GPL v1+).
