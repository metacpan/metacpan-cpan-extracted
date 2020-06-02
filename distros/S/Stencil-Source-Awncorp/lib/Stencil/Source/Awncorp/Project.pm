package Stencil::Source::Awncorp::Project;

use 5.014;

use strict;
use warnings;

use Data::Object::Class;

extends 'Stencil::Source';

our $VERSION = '0.01'; # VERSION

sub dist {
  my ($self, $name) = @_;

  $name =~ s/::/-/g;

  return $name
}

1;



=encoding utf8

=head1 NAME

Stencil::Source::Awncorp::Project

=cut

=head1 ABSTRACT

Stencil Generator for Projects

=cut

=head1 SYNOPSIS

  use Stencil::Source::Awncorp::Project;

  my $s = Stencil::Source::Awncorp::Project->new;

=cut

=head1 DESCRIPTION

This package provides a L<Stencil> generator for L<Dist::Zilla> based projects
that use. This generator produces the following specification:

  name: MyApp
  abstract: Doing One Thing Very Well
  main_module: lib/MyApp.pm

  prerequisites:
  - "routines = 0"
  - "Data::Object::Class = 0"
  - "Data::Object::ClassHas = 0"

  operations:
  - from: editorconfig
    make: .editorconfig
  - from: gitattributes
    make: .gitattributes
  - from: build
    make: .github/build
  - from: release
    make: .github/release
  - from: workflow-release
    make: .github/workflows/releasing.yml
  - from: workflow-test
    make: .github/workflows/testing.yml
  - from: gitignore
    make: .gitignore
  - from: mailmap
    make: .mailmap
  - from: perlcriticrc
    make: .perlcriticrc
  - from: perltidyrc
    make: .perltidyrc
  - from: replydeps
    make: .replydeps
  - from: replyrc
    make: .replyrc
  - from: code-of-conduct
    make: CODE_OF_CONDUCT.md
  - from: contributing
    make: CONTRIBUTING.md
  - from: manifest-skip
    make: MANIFEST.SKIP
  - from: stability
    make: STABILITY.md
  - from: template
    make: TEMPLATE
  - from: version
    make: VERSION
  - from: dist
    make: dist.ini

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Stencil::Source>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/stencil-source-awncorp/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/stencil-source-awncorp/wiki>

L<Project|https://github.com/iamalnewkirk/stencil-source-awncorp>

L<Initiatives|https://github.com/iamalnewkirk/stencil-source-awncorp/projects>

L<Milestones|https://github.com/iamalnewkirk/stencil-source-awncorp/milestones>

L<Contributing|https://github.com/iamalnewkirk/stencil-source-awncorp/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/stencil-source-awncorp/issues>

=cut

__DATA__

@=spec

name: MyApp
abstract: Doing One Thing Very Well
main_module: lib/MyApp.pm

prerequisites:
- "routines = 0"
- "Data::Object::Class = 0"
- "Data::Object::ClassHas = 0"

operations:
- from: editorconfig
  make: .editorconfig
- from: gitattributes
  make: .gitattributes
- from: build
  make: .github/build
- from: release
  make: .github/release
- from: workflow-release
  make: .github/workflows/releasing.yml
- from: workflow-test
  make: .github/workflows/testing.yml
- from: gitignore
  make: .gitignore
- from: mailmap
  make: .mailmap
- from: perlcriticrc
  make: .perlcriticrc
- from: perltidyrc
  make: .perltidyrc
- from: replydeps
  make: .replydeps
- from: replyrc
  make: .replyrc
- from: code-of-conduct
  make: CODE_OF_CONDUCT.md
- from: contributing
  make: CONTRIBUTING.md
- from: manifest-skip
  make: MANIFEST.SKIP
- from: stability
  make: STABILITY.md
- from: template
  make: TEMPLATE
- from: version
  make: VERSION
- from: dist
  make: dist.ini

@=editorconfig

[*]
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = false
tab_width = 2
trim_trailing_whitespace = true

@=gitattributes

