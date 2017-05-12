#!/usr/bin/perl -l
use strict;
use warnings FATAL => "all";

use POE qw( Component::Pool::Thread );
use Test::Simple tests => 100;

my $responses;

POE::Component::Pool::Thread->new
    ( MaxThreads => 1,
      StartThreads => 1,
      EntryPoint => sub {
        my ($result) = @_;
        ok 1;
        return $result;
      },
      CallBack   => sub {
        ok keys(%{ $_[HEAP]->{thread} })== 1;
        $_[KERNEL]->yield("shutdown") if (++$responses == 50);
      },
      inline_states => {
        _start => sub {
            $_[KERNEL]->call($_[SESSION], run => $_) for 1 .. 50;
        },
      }
    );

POE::Kernel->run;
