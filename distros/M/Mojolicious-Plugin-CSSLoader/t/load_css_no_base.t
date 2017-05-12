#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

plugin('CSSLoader', { base => '/css' } );

any '/'      => sub { shift->render( 'default' ) };
any '/hello' => sub {
    my $self = shift;

    $self->css_load( 'second_file.css', {no_base => 1} );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<link rel="stylesheet" href="/css/css_file.css"/>~;
my $hello_check = qq~<link rel="stylesheet" href="second_file.css"/>
<link rel="stylesheet" href="/css/css_file.css"/>~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
% css_load( 'css_file.css' );
