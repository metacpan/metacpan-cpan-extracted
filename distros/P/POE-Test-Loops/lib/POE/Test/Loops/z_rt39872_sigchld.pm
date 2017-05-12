#!/usr/bin/perl
# vim: ts=2 sw=2 expandtab

use strict;
use warnings;

sub POE::Kernel::USE_SIGCHLD () { 1 }
sub POE::Kernel::ASSERT_DEFAULT () { 1 }

BEGIN {
  package
  POE::Kernel;
  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
}

use POE;
use Test::More;
use POE::Wheel::Run;
use POSIX qw( SIGINT );

if ($^O eq "MSWin32" and not $ENV{POE_DANTIC}) {
	plan skip_all => "Perl crashes on $^O";
	exit 0;
}

if ($INC{'Tk.pm'}) {
	plan skip_all => "Test causes XIO and other errors under Tk.";
	exit 0;
}

plan tests => 6;

POE::Session->create(
	inline_states => {
		_start   => \&_start,
		_stop    => \&_stop,
		stdout   => \&stdout,
		stderr   => \&stderr,
		sig_CHLD => \&sig_CHLD,
		error    => \&error,
		done     => \&done
	}
);

$poe_kernel->run;
pass( "Sane exit" );

### End of main code.  Beginning of subroutines.

sub _start {
	my( $kernel, $heap ) = @_[KERNEL, HEAP];

  # This subprocess announces its name and exits when told to.

	my $prog = <<'	PERL';
		$|++;
		my $N = shift;
		print "I am $N\n";
		while(<STDIN>) {
			chomp;
			exit 0 if /^bye/;
			print "Unknown command '$_'\n";
		}
	PERL

	note "$$ _start";

  # Linger a bit.
	$kernel->alias_set( 'worker' );

  # The W1 test

  # Start two subprocesses.
  # They will trigger stdout() when they announce themselves.

	$heap->{W1} = POE::Wheel::Run->new(
		Program => [ $^X, '-e', $prog, "W1" ],
		StdoutEvent => 'stdout',
		StderrEvent => 'stderr',
		ErrorEvent  => 'error'
	);

	$heap->{wheel_id_to_name}{ $heap->{W1}->ID } = 'W1';
	$heap->{wheel_pid_to_name}{ $heap->{W1}->PID } = 'W1';
  $kernel->sig_child($heap->{W1}->PID(), 'sig_CHLD');

	$heap->{W2} = POE::Wheel::Run->new(
		Program => [ $^X, '-e', $prog, "W2" ],
		StdoutEvent => 'stdout',
		StderrEvent => 'stderr',
		ErrorEvent  => 'error'
	);
	$heap->{wheel_id_to_name}{ $heap->{W2}->ID } = 'W2';
	$heap->{wheel_pid_to_name}{ $heap->{W2}->PID } = 'W2';
  $kernel->sig_child($heap->{W2}->PID(), 'sig_CHLD');
}

sub _stop {
	my( $kernel, $heap ) = @_[KERNEL, HEAP];
	note "$$ _stop";
}

# The first wheel is done.
# Kill the other wheels.  We want to be sure only one wheel is done.

sub done {
	my( $kernel, $heap ) = @_[KERNEL, HEAP];
	note "$$ done";

	delete $heap->{W1};
  delete $heap->{W2};

	my @list = keys %{ $heap->{wheel_pid_to_name} };
	is( 0+@list, 1, "One wheel left" );
	kill SIGINT, @list;

	alarm(5); $SIG{ALRM} = sub { die "test case didn't end sanely" };
}

# A child process has announced itself.
# Test whether we got the right output.
# If it's the "W1" test, have it shut down cleanly.

sub stdout {
	my( $kernel, $heap, $input, $id ) = @_[KERNEL, HEAP, ARG0, ARG1];

	my $N = $heap->{wheel_id_to_name}{$id};
	note "$$ ($N) ($id) STDOUT: '$input'";

  # Success if this is an announcement.
	ok( ($input =~ /I am $N/), "Intro output" );

  return if $N ne 'W1';

	my $wheel = $heap->{ $N };

  # One of the subprocesses will be closed normally.
  # The other will be killed later.

  $heap->{closing}{ $N } = 1;
  $wheel->put( 'bye' );
}

# Dump the child's STDERR for diagnostics.

sub stderr {
	my( $kernel, $heap, $input, $id ) = @_[KERNEL, HEAP, ARG0, ARG1];
	my $N = $heap->{wheel_id_to_name}{$id};
	diag("$$ ($N) ($id) STDERR: '$input'");
}

# Abnormal errors.  Not part of the test, but the test should fail
# anyway.

sub error {
	my( $kernel, $heap, $op, $errnum, $errstr, $id, $fh ) = @_[
		KERNEL, HEAP, ARG0..$#_
	];

	unless ( $op eq 'read' and $errnum==0 ) {
    my $N = $heap->{wheel_id_to_name}{$id};
    die("$$ Error $N ($id): $op $errnum ($errstr)");
	}
}

# A child process has exited.  How's that working out for us?

sub sig_CHLD {
	my( $kernel, $heap, $signal, $pid, $status ) = @_[
		KERNEL, HEAP, ARG0..$#_
	];

	my $N = delete $heap->{wheel_pid_to_name}{$pid};
	note "$$ CHLD $N ($pid)";

  unless ($N eq 'W1') {
    is( $heap->{closing}{$N}, undef, "$N killed" );
    return;
  }

  is( $heap->{closing}{$N}, 1, "$N closing" );

	my $wheel = delete $heap->{ $N };

	delete $heap->{closing}{$N};
	delete $heap->{wheel_id_to_name}{ $wheel->ID };

  # A brief delay to make sure all child processes are reaped.
	$kernel->delay( done => 0.25 );
}

1;
