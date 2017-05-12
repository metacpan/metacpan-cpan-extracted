#!perl 
use strict;
use warnings;
package Test::Session;
use parent qw(Mixin::Event::Dispatch);
use Time::HiRes qw(time);

=pod

Sequence is vaguely as follows:

Test session is created, starts as queued
Session starts, state moves to active
Test plan and results are received
Session ends, state moves to finished

We provide the following events:

=over 4

=item * started - execution has started for this test

=item * finished - execution has finished

=item * plan - test plan received

=item * pass - a test step has passed

=item * fail - a test step has failed

=item * comment - a comment has been seen

=back

=cut

# Represents a test (either completed, queued or active).
sub new {
	my $self = bless { }, shift;
	my $session = shift;
	$self->{session} = $session;
	$self->filename($session->name);
	$self->{state} = 'queued';
	$self;
}

=head2 session

Returns the linked L<TAP::Session::Result> object.

=cut

sub session { shift->{session} }

=head2 state

Change state. Hits callbacks. Allowed states are currently:

=over 4

=item * active

=item * queued

=item * finished

=item * aborted

=item * cancelled

=back

=cut

sub state {
	my $self = shift;
	if(@_) {
		my $state = shift;
		die "unknown state '$state'" unless grep $state eq $_, qw(active queued finished aborted cancelled);

		my $previous = $self->{state};
		$self->{state} = $state;
		$self->{started} = time if $state eq 'active';
		$self->invoke_event(state => $state, $previous);
		$self->invoke_event($state =>);
		return $self;
	}
	return $self->{state}
}

sub filename { my $self = shift; if(@_) { $self->{filename} = shift; return $self } return $self->{filename} }
sub passed { my $self = shift; if(@_) { $self->{passed} = shift; return $self } return $self->{passed} }
sub failed { my $self = shift; if(@_) { $self->{failed} = shift; return $self } return $self->{failed} }

=head2 elapsed

Returns total elapsed time for this test. Will be time so far if the test is still running.

=cut

sub elapsed {
	my $self = shift;
	
	return time - $self->{started} if $self->state eq 'active';
	return $self->{finished} - $self->{started};
}

=head2 one_test_passed

Mark a single test as having passed.

=cut

sub one_test_passed { my $self = shift; ++$self->{passed}; $self->invoke_event(test_passed => @_) }

=head2 one_test_failed

Mark a single test as having failed.

=cut

sub one_test_failed { my $self = shift; ++$self->{failed}; $self->invoke_event(test_failed => @_) }

=head2 planned

Set the plan for this test.

=cut

sub planned {
	my $self = shift;
	if(@_) {
		$self->{planned} = shift;
		$self->invoke_event(test_planned => @_);
		return $self
	}
	return $self->{planned}
}

package Test::Session::Manager;
use parent qw(Mixin::Event::Dispatch);
use Scalar::Util ();

=head2 new

Instantiate a new L<Test::Session::Manager>.

=cut

sub new { bless {}, shift }

=head2 add_session

Adds a new test session to be managed. Will attach event handlers as necessary
to ensure that we are updated with any status changes that are relevant to us.

Passes the new session to watchers via the added_session event, and also proxies
any session state events.

=cut

sub add_session {
	my $self = shift;
	my $ts = shift;
	$self->{session}{$ts->state}{$ts->session} = $ts;
	$ts->add_handler_for_event(
		'state' => $self->sap(sub {
			my ($self, $ts, $state, $previous) = @_;
			delete $self->{session}{$previous}{$ts->session};
			$self->{session}{$state}{$ts->session} = $ts;
			$self->invoke_event(session_state => $ts, $state, $previous);
			return $ts;
		}),
	);
	$self->invoke_event(added_session => $ts);
	return $self;
}

sub sap {
	my ($self, $sub) = @_;
	Scalar::Util::weaken $self;
	return sub { $self->$sub(@_) }
}

package Tickit::Test::Layout;
use Tickit::Widget::VBox;
use Tickit::Widget::HBox;
use Tickit::Widget::Table;
use Tickit::Widget::Static;
use Tickit::Widget::Frame;
use Tickit::Widget::Scroller;
use Tickit::Widget::Tabbed;

use IO::Async::Timer::Periodic;
use Tickit::Widget::Progressbar::Horizontal;
use POSIX qw(strftime);
use List::Util qw(sum);
use Scalar::Util ();

# Prevent annoying flicker on redraw
{ no strict 'refs'; *{'Tickit::Widget::_do_clear'} = sub { }; }

=head2 new

=cut

