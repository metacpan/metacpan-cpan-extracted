package Process::Child::Leash;
$Process::Child::Leash::VERSION = '1.00';
=head1 NAME

Process::Child::Leash - to make sure the child process wont get lost with their parent.

=head1 DESCRIPTION

Here is the issue. The parent process is a wrapping bash script around the real process (child).
If we stopped the wrapper script. The real process ( child ) will be still remained and running as normal.

How to terminal the parent process and the child process would be stopped as a chain reaction?

 +
 |--run.sh
   |
   |-- perl script.pl

This module will keep an eye on the parent process. When the parent is gone. It will remove the
the real process ( child ).

=head1 USAGE

=head1 ATTACH IT WITHIN THE CODE

 #!/usr/bin/perl
 use strict;
 use warnings;
 use Process::Child::Leash;

 ... start of the script ...

 ## run.sh
 #!/bin/bash
 export SOMETHING=FOOBAR
 perl script.pl

 >> bash run.sh


=head1 USE IT OUTSIDE THE CODE

 ## run.sh
 #!/bin/bash
 export SOMETHING=FOOBAR
 perl -MProcess::Child::Leash script.pl

 >> bash run.sh

=head1 TIMEOUT THE HANGING PROCESS

Timeout after 10 seconds running.

 ## run.sh
 #!/bin/bash
 export CHILD_LEASH_TIMEOUT=10
 export DBIC_TRACE=1
 perl -MProcess::Child::Leash script.pl
 perl -MProcess::Child::Leash=timeout,10 script.pl

 >> bash run.sh

=head2 THEN WHAT?

get the pid of run.sh, and kill -9 that pid.

The script.pl process will be terminated.

=cut

use strict;
use warnings;
use Mouse;
use Proc::Killfam qw( killfam );
use Unix::PID;

has _started_time => (
    is      => "ro",
    isa     => "Int",
    builder => "_build__started_time",
);

sub _build__started_time { time }

has _child_pid => (
    is         => "rw",
    isa        => "Int",
    lazy_build => 1,
);

sub _build__child_pid { $$ }

has _parent_pid => (
    is      => "ro",
    isa     => "Int",
    builder => "_build__parent_pid",
);

sub _build__parent_pid {
    my $parent_pid = getppid();
    warn "PARENT ID: $parent_pid\n"
      if $ENV{DEBUG_PROCESS_CHILD_LEASH};
    return $parent_pid;
}

has timeout => (
    is      => "ro",
    isa     => "Int",
    builder => "_build_timeout",
);

sub _build_timeout {
         $ENV{CHILD_LEASH_TIMEOUT}
      || $ENV{ZATON_PROCESS_TIMEOUT}
      || $ENV{MUNNER_TIMEOUT}
      || 0;
}

has test => (
    is         => "ro",
    isa        => "Bool",
    lazy_build => 1,
);

no Mouse;

{
    my $IS_TEST = 0;

    sub _build_test {
        return $IS_TEST;
    }

    sub import {
        my $class = shift;
        my %args  = @_;
        return
          if $IS_TEST = $args{test};
        my $leash = $class->new(%args);
        $leash->fasten;
    }
}

sub fasten {
    my $self             = shift;
    my $real_process_pid = fork;
    if ($real_process_pid) {
        $self->_child_pid($real_process_pid);
        $self->_baby_sit;
        exit;
    }
}

sub _baby_sit {
    my $self       = shift;
    my $parent_pid = $self->_parent_pid;
    my $child_pid  = $self->_child_pid;
    my $start_at   = $self->_started_time;
    my $timeout    = $self->timeout;

    warn ">> BABY SITTER: $$\n"
      if $ENV{DEBUG_PROCESS_CHILD_LEASH};

  CHECK: while (1) {
        if ( $self->_is_timeout && $self->_kill_child_process ) {
            return $self->finish("timeout. killed child process");
        }
        elsif ( !$self->_is_child_still_running ) {
            return $self->finish("child is gone. finish checking");
        }
        elsif ( $self->_is_parent_still_running ) {
            sleep 1;
            next CHECK;
        }
        elsif ( $self->_kill_child_process ) {
            return $self->finish("parent is gone. killed child process");
        }
    }
}

{
    my $RETRY = 0;

    sub _kill_child_process {
        my $self = shift;

        my $pid = $self->_child_pid;

        $self->_kill_process($pid);

        if ( $RETRY++ < 10 ) {
            return $self->_is_process_still_running($pid) ? 0 : 1;
        }
        else {
            warn ">> Cannot kill child process $pid.\n";
            return 1;
        }
    }
}

sub _kill_process {
    my $self = shift;
    my $pid  = shift;
    killfam "TERM", $pid;
}

sub _is_timeout {
    my $self    = shift;
    my $timeout = $self->timeout
      or return;
    my $started_time = $self->_started_time;
    my $used_time    = time - $started_time;
    return ( $used_time > $self->timeout ) ? 1 : 0;
}

sub _is_process_still_running {
    my $self = shift;
    my $pid  = shift;
    my @info = Unix::PID->new->pid_info($pid);
    return @info ? 1 : 0;
}

sub _is_parent_still_running {
    my $self = shift;
    my $bool = $self->_is_process_still_running( $self->_parent_pid );
    my @info = Unix::PID->new->pid_info( $self->_parent_pid );
    warn "$bool - $#info - @info\n"
      if $ENV{DEBUG_PROCESS_CHILD_LEASH};
    return $bool;

}

sub _is_child_still_running {
    my $self = shift;
    $self->_is_process_still_running( $self->_child_pid );
}

sub finish {
    my $self = shift;
    exit
      if !$self->test;
    my $message = shift;
    return $message;
}

1;
