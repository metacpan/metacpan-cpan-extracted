use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Awncorp

=cut

=abstract

Personal Perl 5 Stencil Generators

=cut

=synopsis

  use Stencil::Source::Awncorp;

  1;

=cut

=description

This package provides Personal Perl 5 Stencil Generators.

=cut

=scenario classes

This package supports generating classes. See
L<Stencil::Source::Awncorp::Class>.

=example classes

  use Stencil::Source::Awncorp::Class;

  Stencil::Source::Awncorp::Class->new

=cut

=scenario projects

This package supports generating projects. See
L<Stencil::Source::Awncorp::Project>.

=example projects

  use Stencil::Source::Awncorp::Project;

  Stencil::Source::Awncorp::Project->new

=cut

=scenario roles

This package supports generating roles. See
L<Stencil::Source::Awncorp::Role>.

=example roles

  use Stencil::Source::Awncorp::Role;

  Stencil::Source::Awncorp::Role->new

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('classes', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('projects', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->scenario('roles', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
