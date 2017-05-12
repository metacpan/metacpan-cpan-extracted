use strict;
use warnings;

use Test::More tests => 31;
use Sort::External;

my ( $sortex, @raw, @correct );

$sortex = Sort::External->new;
@raw = ( reverse( 'j' .. 's' ), 't' .. 'z', 'a' .. 'i' );
is( $sortex->_compare( 'a', 'b' ), -1, "_compare no sortsub" );
is( $sortex->_compare( 'b', 'a' ), 1,  "_compare no sortsub" );
is( $sortex->_compare( 'a', 'a' ), 0,  "_compare no sortsub" );
for ( 0 .. 10 ) {
    @raw = ( 'a' .. 'c', ('c') x $_, 'd' .. 'z' );
    is( $sortex->_define_range( \@raw, 'c' ),
        2 + $_, "_define_range no sortsub ($_)" );
}

$sortex = Sort::External->new(
    sortsub => sub { $Sort::External::b <=> $Sort::External::a }, );
@correct = reverse( 1 .. 100 );
is( $sortex->_compare( 1, 2 ), 1,  "_compare with sortsub" );
is( $sortex->_compare( 2, 1 ), -1, "_compare with sortsub" );
is( $sortex->_compare( 1, 1 ), 0,  "_compare with sortsub" );
for ( 0 .. 10 ) {
    @raw = reverse( 1 .. 3, (3) x $_, 4 .. 10 );
    is( $sortex->_define_range( \@raw, 3 ),
        7 + $_, "_define_range with sortsub ($_)" );
}

$sortex = Sort::External->new( sortsub => sub ($$) { $_[1] <=> $_[0] }, );
@correct = reverse( 1 .. 100 );
is( $sortex->_compare( 1, 2 ), 1,  "_compare with positional sortsub" );
is( $sortex->_compare( 2, 1 ), -1, "_compare with positional sortsub" );
is( $sortex->_compare( 1, 1 ), 0,  "_compare with positional sortsub" );

