#!/usr/bin/env perl
use strict;
use warnings;

# The Mojolicious counterpart of punk-json: the same body through
# Mojo::JSON.
package BenchMojoJson;
use Mojo::Base 'Mojolicious', -strict;

sub startup {
    my ($self) = @_;
    $self->log->level('fatal');
    $self->routes->get('/' => sub {
        $_[0]->render(json => { hello => 'world' });
    });
}

package main;
use Mojo::Server::PSGI ();
Mojo::Server::PSGI->new(app => BenchMojoJson->new(mode => 'production'))
    ->to_psgi_app;
