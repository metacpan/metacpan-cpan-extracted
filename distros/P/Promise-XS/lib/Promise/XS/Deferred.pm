package Promise::XS::Deferred;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Promise::XS::Deferred

=head1 SYNOPSIS

See L<Promise::XS>.

=head1 DESCRIPTION

This class implements a promise’s “producer” behavior. It is not
to be instantiated directly, but rather via L<Promise::XS>.

=head1 BASIC METHODS

The following are what’s needed to implement normal promise workflows:

=head2 $obj = I<OBJ>->resolve( @ARGUMENTS )

Resolves I<OBJ>’s promise, assigning the given @ARGUMENTS as the value.
Returns I<OBJ>.

B<IMPORTANT:> Behavior here is B<not> defined if anything in @ARGUMENTS is
itself a promise.

=head2 $obj = I<OBJ>->reject( @ARGUMENTS )

Like C<resolve()> but rejects the promise instead.

=head1 ADDITIONAL METHODS

=head2 $yn = I<OBJ>->is_pending()

Returns a boolean that indicates whether the promise is still pending
(as opposed to resolved or rejected).

This shouldn’t normally be necessary but can be useful in debugging.

For compatibility with preexisting promise libraries, C<is_in_progress()>
exists as an alias for this logic.

=head2 $obj = I<OBJ>->clear_unhandled_rejection()

Ordinarily, if a promise’s rejection is “unhandled”, a warning about the
unhandled rejection is produced. Call this after C<reject()> to silence
that warning. (It’s generally better, of course, to handle all errors.)

=cut

#----------------------------------------------------------------------

*is_in_progress = *is_pending;

#----------------------------------------------------------------------
# Undocumented, by design:

sub set_deferral_AnyEvent() {
    require AnyEvent;

    ___set_deferral_generic(
        AnyEvent->can('postpone') || \&_anyevent_postpone_compat,
    );
}

sub set_deferral_IOAsync {
    my ($loop) = @_;

    ___set_deferral_generic(
        $loop->can('later') || \&_ioasync_later_compat,
        $loop,
    );
}

sub set_deferral_Mojo() {
    require Mojo::IOLoop;

    ___set_deferral_generic(
        Mojo::IOLoop->can('next_tick') || \&_mojo_next_tick_compat,
        'Mojo::IOLoop',
    );
}

#----------------------------------------------------------------------
# Polyfills for old versions of the event loops that didn’t include
# zero-timer convenience functions:

my %ae_timer;

sub _anyevent_postpone_compat {
    my $cb = $_[0];

    my ($w, $w_str);

    $w = AnyEvent->timer( after => 0, cb => sub {
        delete $ae_timer{$w_str};
        $cb->();
    } );

    $w_str = "$w";
    $ae_timer{$w_str} = $w;
}

sub _ioasync_later_compat {
    local ($@, $!);
    require IO::Async::Timer;

    $_[0]->add( IO::Async::Timer->new(
        mode => 'countdown',
        delay => 0,
        on_expire => $_[1],
    )->start() );
}

sub _mojo_next_tick_compat {
    Mojo::IOLoop->timer( 0, $_[1] );
}

1;
