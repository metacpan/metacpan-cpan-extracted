package Net::HTTP2::Client::Connection::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::Client::Connection::Mojo

=head1 SYNOPSIS

    my $h2 = Net::HTTP2::Client::Connection::Mojo->new("perl.org");

    $h2->request("GET", "/")->then(
        sub ($resp) {
            print $resp->content();
        },
    )->wait();

=head1 DESCRIPTION

This class extends L<Net::HTTP2::Client::Connection> to work with L<Mojolicious>.

=head1 PROMISES

This class’s returned promises are instances of L<Mojo::Promise> rather than
L<Promise::ES6>.

=cut

#----------------------------------------------------------------------

use parent 'Net::HTTP2::Client::Connection';

use Scalar::Util ();

use Mojo::IOLoop::Client ();
use Mojo::Promise ();

use Net::HTTP2::IOSocketSSL;

use constant _PROMISE_CLASS => 'Mojo::Promise';

# perl -I ../p5-X-Tiny/lib -MCarp::Always -MData::Dumper -I ../p5-Promise-ES6/lib -Ilib -MNet::HTTP2::Client::Connection::Mojo -e'my $h2 = Net::HTTP2::Client::Connection::Mojo->new("google.com"); $h2->request("GET", "/")->then( sub { print Dumper shift } )->wait()'

#$IO::Socket::SSL::DEBUG = 5;
#$Net::SSLeay::trace = 8;

use constant _INIT_OPTS => (
    __PACKAGE__->SUPER::_INIT_OPTS(),
    'reactor',
);

sub _parse_event_args {
    my ($self, %opts) = @_;

    return ( reactor => $opts{'reactor'} );
}

sub _start_io_if_needed {
    my ($self, $host, $port, $h2) = @_;

    $self->{'client'} ||= do {
        my $stream_sr = \$self->{'stream'};
        my $prebuf_sr = \$self->{'prebuf'};

        my $reactor = $self->{'reactor'};

        my $client = Mojo::IOLoop::Client->new();
        $client->reactor($reactor) if $reactor;

        Scalar::Util::weaken($h2);

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        my $rejectors = $self->{'rejectors'} or die 'no rejectors';

        $client->on( connect => sub {
            $$stream_sr = Mojo::IOLoop::Stream->new(pop);
            $$stream_sr->reactor($reactor) if $reactor;
            $$stream_sr->start();

            $$stream_sr->on( error => sub {
                my ($stream, $err) = @_;
                $weak_self->_on_stream_error($err);
            } );

            $$stream_sr->on( close => sub {

                # At global destruction $weak_self might no longer exist.
                #
                $weak_self->_on_stream_close() if $weak_self;
            } );

            $$stream_sr->on( read => sub {
                my ($stream) = @_;

                $h2->feed(pop);

                while ( my $frame = $h2->next_frame() ) {
                    $stream->write($frame);
                }
            } );

            $$stream_sr->write($$prebuf_sr) if $$prebuf_sr;
        } );

        $client->on( error => sub {
            my ($client, $err) = @_;

            $rejectors->reject_all($err);
        } );

        $client->connect(
            address => $host,
            port => $port,
            tls => 1,
            tls_options => {
                Net::HTTP2::IOSocketSSL::tls_proto_args(),
                Net::HTTP2::IOSocketSSL::verify_args_from_boolean($self->{'tls_verify_yn'}),
            },
        );

        $client;
    };

    return;
}

sub _write_frame {
    if (my $stream = $_[0]{'stream'}) {
        $stream->write(@_[1, 2]);
    }
    else {
        $_[0]{'prebuf'} .= $_[1];
    }
}

1;
