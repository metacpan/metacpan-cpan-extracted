#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Relationship');
}

subtest '... testing links sub-building' => sub {

    my $builder = PONAPI::Document::Builder::Relationship->new( name => 'author' );
    isa_ok($builder, 'PONAPI::Document::Builder::Relationship');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    $builder->add_resource({ id => 10, type => 'foo' });
    ok($builder->has_resource, '... we have a resource');
    ok(!$builder->has_resources, '... we do not have a resources');

    is_deeply(
        $builder->build,
        {
            data  => { id => 10, type => 'foo' },
        },
        '... Relationship with links',
    );

};

done_testing;
