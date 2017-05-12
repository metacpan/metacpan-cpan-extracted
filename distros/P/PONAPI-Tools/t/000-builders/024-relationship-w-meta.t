#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Relationship');
}

subtest '... testing meta sub-building' => sub {

    my $builder = PONAPI::Document::Builder::Relationship->new( name => 'author' );
    isa_ok( $builder, 'PONAPI::Document::Builder::Relationship');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    is( $builder->name, 'author', '... name set correctly' );

    ok(!$builder->has_meta, "... new document shouldn't have meta");

    is(
        exception { $builder->add_meta( info => "a meta info" ) },
        undef,
        '... got the (lack of) error we expected'
    );

    ok($builder->has_meta, "... the document should have meta now");

    $builder->add_resource({ id => 10, type => 'foo' });

    is_deeply(
        $builder->build,
        {
            data  => { id => 10, type => 'foo' },
            meta  => { info => "a meta info" }
        },
        '... Relationship with meta',
    );

};

done_testing;
