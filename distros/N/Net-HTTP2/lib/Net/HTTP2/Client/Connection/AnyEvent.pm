package Net::HTTP2::Client::Connection::AnyEvent;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::Client::Connection::AnyEvent

=head1 SYNOPSIS

    my $cv = AnyEvent->condvar();

    my $h2 = Net::HTTP2::Client::Connection::AnyEvent->new("perl.org");

    $h2->request("GET", "/")->then(
        sub ($resp) {
            print $resp->content();
        },
    )->finally($cv);

    $cv->recv();

=head1 DESCRIPTION

This class extends L<Net::HTTP2::Client::Connection> to work with L<AnyEvent>.

It requires that L<Net::SSLeay> support ALPN.

=cut

#----------------------------------------------------------------------

use parent 'Net::HTTP2::Client::Connection';

use AnyEvent::TLS       ();
use AnyEvent::Handle    ();
use Net::SSLeay         ();
use Scalar::Util        ();

# perl -I ../p5-X-Tiny/lib -MData::Dumper -MAnyEvent -I ../p5-IO-SigGuard/lib -I ../p5-Promise-ES6/lib -Ilib -MNet::HTTP2::Client::Connection::AnyEvent -e'my $h2 = Net::HTTP2::Client::Connection::AnyEvent->new("google.com"); my $cv = AnyEvent->condvar(); $h2->request("GET", "/")->then( sub { print Dumper shift } )->finally($cv); $cv->recv();'

sub _start_io_if_needed {
    my ($self, $host, $port, $h2) = @_;

    $self->{'ae_handle'} ||= do {
        my @tls_opts;

        if ($self->{'tls_verify_yn'}) {
            push @tls_opts, (
                verify => 1,
                verify_peername => 'https',
            );
        }

        my $tls = AnyEvent::TLS->new(@tls_opts);

        Net::SSLeay::CTX_set_alpn_protos($tls->ctx(), $self->_ALPN_PROTOS());

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        my $read_chunk;

        AnyEvent::Handle->new(
            connect => [$host, $port],
            tls => 'connect',
            tls_ctx => $tls,

            on_error => sub {
                my ($handle, $fatal, $msg) = @_;
                $weak_self->_on_stream_error($msg);
                $handle->destroy();
            },

            on_eof => sub {
                $weak_self->_on_stream_close() if $weak_self;
                shift()->destroy();
            },

            on_read => sub {

                # NB: This doesn’t empty out rbuf in pre-5.16 perls:
                # substr( $_[0]->rbuf, 0, length($_[0]->rbuf), q<> )
                $read_chunk = $_[0]->rbuf();
                $_[0]->rbuf() = q<>;

                $h2->feed($read_chunk);
            },
        );
    };
}

sub _write_frame {
    $_[0]{'ae_handle'}->push_write($_[1]);
}

1;
