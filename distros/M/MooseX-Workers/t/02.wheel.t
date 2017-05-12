#!/usr/bin/perl
$|++;
use Test::More no_plan;
use warnings;
use strict;

# ------------
# This is NOT an example of how to use MooseX::Workers.
# MooseX::Workers does all of the plumbing below for you.
# ------------

package WheelTester;
use Moose;
use POE qw( Wheel::Run );
# Start the session.  Spawn a simple program, and describe the events
# it will generate as it does things.

has workers => (
    isa       => 'HashRef',
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { {} },
    traits    => [ 'Hash' ],
    handles   => {
        set_worker    => 'set',
        get_worker    => 'get',
        delete_worker => 'delete',
        has_workers   => 'count',
        num_workers   => 'count',
    }
);

# Start a session where each event is handled by a function with the
# same name.  Run POE's Kernel (and thus all its sessions) until done.
has session => (
    isa      => 'POE::Session',
    is       => 'ro',
    weak_ref => 1,
    default  => sub {
        return POE::Session->create(
            object_states => [
                $_[0] => [
                    qw( 
                        _start 
                        _stop 
                        add_worker 
                        worker_output 
                        got_child_stderr 
                        got_child_close
                      )
                ]
            ]
        );

    },
    clearer => 'clear_session',
);

#
# METHODS
#

sub run_command {
    my ( $self, $cmd ) = @_;
    $poe_kernel->post( $self->session => 'add_worker' => $cmd );
}

#
# EVENTS
#
sub _start {
    my ( $self, $session ) = @_[ OBJECT, SESSION ];

}

sub _stop {
    my $self = $_[OBJECT];
    $self->clear_session;
}

sub add_worker {
    my ( $self, $cmd, $kernel ) = @_[ OBJECT, ARG0, KERNEL ];
    ::pass("add command");
    my $wheel = POE::Wheel::Run->new(
        Program     => $cmd,                  # Program to run.
        StdoutEvent => "worker_output",       # Child wrote to STDOUT.
        StderrEvent => "got_child_stderr",    # Child wrote to STDERR.
        CloseEvent  => "got_child_close",     # Child stopped writing.
    );
    $self->workers->{ $wheel->ID } = $wheel;
    $kernel->sig_child($wheel->PID, "got_child_close");
}

# Deal with information the child wrote to its STDOUT.
sub worker_output {
    my $stdout = $_[ARG0];
    ::pass("STDOUT: $stdout");
}

# Deal with information the child wrote to its STDERR.  These are
# warnings and possibly error messages.

sub got_child_stderr {
    my $stderr = $_[ARG0];
    $stderr =~ tr[ -~][]cd;
    ::pass("STDERR: $stderr");
}

# The child has closed its output filehandles.  It will not be sending
# us any more information, so destroy it.

sub got_child_close {
    my ( $self, $wheel_id ) = @_[ OBJECT, ARG0 ];
    ::pass("child closed.");
    delete $self->workers->{$wheel_id};
}

no Moose;

package main;

my $wt = WheelTester->new();
$wt->run_command( sub { print "HELLO\n" } );
POE::Kernel->run();

