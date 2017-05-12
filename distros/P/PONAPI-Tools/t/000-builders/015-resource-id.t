#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Resource::Identifier');
}

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Document::Builder::Resource::Identifier->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok( $builder, 'PONAPI::Document::Builder::Resource::Identifier');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    is($builder->id, '1', '... got the expected id');
    is($builder->type, 'articles', '... got the expected type');

    can_ok( $builder, $_ ) foreach qw[
        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder::Resource::Identifier->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder::Resource::Identifier->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder::Resource::Identifier->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

subtest '... testing an object with meta-info' => sub {

    my $builder = PONAPI::Document::Builder::Resource::Identifier->new(
        id   => '1',
        type => 'articles',
    );

    $builder->add_meta( info => "a meta info" );

    my $EXPECTED = {
        type => 'articles',
        id   => 1,
        meta => { info => "a meta info" },
    };

    my $GOT = $builder->build;

    is_deeply( $GOT, $EXPECTED, '... got the expected result' );

};

done_testing;
