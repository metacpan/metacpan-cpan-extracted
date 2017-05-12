#!/usr/bin/env perl
use strict;
use warnings;
use lib "lib", "../lib";
use Mojo::IOLoop;
use Mojo::IOLoop::Signal;

warn "-> Please send me TERM signal by: kill $$\n";

my $i = 0;
Mojo::IOLoop::Signal->on(TERM => sub {
    my ($self, $name) = @_;
    $i++;
    warn "Got $name signal $i/5\n";
    $i == 5 and Mojo::IOLoop::Signal->unsubscribe('TERM');
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
