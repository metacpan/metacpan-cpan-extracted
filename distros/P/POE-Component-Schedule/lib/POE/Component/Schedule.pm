package POE::Component::Schedule;

use 5.008;

use strict;
use warnings;
use Carp;

our $VERSION = '0.95';

use POE;


BEGIN {
    defined &DEBUG or *DEBUG = sub () { 0 };
}

# Private properties of a schedule ticket
sub PCS_TIMER    () { 0 }  # The POE timer
sub PCS_ITERATOR () { 1 }  # DateTime::Set iterator
sub PCS_SESSION  () { 2 }  # POE session ID
sub PCS_EVENT    () { 3 }  # Event name
sub PCS_ARGS     () { 4 }  # Event args array

# Private constant:
# The name of the counter attached to each session
# We use only one counter for all timers of one session
# All instances of P::C::S will use the same counter for a given session
sub REFCOUNT_COUNTER_NAME () { __PACKAGE__ }

# Scheduling session ID
# This session is a singleton
my $BackEndSession;

# Maps tickets IDs to tickets
my %Tickets = ();
my $LastTicketID = 'a'; # 'b' ... 'z', 'aa' ...

#
# crank up the schedule session
#
sub spawn { ## no critic (Subroutines::RequireArgUnpacking)
    if ( !defined $BackEndSession ) {
	my ($class, %arg)   = @_;
	my $alias = $arg{Alias} || ref $class || $class;

        $BackEndSession = POE::Session->create(
            inline_states => {
                _start => sub {
                    print "# $alias _start\n" if DEBUG;
                    my ($k) = $_[KERNEL];

                    $k->detach_myself;
                    $k->alias_set( $alias );
                    $k->sig( 'SHUTDOWN', 'shutdown' );
                },

                schedule     => \&_schedule,
                client_event => \&_client_event,
                cancel       => \&_cancel,

                shutdown => sub {
                    print "# $alias shutdown\n" if DEBUG;
                    my $k = $_[KERNEL];

                    # Remove all timers of our session
                    # and decrement session references
                    foreach my $alarm ($k->alarm_remove_all()) {
                        my ($name, $time, $t) = @$alarm;
                        $t->[PCS_TIMER] = undef;
                        $k->refcount_decrement($t->[PCS_SESSION], REFCOUNT_COUNTER_NAME);
                    }
                    %Tickets = ();

                    $k->sig_handled();
                },
                _stop => sub {
                    print "# $alias _stop\n" if DEBUG;
                    $BackEndSession = undef;
                },
            },
        )->ID;
    }
    return $BackEndSession;
}

#
# schedule the next event
#  ARG0 is the schedule ticket
#
sub _schedule {
    my ( $k, $t ) = @_[ KERNEL, ARG0];

    #
    # deal with DateTime::Sets that are finite
    #
    my $n = $t->[PCS_ITERATOR]->next;
    unless ($n) {
        # No more events, so release the session
        $k->refcount_decrement($t->[PCS_SESSION], REFCOUNT_COUNTER_NAME);
        $t->[PCS_TIMER] = undef;
        return;
    }

    $t->[PCS_TIMER] = $k->alarm_set( client_event => $n->epoch, $t );
    return $t;
}

#
# handle a client event and schedule the next one
#  ARG0 is the schedule ticket
#
sub _client_event { ## no critic (Subroutines::RequireArgUnpacking)
    my ( $k, $t ) = @_[ KERNEL, ARG0 ];

    $k->post( @{$t}[PCS_SESSION, PCS_EVENT], @{$t->[PCS_ARGS]} );

    return _schedule(@_);
}

#
# cancel an alarm
#
sub _cancel {
    my ( $k, $t ) = @_[ KERNEL, ARG0 ];

    if (defined($t->[PCS_TIMER])) {
        $k->alarm_remove($t->[PCS_TIMER]);
        $k->refcount_decrement($t->[PCS_SESSION], REFCOUNT_COUNTER_NAME);
        $t->[PCS_TIMER] = undef;
    }
    return;
}

