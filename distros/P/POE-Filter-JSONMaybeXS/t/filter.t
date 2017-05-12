use Test::More;
 
BEGIN {
  use_ok( 'POE::Filter::JSONMaybeXS' );
};
 
my $filter = POE::Filter::JSONMaybeXS->new();
if ( ref( $filter) ) {
  pass('new');
} else {
  fail('new');
}
 
my $obj = { foo => 1 };
my $json_array = $filter->put( [ $obj ] );

if ( ref($json_array) eq 'ARRAY' && $json_array->[0] eq '{"foo":1}' ) {
  pass('put');
} else {
  fail('put');
}
 
my $obj_array = $filter->get( $json_array );
if ( ref($obj_array) eq 'ARRAY' && ref( $obj_array->[ 0 ]) eq 'HASH') {
  pass('get');
  if ( exists( $obj_array->[ 0 ]->{foo} ) ) {
    pass('get_foo_bar');
  } else {
    fail('get_foo_bar');
  }
} else {
  fail('get');
  fail('get_foo_bar');
}

done_testing();