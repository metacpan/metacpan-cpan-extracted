#!/usr/bin/env perl
use strict;
use warnings;

# The same 'hello' through Mojolicious, hosted on the same server through
# Mojo::Server::PSGI. Production mode, logging off - what you would deploy.
package BenchMojoHello;
use Mojo::Base 'Mojolicious', -strict;

sub startup {
    my ($self) = @_;
    $self->log->level('fatal');
    $self->routes->get('/' => sub { $_[0]->render(text => 'hello') });
}

package main;
use Mojo::Server::PSGI ();
Mojo::Server::PSGI->new(app => BenchMojoHello->new(mode => 'production'))
    ->to_psgi_app;
