#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Links');
}

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Document::Builder::Links->new;
    isa_ok( $builder, 'PONAPI::Document::Builder::Links');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    can_ok( $builder, $_ ) foreach qw[
        has_links
        has_link

        get_link

        add_link
        add_links
        add_meta

        build
    ];

};

subtest '... testing build' => sub {

    my $builder = PONAPI::Document::Builder::Links->new;
    $builder->add_link('self', 'https://www.ponapi.org');

    ok($builder->has_link('self'), "... builder has 'self' link");
    ok($builder->has_links==1,     "... builder doesn't have multiple links");

    $builder->add_meta( 'info', 'meta inside links' );

    my $EXPECTED = {
        self => 'https://www.ponapi.org',
        meta => {
            info => 'meta inside links',
        },
    };

    my $GOT = $builder->build;

    is_deeply( $GOT, $EXPECTED, '... got the expected result' );

};

done_testing;
