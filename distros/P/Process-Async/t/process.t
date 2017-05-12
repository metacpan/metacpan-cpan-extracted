use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util qw(refaddr);

my $original_loop_addr;

{ # This is the instance held by the parent process for communicating with the child
	package Demo::Parent;
	use parent qw(Process::Async::Child);
	use POSIX qw(strftime);
	use Test::More;

	sub finished { $_[0]->{finished} ||= $_[0]->loop->new_future }

	sub cmd_started {
		my ($self, $v) = @_;
		note "Child process reports that it started at " . strftime '%Y-%m-%d %H:%M:%S', localtime $v;
		is(Scalar::Util::refaddr($self->loop), $original_loop_addr, 'we still have the same refaddr for the loop');
		is(Scalar::Util::refaddr($IO::Async::Loop::ONE_TRUE_LOOP), $original_loop_addr, 'and the global loop agrees');
		$self->send_command('shutdown')
	}
	sub cmd_finished {
		my ($self, $v) = @_;
		note "Child process reports finished at " . strftime '%Y-%m-%d %H:%M:%S', localtime $v;
		ok(!$self->finished->is_ready, 'not ready yet');
		$self->finished->done;
	}
}
{ # This is the code which runs in the fork
	package Demo::Worker;
	use parent qw(Process::Async::Worker);
	use Test::More;

	sub completion { $_[0]->{completion} ||= $_[0]->loop->new_future }

	sub cmd_shutdown {
		my ($self, $v) = @_;
		$self->debug_printf("Had shutdown request");
		my $f;
		$f = $self->loop->delay_future(
			after => 0.05,
		)->then(sub {
			$self->send_command(finished => time)
		})->then(sub {
			$self->completion->done($v)
		})->on_ready(sub { undef $f });
	}

	sub run {
		my ($self, $loop) = @_;
		$self->debug_printf("Worker started");
		isnt(Scalar::Util::refaddr($self->loop), $original_loop_addr, 'child had a different refaddr for the loop');
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

my $loop = new_ok('IO::Async::Loop');
$original_loop_addr = refaddr($loop);
my $pm;
is(exception {
	$loop->add(
		$pm = new_ok('Process::Async::Manager' => [
			worker => 'Demo::Worker',
			child  => 'Demo::Parent',
		])
	)
}, undef, 'no exception when adding manager');
ok(my $child = $pm->spawn, 'spawn child');
isa_ok($child->finished, 'Future');
Future->wait_any(
	$child->finished,
	$loop->timeout_future(after => 5)
)->then(sub {
	ok($child->finished->is_done, 'child process finished OK');
	Future->done;
})->get;

done_testing;

