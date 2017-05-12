use Test::More tests => 3;
use strict;
use Data::Dumper;

use String::LCSS_XS qw(lcss_all);


my @result = lcss_all ( 'ABBA', 'BABA' );
is_deeply ( \@result, [ [ 'AB', 0, 1],['BA',2,0], ['BA',2,2] ] , "ABBA vs BABA" );
@result = lcss_all ( "zyzxx", "abczyzefg" );

is_deeply(\@result, [ [ 'zyz',0,3] ], 'wantarray returns positions');
@result = lcss_all ( 'ABZ'x50, 'XAB'x100 );
is(scalar(@result),5000, "many lcss works (realloc)");