#
# Takes a POE::Session, an event name and a DateTime::Set
# Returns a ticket object
#
sub add {

    my ( $class, $session, $event, $iterator, @args ) = @_;

    # Remember only the session ID
    $session = $poe_kernel->alias_resolve($session) unless ref $session;
    defined($session) or croak __PACKAGE__ . "->add: first arg must be an existing POE session ID or alias.";
    $session = $session->ID;

    # We don't want to loose the session until the event has been handled
    $poe_kernel->refcount_increment($session, REFCOUNT_COUNTER_NAME) > 0
      or croak __PACKAGE__ . "->add: first arg must be an existing POE session ID or alias: $!";

    ref $iterator && $iterator->isa('DateTime::Set')
      or croak __PACKAGE__ . "->add: third arg must be a DateTime::Set";

    $class->spawn unless $BackEndSession;

    my $id = $LastTicketID++;
    my $ticket = $Tickets{$id} = [
        undef, # Current alarm id
        $iterator,
        $session,
        $event,
        \@args,
    ];

    $poe_kernel->post( $BackEndSession, schedule => $ticket);

    # We return a kind of smart pointer, so the schedule
    # can be simply destroyed by releasing its object reference
    return bless \$id, ref($class) || $class;
}

sub delete {
    my $id = ${$_[0]};
    return unless exists $Tickets{$id};
    $poe_kernel->post($BackEndSession, cancel => delete $Tickets{$id});
    return;
}

# Releasing the ticket object will delete the ressource
sub DESTROY {
    return $_[0]->delete;
}

{
    no warnings;
    *new = \&add;
}

1;
__END__

=head1 NAME

POE::Component::Schedule - Schedule POE events using DateTime::Set iterators

=head1 SYNOPSIS

    use POE qw(Component::Schedule);
    use DateTime::Set;

    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]{sched} = POE::Component::Schedule->add(
                    $_[SESSION], Tick => DateTime::Set->from_recurrence(
                        after      => DateTime->now,
                        before     => DateTime->now->add(seconds => 3),
                        recurrence => sub {
                            return $_[0]->truncate( to => 'second' )->add( seconds => 1 )
                        },
                    ),
                );
            },
            Tick => sub {
                print 'tick ', scalar localtime, "\n";
            },
            remove_sched => sub {
                # Three ways to remove a schedule
                # The first one is only for API compatibility with POE::Component::Cron
                $_[HEAP]{sched}->delete;
                $_[HEAP]{sched} = undef;
                delete $_[HEAP]{sched};
            },
            _stop => sub {
                print "_stop\n";
            },
        },
    );

    POE::Kernel->run();

=head1 DESCRIPTION

This component encapsulates a session that sends events to client sessions
on a schedule as defined by a DateTime::Set iterator.

=head1 POE::Component::Schedule METHODS

=head2 spawn(Alias => I<name>)

Start up the PoCo::Schedule background session with the given alias. Returns
the back-end session handle.

No need to call this in normal use, C<add()> and C<new()> all crank
one of these up if it is needed.

=head2 add(I<$session>, I<$event_name>, I<$iterator>, I<@event_args>)

    my $sched = POE::Component::Schedule->add(
        $session,
        $event_name,
        $DateTime_Set_iterator,
        @event_args
    );

Add a set of events to the scheduler.

Returns a schedule handle. The event is automatically deleted when the handle
is not referenced anymore.

=head2 new(I<$session>, I<$event_name>, I<$iterator>, I<@event_args>)

C<new()> is an alias for C<add()>.

=head1 SCHEDULE HANDLE METHODS

=head2 delete()

Removes a schedule using the handle returned from C<add()> or C<new()>.

B<DEPRECATED>: Schedules are now automatically deleted when they are not
referenced anymore. So just setting the container variable to C<undef> will
delete the schedule.

=head1 SEE ALSO

L<POE>, L<DateTime::Set>, L<POE::Component::Cron>.

=head1 SUPPORT

You can look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Schedule>:
post bug report there.

=item * CPAN Ratings

L<http://cpanratings.perl.org/p/POE-Component-Schedule>:
if you use this distibution, please add comments on your experience for other
users.

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Schedule/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Schedule>

=back


=head1 ACKNOWLEDGMENT & HISTORY

This module was a friendly fork of L<POE::Component::Cron> to extract the
generic parts and isolate the Cron specific code in order to reduce
dependencies on other CPAN modules.

See L<https://rt.cpan.org/Ticket/Display.html?id=44442>.

The orignal author of POE::Component::Cron is Chris Fedde.

POE::Component::Cron is now implemented as a class that inherits from
POE::Component::Schedule.

Most of the POE::Component::Schedule internals have since been rewritten in
0.91_01 and we have now a complete test suite.

=head1 AUTHORS

=over 4

=item Olivier MenguE<eacute>, C<<< dolmen@cpan.org >>>

=item Chris Fedde, C<<< cfedde@cpan.org >>>

=back

=head1 COPYRIGHT AND LICENSE

=over 4

=item Copyright E<copy> 2009-2010 Olivier MenguE<eacute>.

=item Copyright E<copy> 2007-2008 Chris Fedde.

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
