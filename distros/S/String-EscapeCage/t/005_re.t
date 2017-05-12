#!perl -T

use warnings;
use strict;
use Test::More tests => 6; 

BEGIN {
	use_ok( 'String::EscapeCage', qw( cage uncage escapehtml ) );
}

my $caged = cage 'dangerous';

'hi there' =~ /(hi) (there)/;  # set $1
my $uncaged = uncage $caged;
is( $1, 'hi', "Calling uncage didn't change \$1" );

my($dan,$gerous) = $caged->re( qr/(hi) (there)/ );
is( $1, 'hi', "Calling failing re didn't change \$1" );
ok( !$dan && !$gerous, "Failing match (successfully) returned undefs" );

($dan,$gerous) = $caged->re( qr/(dan)(gerous)/ );
is( $1, 'hi', "Calling matching re didn't change \$1" );
ok( $dan eq 'dan' && $gerous eq 'gerous', "Match returned captured texts" );
