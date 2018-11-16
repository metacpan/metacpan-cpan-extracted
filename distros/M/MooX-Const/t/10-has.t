#!perl

use Test::Most;

use Moo;

use Types::Standard -types;

use MooX::Const v0.2.0;

throws_ok {

    has a => ( is => 'const', isa => 'Foo' );

} qr/isa must be a Type::Tiny type/;

throws_ok {

    has b => ( is => 'wo', isa => Str );

} qr/write-once attributes are not supported for Value types/;

throws_ok {

    has c => ( is => 'const', isa => InstanceOf['Thing'] );

} qr/isa cannot be a type of Types::Standard::Object/;

throws_ok {

    has d => ( is => 'wo', isa => InstanceOf['Thing'] );

} qr/isa cannot be a type of Types::Standard::Object/;

throws_ok {

    has e => ( is => 'const', isa => Ref, trigger => sub {}  );

} qr/triggers are not applicable to const attributes/;

lives_ok {

    has f => ( is => 'wo', isa => Ref, trigger => sub {}  );

} 'triggers allowed for write-once attributes';

throws_ok {

    has g => ( is => 'const' );

} qr/Missing isa for a const attribute/;

throws_ok {

    has h => ( is => 'const', isa => Undef );

} qr/isa must be a type of Types::Standard::Ref/;

done_testing;