sub new {
	my $self = bless {}, shift;
	my %args = @_;
	my $tickit = $args{tickit} or die 'tickit';
	my $loop = $args{loop} or die 'loop';
	Scalar::Util::weaken($self->{loop} = $loop);
	$self->{manager} = $args{manager} or die 'manager';

	$self->{session} = {
		active => { },
		queued => { },
		completed => { },
	};
	$self->{started} = $loop->time;

# Set up all Tickit widgets, and start our display handling
	$self->create_widgets($loop);
	$tickit->set_root_widget($self->holder);
	$loop->add($tickit);
	$tickit->start;

# Hook into the manager events
	$self->{manager}->add_handler_for_event(
		added_session => $self->sap(sub {
			my ($self, $manager, $ts) = @_;
			$self->add_session($ts);
			$self;
		}),
		session_state => $self->sap(sub {
			my ($self, $manager, $ts, $state, $previous) = @_;
			die "Setting state to same as previous for $ts" if $state eq $previous;
			die "Apparently we exist already in that state?" if exists $self->{session}{$state}{$ts->session};
			$self->{session}{$state}{$ts->session} = delete $self->{session}{$previous}{$ts->session};
			++$self->{states_changed};
			$self;
		}),
	);

	return $self;
}

sub create_widgets {
	my $self = shift;
	my $loop = shift;
	$self->{holder} = Tickit::Widget::VBox->new;
	$self->add_table;
	$self->add_details;
	$self->add_status(loop => $loop);
}

=head2 add_session

Called from L<::Manager>

=cut

sub add_session {
	my ($self, $ts) = @_;

# Create the initial set of widgets
	my $data = {
		label => Tickit::Widget::Static->new(text => $ts->filename),
		progress => Tickit::Widget::Progressbar::Horizontal->new,
		elapsed => Tickit::Widget::Static->new(text => '00:00:00'),
		started => $self->loop->time,
		ts => $ts,
	};

	$data->{row} = $self->table->add_row(
		$data->{label},
		0,
		0,
		0,
		$data->{progress},
		$data->{elapsed},
	);

# Apply handlers for various updates from the test session.
	$ts->add_handler_for_event(
		test_passed => $self->sap(sub {
			my ($self, $ts, $test) = @_;
			my $data = $self->{session}{active}{$ts->session};
			$data->{row}->cell(1)->set_text($ts->passed);
			$data->{progress}->completion((($ts->passed || 0) + ($ts->failed || 0)) / $ts->planned) if $ts->planned;
			++$self->{totals}{passed};
			++$self->{totals_changed};
			$self;
		}),

		test_failed => $self->sap(sub {
			my ($self, $ts, $test) = @_;
			my $data = $self->{session}{active}{$ts->session};
			$data->{row}->cell(2)->set_text($ts->failed);
			$data->{progress}->completion((($ts->passed || 0) + ($ts->failed || 0)) / $ts->planned) if $ts->planned;
			++$self->{totals}{failed};
			++$self->{totals_changed};
			$self;
		}),

		test_planned => $self->sap(sub {
			my ($self, $ts, $test) = @_;
			my $data = $self->{session}{active}{$ts->session};
			$data->{row}->cell(3)->set_text($ts->planned);
			$self->{totals}{planned} += $ts->planned;
			++$self->{totals_changed};
			$self;
		}),
	);
	$self->{session}{queued}{$ts->session} = $data;
	$self;
}

=head2 update_planned

=cut

sub update_planned {
	my ($self, $ts) = @_;
	$self->{session}{active}{$ts->session}{row}->cell(3)->set_text($ts->planned);
	$self->{session}{active}{$ts->session}{label}->pen->chattrs({
		fg => 2,
		b => 1,
	});
#	$self->{total}{planned} += $ts->planned;
#	++$self->{total_changed};
	$self
}

=head2 add_table

=cut

sub add_table {
	my $self = shift;

	my $fr = Tickit::Widget::Frame->new(
		style => 'single',
		title => 'Active tests',
		b => 1,
	);
	$fr->add(
		($self->{table} = Tickit::Widget::Table->new(
			padding => 0,
			b => 0,
			columns => [
				{ label => 'Test file', align => 'left', width => 'auto' },
				{ label => 'Passed', align => 'right', width => 'auto' },
				{ label => 'Failed', align => 'right', width => 'auto' },
				{ label => 'Planned', align => 'right', width => 'auto' },
				{ label => 'Status', align => 'center', width => 'auto' },
				{ label => 'Elapsed', align => 'right', width => '9' },
			],
		))
	);
	$self->holder->add($fr, expand => 1);
	$self;
}

=head2 add_details

=cut

sub add_details {
	my $self = shift;

	my $fr = Tickit::Widget::Frame->new(
		style => 'single',
		title => 'Test details',
		b => 0,
	);
	$fr->add(my $tabbed = Tickit::Widget::Tabbed->new);
	$tabbed->add_tab(Tickit::Widget::Scroller->new, label => 'first.t');
	$tabbed->add_tab(Tickit::Widget::Scroller->new, label => 'second.t');
	$self->holder->add($fr, expand => 1);
	return $self;
}

=head2 add_status

=cut

