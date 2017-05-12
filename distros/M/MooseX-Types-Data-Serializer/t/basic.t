#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use Data::Serializer;

BEGIN { use_ok('MooseX::Types::Data::Serializer') }

{
    package MyClass;
    use Moose;
    use MooseX::Types::Data::Serializer qw( Serializer RawSerializer );

    has s => ( is=>'ro', isa=>'Data::Serializer', coerce=>1 );
    has r => ( is=>'ro', isa=>'Data::Serializer::Raw', coerce=>1 );
    has ms => ( is=>'ro', isa=>Serializer, coerce=>1 );
    has mr => ( is=>'ro', isa=>RawSerializer, coerce=>1 );

    sub is_s { return is_Serializer($_[1]) }
    sub is_r { return is_RawSerializer($_[1]) }

    sub to_s { return to_Serializer($_[1]) }
    sub to_r { return to_RawSerializer($_[1]) }
}

my $o = MyClass->new(
    s => Data::Serializer->new( serializer=>'Storable' ),
    r => 'Storable',
    ms => { serializer=>'Storable' },
    mr => Data::Serializer::Raw->new( serializer=>'Storable' ),
);

isa_ok( $o->s(), 'Data::Serializer', '$o->s()' );
isa_ok( $o->r(), 'Data::Serializer::Raw', '$o->r()' );
isa_ok( $o->ms(), 'Data::Serializer', '$o->ms()' );
isa_ok( $o->mr(), 'Data::Serializer::Raw', '$o->mr()' );

ok( $o->is_s( $o->s() ), 'is_Serializer' );
ok( $o->is_r( $o->r() ), 'is_RawSerializer' );

ok( (!$o->is_s([])), 'ArrayRef is not a Serializer' );
ok( (!$o->is_s(MyClass->new())), 'MyClass is not a Serializer' );
ok( (!$o->is_s(undef)), 'undef is not a Serializer' );

ok( $o->to_s( 'Storable' ), 'to_Serializer' );
ok( $o->to_r({ serialzier=>'Storable' }), 'to_RawSerializer' );

done_testing;
