#!/usr/bin/env perl
use strict;
use warnings;
# BENCH-PATH: /books/42

# The Mojolicious counterpart of punk-dyn: one placeholder capture.
package BenchMojoDyn;
use Mojo::Base 'Mojolicious', -strict;

sub startup {
    my ($self) = @_;
    $self->log->level('fatal');
    $self->routes->get('/books/:id' => sub { $_[0]->render(text => 'hello') });
}

package main;
use Mojo::Server::PSGI ();
Mojo::Server::PSGI->new(app => BenchMojoDyn->new(mode => 'production'))
    ->to_psgi_app;
