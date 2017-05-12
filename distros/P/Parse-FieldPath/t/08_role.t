use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use MooseX::Test::Role;
use Parse::FieldPath::Role;

my $obj = consumer_of('Parse::FieldPath::Role');
$obj->meta->add_attribute( a  => ( is     => 'rw' ) );
$obj->meta->add_attribute( b  => ( is     => 'rw' ) );
$obj->meta->add_attribute( c  => ( reader => 'get_c', writer => 'set_c' ) );
$obj->meta->add_attribute( ro => ( is     => 'ro' ) );
$obj->meta->add_attribute( wo => ( writer => 'wo' ) );

can_ok( $obj, 'extract_fields' );
can_ok( $obj, 'all_fields' );

cmp_bag( $obj->all_fields(), [qw/a b ro get_c/],
    'all_fields() should return all attributes reader method names' );

$obj->a(1);
$obj->b(2);
$obj->set_c(3);
$obj->wo('write-only');
cmp_deeply(
    $obj->extract_fields(""),
    { a => 1, b => 2, ro => undef, get_c => 3 },
    'extract_fields() should return a hashref filled with the attributes'
);

cmp_deeply(
    $obj->extract_fields("a"),
    { a => 1 },
    'extract_fields() should use the field_path argument'
);
