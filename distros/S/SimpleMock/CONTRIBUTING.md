# Contributing to SimpleMock

Contributions are welcome! Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork and create a feature branch
3. Install dependencies: `cpanm --installdeps .`
4. Build: `perl Makefile.PL && make`

## Making Changes

- Add tests for any new functionality under `t/unit_tests/`
- Ensure all tests pass: `prove -Ilib -It/lib -r t/`
- Follow the existing code style

## Adding a New Mock Model

1. Create `lib/SimpleMock/Model/MYMODEL.pm` with a `validate_mocks` sub
2. Create `lib/SimpleMock/Mocks/Some/Module.pm` to patch the target module
3. Add tests under `t/unit_tests/SimpleMock/Model/`
4. Update the MANIFEST

## Submitting Changes

1. Commit your changes with a clear message
2. Push to your fork
3. Open a pull request against the `main` branch

## Reporting Bugs

Open an issue on [GitHub](https://github.com/cliveholloway/perl_simplemock/issues) with steps to reproduce the problem.
