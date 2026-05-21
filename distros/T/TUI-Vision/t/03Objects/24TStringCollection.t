use strict;
use warnings;

use Test::More;

use_ok( 'TUI::Objects::StringCollection' );

BEGIN {
  use_ok 'TUI::Objects::StringCollection';
}

is(
  TStringCollection(), 'TUI::Objects::StringCollection',
  'TStringCollection() returns package name'
);

my $class = TStringCollection();

ok( $class->can( 'from' ), "$class has from()" );

my $obj = $class->new( limit => 0, delta => 0 );
isa_ok( $obj, $class, 'new() created object' );

my $obj2 = new_TStringCollection( 0, 0 );
isa_ok( $obj2, $class, 'new_TStringCollection() created object' );

ok( $obj->can( 'compare' ), 'compare() exists' );

cmp_ok( $obj->compare( 1, 2 ), '==', -1, '1 < 2 numerically' );
cmp_ok( $obj->compare( 2, 1 ), '==',  1, '2 > 1 numerically' );
cmp_ok( $obj->compare( 5, 5 ), '==',  0, '5 == 5 numerically' );

done_testing();
