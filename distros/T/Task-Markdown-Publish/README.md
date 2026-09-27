# Task::Markdown::Publish

`Task::Markdown::Publish` installs the complete documentation conversion and
publishing toolchain for Perl distributions. It contains everything installed
by `Task::Markdown::Pod`, plus the reusable site publisher and the MakeMaker
targets for building, previewing, and publishing documentation.

## Installation

Install the released bundle and its Perl prerequisites from CPAN:

```sh
cpanm Task::Markdown::Publish
```

The bundle installs:

- `Task::Markdown::Pod`, `Markdown::Pod::Embed`, `Docbook::Convert`, and
  `ASPEER::MakeMaker::Markdown::Pod` for conversion and maintenance;
- `Markdown::Publish` for MkDocs, VitePress, Docusaurus, and Astro Starlight
  site operations;
- `ASPEER::MakeMaker::Markdown::Publish` for `publish_build`,
  `publish_serve`, `publish_gh`, `publish_gh-push`, and
  `publish_cloudflare` MakeMaker targets.

## System prerequisites

CPAN installs Perl modules only. On Fedora, install the conversion and basic
build prerequisites with:

```sh
sudo dnf install perl perl-App-cpanminus perl-devel make gcc expat-devel \
  pandoc libxml2 libxslt git
```

The default MkDocs backend additionally needs Python and MkDocs Material:

```sh
sudo dnf install python3-pip
python3 -m pip install --user mkdocs-material
```

VitePress, Docusaurus, and Astro Starlight need Node.js and npm. Their project
packages are installed into temporary build directories by `Markdown::Publish`:

```sh
sudo dnf install nodejs npm
```

Cloudflare publication needs Wrangler and an authenticated account. Install it
only when that explicit deployment target is required:

```sh
npm install --global wrangler
wrangler login
```

Pandoc is used for DocBook conversion and README generation; `xmllint` and
`xsltproc` are supplied by Fedora's `libxml2` and `libxslt` packages. Git is
needed only for `gh`/`gh-push` publication branch operations. No Task module
creates accounts, authenticates tools, pushes Git branches, or deploys sites.

## Use

Enable the complete MakeMaker target set:

```perl
use ExtUtils::MakeMaker;
use ASPEER::MakeMaker::Markdown::Publish;

WriteMakefile(
    NAME         => 'My::Module',
    VERSION_FROM => 'lib/My/Module.pm',
    META_MERGE   => {
        'meta-spec' => {version => 2},
        x_documentation => {
            publish => {
                module  => 'mkdocs',
                sources => ['doc'],
            },
        },
    },
);
```

Then run the local workflows explicitly:

```sh
perl Makefile.PL
make doc
make publish_build
make publish_serve
```

The standalone publisher provides the same site operations without MakeMaker:

```sh
markdown-publish build
markdown-publish serve
```

Publication branch updates and Cloudflare deployment remain separate, explicit
operations. See the `Markdown::Publish` documentation before using them.

## GitHub attestations

Tagged releases build one distribution archive, publish it to GitHub Releases
and CPAN, and attach GitHub provenance and a Sigstore bundle. After downloading
`Task-Markdown-Publish-VERSION.tar.gz` from CPAN, verify its attestation with:

```sh
gh attestation verify Task-Markdown-Publish-VERSION.tar.gz \
  --repo aspeer/pm-Task-Markdown-Publish
```

## Author

Andrew Speer <andrew.speer@isolutions.com.au>

## License and copyright

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
