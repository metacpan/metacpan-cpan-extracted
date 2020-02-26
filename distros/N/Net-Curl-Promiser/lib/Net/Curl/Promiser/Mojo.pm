package Net::Curl::Promiser::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Curl::Promiser::Mojo - support for L<Mojolicious>

=head1 SYNOPSIS

    my $promiser = Net::Curl::Promiser::Mojo->new();

    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );

    $promiser->add_handle_p($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url failed: " . shift },
    )->wait();

=head1 DESCRIPTION

This module provides a L<Mojolicious>-compatible interface for
L<Net::Curl::Promiser>.

See F</examples> in the distribution for a fleshed-out demonstration.

=head1 MOJOLICIOUS SPECIALTIES

This module’s interface is that provided by
L<Net::Curl::Promiser::LoopBase>, with the following tweaks to make it
more Mojo-friendly:

=over

=item * This module uses L<Mojo::Promise> rather than L<Promise::ES6>
as its promise implementation.

=item * C<add_handle_p()> is an alias for the base class’s C<add_handle()>.
This alias conforms to Mojo’s convention of postfixing C<_p> onto the end
of promise-returning functions.

=back

=cut

#----------------------------------------------------------------------

use parent 'Net::Curl::Promiser::LoopBase';

use Net::Curl::Multi ();

use Mojo::IOLoop ();
use Mojo::Promise ();

use Net::Curl::Promiser::FDFHStore ();

use constant PROMISE_CLASS => 'Mojo::Promise';

#----------------------------------------------------------------------

*add_handle_p = __PACKAGE__->can('add_handle');

#----------------------------------------------------------------------

sub _INIT {
    my ($self, $args_ar) = @_;

    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERFUNCTION(), \&_cb_timer );
    $self->setopt( Net::Curl::Multi::CURLMOPT_TIMERDATA(), $self );

    $self->{'_fhstore'} = Net::Curl::Promiser::FDFHStore->new();

    return;
}

sub _cb_timer {
    my ($multi, $timeout_ms, $self) = @_;

    my ($ot, $rt) = delete @{$self}{'onetimer','recurtimer'};
    Mojo::IOLoop->remove($ot) if $ot;
    Mojo::IOLoop->remove($rt) if $rt;

    if ($timeout_ms < 0) {
        if ($multi->handles()) {
            my $cb = sub {
                $self->_time_out_in_loop();
            };

            $self->{'onetimer'} = Mojo::IOLoop->timer( 5 => $cb );
            $self->{'recurtimer'} = Mojo::IOLoop->recurring( 5 => $cb );
        }
    }
    else {
        $self->{onetimer} = Mojo::IOLoop->timer(
            $timeout_ms / 1000,
            sub {
                $self->_time_out_in_loop();
            },
        );
    }

    return 1;
}

sub _fh_is_stale {
    local $!;

    stat $_[0] or do {
        return 1 if $!{'EBADF'};
        die "stat() on socket: $!";
    };

    return 0;
}

sub _io {
    my ($self, $fd, $read_yn, $write_yn) = @_;

    my $socket = $self->{'_watched_sockets'}{$fd} ||= do {
        my $s = $self->{'_fhstore'}->get_fh($fd);

        Mojo::IOLoop->singleton->reactor->io(
            $s,
            sub {
                $self->_process_in_loop($fd, $_[1] ? Net::Curl::Multi::CURL_CSELECT_OUT() : Net::Curl::Multi::CURL_CSELECT_IN());
            },
        );

        $s;
    };

    Mojo::IOLoop->singleton->reactor->watch(
        $socket,
        $read_yn,
        $write_yn,
    );

    return;
}

sub _SET_POLL_IN {
    my ($self, $fd) = @_;

    $self->_io( $fd, 1, 0 );

    return;
}

sub _SET_POLL_OUT {
    my ($self, $fd) = @_;

    $self->_io( $fd, 0, 1 );

    return;
}

sub _SET_POLL_INOUT {
    my ($self, $fd) = @_;

    $self->_io( $fd, 1, 1 );

    return;
}

sub _STOP_POLL {
    my ($self, $fd) = @_;

    if (my $socket = delete $self->{'_watched_sockets'}{$fd}) {
        Mojo::IOLoop->remove($socket);
    }
    else {
        $self->_handle_extra_stop_poll($fd);
    }

    return;
}

#----------------------------------------------------------------------

1;
