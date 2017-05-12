use strict;
use warnings;
use Test::More;
use POE::Component::Sequence;
use Time::HiRes qw(sleep);

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTests;

sequence_test "Pause and resume" => sub {
	my ($sequence, $test_sequence) = @_;
	$sequence->add_action(sub {
		my $self = shift;

		is $self->pause_state, 0, "Pause state before pause is 0";

		$self->pause();
		is $self->pause_state, 1, "Pause state after pause is 1";

		$self->pause();
		is $self->pause_state, 2, "Pause state after repeated pause is 2";

		$self->resume();
		is $self->pause_state, 1, "Resume lowers the sequence pause state by one";

		# The test sequence expects this sub sequence to ultimately hit 'finally'
		# Since we're leaving it paused here, this will never happen.  Let's trigger
		# resume on it manually here so we can continue to the next test
		$test_sequence->resume();
	});

	$sequence->add_action(sub {
		ok 0, "This should never be reached; the sequence is paused";
	});
}, tests => 4;

sequence_test "Auto pause" => sub {
	my ($sequence, $test_sequence) = @_;
	$sequence->options_set(auto_pause => 1);
	$sequence->add_action(sub {
		my $self = shift;
		is $self->pause_state, 1, "Pause state before pause is 1 (auto-pause)";
		$test_sequence->resume();
	});
	$sequence->add_action(sub {
		ok 0, "This should never be reached; the sequence is paused";
	});
}, tests => 1;


sequence_test "Auto pause and resume" => sub {
	my ($sequence, $test_sequence) = @_;
	$sequence->options_set(auto_pause => 1);
	$sequence->options_set(auto_resume => 1);
	$sequence->add_action(sub {
		my $self = shift;
		is $self->pause_state, 1, "Pause state before pause is 1 (auto-pause)";
	});
	$sequence->add_action(sub {
		ok 1, "Auto-resume resumed the sequence after the action";
	});
}, tests => 2;

sequence_test "Add delay" => sub {
	my $sequence = shift;
	my @touch_points;

	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 1;
		$sequence->add_delay(0.01, sub { push @touch_points, 2 });
	});

	# This is here for consistency with tests below
	$sequence->add_action(sub { });

	$sequence->add_action(sub {
		push @touch_points, 3;
		# The delay should trigger after this action runs but before the finally callback
		# To ensure this, let's sleep for the length of the delay
		sleep 0.01;
	});

	$sequence->add_finally_callback(sub {
		is_deeply \@touch_points, [1, 3, 2], "Adding a delay caused sequence to run in the expected order";
	});
}, tests => 1;

sequence_test "Named delays, removed" => sub {
	my $sequence = shift;
	my @touch_points;

	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 1;
		$self->add_delay(0.01, sub { push @touch_points, 2 }, 'foo');
		$self->remove_delay('foo');
	});

	# This is here for consistency with tests below
	$sequence->add_action(sub { });

	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 3;
		sleep 0.01;
	});

	$sequence->add_finally_callback(sub {
		is_deeply \@touch_points, [1, 3], "Using named delays, removed the sub that adds '2'";
	});
}, tests => 1;

sequence_test "Named delays, adjusted" => sub {
	my $sequence = shift;
	my @touch_points;

	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 1;
		$self->add_delay(0.01, sub { push @touch_points, 2 }, 'foo');
		$self->adjust_delay('foo', 0);
	});

	# The POE event stack is FIFO, and it should contain something like this:
	#   delay_add, delay_adjust, next
	# When we adjust the delay to 0, it'll put a 'delay_complete' onto the event stack
	# at the end.  In order to get [1, 2, 3], we need to have the 'next' do nothing
	$sequence->add_action(sub { });

	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 3;
	});

	$sequence->add_finally_callback(sub {
		is_deeply \@touch_points, [1, 2, 3], "Adjusted delay ran as expected";
	});
}, tests => 1;

sequence_test "Timeout" => sub {
	my $sequence = shift;
	
	$sequence->add_action(sub {
		my $self = shift;

		# Do something that'll take a long time
		$self->pause;
		# ...

		# Set a timeout so that we don't wait forever
		$self->add_delay(0.1, sub { $self->failed("Took too long") });
	});

	$sequence->add_error_callback(sub {
		my ($self, $error) = @_;
		like $error, qr/Took too long/, "Timeout threw error message";
	});
}, tests => 1;

run_tests;
