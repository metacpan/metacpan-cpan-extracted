# DEVELOP.md

## Development Setup

This Perl module is managed using [Minilla](https://metacpan.org/pod/Minilla).

To work on the project, you'll need `perl` and `cpanm` installed.

Clone the repo:

```sh
git clone
```

Install [Minilla](https://metacpan.org/pod/Minilla):

```sh
% cpanm --with-recommends Minilla
```

Install dependencies and dev dependencies:

```sh
% cpanm --installdeps --with-develop .

```

All project metadata and build scripts are updated by Minilla.

The developer is responsible for:

- Source code and documentation in `./lib`
- Tests in `./t`
- Dependencies in `cpanfile`
- Package settings in `minil.toml`
- Adding files to git (Minilla uses `git ls-files` to determine what files to package into a release)
- Adding updates to `Changes`
- Updating the package version in `./lib/Mojo/Feed.pm` `$VERSION`

To run tests:

```prove -l t/*

```

To create a new release:

- Update code, docs, tests and `Changes` file
- Update `$VERSION`
- Run `minil dist` to build, `minil release` to upload to CPAN.
