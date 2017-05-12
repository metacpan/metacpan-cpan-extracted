package Sim::Dispatcher;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw( carp croak );

our $DEBUG = 0;

sub new {
    my $self = ref $_[0] ? ref shift : shift;
    my %opts = @_;
    croak "No clock given" if !$opts{clock};
    bless {
        clock => $opts{clock},
        queue => [],
    }, $self;
}

sub now {
    $_[0]->{clock}->now;
}

sub schedule {
    my $self = shift;
    my %events = @_;
    while (my ($time, $handle) = each %events) {
        if ($time < $self->now) {
            carp "out-dated event [$time => $handle] ignored";
            next;
        }
        $self->_insert_event([$time => $handle]);
    }
}

sub _insert_event {
    my ($self, $event) = @_;
    my $queue = $self->{queue};
    for (my $i = 0; $i < @$queue; $i++) {
        if ($event->[0] < $queue->[$i]->[0]) {
            splice( @$queue, $i, 0, $event );
            return;
        }
    }
    push @$queue, $event;
}

sub fire_next ($) {
    my $self = shift;
    my $queue = $self->{queue};
    my $clock = $self->{clock};
    return undef if @$queue == 0;
    my $event = shift @$queue;
    my ($time, $handle) = @$event;
    my $now = $self->now;
    if ($time >= $now) {
        $clock->push_to($time);
        $handle->();
    } else {
        die "Clock modified outside of the dispatcher: next event is at $time while now is $now";
    }
    return 1;
}

sub run ($@) {
    my $self = shift;
    my %opts = @_;
    my $end_time = $self->now + $opts{duration} if defined $opts{duration};
    my $fires    = $opts{fires} || 100_000_000;
    my $i = 0;
    while (1) {
        #warn "run: next!";
        last if ++$i > $fires;
        my $t = $self->time_of_next;
        last if !defined $t or (defined $end_time and $t > $end_time);
        $self->fire_next;
    }
}

sub time_of_next ($) {
    my $self = shift;
    my $queue = $self->{queue};
    return @$queue ? $queue->[0]->[0] : undef;
}

sub reset ($) {
    my $self = shift;
    $self->{queue} = [];
    $self->{clock}->reset();
}

1;
__END__

=head1 NAME

Sim::Dispatcher - Event dispatcher for Sim

=head1 VERSION

This document describes Sim::Dispatcher 0.03 released
on June 2, 2007.

=head1 SYNOPSIS

    use Sim::Dispatcher;
    use Sim::Clock;

    my $clock = Sim::Clock->new;
    # you can also use your own Clock instance here
    my $engine = Sim::Dispatcher->new(clock => $clock);

    # Example 1: Static scheduling

    $engine->schedule(
       0 => sub { print $engine->now, ": morning!\n" },
       1 => sub { print $engine->now, ": afternoon!\n" },
       5 => sub { print $engine->now, ": night!\n" },
    );
    $engine->run( duration => 50 );
    # or Sim::Dispatcher->run( fires => 5 );

    $engine->reset();

    # Example 2: Dynamic (recursive) scheduling

    my ($count, $handler);

    # event handler:
    $handler = sub {
        $count++;
        my $time_for_next = $engine->now() + 2;
        $engine->schedule(
            $time_for_next => $handler,
        );
    };
    # only schedule the "seed" event
    $engine->schedule(
        0.5 => $handler,
    );
    $engine->run( fires => 5 );
    print "count: $count\n";  # 5
    print "now: ", $engine->now(), "\n";  # 8

=head1 DESCRIPTION

This class implements the most important component in the
whole Sim library, the event dispatcher. Basically, every
activites should be coordinated by this dispatcher.
Every other objects in a simulator either register an
event scheduled to happen at some point in the "future",
or iterate through the dispatching steps.

=head1 METHODS

=over

=item C<< $obj = Sim::Dispatcher->new( clock => $clock) >>

Object constructor accepting one mandatory named
argument C<$clock> which is an instance of classes like
L<Sim::Clock>.

=item C<< $obj->schedule( $time => $handle, ... ) >>

You can use this method to register events scheduled for the future, where
$time is the timestamp and $handle is an anonymous sub which will be invoked
by the dispatcher when the simulation time is at $time.

=item C<< $obj->run( duration => $time, fires => $count ) >>

Runs the dispatcher according to the time duration and event firing count.
both of these named parameters are optional. When none is specified,
C<< fires => 100_000_000 >> will be assumed.

=item C<< $obj->fire_next() >>

This method allows you to iterate through the dispatcher running process yourself.
You should only call C<fire_next> by hand if you've found the limitation criteria
given by the C<run> method can't fit your needs.

=item C<< $obj->now() >>

Reads the value of the simulation time.

=item C<< $obj->time_of_next() >>

Gets the timestamp of the next (or nearest) coming event, which is always a bit
greater or equal to "now".

=item C<< $obj->reset() >>

Clears the internal event queue of the dispatcher and resets the internal simulation
clock too.

=back

=head1 CONCURRENCY ISSUES

If two events have exactly the same timestamp, say, 1.5,
then the one registered earlier will be fired first.

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007 by Agent Zhang. All rights reserved.

This library is free software; you can modify and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

L<Sim::Clock>, L<Sim>.

