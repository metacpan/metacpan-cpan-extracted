package Net::Curl::Promiser;

use strict;
use warnings;

our $VERSION = '0.12';

=encoding utf-8

=head1 NAME

Net::Curl::Promiser - Asynchronous L<libcurl|https://curl.haxx.se/libcurl/>, the easy way!

=head1 DESCRIPTION

L<Net::Curl::Multi> is powerful but tricky to use: polling, callbacks,
timers, etc. This module does all of that for you and puts a Promise
interface on top of it, so asynchronous I/O becomes almost as simple as
synchronous I/O.

L<Net::Curl::Promiser> itself is a base class; you’ll need to provide
an interface to whatever event loop you use. See L</SUBCLASS INTERFACE>
below.

This distribution provides the following as both demonstrations and
portable implementations:

=over

=item * L<Net::Curl::Promiser::Mojo> (for L<Mojolicious>)

=item * L<Net::Curl::Promiser::AnyEvent> (for L<AnyEvent>)

=item * L<Net::Curl::Promiser::IOAsync> (for L<IO::Async>)

=item * L<Net::Curl::Promiser::Select> (for manually-written
C<select()> loops)

=back

(See the distribution’s F</examples> directory for one based on Linux’s
C<epoll>.)

=head1 PROMISE IMPLEMENTATION

This class’s default Promise implementation is L<Promise::ES6>.
You can use a different one by overriding the C<PROMISE_CLASS()> method in
a subclass, as long as the substitute class’s C<new()> method works the
same way as Promise::ES6’s (which itself follows the ECMAScript standard).

(NB: L<Net::Curl::Promiser::Mojo> uses L<Mojo::Promise> instead of
Promise::ES6.)

=head2 B<Experimental> L<Promise::XS> support

Try out experimental Promise::XS support by running with
C<NET_CURL_PROMISER_PROMISE_ENGINE=Promise::XS> in your environment.
This will override C<PROMISE_CLASS()>.

=cut

#----------------------------------------------------------------------

use Net::Curl::Multi ();

use constant _DEBUG => 0;

use constant _DEFAULT_TIMEOUT => 1000;

use constant PROMISE_CLASS => 'Promise::ES6';

#----------------------------------------------------------------------

=head1 GENERAL-USE METHODS

The following are of interest to any code that uses this module:

=head2 I<CLASS>->new(@ARGS)

Instantiates this class. This creates an underlying
L<Net::Curl::Multi> object and calls the subclass’s C<_INIT()>
method at the end, passing a reference to @ARGS.

(Most end classes of this module do not require @ARGS.)

=cut

sub new {
    my ($class, @args) = @_;

    my %props = (
        callbacks => {},
        to_fail => {},
    );

    my $self = bless \%props, $class;

    my $multi = Net::Curl::Multi->new();
    $self->{'multi'} = $multi;

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_SOCKETDATA,
        $self,
    );

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_SOCKETFUNCTION,
        \&_socket_fn,
    );

    $self->_INIT(\@args);

    return $self;
}

#----------------------------------------------------------------------

=head2 promise($EASY) = I<OBJ>->add_handle( $EASY )

A passthrough to the underlying L<Net::Curl::Multi> object’s
method of the same name, but the return is given as a Promise object.

That promise resolves with the passed-in $EASY object.
It rejects with either the error given to C<fail_handle()> or the
error that L<Net::Curl::Multi> object’s C<info_read()> returns.

B<IMPORTANT:> As with libcurl itself, HTTP-level failures
(e.g., 4xx and 5xx responses) are B<NOT> considered failures at this level.

=cut

sub add_handle {
    my ($self, $easy) = @_;

    $self->{'multi'}->add_handle($easy);

    my $env_engine = $ENV{'NET_CURL_PROMISER_PROMISE_ENGINE'} || q<>;

    my $promise;

    if ($env_engine eq 'Promise::XS') {
        require Promise::XS;

        my $deferred = Promise::XS::deferred();
        $self->{'deferred'}{$easy} = $deferred;
        $promise = $deferred->promise();
    }
    elsif ($env_engine) {
        die "bad promise engine: [$env_engine]";
    }
    else {
        $self->PROMISE_CLASS()->can('new') or do {
            my $class = $self->PROMISE_CLASS();

            local $@;
            die if !eval "require $class";
        };

        $promise = $self->PROMISE_CLASS()->new( sub {
            $self->{'callbacks'}{$easy} = \@_;
        } );
    }

    return $promise;
}

=head2 $obj = I<OBJ>->cancel_handle( $EASY )

Prematurely cancels $EASY. The associated promise will be abandoned
in pending state, never to resolve nor reject.

Returns I<OBJ>.

=cut

