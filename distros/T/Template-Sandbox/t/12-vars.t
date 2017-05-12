#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;

BEGIN
{
    eval "use Test::Exception";
    plan skip_all => "Test::Exception required for testing template vars" if $@;
}

plan tests => 18;

my ( $template );

#
#  1-4:  add_var()
$template = Template::Sandbox->new();
$template->add_var( a => 42 );
is( $template->_var_value( 'a' ), 42,
    'add_var scalar numeric' );
$template->add_var( a => 'overwritten' );
is( $template->_var_value( 'a' ), 'overwritten',
    'add_var scalar string overwrite' );
$template->add_var( b => [ 12, 15 ] );
is_deeply( $template->_var_value( 'b' ), [ 12, 15 ],
    'add_var arrayref' );
$template->add_var( c => { 'first' => 5, 'second' => 'SECOND' } );
is_deeply( $template->_var_value( 'c' ),
    { 'first' => 5, 'second' => 'SECOND' },
    'add_var hashref' );

#
#  5-8: add_vars()
$template->add_vars( {
    a => 9,
    b => 'string now',
    c => [ 'arrayref now', 12 ],
    d => { 'new' => 'just in' },
    } );
is( $template->_var_value( 'a' ), 9,
    'add_vars scalar numeric' );
is( $template->_var_value( 'b' ), 'string now',
    'add_vars scalar string' );
is_deeply( $template->_var_value( 'c' ), [ 'arrayref now', 12 ],
    'add_vars arrayref' );
is_deeply( $template->_var_value( 'd' ), { 'new' => 'just in' },
    'add_vars hashref' );

#
#  9-12: merge_var()
$template->merge_var( c => [ 'newly appended' ] );
is_deeply( $template->_var_value( 'c' ),
    [ 'arrayref now', 12, 'newly appended' ],
    'merge_var existing arrayref' );
$template->merge_var( d => { 'newer' => 'newly merged' } );
is_deeply( $template->_var_value( 'd' ),
    { 'new' => 'just in', 'newer' => 'newly merged', },
    'merge_var existing hashref' );
$template->merge_var( e => [ 'super new' ] );
is_deeply( $template->_var_value( 'e' ),
    [ 'super new' ],
    'merge_var new arrayref' );
$template->merge_var( f => { 'brand' => 'spanking new' } );
is_deeply( $template->_var_value( 'f' ),
    { 'brand' => 'spanking new', },
    'merge_var new hashref' );

#
#  13-16: merge_vars()
$template->merge_vars( {
    c => [ 'newest appended' ],
    d => { 'fresh' => 'off the press' },
    g => [ 'never seen before' ],
    h => { 'like unto' => 'that which hath never before been seen' },
    } );
is_deeply( $template->_var_value( 'c' ),
    [ 'arrayref now', 12, 'newly appended', 'newest appended' ],
    'merge_vars existing arrayref' );
is_deeply( $template->_var_value( 'd' ),
    { 'new' => 'just in', 'newer' => 'newly merged',
      'fresh' => 'off the press' },
    'merge_vars existing hashref' );
is_deeply( $template->_var_value( 'g' ),
    [ 'never seen before' ],
    'merge_vars new arrayref' );
is_deeply( $template->_var_value( 'h' ),
    { 'like unto' => 'that which hath never before been seen' },
    'merge_vars new hashref' );

#
#  17: error on add_var of non-top-level var
throws_ok
    {
        $template->add_var( 'broken.var' => 'this is broken' );
    }
    qr/Template post-initialization error: Bad argument to add_var, expected top-level variable name, got: broken\.var at /,
    'error on add_var of non-top-level var';

#
#  18: error on add_vars of non-top-level var
throws_ok
    {
        $template->add_vars( {
            ok           => 'this is ok',,
            'broken.var' => 'index index index',
            } );
    }
    qr/Template post-initialization error: Bad var\(s\) in add_vars, expected top-level variable name, got: broken\.var at /,
    'error on add_vars of non-top-level var';
