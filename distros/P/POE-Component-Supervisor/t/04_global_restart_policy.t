#!/usr/bin/perl

sub POE::Kernel::USE_SIGCHLD () { 1 }

use strict;
use warnings;

use Log::Dispatch::Config::TestLog;

use Test::More 'no_plan';

BEGIN {
use_ok 'POE::Component::Supervisor';
use_ok 'POE::Component::Supervisor::Supervised::Proc';
use_ok 'POE::Component::Supervisor::Supervised::Session';
}

use POE;

my $n = 10;
my $mid = int( ($n + 1) / 2 );

my @classes = qw(Proc Session);
foreach my $class ( @classes, undef, undef ) {
    foreach my $policy (qw(one all rest)) {
        my %pids;

        my ( $supervisor, $session );

        $session = POE::Session->create(
            inline_states => {
                _start => sub {
                    $supervisor = POE::Component::Supervisor->new(
                        restart_policy => $policy,
                        children => [
                            map {
                                my $i = $_;
                                my $actual_class = ( $class || $classes[int rand @classes] );

                                if ( $actual_class eq 'Proc' ) {
                                    POE::Component::Supervisor::Supervised::Proc->new(
                                        program => sub {
                                            $| = 1;
                                            print "$i proc=$$\n";
                                            if ( $i == $mid ) {
                                                exit 1;
                                            } else {
                                                sleep 10; # not indefinitely, hangs in some cases
                                            }
                                        },
                                        stdout_callback => sub {
                                            my ( $key, $value ) = split /\s/, $_[ARG0];
                                            push @{ $pids{$key} ||= [] }, $value;

                                            if ( @{ $pids{$key} } >= 3 ) {
                                                $supervisor->stop;
                                                $poe_kernel->post( $session, "clear_alarm" );
                                            }
                                        },
                                    );
                                } else {
                                    POE::Component::Supervisor::Supervised::Session->new(
                                        start_callback => sub {
                                            POE::Session->create(
                                                inline_states => {
                                                    _start => sub {
                                                        $poe_kernel->yield("body");
                                                        push @{ $pids{$i} ||= [] }, "session=" . $_[SESSION]->ID;

                                                        if ( @{ $pids{$i} } >= 3 ) {
                                                            $supervisor->stop;
                                                            $poe_kernel->post( $session, "clear_alarm" );
                                                        }

                                                        POE::Session->create(
                                                            inline_states => {
                                                                _start => sub { $_[KERNEL]->yield("elk") },
                                                            },
                                                        );
                                                    },
                                                    body => sub {
                                                        if ( $i == $mid ) {
                                                            die "OI";
                                                        } else {
                                                            $_[KERNEL]->delay_set( blah => 10 );
                                                        }
                                                    },
                                                }
                                            );
                                        },
                                    );
                                }
                            } ( 1 .. 10 ),
                        ],
                    );

                    $_[KERNEL]->delay_set( stop_children => 5 );
                },
                clear_alarm => sub {
                    $_[KERNEL]->alarm_remove_all;
                },
                stop_children => sub {
                    $supervisor->stop;
                },
            },
        );

        $poe_kernel->run;

        is( scalar(keys %pids), $n, "10 children ($policy, " . ($class  || "random") . ")" );

        # the numbers of PIDs we expect to have vary based on the policy
        my @before = ( $policy eq 'all' ? ( '>=', 2 ) : ( '==', 1 ));
        my @after  = ( $policy eq 'one' ? ( '==', 1 ) : ( '>=', 2 ) );

        cmp_ok( scalar(@{ $pids{$_} }), $before[0], $before[1], "child $_ had $before[1]" ) for 1 .. $mid-1;
        cmp_ok( scalar(@{ $pids{$mid} }), '>=',      2,           "child $mid has 2" );
        cmp_ok( scalar(@{ $pids{$_} }), $after[0], $after[1],   "child $_ had $after[1]" ) for $mid+1 .. $n;
    }
}

