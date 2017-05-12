#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {

    $SIG{__WARN__} = sub {
        my $msg = shift;
        print STDERR $msg unless $msg =~ m/Object::Quick is depricated/;
    };

    require_ok('Object::Quick');
    Object::Quick->import();
    ok( !__PACKAGE__->can($_), "$_ not imported" ) for qw/obj method clear/;

    Object::Quick->import('objx');
    ok( !__PACKAGE__->can($_), "$_ not imported" ) for qw/obj method clear/;
    can_ok( __PACKAGE__, 'objx' );

    Object::Quick->import( 'objy', 'vmy' );
    ok( !__PACKAGE__->can($_), "$_ not imported" ) for qw/obj method clear/;
    can_ok( __PACKAGE__, 'objy', 'vmy' );

    Object::Quick->import( 'objz', 'vmz', 'clearz' );
    ok( !__PACKAGE__->can($_), "$_ not imported" ) for qw/obj method clear/;
    can_ok( __PACKAGE__, 'objz', 'vmz', 'clearz' );

    Object::Quick->import('-obj');
    can_ok( __PACKAGE__, qw/obj method clear/ );
}

is( clear(), \$Mock::Quick::Util::CLEAR, "clear returns the clear reference" );

my $one = obj( foo => 'bar' );
isa_ok( $one, 'Mock::Quick::Object' );
is( $one->foo, 'bar', "created properly" );

my $two = method { 'vm' };
isa_ok( $two, 'Mock::Quick::Method' );
is( $two->(), "vm", "virtual method" );

my $three = obj( foo => method { 'bar' } );
is( $three->foo, 'bar', "ran virtual method" );
$three->foo( clear() );
ok( !$three->foo, "cleared" );

done_testing;
