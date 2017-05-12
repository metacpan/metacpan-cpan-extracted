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
    isa_ok( $builder, 'PONAPI::Document::Builder::Relationship');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    ok(!$builder->has_links, "new relationship should not have links");

    $builder->add_links(
        related => "/related/2",
        self    => "/self/1",
    );

    ok($builder->has_links, "relationship should now have links");

    $builder->add_resource({ id => 10, type => 'foo' });

    is_deeply(
        $builder->build,
        {
            data  => { id => 10, type => 'foo' },
            links => {
                self    => "/self/1",
                related => "/related/2",
            }
        },
        '... Relationship with links',
    );

};

done_testing;
