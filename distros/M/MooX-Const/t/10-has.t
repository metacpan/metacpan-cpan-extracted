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

throws_ok {

    has e1 => ( is => 'const', isa => Str, trigger => sub {}  );

} qr/triggers are not applicable to const attributes/;

throws_ok {

    has e2 => ( is => 'const', isa => Str, writer => 1 );

} qr/writers are not applicable to const attributes/;

throws_ok {

    has e3 => ( is => 'const', isa => Ref, writer => 1 );

} qr/writers are not applicable to const attributes/;

throws_ok {

    has e4 => ( is => 'const', isa => Str, clearer => 1 );

} qr/clearers are not applicable to const attributes/;

throws_ok {

    has e5 => ( is => 'const', isa => Ref, clearer => 1 );

} qr/clearers are not applicable to const attributes/;

lives_ok {

    has f => ( is => 'once', isa => Ref, trigger => sub {}  );

} 'triggers allowed for write-once attributes';

lives_ok {

    has f3 => ( is => 'once', isa => Ref, writer => 'set_f3' );

} 'writers allowed for write-once attributes';

lives_ok {

    has f2 => ( is => 'wo', isa => Ref, trigger => sub {}  );

} 'triggers allowed for write-once attributes (deprecated)';

throws_ok {

    has g => ( is => 'const' );

} qr/Missing isa for a const attribute/;

throws_ok {

    has h => ( is => 'const', isa => Undef );

} qr/isa must be a type of Types::Standard::Ref/;

done_testing;
