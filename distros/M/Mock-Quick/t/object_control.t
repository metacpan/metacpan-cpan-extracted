#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;
use Mock::Quick::Method;
use Mock::Quick::Object;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Object::Control';
    use_ok( $CLASS );
    can_ok( $CLASS, qw/strict set_methods set_attributes new clear/ );
}

tests basic => sub {
    my $obj = Mock::Quick::Object->new( foo => 'foo' );
    my $control = $CLASS->new( $obj );
    isa_ok( $control, $CLASS );

    ok( !$control->strict, "not strict" );
    ok( $control->strict(1), "set strict" );
    ok( $control->strict(), "is strict" );

    can_ok( $obj, 'foo' );

    ok( !$obj->can( $_ ), "can't $_ yet" ) for qw/ bar baz /;

    $control->set_methods( bar => sub { 'bar' });
    $control->set_attributes( baz => 'baz' );
    can_ok( $obj, qw/bar baz/ );
    is( $obj->bar, 'bar', "got bar" );
    is( $obj->baz, 'baz', "got baz" );

    $control->clear( 'foo' );
    ok( !$obj->can('foo'), "no more foo" );
};

run_tests;
done_testing;
