use strict;
use warnings;
use TAP::Harness;
use TAP::Formatter::Event;
use Test::More tests => 24;

use constant DEBUG => 0;

# This nasty line will report each event as it happens.
BEGIN { return unless DEBUG; no strict 'refs'; no warnings 'redefine'; my $next = \&Mixin::Event::Dispatch::invoke_event; *{'Mixin::Event::Dispatch::invoke_event'} = sub { note "Event [$_[1]] for [$_[0]] with " . ($#_ >= 2 ? join(', ', map defined($_) ? $_ : 'undef', @_[2..$#_]) : 'no parameters');goto &$next; }; }

open my $fh, '>', \my $stdout or die $!; # stash stdout(+stderr) somewhere, currently we ignore it
my $harness = TAP::Harness->new({
	formatter => (my $formatter = TAP::Formatter::Event->new( {
		verbosity => 1,
		stdout => $fh,
	})),
	merge => 1,
});
{ # attach event handlers to some simple tests to verify our sample TAP works as expected
	my %had_event;
	my @passed = ('- is okay', '- this passes');
	my @failed = ('- fails because 2 != 3', '- this fails');
	$formatter->add_handler_for_event(
		# we have a new test file
		new_session => sub {
			my ($self, $session) = @_;
			is($had_event{new_session}++, 0, 'first new_session event');
			ok(!exists $had_event{test_finished}, 'not yet finished');
			subtest 'new_session' => sub {
				plan tests => 2;
				isa_ok($session, 'TAP::Formatter::Session');
				is($session->name, 't/simpletest.test', 'test file matches');
				done_testing();
			};
		},
		test_passed => sub {
			my ($self, $session, $test) = @_;
			cmp_ok($had_event{test_passed}++, '<', 2, 'only two test_passed events');
			ok(exists $had_event{new_session}, 'have seen new_session');
			ok(!exists $had_event{test_finished}, 'not yet finished');
			subtest 'test_passed' => sub {
				plan tests => 2;
				is($test->description, shift(@passed), 'description matches');
				is($test->ok, 'ok', 'status matches');
				done_testing();
			};
		},
		test_failed => sub {
			my ($self, $session, $test) = @_;
			cmp_ok($had_event{test_failed}++, '<', 2, 'only two test_failed events');
			ok(exists $had_event{new_session}, 'have seen new_session');
			ok(!exists $had_event{test_finished}, 'not yet finished');
			subtest 'test_failed' => sub {
				plan tests => 2;
				is($test->description, shift(@failed), 'description matches');
				is($test->ok, 'not ok', 'status matches');
				done_testing();
			};
		},
		# one test finished
		test_finished => sub {
			my ($self, $session, $test) = @_;
			is($had_event{test_finished}++, 0, 'single test_finished');
			ok(exists $had_event{new_session}, 'have seen new_session');
		},
		summary => sub {
			my ($self, $test) = @_;
			is($had_event{summary}++, 0, 'single summary');
			ok(exists $had_event{new_session}, 'have seen new_session');
			ok(exists $had_event{test_finished}, 'have seen test_finished');
		},
	);
	$harness->runtests('t/simpletest.test');
}

done_testing();

