package Net::HTTP2::Client::Connection::IOAsync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::HTTP2::Client::Connection::IOAsync

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    my $h2 = Net::HTTP2::Client::Connection::IOAsync->new( $loop, 'perl.org' );

    $h2->request("GET", "/")->then(
        sub ($resp) {
            print $resp->content();
        },
    )->finally( sub { $loop->stop() } );

    $loop->run();

=head1 DESCRIPTION

This class extends L<Net::HTTP2::Client::Connection> to work with L<IO::Async>.

It requires L<IO::Async::SSL>, which as of this writing is a separate
distribution.

=cut

#----------------------------------------------------------------------

use parent 'Net::HTTP2::Client::Connection';

use IO::Async::SSL ();
use Scalar::Util   ();

use Net::HTTP2::IOSocketSSL ();

# perl -I ../p5-X-Tiny/lib -MIO::Async::Loop -MData::Dumper -MAnyEvent -I ../p5-IO-SigGuard/lib -I ../p5-Promise-ES6/lib -Ilib -MNet::HTTP2::Client::Connection::IOAsync -e'my $loop = IO::Async::Loop->new(); my $pool = Net::HTTP2::Client::Connection::IOAsync->new($loop, "google.com"); $pool->request("GET", "/")->then( sub { print Dumper shift } )->finally(sub { $loop->stop() }); $loop->run()'

#$IO::Socket::SSL::DEBUG = 5;
#$Net::SSLeay::trace = 8;

sub _parse_args {
    my ($class, $loop) = splice @_, 0, 2;

    return (
        $class->SUPER::_parse_args(@_),
        loop => $loop,
    );
}

sub _start_io_if_needed {
    my ($self, $host, $port, $h2) = @_;

    if (!$self->{'_io_started'}) {
        $self->{'_io_started'} = 1;

        my $stream_sr = \$self->{'stream'};

        my $prebuf_sr = \$self->{'prebuf'};

        my $weak_self = $self;
        Scalar::Util::weaken($weak_self);

        $self->{'loop'}->SSL_connect(
            host => $host,
            service => $port,

            Net::HTTP2::IOSocketSSL::tls_proto_args(),
            Net::HTTP2::IOSocketSSL::verify_args_from_boolean($self->{'tls_verify_yn'}),

            SSL_hostname => $host,

            on_stream => sub {
                my $stream = $_[0];

                $stream_sr = \$stream;

                $stream->configure(
                    on_read => sub {
                        $h2->feed(
                            substr( ${ $_[1] }, 0, length ${ $_[1] }, q<> ),
                        );
                    },

                    on_read_eof => sub {
                        $weak_self->_on_stream_close() if $weak_self;
                    },

                    on_read_error => sub {
                        my $err = shift;
                        $weak_self->_on_stream_error($err);
                    },

                    on_write_error => sub {
                        my $err = shift;
                        $weak_self->_on_stream_error($err);
                    },
                );

                $stream->write($$prebuf_sr) if $$prebuf_sr;

                $self->{'loop'}->add($stream);
            },

            on_resolve_error => sub {
    print STDERR Dumper( resolve => @_ );
            },
            on_connect_error => sub {
    use Data::Dumper;
    print STDERR Dumper( connect => @_ );
    },
            on_ssl_error => sub {
    use Data::Dumper;
    print STDERR Dumper( tls => @_ );
            },
        );
    }

    return;
}

sub _write_frame {
    if (my $stream = $_[0]{'stream'}) {
        $stream->write($_[1]);
    }
    else {
        $_[0]{'prebuf'} .= $_[1];
    }
}

1;