*.pl linguist-language=Perl
*.pm linguist-language=Perl
*.t linguist-language=Perl

.github/* linguist-documentation
dev/* linguist-documentation

@=build

#!/bin/bash

# Check the repo is in ready-state
if ! git diff-index --quiet HEAD --; then
  echo "Uncommitted changes!" && exit 0;
fi

# Build Package
DZIL_RELEASE=0 dzil build

# Push generated POD changes
if ! git diff-index --quiet HEAD --; then
  git checkout CHANGES && git add . && git commit -m 'Update documentation'
fi

@=release

#!/bin/bash

export V=$1
export DZIL_RELEASE=1

# Ensure release version is explicit
if [ ! -n "$V" ]; then
  echo 'No release version!' && exit 0;
fi

# Check the repo is in ready-state
if ! git diff-index --quiet HEAD --; then
  echo "Uncommitted changes!" && exit 0;
fi

# Test fake build before release
if ! dzil test; then
  echo "Build test failed!" && exit 0;
fi

# Cleanup the mess
dzil clean

# Delete existing release tag (if exists)
git tag -d cpan $V 2> /dev/null
git push origin :refs/tags/cpan :refs/tags/$V 2> /dev/null

# Persist Release VERSION
echo $V > VERSION

# Delete existing POD documents
find lib -type f -name \*.pod -exec rm {} \;

# Regenerate all necessary POD documents
testauto -o lib -t TEMPLATE

# Push generated POD changes
if ! git diff-index --quiet HEAD --; then
  git add . && git commit -m 'Add release updates'
fi

# Build, Tag, and Push Package Release
dzil release

# Tag as CPAN for releasing
git tag cpan 2> /dev/null

# Re-push all tags (just in case)
git push --tags 2> /dev/null

@=workflow-release

name: Releasing

on:
  push:
    tags:
    - cpan

jobs:
  Perl-5300:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.30
      run: sudo perlbrew install -n perl-5.30.0
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.30.0 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.30.0 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.30.0 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.30.0 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.30.0 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Perl-5280:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.28
      run: sudo perlbrew install -n perl-5.28.0
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.28.0 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.28.0 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.28.0 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.28.0 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.28.0 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Perl-5260:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.26
      run: sudo perlbrew install -n perl-5.26.0
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.26.0 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.26.0 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.26.0 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.26.0 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.26.0 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Perl-5240:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.24
      run: sudo perlbrew install -n perl-5.24.0
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.24.0 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.24.0 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.24.0 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.24.0 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.24.0 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Perl-5220:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.22
      run: sudo perlbrew install -n perl-5.22.0
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.22.0 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.22.0 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.22.0 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.22.0 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.22.0 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Perl-5182:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Install Perlbrew
      run: sudo apt install -y perlbrew
    - name: Initial Perlbrew
      run: sudo perlbrew init
    - name: Install CPANM
      run: sudo perlbrew install-cpanm
    - name: Install Perl 5.18
      run: sudo perlbrew install -n perl-5.18.2
    - name: Verify Perl Version
      run: sudo perlbrew exec --with perl-5.18.2 perl -V
    - name: Install Perl::Critic
      run: sudo perlbrew exec --with perl-5.18.2 cpanm -qn Perl::Critic
    - name: Install Perl Dependencies
      run: sudo perlbrew exec --with perl-5.18.2 cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: sudo perlbrew exec --with perl-5.18.2 perlcritic lib t
    - name: Testing Project
      run: sudo perlbrew exec --with perl-5.18.2 prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

  Dist-Upload:
    runs-on: ubuntu-latest
    needs: ["Perl-5300", "Perl-5280", "Perl-5260", "Perl-5240", "Perl-5220", "Perl-5182"]

    steps:
    - uses: actions/checkout@v1
    - name: Setup Git User
      run: git config --global user.name "Al Newkirk"
    - name: Setup Git Email
      run: git config --global user.email "awncorp@cpan.org"
    - name: Setup GitHub User
      run: git config --global github.user ${{ secrets.GithubUser }}
    - name: Setup GitHub Token
      run: git config --global github.token ${{ secrets.GithubToken }}
    - name: Install CPANM
      run: sudo apt install -y cpanminus
    - name: Install Dist::Zilla
      run: sudo cpanm -qn Dist::Zilla
    - name: Install Dist::Zilla Dependencies
      run: dzil authordeps | sudo cpanm -qn
    - name: Install Project Dependencies
      run: sudo cpanm -qn --reinstall --installdeps .
    - name: Cleanup Build Environment
      run: dzil clean
    - name: Build Project Distribution
      run: V=$(cat VERSION) DZIL_RELEASING=1 dzil build
    - name: Discard Generated Changelog
      run: git checkout CHANGES
    - name: Discard Generated Tarball
      run: rm $(ls *.tar.gz)
    - name: Copy CHANGES to Build Directory
      run: cp -f CHANGES $(echo *-$(cat VERSION))
    - name: Manually Create Release Tarball
      run: tar czf $(echo *-$(cat VERSION)).tar.gz $(echo *-$(cat VERSION))
    - name: Upload to CPAN
      run: cpan-upload -u ${{ secrets.CpanUser }} -p ${{ secrets.CpanPass }} $(ls *.tar.gz)

@=workflow-test

name: Testing

on:
  push:
    branches:
    - issue-*
    - milestone-*
    - project-*

jobs:
  Perl-0000:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v1
    - name: Setup Git User
      run: git config --global user.name "Al Newkirk"
    - name: Setup Git Email
      run: git config --global user.email "awncorp@cpan.org"
    - name: Setup GitHub User
      run: git config --global github.user ${{ secrets.GithubUser }}
    - name: Setup GitHub Token
      run: git config --global github.user ${{ secrets.GithubToken }}
    - name: Install CPANM
      run: sudo apt install -y cpanminus
    - name: Install Perl::Critic
      run: sudo cpanm -qn Perl::Critic
    - name: Install Project Dependencies
      run: sudo cpanm -qn --reinstall --installdeps .
    - name: Critiquing Project
      run: perlcritic lib t
    - name: Testing Project
      run: prove -Ilib -r t
      env:
        HARNESS_OPTIONS: j9

@=gitignore

/*

!/.github
!/bin
!/lib
!/t

!CHANGES
!CODE_OF_CONDUCT.md
!CONTRIBUTING.md
!INSTALL
!LICENSE
!Makefile.PL
!MANIFEST.SKIP
!META.json
!META.yml
!OVERVIEW.md
!README
!README.md
!STABILITY.md
!TEMPLATE
!VERSION
!build
!cpanfile
!dist.ini
!release

!.editorconfig
!.gitattributes
!.gitignore
!.mailmap
!.perltidyrc
!.perlcriticrc
!.replyrc
!.replydeps

@=mailmap

Al Newkirk <awncorp@cpan.org> <al@alnewkirk.com>
Al Newkirk <awncorp@cpan.org> <al@iamalnewkirk.com>

@=perlcriticrc

color=1
severity=5
theme=risky + (pbp * security) - cosmetic
verbose=4
exclude=ClassHierarchies NamingConventions RequireTestLabels

[-Modules::RequireVersionVar]
[-Modules::RequireExplicitPackage]

@=perltidyrc

-pbp     # Start with Perl Best Practices
-w       # Show all warnings
-iob     # Ignore old breakpoints
-l=80    # 80 characters per line
-mbl=2   # No more than 2 blank lines
-i=2     # Indentation is 2 columns
-ci=2    # Continuation indentation is 2 columns
-vt=0    # Less vertical tightness
-pt=2    # High parenthesis tightness
-bt=2    # High brace tightness
-sbt=2   # High square bracket tightness
-wn      # Weld nested containers
-isbc    # Don't indent comments without leading space
-cab=0   # Break after comma (comma arrow breakpoints)
-novalign

@=replydeps

Reply
App::Nopaste
B::Keywords
Class::Refresh
IO::Pager
Proc::InvokeEditor
Term::ReadKey
Term::ReadLine::Gnu

@=replyrc

[Editor]
[Interrupt]
[FancyPrompt]
[DataDumper]
[AutoRefresh]

[Colors]
[Hints]
[LexicalPersistence]
[LoadClass]
[Nopaste]
[Packages]
[Pager]
[ReadLine]
[ResultCache]

[Autocomplete::Commands]
[Autocomplete::Functions]
[Autocomplete::Globals]
[Autocomplete::Keywords]
[Autocomplete::Lexicals]
[Autocomplete::Methods]
[Autocomplete::Packages]

@=code-of-conduct

## Pledge

In the interest of fostering an open, inclusive, and welcoming environment, we,
as contributors and maintainers pledge, to the best of our ability, to make
participation in our project and our community an enjoyable experience for
everyone involved.

## Standards

Examples of acceptable behavior by participants include:

* Being polite and respectful in communication
* Willing to give and receive constructive criticism
* Advancing the successful development of the project
* Being a productive member of the community

Examples of unacceptable behavior by participants include:

* Being impolite or disrespectful in communication
* Unwilling to receive constructive criticism
* Hindering the successful development of the project
* Being an unproductive member of the community

## Maintainership

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior. Project maintainers have
the right and responsibility to remove, edit, or reject comments, commits,
code, wiki edits, issues, and other contributions that are not aligned with
this Code of Conduct, or to ban temporarily or permanently any contributor for
other behaviors that they deem inappropriate.

Additionally, project maintainers are obligated to:

* Help contributors
* Review comments, commits, issues, and other project contributions
* Approve comments, commits, issues, and other project contributions
* Enforce community guidelines

### Policy Scope

This Code of Conduct applies only and exclusively to official project spaces,
mediums, and accounts owned by and representative of the project. Examples of
project representation include using an official project e-mail address,
posting via an official social media account or acting as an appointed
representative at an online or offline event.

Please take note that this does not include the personal public or private
social media accounts, non-project related websites, emails, communications or
activities online or offline, of any participant of this project, maintainer
and individual contributor alike. Representation of the project may be further
defined and clarified by project maintainers.

Incidents reported in bad faith, or maliciously, and/or in an attempt to use
this project and its Code of Conduct to address activities unrelated to the
project and/or outside of its official project spaces, mediums, and accounts
owned by and representative of the project will not be considered and may face
temporary or permanent repercussions where applicable as determined by members
of the project's leadership.

### Policy Enforcement

Instances of violations may be reported by contacting the project maintainers
at al@iamalnewkirk.com. All complaints will be reviewed and investigated and
will result in a response that is deemed necessary and appropriate to the
circumstances. The project team is obligated to maintain confidentiality with
regard to the reporter of an incident. Further details of specific enforcement
policies may be posted separately.

@=contributing

## Contributing

Thanks for your interest in this project. We welcome all community
contributions! To install locally, follow the instructions in the
[README.md](./README.mkdn) file.

## Releasing

This project uses [Dist::Zilla](https://github.com/rjbs/Dist-Zilla) to manage
its build and release processes. For ease and consistency there is also a
_"build"_ and _"release"_ script in the project .github folder which executes
the most common steps in releasing this software.

```
  $ bash ./.github/release 0.01
```

## Directory Structure

```
  lib
  ├── Class.pm
  ├── Class
  │   └── Widget.pm
  t
  ├── Class.t
  └── Class_Widget.t
```

Important! Before you checkout the code and start making contributions you need
to understand the project structure and reasoning. This will help ensure you
put code changes in the right place so they won't get overwritten.

The `lib` directory is where the packages (modules, classes, etc) are. Feel
free to create, delete and/or update as you see fit. All POD (documentation)
changes are made in their respective test files under the `t` directory. This
is necessary because the documentation is auto-generated during release.

Thank you so much!

## Questions, Suggestions, Issues/Bugs

Please post any questions, suggestions, issues or bugs to the [issue
tracker](../../issues) on GitHub.

@=manifest-skip

^(?!CHANGES|INSTALL|LICENSE|Makefile.PL|META*|README*|cpanfile|lib\/.*|t\/.*).*$

@=stability

## Stability

Our top priority is to provide a reliable development framework that important
work is based upon. As such, we promise to put stability and backward
compatibility first in the development of this project.

Version 1.00 of this distribution is considered stable. Any changes to the API
that result in changes to the test suite will be preceded by a three (3) month
notice period, with the following exceptions:

* Changes necessary to maintain compatibility with:

  - Perl +5.14
  - Other major dependencies

* Contradictions between the implementation and documentation

* Features explicitly documented as "experimental" or "unstable"

* Changes to the documentation

## Versioning

This distribution uses the standard Perl two component number versioning scheme
but increments it based on [semver](https://semver.org) semantics. For example,
a version number of `1.23` is treated as the semver-based version number
`1.2.3`.

## Releasing

This distribution and its source code is maintained and released on GitHub,
with the CPAN serving as the canonical repository. This means that hotfixes,
changes in documentation, and experimental features will be released on GitHub,
only shipping stable releases to the CPAN.

## Questions, Suggestions, Issues/Bugs

Please post any questions, suggestions, issues or bugs to the [issue
tracker](../../issues) on GitHub.

@=template

+=encoding utf8

{content}

+=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

+=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/blob/master/LICENSE>.

+=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/wiki>

L<Project|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]>

L<Initiatives|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/projects>

L<Milestones|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/milestones>

L<Contributing|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/[% self.dist(data.name).lower %]/issues>

+=cut

@=version

0.01

@=dist

name = [% self.dist(data.name) %]
abstract = [% data.abstract %]
main_module = [% data.main_module %]
author = Al Newkirk <awncorp@cpan.org>
license = Apache_2_0
copyright_holder = Al Newkirk
copyright_year = 2019

[Authority]
authority = cpan:AWNCORP
do_munging = 0

[MetaJSON]
[MetaYAML]
[OurPkgVersion]
[GatherDir]
[ManifestSkip]
[FakeRelease]
[ReadmeAnyFromPod]
[ReadmeAnyFromPod / ReadmeMarkdownInBuild]
filename = README.md

[Run::BeforeBuild]
run = rm -f cpanfile
run = rm -f INSTALL
run = rm -f CHANGES
run = rm -f LICENSE
run = rm -f README
run = rm -f README.md
run = rm -f Makefile.PL

[CopyFilesFromBuild]
copy = cpanfile
copy = INSTALL
copy = CHANGES
copy = LICENSE
copy = README
copy = README.md
copy = Makefile.PL

[Git::CommitBuild]
branch = builds
message = Build %h (on %b)
multiple_inheritance = 0

[ChangelogFromGit::CPAN::Changes]
show_author = 0
tag_regexp = ^(v?\d+\.\d+(\.\d+)?)$
file_name = CHANGES
wrap_column = 80
debug = 0

[@Git]
tag_format = %v
tag_message = Release: %v
changelog = CHANGES
allow_dirty = CHANGES
allow_dirty = INSTALL
allow_dirty = LICENSE
allow_dirty = Makefile.PL
allow_dirty = README
allow_dirty = README.md
allow_dirty = cpanfile
allow_dirty = dist.ini

[Git::NextVersion]
first_version = 0.01
version_regexp = ^(.+)$

[GitHub::Meta]
[GitHub::Update]
metacpan = 1

[Run::BeforeRelease]
run = git add .
run = git commit -m "Built release version %v"

[Prereqs]
perl = 5.014
[%- IF data.prerequisites %]
[% FOR item IN data.prerequisites %]
[%- item %]
[% END -%]
[% END -%]

[Prereqs / TestRequires]
perl = 5.014
[%- IF data.prerequisites %]
[% FOR item IN data.prerequisites %]
[%- item %]
[% END -%]
[% END -%]

[CPANFile]
[CoalescePod]
[ContributorsFromGit]
[MakeMaker]
[InstallGuide]
[License]