sub cancel_handle {
    my ($self, $easy) = @_;

    $self->_is_pending($easy) or die "Cannot cancel non-pending request!";

    # We need to cancel immediately so that our N::C::Multi object
    # removes the handle before the next event loop iteration.
    $self->_finish_handle($easy, 1);

    return $self;
}

=head2 $obj = I<OBJ>->fail_handle( $EASY, $REASON )

Like C<cancel_handle()> but rejects $EASY’s associated promise
with the given $REASON.

Returns I<OBJ>.

=cut

sub fail_handle {
    my ($self, $easy, $reason) = @_;

    $self->_is_pending($easy) or die "Cannot fail non-pending request!";

    $self->{'to_fail'}{$easy} = [ $easy, \$reason ];

    return $self;
}

sub _is_pending {
    my ($self, $easy) = @_;

    return $self->{'callbacks'}{$easy} || $self->{'deferred'}{$easy};
}

#----------------------------------------------------------------------

=head2 $obj = I<OBJ>->setopt( … )

A passthrough to the underlying L<Net::Curl::Multi> object’s
method of the same name. Returns I<OBJ> to facilitate chaining.

C<CURLMOPT_SOCKETFUNCTION> or C<CURLMOPT_SOCKETDATA> are set internally;
any attempt to set them via this interface will prompt an error.

=cut

sub setopt {
    my $self = shift;

    for my $opt ( qw( SOCKETFUNCTION  SOCKETDATA ) ) {
        my $fullopt = "CURLMOPT_$opt";

        if ($_[0] == Net::Curl::Multi->can($fullopt)->()) {
            my $ref = ref $self;
            die "Don’t set $fullopt via $ref!";
        }
    }

    $self->{'multi'}->setopt(@_);
    return $self;
}

=head2 $obj = I<OBJ>->handles( … )

A passthrough to the underlying L<Net::Curl::Multi> object’s
method of the same name.

=cut

sub handles {
   return shift()->{'multi'}->handles();
}

#----------------------------------------------------------------------

=head1 EVENT LOOP METHODS

The following are needed only when you’re managing an event loop directly:

=head2 $num = I<OBJ>->get_timeout()

Returns the underlying L<Net::Curl::Multi> object’s C<timeout()>
value, with a suitable (positive) default substituted if that value is
less than 0.

(NB: This value is in I<milliseconds>.)

This may not suit your needs; if you wish/need, you can handle timeouts
via the L<CURLMOPT_TIMERFUNCTION|Net::Curl::Multi/CURLMOPT_TIMERFUNCTION>
callback instead.

This should only be called (if it’s called at all) from event loop logic.

=cut

sub get_timeout {
    my ($self) = @_;

    my $timeout = $self->{'multi'}->timeout();

    return( $timeout < 0 ? _DEFAULT_TIMEOUT() : $timeout );
}

#----------------------------------------------------------------------

=head2 $obj = I<OBJ>->process( @ARGS )

Tell the underlying L<Net::Curl::Multi> object which socket events have
happened.

If, in fact, no events have happened, then this calls
C<socket_action(CURL_SOCKET_TIMEOUT)> on the
L<Net::Curl::Multi> object (similar to C<time_out()>).

Finally, this reaps whatever pending HTTP responses may be ready and
resolves or rejects the corresponding Promise objects.

This should only be called from event loop logic.

Returns I<OBJ>.

=cut

sub process {
    my ($self, @fd_action_args) = @_;

    my $fd_action_hr = $self->_GET_FD_ACTION(\@fd_action_args);

    if (%$fd_action_hr) {
        for my $fd (keys %$fd_action_hr) {
            $self->{'multi'}->socket_action( $fd, $fd_action_hr->{$fd} );
        }
    }
    else {
        $self->{'multi'}->socket_action( Net::Curl::Multi::CURL_SOCKET_TIMEOUT() );
    }

    $self->_process_pending();

    return $self;
}

#----------------------------------------------------------------------

=head2 $is_active = I<OBJ>->time_out();

Tell the underlying L<Net::Curl::Multi> object that a timeout happened,
and reap whatever pending HTTP responses may be ready.

Calls C<socket_action(CURL_SOCKET_TIMEOUT)> on the
underlying L<Net::Curl::Multi> object. The return is the same as
that operation returns.

Since C<process()> can also do the work of this function, a call to this
function is just an optimization.

This should only be called from event loop logic.

=cut

sub time_out {
    my ($self) = @_;

    my $is_active = $self->{'multi'}->socket_action( Net::Curl::Multi::CURL_SOCKET_TIMEOUT() );

    $self->_process_pending();

    return $is_active;
}

#----------------------------------------------------------------------

=head1 SUBCLASS INTERFACE

B<NOTE:> The distribution provides several ready-built end classes;
unless you’re managing your own event loop, you don’t need to concern
yourself with this.

