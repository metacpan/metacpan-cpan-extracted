use strict;
use warnings;
use Test::More tests => 2;
use Ref::Util qw<is_arrayref is_hashref>;

# Call multiple routines in a single list expression:
my @got = ( is_arrayref([]), is_hashref({}) );

ok( $got[0], 'got arrayref in list context' );
ok( $got[1], 'got hashref in list context' );
