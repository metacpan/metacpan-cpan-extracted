#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::CSSLoader';

## Webapp START

plugin('CSSLoader');

any '/'      => sub { shift->render( 'default' ) };
any '/hello' => sub {
    my $self = shift;

    $self->css_load( <<'CSS', {no_file => 1} );
    .test { color: #ffffff; }
CSS
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<style type="text/css">.text { color: #ffffff; }</style>
<link rel="stylesheet" href="css_file.css"/>~;
my $hello_check = q!<style type="text/css">    .test { color: #ffffff; }
</style>
<style type="text/css">.text { color: #ffffff; }</style>
<link rel="stylesheet" href="css_file.css"/>!;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
% css_load( ".text { color: #ffffff; }", {no_file => 1} );
% css_load( 'css_file.css' );
