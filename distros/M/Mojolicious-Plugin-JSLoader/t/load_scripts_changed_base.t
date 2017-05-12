#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::JSLoader';

## Webapp START

plugin('JSLoader', { base => '/js' } );

hook( before_render => sub {
    my $c = shift;
    $c->req->url->base( Mojo::URL->new( '/asepo/' ));
});

any '/'      => sub { shift->render( 'default' ) };
any '/hello' => sub {
    my $self = shift;

    $self->js_load( 'second_file.js' );
    $self->render( 'default' );
};

## Webapp END

my $t = Test::Mojo->new;

my $base_check  = qq~<script type="text/javascript" src="/asepo/js/js_file.js"></script>~;
my $hello_check = qq~<script type="text/javascript" src="/asepo/js/second_file.js"></script>
<script type="text/javascript" src="/asepo/js/js_file.js"></script>~;

$t->get_ok( '/' )->status_is( 200 )->content_is( $base_check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
% js_load( 'js_file.js' );
