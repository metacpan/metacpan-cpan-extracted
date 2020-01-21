#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Object::Depot;

{
  package Test::aliases;
  use Moo;
  has actual_key => ( is=>'ro' );
}

my $depot = Object::Depot->new(
  class => 'Test::aliases',
  key_argument => 'actual_key',
);

$depot->add_key( 'baz' );
$depot->add_key( 'bar' );
$depot->alias_key( foo => 'bar' );

is(
    $depot->fetch('foo')->actual_key(),
    'bar',
    'key alias was used',
);

is(
    $depot->fetch('bar')->actual_key(),
    'bar',
    'key alias was not used',
);

is(
    $depot->fetch('baz')->actual_key(),
    'baz',
    'key alias was not used',
);

done_testing;
