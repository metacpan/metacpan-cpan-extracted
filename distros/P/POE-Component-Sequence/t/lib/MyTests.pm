package MyTests;

use strict;
use warnings;
use Carp;
use Test::More;
use Scalar::Util qw(blessed);
use base 'Exporter';

our @EXPORT = qw(is_method_chained sequence_test run_tests);

sub is_method_chained ($;$;@) {
	my ($object, $method, $description, @args) = @_;

	my $class = blessed $object;
	if (! defined $class) {
		carp "Can't call is_method_chained() on a non-blessed object";
		ok 0, 'is_method_chained';
		return;
	}

	$description ||= "Method '$method' on $class object is chained";

	my $return = $object->$method(@args);

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	is $return, $object, $description;
	
	return $return;
}

my ($test_sequence, $test_count);
my $builder = Test::More->builder();

sub sequence_test ($;&;@) {
	my ($description, $code, %args) = @_;

	# Fetch caller info in case we need to report errors with it
	my @caller = caller();

	$test_count += $args{tests} if $args{tests};
	$test_sequence ||= POE::Component::Sequence->new();

	# Create a sequence and pass it to the code for setup.  Set up a series of tests
	# such that we wait for each test to complete before running the next one

	my $test = POE::Component::Sequence->new();
	my $return = $code->( $test, $test_sequence );

	# If the test created it's own sequence, it can return it and we'll work with that
	if ($return && blessed $return && $return->isa('POE::Component::Sequence')) {
		$test = $return;
	}

	$test_sequence->add_action(sub {
		$test_sequence->pause;

		$builder->note("\n$description\n\n");
		my $initial_test_count = $builder->current_test;

		$test->add_finally_callback(sub {
			$test_sequence->resume;

			if ($args{tests}) {
				# Ensure that we actually ran the number of tests we said we would
				my $actual = $builder->current_test - $initial_test_count;
				my $difference = $args{tests} - $actual;
				if ($difference) {

					# Below we call the Test::Builder ok() method with 0
					# We'd like this to report the context of this call as being from
					# the caller to sequence_test().  We can't adjust Test::Builder::Level
					# because POE puts us outside the callstack of sequence_test

					no strict 'refs';
					no warnings 'redefine';
					local *{"Test::Builder::caller"} = sub {
						return wantarray ? @caller : $caller[0];
					};

					$builder->diag("Expected to run $args{tests} tests; ran $actual");
					if ($difference > 0) {
						foreach (1..$difference) {
							$builder->ok(0);
						}
					}
				}
			}
		});
		$test->run();
	});
}

sub run_tests () {
	plan tests => $test_count if $test_count;
	$test_sequence->add_finally_callback(sub { done_testing });
	$test_sequence->run();
	POE::Kernel->run();
}

1;
