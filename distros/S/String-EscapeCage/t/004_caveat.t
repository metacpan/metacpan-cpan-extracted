#!perl -T

use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
	use_ok( 'String::EscapeCage', qw( cage uncage escapehtml ) );
}

my $caged = cage 'dangerous';

'hi there' =~ /(hi) (there)/;  # set $1
my $uncaged = uncage $caged;
is( $1, 'hi', "Calling uncage didn't change \$1" );
