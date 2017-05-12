#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

## Webapp START

plugin('BootstrapAlerts');

any '/' => sub { shift->render( 'default' ) };
any '/hello' => sub { shift->render };

## Webapp END

my $t = Test::Mojo->new;

my $hello_check = qq~<div id="test"></div>\n\n~;

$t->get_ok( '/' )->status_is( 200 )->content_is( "\n" );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $hello_check );

done_testing();

__DATA__
@@ default.html.ep
%= notifications()

@@ hello.html.ep
<div id="test"></div>
%= notifications()
