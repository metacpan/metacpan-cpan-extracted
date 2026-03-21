# Contributing to NBI-Slurm

Thank you for your interest in contributing to NBI-Slurm!

## Reporting bugs and requesting features

Please open an issue on the [GitHub issue tracker](https://github.com/quadram-institute-bioscience/NBI-Slurm/issues).
When reporting a bug, include:

- Your Perl version (`perl -v`)
- Your SLURM version (`sinfo --version`)
- NBI-Slurm version (`runjob --version`)
- The command you ran and the output or error you received

## Submitting changes

1. Fork the repository and create a branch from `main`.
2. Make your changes. If you are adding a feature or fixing a non-trivial bug, add a test in `t/`.
3. Run the test suite locally to confirm nothing is broken:
   ```bash
   prove -rv t/
   ```
4. Open a pull request describing what you changed and why.

## Code style

- Perl code follows the conventions already in use in `lib/NBI/` and `bin/`.
- All public methods and command-line tools must have POD documentation.
- Run `prove xt/release/00-pod.t` to check POD validity before submitting.

## Development setup

The package uses [Dist::Zilla](https://dzil.org) for building and testing:

```bash
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
dzil listdeps --missing | cpanm
dzil test
```

## Questions

For questions about usage, open a GitHub issue with the `question` label.
For anything else, contact the maintainer via the address in `dist.ini`.
