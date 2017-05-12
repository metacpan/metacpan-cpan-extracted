use strict;
use warnings;
use Test::More;
use POE::Component::Sequence;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTests;

sequence_test "Custom handler" => sub {
	my $sequence = shift;

	# Implement a simple calculator
	$sequence->add_handler(sub {
		my ($self, $request) = @_;
		my $action = $request->{action};

		# If a simple value is passed, start with that value and pass it along
		if (! ref $action) {
			return { value => $action };
		}

		# Else, it's an array
		if (ref $action ne 'ARRAY') {
			return { deferred => 1 };
		}

		# The first item is an operator to perform on the current value; the second is a value to the operator
		my ($operator, $num) = @$action;
		my $value = $self->result;
		return { value => eval "$value $operator $num" };
	});

	# Start with 2
	$sequence->add_action(2);

	# Add 10
	$sequence->add_action([ '+', 10 ]);

	# Multiply by 4
	$sequence->add_action([ '*', 4 ]);

	$sequence->add_callback(sub {
		is shift->result, 48, "Calculation worked: result of (2 + 10) * 4";
	});
}, tests => 1;

run_tests;
