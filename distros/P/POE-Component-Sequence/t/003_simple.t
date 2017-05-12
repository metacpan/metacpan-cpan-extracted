use strict;
use warnings;
use Test::More;
use POE::Component::Sequence;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTests;

sequence_test "Return values and passing context" => sub {
	my $sequence = shift;

	$sequence->add_action(sub {
		return 68;
	});

	$sequence->add_action(sub {
		my $self = shift;
		is $self->result, 68, "Return value of previous action is stored in result()";
		$self->heap_set(number => 42);
	});

	$sequence->add_action(sub {
		my $self = shift;
		is $self->heap_index('number'), 42, "Number passed from one action to another following";
		$self->finished( "Magic value" );
		return "last action return";
	});

	$sequence->add_callback(sub {
		my ($self, $result) = @_;
		is $result, "Magic value", "The value pased to finished() inside an action is passed to the callback";
		is $self->result, "last action return", "result() still contains the return value of the last action";
	});

	$sequence->add_callback(sub {
		my ($self, $result) = @_;
		is $result, "Magic value", "Each callback receives the same finished() value";
	});
}, tests => 5;

sequence_test "Error and finally callbacks" => sub {
	my $sequence = shift;
	my %touch_points;

	$sequence->add_action(sub {
		die "You have a SERIOUS bug in your code";
	});

	$sequence->add_action(sub {
		$touch_points{second_action} = 1;
	});

	$sequence->add_callback(sub {
		$touch_points{callback} = 1;
	});

	$sequence->add_error_callback(sub {
		my ($self, $error) = @_;
		like $error, qr/SERIOUS bug/, "Caught error message from first action";
		is int(keys %touch_points), 0, "No action or callback was called";
	});

	$sequence->add_finally_callback(sub {
		ok 1, "Reached finally callback";
	});
}, tests => 3;

sequence_test "Error handling inside callbacks" => sub {
	my $sequence = shift;
	my %touch_points;

	$sequence->add_action(sub {
		shift->finished("Some value");
	});

	$sequence->add_action(sub {
		$touch_points{after_finished} = 1;
	});

	$sequence->add_callback(sub {
		my ($self, $result) = @_;
		is $result, "Some value", "Have result in callback";
		die "Failed inside callback";
	});

	$sequence->add_callback(sub {
		$touch_points{second_callback} = 1;
	});

	$sequence->add_error_callback(sub {
		my ($self, $error) = @_;
		like $error, qr/Failed inside callback/, "Caught failure inside callback with error_callback";
		ok ! $touch_points{after_finished}, "An action calling finished() stops further actions";
		ok ! $touch_points{second_callback}, "A callback dying stops further callbacks";

	});
}, tests => 4;

sequence_test "Chained create style" => sub {
	my %touch_points;
	my $sequence = POE::Component::Sequence
		->new(
			sub {
				$touch_points{action}++;
			},
			sub {
				$touch_points{action}++;
			},
		)
		->add_callback(sub {
			$touch_points{callback}++;
		})
		->add_finally_callback(sub {
			is $touch_points{action}, 2, "Called two actions";
			is $touch_points{callback}, 1, "Called one callback";
		});
	return $sequence;
}, tests => 2;

sequence_test "Parameterized new() create style" => sub {
	my $sequence = shift;
	my %touch_points;

	# Because of the nature of the testing framework, which evaluates success of the test
	# in a 'finally' callback, we can't perform tests in our add_finally_callback() in 
	# new() args here since the evaluation (in MyTests) will happen before our add_finally_callback
	# below.  To deal with this, let's create a sub sequence.
	my $subseq = POE::Component::Sequence->new(
		{
			add_callback => sub { $touch_points{callback}++ },
			add_finally_callback => sub {
				is $touch_points{action}, 2, "Called two actions";
				is $touch_points{callback}, 1, "Called one callback";
			},
		},
		sub { $touch_points{action}++ },
		sub { $touch_points{action}++ },
	);

	$sequence->add_action(sub {
		my $self = shift;
		$self->pause;
		$subseq->add_finally_callback(sub { $self->resume });
		$subseq->run();
	});

}, tests => 2;

run_tests;
