#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', '../lib';
use Mojolicious::Lite;

plugin('BootstrapAlerts', { auto_inject => 1, after => '#test' } );

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

app->start;

__DATA__
@@ default.html.ep
<div id="test"></div>
