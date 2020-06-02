use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Awncorp::Project

=cut

=abstract

Stencil Generator for Projects

=cut

=synopsis

  use Stencil::Source::Awncorp::Project;

  my $s = Stencil::Source::Awncorp::Project->new;

=cut

=libraries

Types::Standard

=cut

=inherits

Stencil::Source

=cut

=description

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

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
