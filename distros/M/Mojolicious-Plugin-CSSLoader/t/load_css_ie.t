#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::JSON qw(decode_json);

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

plugin('CSSLoader');

any '/hello' => sub {
    my $self = shift;

    my $params = $self->param('ie');

    if ( $params !~ m{\A [01] \z}x ) {
        $params = decode_json( $params );
    }

    $self->css_load( 'second_file.css', { ie => $params } );
    $self->render;
};

## Webapp END

my $t = Test::Mojo->new;

my %hello_checks = (
    '0'        => qq~<!-- [if !IE ]><!--><link rel="stylesheet" href="second_file.css"/><!--<![endif]-->~,
    '1'        => qq~<!-- [if IE ]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
    '{">":7}'  => qq~<!-- [if gt IE 7]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
    '{">=":7}' => qq~<!-- [if gte IE 7]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
    '{"<":7}'  => qq~<!-- [if lt IE 7]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
    '{"<=":7}' => qq~<!-- [if lte IE 7]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
    '{"==":7}' => qq~<!-- [if IE 7]><link rel="stylesheet" href="second_file.css"/><![endif]-->~,
);

for my $params ( sort keys %hello_checks ) {
    $t->get_ok( '/hello?ie=' . $params )->status_is( 200 )->content_is( $hello_checks{$params} . " loaded\n", "params: $params" );
}

done_testing();

__DATA__
@@hello.html.ep
 loaded
