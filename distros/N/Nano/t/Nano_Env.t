use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Env

=cut

=tagline

Nano Environment

=cut

=abstract

Nano Environment Abstraction

=cut

=synopsis

  use Nano::Env;

  my $env = Nano::Env->new;

=cut

=libraries

Nano::Types

=cut

=inherits

Zing::Env

=cut

=description

This package provides a L<Zing> environment abstraction specific to L<Nano>
applications.

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
