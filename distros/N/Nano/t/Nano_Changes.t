use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Changes

=cut

=tagline

Transaction Index

=cut

=abstract

Transaction Index Super Class

=cut

=synopsis

  use Nano::Changes;

  my $changes = Nano::Changes->new;

  # $changes->state;

=cut

=libraries

Nano::Types

=cut

=inherits

Nano::Node

=cut

=attributes

domain: ro, opt, Domain

=cut

=description

This package provides a transaction index super class. It is meant to be
subclassed or used via L<Nano::Track>.

=cut

package main;

BEGIN {
  $ENV{ZING_STORE} = 'Zing::Store::Hash';
}

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
