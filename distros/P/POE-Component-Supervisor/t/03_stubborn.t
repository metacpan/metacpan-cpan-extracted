#!/usr/bin/perl

sub POE::Kernel::USE_SIGCHLD () { 1 }

use strict;
use warnings;

use Log::Dispatch::Config::TestLog;

use Test::More 'no_plan';

BEGIN {
use_ok 'POE::Component::Supervisor';
use_ok 'POE::Component::Supervisor::Supervised::Proc';
}

use POE;

{
    # test a simple explicit stop scenario

    my $output = 0;
    my $pid;

    my ( $supervisor, $child );

    POE::Session->create(
        inline_states => {
            _start => sub {
                $supervisor = POE::Component::Supervisor->new(
                    children => [
                        $child = POE::Component::Supervisor::Supervised::Proc->new(
                            until_kill => 0.2,
                            program => sub {

                                foreach my $sig ( values %SIG ) {
                                    $sig = 'IGNORE';
                                }

                                while (1) {
                                    print "$$\n";
                                    select(undef,undef,undef,0.1);
                                }
                            },
                            stdout_callback => sub { $pid ||= 0 + $_[ARG0]; $output++ },
                        ),
                    ],
                );

                $_[KERNEL]->delay_set( stop_child => 0.1, $supervisor );
            },
            stop_child => sub {
                $supervisor->stop($child);
            },
        },
    );

    $poe_kernel->run;

    # until_kill + stop_child delay == 2 + 1 == 3
    cmp_ok( $output, '>=', 2, "output" );
    cmp_ok( $output, '<=', 4 + 3, "output" ); # we are willing to tolerate up to 3 extra outputs, but it should be between 2 and 4

    isnt( $pid, $$, "pid was diff" );
}


