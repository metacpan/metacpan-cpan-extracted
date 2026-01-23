# Contributing to PDF::Reuse

Thank you for considering contributing to PDF::Reuse!

## How to Contribute

1. **Report Bugs** - Open an issue at https://github.com/cnighswonger/PDF-Reuse/issues
2. **Submit Patches** - Fork the repo, create a branch, and submit a pull request
3. **Improve Documentation** - Corrections and clarifications are always welcome

## Development Setup

```bash
git clone https://github.com/cnighswonger/PDF-Reuse.git
cd PDF-Reuse
perl Makefile.PL
make
make test
```

## Pull Request Guidelines

- Include tests for bug fixes and new features
- Ensure all existing tests pass (`make test`)
- Keep changes focused - one fix or feature per PR
- Update the Changes file with a brief description

## Code Style

- Follow existing code conventions in the module
- Use `strict` and `warnings`
- Test with Perl 5.24+ (minimum supported is 5.006, but modern Perl is preferred for development)

## License

By contributing, you agree that your contributions will be licensed under the
same terms as the module itself (the Perl 5 license).
