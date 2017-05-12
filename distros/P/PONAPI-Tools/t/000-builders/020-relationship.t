#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Relationship');
}

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Document::Builder::Relationship->new( resource => { id => 10, type => 'foo' }, name => 'author' );
    isa_ok( $builder, 'PONAPI::Document::Builder::Relationship');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    can_ok( $builder, $_ ) foreach qw[
        name

        has_resource
        has_resources

        links_builder
        add_link
        add_links
        add_meta

        build
    ];

};

done_testing;
