#!/usr/bin/perl

package MyThread;

use strict;
use warnings;

use base qw(Pots::Thread);

sub run {
    my $self = shift;
    my $msg;
    my $quit = 0;

    while (!$quit) {
        $msg = $self->getmsg();

        for ($msg->type()) {
            if (/quit/) {
                $quit = 1;
            } else {
                print "Got a message of type ", $msg->type(), "\n";
            }
        }
    }
}

1;

package main;

use Pots::Message;

my $th = MyThread->new();
$th->start();

my $msg = Pots::Message->new('MyMessage');
$th->postmsg($msg);

sleep(5);
$th->stop();
