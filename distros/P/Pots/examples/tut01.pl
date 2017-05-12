#!/usr/bin/perl

package MyThread;

use strict;
use warnings;

use base qw(Pots::Thread);

sub run {
    my $self = shift;

    print "Hello there, I'm thread #", $self->tid(), "\n";
}

1;

package main;

my $th = MyThread->new();
$th->start();
sleep(5);
$th->stop();
