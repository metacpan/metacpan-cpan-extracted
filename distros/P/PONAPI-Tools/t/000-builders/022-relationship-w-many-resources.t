#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Relationship');
}

subtest '... testing relationship with multiple data' => sub {

    my $builder = PONAPI::Document::Builder::Relationship->new( name => 'author' );
    isa_ok( $builder, 'PONAPI::Document::Builder::Relationship');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    $builder->add_resource({ id => "1", type => "articles" });
    $builder->add_resource({ id => "1", type => "nouns" });

    ok($builder->has_resource, '... we have a resource');
    ok($builder->has_resources, '... we have many resources');

    is_deeply(
        $builder->build,
        {
            data => [
                { id => "1", type => "articles" },
                { id => "1", type => "nouns" },
            ]
        },
        '... Relationship with multiple data',
    );

};

done_testing;
