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
    before      => '#tester',
});

any '/' => sub {
    my $self = shift;

    $self->notify( 'success', 'message' );
    $self->render( 'default' );
};

any '/no' => sub { shift->render('default') };
any '/hello' => \&hello;

sub hello {
    my $self = shift;

    $self->notify( 'success', 'message2' );
    $self->notify( 'error', [qw/item1 item2/] );
    $self->render( 'default' );
}

any '/json' => sub {
    my $self = shift;
    $self->notify( 'success', 'message2' );
    $self->render( json => { test => 1 } );
};

## Webapp END

my $t = Test::Mojo->new;

my $check = '<div id="tester">hallo</div>' . "\n";

$t->get_ok( '/' )->status_is( 200 )->content_like( qr/div class="alert/ )->content_like( qr/\Q$check\E/ );
$t->get_ok( '/hello' )->status_is( 200 )->content_like( qr/div class="alert/ )->content_like( qr/\Q$check\E/ );
$t->get_ok( '/no' )->status_is( 200 )->content_is( $check );
$t->get_ok( '/json' )->status_is( 200 )->content_is( '{"test":1}' );

done_testing();

__DATA__
@@ default.html.ep
<div id="tester">hallo</div>
