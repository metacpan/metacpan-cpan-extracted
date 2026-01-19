#!perl

use v5.20;
use warnings;

use Test2::V0;

use Protocol::Sys::Virt::TypedParams;


#
# typed_field_new
#

my $field;
$field = typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) );
is( $field, { field => 'fieldname', value => { type => 1, i => 3 } } );

#
# typed_value_new
#

my $param;
$param = typed_value_new( TYPED_PARAM_INT, 3 );
is( $param, { type => 1, i => 3 } );

$param = typed_value_new( TYPED_PARAM_UINT, 3 );
is( $param, { type => 2, ui => 3 } );

$param = typed_value_new( TYPED_PARAM_LLONG, 3 );
is( $param, { type => 3, l => 3 } );

$param = typed_value_new( TYPED_PARAM_ULLONG, 3 );
is( $param, { type => 4, ul => 3 } );

$param = typed_value_new( TYPED_PARAM_DOUBLE, 3.1 );
is( $param, { type => 5, d => 3.1 } );

$param = typed_value_new( TYPED_PARAM_BOOLEAN, \1 );
is( $param, { type => 6, b => \1 } );

$param = typed_value_new( TYPED_PARAM_STRING, 'test' );
is( $param, { type => 7, s => 'test' } );


#
# typed_params_new
#

my $params;
$params = typed_params_new();
is( $params, [] );


$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
is( $params, [ { field => 'fieldname', value => { type => 1, i => 3 } } ] );


#
# typed_params_field (getter)
#

$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$field = typed_params_field( $params, 'fieldname' );
is( $field, { field => 'fieldname', value => { type => 1, i => 3 } } );

$field = typed_params_field( $params, 'none-existent' );
is( $field, undef );

#
# typed_params_field (setter)
#

$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$field = typed_params_field( $params, 'fieldname', typed_value_new( TYPED_PARAM_STRING, 'test' ) );
is( $field, { field => 'fieldname', value => { type => 7, s => 'test' } } );
is( $params, [ { 'field' => 'fieldname', 'value' => { 'type' => 7, 's' => 'test' } } ] );

$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$field = typed_params_field( $params, 'newfield', typed_value_new( TYPED_PARAM_STRING, 'test' ) );
is( $field, { field => 'newfield', value => { type => 7, s => 'test' } } );
is( $params,
    [
     { 'field' => 'fieldname', 'value' => { 'type' => 1, 'i' => 3 } },
     { 'field' => 'newfield', 'value' => { 'type' => 7, 's' => 'test' } }
    ] );


#
# typed_params_fields
#

my $fields;
$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ),
                              typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$fields = typed_params_fields( $params, 'non-existent' );
is( $fields, [] );

$fields = typed_params_fields( $params, 'fieldname' );
is( $fields, $params );

#
# typed_params_field_XXX_value (getter)
#

my $value;
$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );

ok lives {
    $value = typed_params_field_int_value( $params, 'fieldname' );
};
is( $value, 3 );
like( dies {
    $value = typed_params_field_boolean_value( $params, 'fieldname' );
}, qr/^TypedParam type mismatch: expected 6, found 1/);

$value = typed_params_field_int_value( $params, 'non-existent' );
is( $value, undef );

#
# typed_params_field_XXX_value (setter)
#

$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$value = typed_params_field_int_value( $params, 'fieldname', 5 );
is( $value, 5 );
is( $params,
    [
     { 'field' => 'fieldname', 'value' => { 'type' => 1, 'i' => 5 } }
    ] );

like( dies {
    $value = typed_params_field_boolean_value( $params, 'fieldname', \1 );
}, qr/TypedParam type mismatch: expected 6, found 1/);

$params = typed_params_new( [ typed_field_new( 'fieldname', typed_value_new( TYPED_PARAM_INT, 3 ) ) ] );
$value = typed_params_field_int_value( $params, 'non-existent', 7 );
is( $value, 7 );
is( $params,
    [
     { 'field' => 'fieldname', 'value' => { 'type' => 1, 'i' => 3 } },
     { 'field' => 'non-existent', 'value' => { 'type' => 1, 'i' => 7 } }
    ] );


done_testing;
