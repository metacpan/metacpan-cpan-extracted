package TAP::Formatter::Event;
# ABSTRACT: generate events from TAP::Formatter methods
use strict;
use warnings;
use parent qw(TAP::Formatter::Base Mixin::Event::Dispatch);
use TAP::Formatter::Event::Session;

our $VERSION = '0.001';

=head1 NAME

TAP::Formatter::Event - event interface to L<TAP::Formatter> or L<TAP::Harness::Async>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use TAP::Harness;
 use TAP::Formatter::Event;
 my $harness = TAP::Harness->new({
   formatter => TAP::Formatter::Event->new({ verbosity => 1 })->add_handler_for_event(
     test_failed => sub {
       my ($self, $session, $test) = @_;
       print "Failed test: " . $test->description . "\n";
     }
   ),
 });
 $harness->runtests(@ARGV);

=head1 DESCRIPTION

Used by some examples in L<TAP::Harness::Async>. Note that L<TAP::Harness> provides an event
interface already, so unless you're specifically after the async approach for running tests
then you may be better served by L<TAP::Parser/CALLBACKS>.

=head1 METHODS

Normally all methods would be called from L<TAP::Harness::Async>. See L<Mixin::Event::Dispatch>
and L<TAP::Formatter::Base> for other available methods.

=cut

=head2 open_test

=cut

sub open_test {
	my $self = shift;
	my ($test, $parser) = @_;
	my $session = TAP::Formatter::Event::Session->new({
		name	=> $test,
		formatter  => $self,
		parser     => $parser,
	});
	$self->invoke_event(new_session => $session);
	return $session;
}

=head2 summary

=cut

sub summary {
	my $self = shift;
	$self->invoke_event(summary =>);
	return 1;
}

1;

__END__

=head1 EVENTS

Events are triggered through the L<Mixin::Event::Dispatch/invoke_event> interface,
use L<Mixin::Event::Dispatch/add_handler_for_event> to attach handlers as required.
Unhandled events are ignored.

Example:

 my $file;
 $formatter->add_handler_for_event(
   test_failed => sub { warn "Test failed: " . $_[1]->description },
   new_session => sub {
     my ($self, $session) = @_;
     $file = $session->name;
     warn "Started session for [$file]";
     return $self;
   },
   test_passed => sub {
     my ($self, $test) = @_;
     warn "Test passed, description: " . $test->description;
     ++$passed{$self->testfile};
     $self;
   }
 );

=head2 new_session

Called when a new session ("test file") starts.

Receives a single L<TAP::Parser::Result> object.

=head2 test_started

A test run has started.

=head2 test_result

We have received a single result.

=head2 test_plan

This is the plan for the current test.

=head2 test_passed

A test has passed.

=head2 test_failed

A test has failed.

=head2 test_unknown

Unknown test result.

=head2 test_finished

A test file has finished.

=head2 summary

The summary results are ready.

=head1 SEE ALSO

=over 4

=item * L<TAP::Formatter>

=item * L<TAP::Formatter::Session>

=item * L<TAP::Harness>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
