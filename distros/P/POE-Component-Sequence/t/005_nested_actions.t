
use strict;
use warnings;
use Test::More;
use POE::Component::Sequence;
use POE::Component::Sequence::Nested;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyTests;
use Time::HiRes qw(time);

sequence_test "Actions inside actions" => sub {
	my $sequence = shift;
	my @touch_points;
	
	$sequence->add_action(sub {
		my $self = shift;
		push @touch_points, 1;

		$self->add_action(sub {
			push @touch_points, 2;
		});
	});

	$sequence->add_action(sub {
		push @touch_points, 3;
	});

	$sequence->add_finally_callback(sub {
		is_deeply \@touch_points, [1, 2, 3], "Adding an action inside another action enqueues it next";
	});
}, tests => 1;

sequence_test "Nested sequences with merged heap, auto resume and pause" => sub {
	my $sequence = shift;

	$sequence->options_set(
		auto_pause  => 1,
		auto_resume => 1,
		merge_heap  => 1,
	);

	$sequence->add_action(sub {
		shift->heap_set(before => scalar time);
	});

	$sequence->add_action(sub {
		POE::Component::Sequence->new(sub {
			shift->heap_set(inside => scalar time);
		})->run;
	});

	$sequence->add_action(sub {
		shift->heap_set(after => scalar time);
	});

	$sequence->add_finally_callback(sub {
		my $self = shift;
		ok $self->heap_index('before') < $self->heap_index('inside'), "Subsequence triggered after first action";
		ok $self->heap_index('inside') < $self->heap_index('after'), "Subsequence triggered before last action";
	});
}, tests => 2;

sequence_test "Nested sequences with auto-error propogation" => sub {
	my $sequence = shift;

	$sequence->options_set(
		auto_pause  => 1,
		auto_resume => 1,
		auto_error  => 1,
	);

	$sequence->add_action(sub {
		POE::Component::Sequence->new(sub {
			die "Inside subsequence";
		})->run;
	});

	$sequence->add_error_callback(sub {
		my ($self, $error) = @_;
		like $error, qr/Inside subsequence/, "Caught error inside subsequence in my own error callback";
	});
}, tests => 1;

run_tests;