sub add_status {
	my $self = shift;
	my %args = @_;
	my $loop = $args{loop};

	my $hbs = Tickit::Widget::HBox->new(bg => 4);
	$hbs->add(
		(my $ts = Tickit::Widget::Static->new(
			text => '0 tests running, 0 queued, 0 completed.',
			align => 'left',
		)),
		expand => 1,
	);
	$hbs->add(
		(my $test_stats = Tickit::Widget::Static->new(
			text => '0/0/0',
			align => '0.5',
		)),
		expand => 1,
	);
	$hbs->add(
		(Tickit::Widget::Static->new(
			text => '[',
			align => 'left',
		)),
	);
	$hbs->add(
		(my $total_progress = Tickit::Widget::Progressbar::Horizontal->new(
			completion => 0.0
		)),
		expand => 1,
	);
	$hbs->add(
		(Tickit::Widget::Static->new(
			text => ']',
			align => 'left',
		)),
	);
	$hbs->add(
		(my $elapsed = Tickit::Widget::Static->new(
			text => 'Elapsed 03:09:23',
			align => 'right',
		)),
		expand => 1,
	);
	$self->holder->add($hbs);
	{
		my $timer = IO::Async::Timer::Periodic->new(
			interval => 1.0,
			on_tick => $self->sap(sub {
				my $self = shift;
				$elapsed->set_text('Elapsed ' . strftime '%H:%M:%S', gmtime ($loop->time - $self->started));
				foreach (values %{$self->{session}{active}}) {
					$_->{elapsed}->set_text(strftime '%H:%M:%S', gmtime $_->{ts}->elapsed);
				}
			})
		);
		$loop->add($timer);
		$timer->start;
	}
	{
		my $timer = IO::Async::Timer::Periodic->new(
			interval => 0.1,
			on_tick => $self->sap(sub {
				my $self = shift;
				return 1 unless $self->totals_changed;

				$test_stats->set_text(join '/', map $self->{totals}{$_} || 0, qw(passed failed planned));
				$total_progress->completion(
					sum(map $self->{totals}{$_} // 0, qw(passed failed))
					/ $self->{totals}{planned}
				) if $self->{totals}{planned};
				$self->{totals_changed} = 0;
				return 1 unless $self->states_changed;

				$ts->set_text(sprintf '%d tests running, %d queued, %d completed.', map scalar keys %{$self->{session}{$_}}, qw(active queued finished));
			}),
		);
		$loop->add($timer);
		$timer->start;
	}
}

# Accessors

sub totals_changed { shift->{totals_changed} }
sub states_changed { shift->{states_changed} }

sub manager { shift->{manager} }
sub loop { shift->{loop} }
sub holder { shift->{holder} }
sub table { shift->{table} }
sub started { shift->{started} }

# Utils

sub sap {
	my ($self, $sub) = @_;
	Scalar::Util::weaken $self;
	return sub { $self->$sub(@_) }
}

package MySourceHandler;
use parent qw(TAP::Parser::SourceHandler::Perl);
use TAP::Parser::IteratorFactory;
use TAP::Parser::Iterator::Process::Async;
use Carp qw(carp confess cluck);

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

=head2 _create_iterator

We exist purely to pass the loop parameter to our custom iterator. Since L<IO::Async::Process>
does all the real work, we just need to bypass some of the manual selection logic.

=cut

sub _create_iterator {
	my ( $class, $source, $command, $setup, $teardown ) = @_;

	my $loop = $source->config->{$class}->{loop};
	return TAP::Parser::Iterator::Process::Async->new({
		command  => $command,
		merge    => $source->merge,
		setup    => $setup,
		teardown => $teardown,
		loop	 => $loop,
	});
}

package main;
use TAP::Harness::Async;
use TAP::Formatter::Event;
use IO::Async::Loop;
use Tickit::Async;

my $loop = IO::Async::Loop->new;

my $tickit = Tickit::Async->new;
my $man = Test::Session::Manager->new;

# Set up our layout
my $layout = Tickit::Test::Layout->new(
	tickit => $tickit,
	loop => $loop,
	manager => $man,
);

# TAP::Harness - all these options likely need to be set as defaults in TAP::Harness::Async itself
my $harness = TAP::Harness::Async->new({
	loop => $loop,
	formatter => (my $formatter = TAP::Formatter::Event->new( {
		verbosity => 1,
	})),
	merge => 1,
	sources =>  {
		MySourceHandler => { loop => $loop }
	}
});

# Mapping from description to original test
my %test_for_description;

$harness->callback(after_runtests => sub {
# TAP::Parser::Aggregator
	my $aggregator = shift;
	$test_for_description{$_}->state('finished') for $aggregator->descriptions;
	return 1;
});

my %test_for;
$formatter->add_handler_for_event(
# We have a new test plan for this session.
	test_plan => sub {
		my ($self, $session, $plan) = @_;
		$test_for{$session}->planned($plan->tests_planned);
	},
	test_failed => sub {
		my ($self, $session, $test) = @_;
		$test_for{$session}->one_test_failed($test);
	},
	test_passed => sub {
		my ($self, $session, $test) = @_;
		$test_for{$session}->one_test_passed($test);
	},
# Start up a new session.
	new_session => sub {
		my ($self, $session) = @_;
		my $file = $session->name;
		my $ts = Test::Session->new($session);
		$test_for{$session} = $ts;
		$man->add_session($ts);
		$ts->state('active');
		$test_for_description{$file} = $ts;
		return $self;
	},
);

# uniqify the incoming results
my $agg;
{ my %seen; ($agg) = map $harness->runtests($_), grep !$seen{$_}++, @ARGV; }

$loop->loop_forever;
$tickit->stop;
warn "completed";

