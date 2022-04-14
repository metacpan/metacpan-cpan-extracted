package Net::Curl::Promiser;

use strict;
use warnings;

our $VERSION = '0.18';

=encoding utf-8

=head1 NAME

Net::Curl::Promiser - Asynchronous L<libcurl|https://curl.haxx.se/libcurl/>, the easy way!

=head1 DESCRIPTION

=begin html

<a href='https://coveralls.io/github/FGasper/p5-Net-Curl-Promiser?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Net-Curl-Promiser/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

L<Net::Curl::Multi> is powerful but tricky to use: polling, callbacks,
timers, etc. This module does all of that for you and puts a Promise
interface on top of it, so asynchronous I/O becomes almost as simple as
synchronous I/O.

L<Net::Curl::Promiser> itself is a base class; you’ll need to use
a subclass that works with your chosen event interface.

This distribution provides the following usable subclasses:

=over

=item * L<Net::Curl::Promiser::Mojo> (for L<Mojolicious>)

=item * L<Net::Curl::Promiser::AnyEvent> (for L<AnyEvent>)

=item * L<Net::Curl::Promiser::IOAsync> (for L<IO::Async>)

=item * L<Net::Curl::Promiser::Select> (for manually-written
C<select()> loops)

=back

If the event interface you want to use isn’t compatible with one of the
above, you’ll need to create your own L<Net::Curl::Promiser> subclass.
This is undocumented but pretty simple; have a look at the ones above as
well as another based on Linux’s L<epoll(7)> in the distribution’s
F</examples>.

=head1 MEMORY LEAK DETECTION

This module will, by default, C<warn()> if its objects are C<DESTROY()>ed
during Perl’s global destruction phase. To suppress this behavior, set
C<$Net::Curl::Promiser::IGNORE_MEMORY_LEAKS> to a truthy value.

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

=head1 DESIGN NOTES

Internally each instance of this class uses an instance of
L<Net::Curl::Multi> and an instance of L<Net::Curl::Promiser::Backend>.
(The latter, in turn, is subclassed to provide logic specific to
each event interface.) These are kept separate to avoid circular references.

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LeakDetector';

# So that Net::Curl::Easy::Code’s overloading gets set up:
use Net::Curl::Easy ();

use Net::Curl::Multi ();

use constant _DEBUG => 0;

use constant _DEFAULT_TIMEOUT => 1000;

our $IGNORE_MEMORY_LEAKS;

#----------------------------------------------------------------------

=head1 GENERAL-USE METHODS

The following are of interest to any code that uses this module:

=head2 I<CLASS>->new(@ARGS)

Instantiates this class, including creation of an underlying
L<Net::Curl::Multi> object.

=cut

sub new {
    my ($class, @args) = @_;

    my %props = (
        callbacks => {},
        to_fail => {},
        ignore_leaks => $IGNORE_MEMORY_LEAKS,
    );

    my $self = bless \%props, $class;

    my $multi = Net::Curl::Multi->new();
    $self->{'multi'} = $multi;

    my $backend = $self->_INIT(\@args);
    $self->{'backend'} = $backend;

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_SOCKETDATA,
        $backend,
    );

    $multi->setopt(
        Net::Curl::Multi::CURLMOPT_SOCKETFUNCTION,
        \&_socket_fn,
    );

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

    return $self->{'backend'}->add_handle($easy, $self->{'multi'});
}

=head2 $obj = I<OBJ>->cancel_handle( $EASY )

Prematurely cancels $EASY. The associated promise will be abandoned
in pending state, never to resolve nor reject.

Returns I<OBJ>.

=cut

sub cancel_handle {
    my ($self, $easy) = @_;

    $self->{'backend'}->cancel_handle($easy, $self->{'multi'});

    return $self;
}

=head2 $obj = I<OBJ>->fail_handle( $EASY, $REASON )

Like C<cancel_handle()> but rejects $EASY’s associated promise
with the given $REASON.

Returns I<OBJ>.

=cut

sub fail_handle {
    my ($self, $easy, $reason) = @_;

    if (!defined $reason || !length $reason) {
        require Carp;
        Carp::carp("fail_handle(): no reason given");
    }

    $self->{'backend'}->fail_handle($easy, $reason, $self->{'multi'});

    return $self;
}

#----------------------------------------------------------------------

=head2 $obj = I<OBJ>->setopt( … )

A passthrough to the underlying L<Net::Curl::Multi> object’s
method of the same name. Returns I<OBJ> to facilitate chaining.

This class requires control of certain L<Net::Curl::Multi> options;
if you attempt to set one of these here you’ll get an exception.

=cut

sub _SETOPT_FORBIDDEN { qw( SOCKETFUNCTION  SOCKETDATA ) };

sub setopt {
    my $self = shift;

    for my $opt ( $self->_SETOPT_FORBIDDEN() ) {
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

sub _socket_fn {
    my ( $multi, $fd, $action, $backend ) = @_[0, 2, 3, 5];

    # IMPORTANT: Removing handles within this function is likely to
    # corrupt libcurl.

    if ($action == Net::Curl::Multi::CURL_POLL_IN) {
        print STDERR "FD $fd, IN\n" if _DEBUG;

        $backend->SET_POLL_IN($fd, $multi);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_OUT) {
        print STDERR "FD $fd, OUT\n" if _DEBUG;

        $backend->SET_POLL_OUT($fd, $multi);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_INOUT) {
        print STDERR "FD $fd, INOUT\n" if _DEBUG;

        $backend->SET_POLL_INOUT($fd, $multi);
    }
    elsif ($action == Net::Curl::Multi::CURL_POLL_REMOVE) {
        print STDERR "FD $fd, STOP\n" if _DEBUG;

        $backend->STOP_POLL($fd, $multi);
    }
    else {
        warn( __PACKAGE__ . ": Unrecognized action $action on FD $fd\n" );
    }

    return 0;
}

#----------------------------------------------------------------------

=head1 EXAMPLES

See the distribution’s F</examples> directory.

=head1 SEE ALSO

Try L<Net::Curl::Easier> for a more polished variant of Net::Curl::Easy.

L<Net::Curl::Simple> implements a similar idea to this module but
doesn’t return promises. It has a more extensive interface that provides
a more “perlish” experience than L<Net::Curl::Easy>.

If you use L<AnyEvent>, then L<AnyEvent::XSPromises> with
L<AnyEvent::YACurl> may be a nicer fit for you.

=head1 REPOSITORY

L<https://github.com/FGasper/p5-Net-Curl-Promiser>

=head1 LICENSE & COPYRIGHT

Copyright 2019-2020 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=cut

1;
