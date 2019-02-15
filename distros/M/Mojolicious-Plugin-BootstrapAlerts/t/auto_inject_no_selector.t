#!/usr/bin/env perl

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use lib 'lib';
use lib '../lib';

use_ok 'Mojolicious::Plugin::BootstrapAlerts';

## Webapp START

plugin('BootstrapAlerts', {
    auto_inject => 1,
});

any '/' => sub {
    my $self = shift;

    $self->notify( 'success', 'message' );
    $self->render( 'default' );
};

any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->notify( 'success', 'message2' );
    $self->notify( 'error', [qw/item1 item2/] );
    $self->render( 'default' );
}

## Webapp END

my $t = Test::Mojo->new;

my $check = '<div id="tester">hallo</div>' . "\n";

$t->get_ok( '/' )->status_is( 200 )->content_is( $check );
$t->get_ok( '/hello' )->status_is( 200 )->content_is( $check );

done_testing();

__DATA__
@@ default.html.ep
<div id="tester">hallo</div>
