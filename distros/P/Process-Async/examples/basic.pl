#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

{ # This is the instance held by the parent process for communicating with the child
	package Demo::Child;
	use parent qw(Process::Async::Child);
	use POSIX qw(strftime);

	sub finished { $_[0]->{finished} ||= $_[0]->loop->new_future }

	sub cmd_started {
		my ($self, $v) = @_;
		say "Child process reports started at " . strftime '%Y-%m-%d %H:%M:%S', localtime $v;
		$self->send_command('shutdown')
	}
	sub cmd_finished {
		my ($self, $v) = @_;
		say "Child process reports finished at " . strftime '%Y-%m-%d %H:%M:%S', localtime $v;
		$self->finished->done;
	}
}
{ # This is the code which runs in the fork
	package Demo::Worker;
	use parent qw(Process::Async::Worker);

	sub completion { $_[0]->{completion} ||= $_[0]->loop->new_future }

	sub cmd_shutdown {
		my ($self, $v) = @_;
		$self->debug_printf("Had shutdown request");
		my $f;
		$f = $self->loop->delay_future(
			after => 1.1,
		)->then(sub {
			$self->send_command(finished => time)
		})->then(sub {
			$self->completion->done($v)
		})->on_ready(sub { undef $f });
	}

	sub run {
		my ($self, $loop) = @_;
		$self->debug_printf("Worker started");
		$self->send_command(started => time)->then(sub {
			$self->completion
		})->get;
		$self->debug_printf("Worker finished");

		# our exitcode
		return 0;
	}
}

use Process::Async;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $pm = Process::Async::Manager->new(
		worker => 'Demo::Worker',
		child  => 'Demo::Child',
	)
);
my $child = $pm->spawn;
$child->finished->get;

