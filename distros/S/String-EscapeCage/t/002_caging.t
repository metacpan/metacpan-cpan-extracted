#!perl -T

use warnings;
use strict;
use Test::More tests => 7;

BEGIN {
	use_ok( 'String::EscapeCage', qw( cage uncage escapehtml ) );
}

my $caged = cage 'dangerous';
isa_ok( $caged, 'String::EscapeCage' );

is( uncage $caged, 'dangerous',
  'Uncaging works' );

eval { print $caged };
ok( $@, 'Trying to access a caged string dies' );

is( $caged->escapehtml, 'dangerous',
  'Escaping a trivial string gives a string' );

eval { print "still $caged" };
ok( $@, 'Trying to access an interpolated caged string dies' );

is( escapehtml "still $caged", 'still dangerous',
  'Interpolatation gives an EscapeCage' );
