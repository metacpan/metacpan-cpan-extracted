package ONE::Timer;
{
  $ONE::Timer::VERSION = 'v0.2.0';
}
# Dist::Zilla: +PodWeaver
# ABSTRACT: Timer/timeout events for MooseX::Event
use AnyEvent ();
use MooseX::Event;
use Scalar::Util ();

has 'delay'    => (isa=>'Num|CodeRef', is=>'ro', default=>0);


has 'interval' => (isa=>'Num', is=>'ro', default=>0);

has '_guard'   => (is=>'rw');


has_event 'timeout';

no MooseX::Event; # Remove the moose helpers, so we can declare our own after method

use Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw( sleep sleep_until );


sub sleep {
    return if $_[-1] <= 0;
    my $cv = AE::cv;
    my $w; $w=AE::timer( $_[-1], 0, sub { undef $w; $cv->send } );
    $cv->recv;
}


sub sleep_until {
    my $for = $_[-1] - AE::time;
    return if $for <= 0;
    my $cv = AE::cv;
    my $w; $w=AE::timer( $for, 0, sub { undef $w; $cv->send } );
    $cv->recv;
}


sub after {
    my $class = shift;
    my( $after, $on_timeout ) = @_;
    my $self = $class->new( delay=> $after );
    $self->on( timeout => $on_timeout );
    $self->start( defined(wantarray) );
    return $self;
}


sub at {
    my $class = shift;
    my( $at, $on_timeout ) = @_;
    my $self = $class->new( delay=> sub {$at - AE::time}  );
    $self->on( timeout => $on_timeout );
    $self->start( defined(wantarray) );
    return $self;
}


sub every {
    my $class = shift;
    my( $every, $on_timeout ) = @_;
    my $self = $class->new( delay => $every, interval => $every );
    $self->on( timeout => $on_timeout );
    $self->start( defined(wantarray) );
    return $self;
}


sub start {
    my $self = shift;
    my( $is_weak ) = @_;
    
    if ( defined $self->_guard ) {
        require Carp;
        Carp::croak( "Can't start a timer that's already running" );
    }
    
    my $cb;
    Scalar::Util::weaken($self) if $is_weak;
    if ( $self->interval ) {
        $cb = sub { $self->emit('timeout') };
    }
    else {
        $cb = sub { $self->cancel; $self->emit('timeout'); }
    }
    my $delay;
    if ( ref $self->delay ) {
        $delay = $self->delay->();
        $delay = 0 if $delay < 0;
    }
    else {
        $delay = $self->delay;
    }
    my $w = AE::timer $delay, $self->interval, sub { $self->emit('timeout') };
    $self->_guard( $w );
}


sub cancel {
    my $self = shift;
    unless (defined $self->_guard) {
        require Carp;
        Carp::croak( "Can't cancel a timer that's not running" );
    }
    $self->_guard( undef );
}


__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=head1 NAME

ONE::Timer - Timer/timeout events for MooseX::Event

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

    use ONE qw( Timer=sleep:sleep_until );
    
    # After five seconds, say Hi
    ONE::Timer->after( 5, sub { say "Hi!" } );
    
    sleep 3; # Sleep for 3 seconds without blocking events from firing
    
    # Two seconds from now, say At!
    ONE::Timer->at( time()+2, sub { say "At!" } );
    
    # Every 5 seconds, starting 5 seconds from now, say Ping
    ONE::Timer->every( 5, sub { say "Ping" } );
    
    sleep_until time()+10; # Sleep until 10 seconds from now
    
    my $timer = ONE::Timer->new( delay=>5, interval=>25 );
    
    $timer->on( timeout => sub { say "Timer tick" } );
    
    $timer->start(); # Will say "Timer tick" in 5 secs and then ever 25 secs after that
    
    # ... later
    
    $timer->cancel(); # Will stop saying "Timer tick"

=head1 DESCRIPTION

Trigger events at a specific time or after a specific delay.

=head1 EVENTS

=head2 timeout

This event takes no arguments.  It's emitted when the event time completes.

=head1 ATTRIBUTES

=head2 our Num|CodeRef $.delay is ro = 0;

The number of seconds to delay before triggering this event.  By default, triggers immediately.

=head2 our Num $.interval is ro = 0;

The number of seconds to delay

=head1 CLASS METHODS

=head2 our method after( Rat $seconds, CodeRef $on_timeout ) returns ONE::Timer

Asynchronously, after $seconds, calls $on_timeout.  If you store the return
value, it acts as a guard-- if it's destroyed then the timer is canceled.

=head2 our method at( Rat $epochtime, CodeRef $on_timeout ) returns ONE::Timer

Asychronously waits until $epochtime and then calls $on_timeout. If you store the
return value, it acts as a guard-- if it's destoryed then the timer is canceled.

=head2 our method every( Rat $seconds, CodeRef $on_timeout ) returns ONE::Timer

Asychronously, after $seconds and every $seconds there after, calls $on-Timeout.  If you
store the return value it acts as a guard-- if it's destroyed then the timer is canceled.

=head2 our method new( :$delay, :$interval? ) returns ONE::Timer

Creates a new timer object that will emit it's "timeout" event after $delay
seconds and every $interval seconds there after.  Delay can be a code ref,
in which case it's return value is the number of seconds to delay.

=head1 METHODS

=head2 our method start( $is_obj_guard = False )

Starts the timer object running.  If $is_obj_guard is true, then destroying
the object will cancel the timer.

=head2 our method cancel()

Cancels a running timer. You can start the timer again by calling the start
method.  For after and every timers, it begins waiting all over again. At timers will
still emit at the time you specified (or immediately if that time has passed).

=head1 HELPERS

=head2 our sub sleep( Rat $secs ) is export

Sleep for $secs while allowing events to emit (and Coroutine threads to run)

=head2 our sub sleep_until( Rat $epochtime ) is export

Sleep until $epochtime while allowing events to emit (and Coroutine threads to run)

=for test_synopsis use v5.10;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<ONE|ONE>

=item *

L<ONE|ONE>

=item *

L<AnyEvent|AnyEvent>

=item *

L<http://nodejs.org/docs/v0.5.4/api/timers.html|http://nodejs.org/docs/v0.5.4/api/timers.html>

=back

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

