#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Pod::Advent;

my $advent = Pod::Advent->new;
isa_ok($advent, 'Pod::Advent');
my $s;
$s = $advent->css_url;
is( $s, '../style.css', 'got default css_url' );

$s = $advent->css_url('foo.css');
is( $s, 'foo.css', 'set css_url' );
$s = $advent->css_url;
is( $s, 'foo.css', 'got css_url' );


