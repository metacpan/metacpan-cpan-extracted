# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 5;

BEGIN {
    use_ok( 'POE::Filter::JSON' );
};

my $filter = POE::Filter::JSON->new( keysort => 1 );
if ( ref( $filter) ) {
    pass('new');
} else {
    fail('new');
}

my $obj = { foo => 1, bar => 2 };
my $json_array = $filter->put( [ $obj ] );

if ( ref($json_array) eq 'ARRAY' && $json_array->[0] eq '{"bar":2,"foo":1}' ) {
    pass('put');
} else {
    fail('put');
}

my $obj_array = $filter->get( $json_array );
if ( ref($obj_array) eq 'ARRAY' && ref( $obj_array->[ 0 ]) eq 'HASH') {
    pass('get');
    if ( exists( $obj_array->[ 0 ]->{foo} ) && exists( $obj_array->[ 0 ]->{bar} ) ) {
        pass('get_foo_bar');
    } else {
        fail('get_foo_bar');
    }
} else {
    fail('get');
    fail('get_foo_bar');
}