To use Net::Curl::Promiser, you’ll need a subclass that defines
the following methods:

=over

=item * C<_INIT(\@ARGS)>: Called at the end of C<new()>. Receives a reference
to the arguments given to C<new()>.

=item * C<_SET_POLL_IN($FD)>: Tells the event loop that the given file
descriptor is ready to read.

=item * C<_SET_POLL_OUT($FD)>: Like C<_SET_POLL_IN()> but for a write event.

=item * C<_SET_POLL_INOUT($FD)>: Like C<_SET_POLL_IN()> but registers
a read and write event simultaneously.

=item * C<_STOP_POLL($FD)>: Tells the event loop that the given file
descriptor is finished.

=item * C<_GET_FD_ACTION(\@ARGS)>: Receives a reference to the arguments
given to C<process()> and returns a reference to a hash of
( $fd => $event_mask ). $event_mask is the sum of
C<Net::Curl::Multi::CURL_CSELECT_IN()> and/or
C<Net::Curl::Multi::CURL_CSELECT_OUT()>, depending on which events
are available.

=back

B<IMPORTANT:> Your event loop B<MUST> B<NOT> close file descriptors. This means
that, if you create Perl filehandles from the file descriptors, you need to
prevent Perl from closing the underlying file descriptors.

=cut

#----------------------------------------------------------------------

sub _socket_fn {
    my ( $fd, $action, $self ) = @_[2, 3, 5];

    if ($action == Net::Curl::Multi::CURL_POLL_IN) {
        print STDERR "FD $fd, IN\n" if _DEBUG;

        $self->_SET_POLL_IN($fd);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_OUT) {
        print STDERR "FD $fd, OUT\n" if _DEBUG;

        $self->_SET_POLL_OUT($fd);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_INOUT) {
        print STDERR "FD $fd, INOUT\n" if _DEBUG;

        $self->_SET_POLL_INOUT($fd);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_REMOVE) {
        print STDERR "FD $fd, STOP\n" if _DEBUG;

        $self->_STOP_POLL($fd);

        # In case we got a read and a remove right away.
        # This *may* not be needed but doesn’t seem to hurt.
        $self->_process_pending();
    }
    else {
        warn "$self: Unrecognized action $action on FD $fd\n";
    }

    return 0;
}

sub _finish_handle {
    my ($self, $easy, $cb_idx, $payload) = @_;

    # If $cb_idx == 0, then $payload is a promise resolution.
    # If $cb_idx == 1, then $payload is either:
    #   undef       - request canceled
    #   scalar ref  - promise rejection

    my $err = $@;

    # Don’t depend on the caller to report failures.
    # (AnyEvent, for example, blackholes them.)
    warn if !eval {
        delete $self->{'to_fail'}{$easy};

        if ( my $cb_ar = delete $self->{'callbacks'}{$easy} ) {
            $cb_ar->[$cb_idx]->($cb_idx ? $$payload : $payload) if !$cb_idx || $payload;
        }
        elsif ( my $deferred = delete $self->{'deferred'}{$easy} ) {
            if ($cb_idx) {
                $deferred->reject($$payload) if $payload;
            }
            else {
                $deferred->resolve($payload);
            }
        }
        else {

            # This shouldn’t happen, but just in case:
            require Data::Dumper;
            print STDERR Data::Dumper::Dumper( ORPHAN => $easy => $payload );
        }

        $self->{'multi'}->remove_handle( $easy );

        1;
    };

    $@ = $err;

    return;
}

sub _clear_failed {
    my ($self) = @_;

    for my $val_ar ( values %{ $self->{'to_fail'} } ) {
        my ($easy, $reason_sr) = @$val_ar;
        $self->_finish_handle( $easy, 1, $reason_sr );
    }

    %{ $self->{'to_fail'} } = ();

    return;
}

sub _process_pending {
    my ($self) = @_;

    $self->_clear_failed();

    while ( my ( $msg, $easy, $result ) = $self->{'multi'}->info_read() ) {

        if ($msg != Net::Curl::Multi::CURLMSG_DONE()) {
            die "Unrecognized info_read() message: [$msg]";
        }

        $self->_finish_handle(
            $easy,
            ($result == 0) ? ( 0 => $easy ) : ( 1 => \$result ),
        );
    }

    return;
}

#----------------------------------------------------------------------

=head1 EXAMPLES

See the distribution’s F</examples> directory.

=head1 SEE ALSO

If you use L<AnyEvent>, then L<AnyEvent::XSPromises> with
L<AnyEvent::YACurl> may be a nicer fit for you.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-Curl-Promiser>

=head1 LICENSE & COPYRIGHT

Copyright 2019-2020 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=cut

1;
