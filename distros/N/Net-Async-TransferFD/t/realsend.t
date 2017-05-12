use strict;
use warnings;

use Test::More;
use Test::Fatal;

use feature qw(say);
use IO::Handle;
use IO::Async::Loop;
use IO::Async::Process;
use IO::Async::Socket;
use IO::Async::Handle;
use File::Temp qw(tempfile);
use Net::Async::TransferFD;

my $loop = IO::Async::Loop->new;
$loop->attach_signal(
	PIPE => sub { fail "SIGPIPE received" }
);
my $loop_class = ref $loop;

my $completion = $loop->new_future;
note "Parent is $$";
my $proc = IO::Async::Process->new(
	code => sub {
		Test::More->builder->output(\*STDOUT);
		Test::More->builder->failure_output(\*STDERR);
		note "Child is $$";
		my $loop = $loop_class->new;
		my $handle_recv = $loop->new_future;
		my $io = IO::Handle->new;
		ok($io->fdopen(3, 'r+'), "Opened control channel");
		$loop->add(
			my $txfr = new_ok('Net::Async::TransferFD', [
				handle => $io,
				on_fh => sub {
					my $h = shift;
					isa_ok($h, 'GLOB');
					is(join('', <$h>), 'some test content', 'have expected content when reading from handle');
					$handle_recv->done;
				}
			])
		);
		Future->wait_any(
			$loop->timeout_future(after => 3),
			$handle_recv
		)->get;
		is(exception {
			$txfr->stop;
		}, undef, 'no exception when stopping txfr object');
		# $io->close;
		note "End of child loop";
	},
	stdio => {
		from => '',
		on_read => sub {
			my ( $stream, $buffref ) = @_;
			while($$buffref =~ s/^(.*)\n//) {
				my $line = $1;
				if($line =~ /^# (.*)/) {
					note "(child) $1";
				} else {
					my ($type, $idx, $msg) = $line =~ /^([^\d]+) (\d+) - (.*)$/;
					$msg = "(child) $msg";
					($type eq 'ok') ? pass($msg) : fail($msg);
				}
			}
			return 0;
		},
	},
	stderr => {
		on_read => sub {
			my ( $stream, $buffref ) = @_;
			while($$buffref =~ s/^(.*)\n//) {
				diag "(child) $1";
			}
			return 0;
		},
	},
	fd3 => {
		via => 'socketpair',
		on_read => sub { 0 },
#			my ( $stream, $buffref, $eof ) = @_;
#			print $$buffref;
#			note "EOF" if $eof;
#			$stream->close if $eof;
#			$$buffref = '';
#			return 0;
#		},
	},
	on_finish => sub {
		$completion->done;
	},
	on_exception => sub {
		fail "had process exception - @_";
		$completion->fail(@_);
	}
);
$loop->add($proc);

my $io = $proc->fd(3); #->write_handle;

$loop->add(
	my $txfr = new_ok('Net::Async::TransferFD', [
		handle => $io,
		on_fh => sub {
			my $h = shift;
			note "(parent) New handle $h - " . join '', <$h>;
		}
	])
);

note 'Parent - sending FDs to child';
my $name;
{
	(my $fh, $name) = tempfile(UNLINK => 1);
	$fh->print("some test content");
	$fh->close;
}
{
	open my $fh, '<', $name or die $!;
	Future->wait_any(
		$txfr->send($fh)->then(sub {
			is(exception {
				$txfr->stop;
			}, undef, 'no exception when stopping');
#			$proc->fd(3)->close;
			$completion
		}),
		$loop->timeout_future(after => 3)->on_fail(sub {
			fail "Had timeout";
			$proc->kill(9) if $proc->is_running
		})
	)->get;
}
done_testing;
