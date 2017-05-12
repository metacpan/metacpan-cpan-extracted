package Protocol::TLS::Server;
use strict;
use warnings;
use Carp;
use MIME::Base64;
use Protocol::TLS::Trace qw(tracer bin2hex);
use Protocol::TLS::Utils qw(load_cert load_priv_key);
use Protocol::TLS::Context;
use Protocol::TLS::Connection;
use Protocol::TLS::Constants
  qw(cipher_type const_name :versions :ciphers :c_types :end_types :hs_types :state_types :alert_desc);

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless { %opts, sid => {} }, $class;
    $self->{cert} = load_cert( $opts{cert_file} );
    $self->{key}  = load_priv_key( $opts{key_file} );
    $self;
}

sub new_connection {
    my ( $self, %opts ) = @_;
    my $ctx = Protocol::TLS::Context->new( type => SERVER );
    $ctx->{key}      = $self->{key};
    $ctx->{cert}     = $self->{cert};
    $ctx->{proposed} = {
        ciphers => [
            TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_NULL_SHA256,
            TLS_RSA_WITH_NULL_SHA,
        ],
        tls_version => TLS_v12,
        compression => [0],
    };
    my $con = Protocol::TLS::Connection->new($ctx);

    $ctx->{on_change_state} = sub {
        my ( $ctx, $prev_state, $new_state ) = @_;
        tracer->debug( "State changed from "
              . const_name( 'state_types', $prev_state ) . " to "
              . const_name( 'state_types', $new_state )
              . "\n" );
    };

    if ( exists $opts{on_data} ) {
        $ctx->{on_data} = $opts{on_data};
    }

    $ctx->state_cb(
        STATE_HS_START,
        sub {
            my $ctx = shift;
            my $p   = $ctx->{pending};
            my $sp  = $p->{securityParameters};
            my $sid = $p->{session_id};

            # Resume session
            if ( $sid ne '' && exists $self->{sid}->{$sid} ) {
                my $s = $self->{sid}->{$sid};
                $p->{tls_version} = $s->{tls_version};
                $p->{cipher}      = $s->{cipher};
                $sp->{$_}         = $s->{securityParameters}->{$_}
                  for keys %{ $s->{securityParameters} };

                # save sid as proposed
                $ctx->{proposed}->{session_id} = $sid;
                tracer->debug( "Resume session: " . bin2hex($sid) );

                $ctx->enqueue(
                    [
                        CTYPE_HANDSHAKE,
                        HSTYPE_SERVER_HELLO,
                        {
                            tls_version   => $p->{tls_version},
                            server_random => $sp->{server_random},
                            session_id    => $sid,
                            cipher        => $p->{cipher},
                            compression   => $sp->{CompressionMethod}
                        }
                    ]
                );
                $ctx->enqueue( [CTYPE_CHANGE_CIPHER_SPEC],
                    [ CTYPE_HANDSHAKE, HSTYPE_FINISHED, $ctx->finished ] );
            }

            # New session
            else {
                $sid = $p->{session_id} = $ctx->crypto->random(32);
                $ctx->enqueue(
                    [
                        CTYPE_HANDSHAKE,
                        HSTYPE_SERVER_HELLO,
                        {
                            tls_version   => $p->{tls_version},
                            server_random => $sp->{server_random},
                            session_id    => $sid,
                            cipher        => $p->{cipher},
                            compression   => $sp->{CompressionMethod}
                        }
                    ],
                    [ CTYPE_HANDSHAKE, HSTYPE_CERTIFICATE, $ctx->{cert} ],
                    [ CTYPE_HANDSHAKE, HSTYPE_SERVER_HELLO_DONE ]
                );
            }
        }
    );

    $ctx->state_cb( STATE_HS_FULL,
        sub {
            my $ctx = shift;
            $ctx->enqueue( [CTYPE_CHANGE_CIPHER_SPEC],
                [ CTYPE_HANDSHAKE, HSTYPE_FINISHED, $ctx->finished ] );
        }
    );

    $ctx->state_cb( STATE_OPEN,
        sub {
            my $ctx = shift;
            my $p   = $ctx->{pending};

            # add sid to server's cache
            $self->{sid}->{ $p->{session_id} } = $ctx->copy_pending;
            tracer->debug( "Saved sid: " . bin2hex( $p->{session_id} ) );
            $ctx->{session_id}  = $p->{session_id};
            $ctx->{tls_version} = $p->{tls_version};
            $ctx->clear_pending;

            # Handle callbacks
            if ( exists $opts{on_handshake_finish} ) {
                $opts{on_handshake_finish}->($ctx);
            }
        }
    );

    $con;
}

1
__END__

=encoding utf-8

=head1 NAME

Protocol::TLS::Server - pure Perl TLS Server

=head1 SYNOPSIS

    use Protocol::TLS::Server;

    # Create server object.
    # Load X509 certificate and private key
    my $server = Protocol::TLS::Server->new(
        cert_file => 'server.crt',
        key_file  => 'server.key',
    );

    # You must create tcp server yourself
    my $cv = AE::cv;
    tcp_server undef, 4443, sub {
        my ( $fh, $host, $port ) = @_ or do {
            warn "Client error\n";
            $cv->send;
            return;
        };

        # Create new TLS-connection object
        my $con = $server->new_connection(

            # Callback executed when TLS-handshake finished
            on_handshake_finish => sub {
                my ($tls) = @_;
                
                # send application data
                $tls->send("hello");
            },

            # Callback executed when application data received
            on_data => sub {
                my ( $tls, $data ) = @_;
                print $data;

                # send close notify and close application level connection
                $tls->close;
            }
        );

        # socket handling
        my $h;
        $h = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                $_[0]->destroy;
                print "connection error\n";
                $cv->send;
            },
            on_eof => sub {
                $h->destroy;
                print "that's all folks\n";
                $cv->send;
            },
        );

        # low level socket operations (read/write)
        $h->on_read(
            sub {
                my $handle = shift;

                # read TLS records from socket and put them to $con object
                $con->feed( $handle->{rbuf} );
                $handle->{rbuf} = '';

                # write TLS records to socket
                while ( my $record = $con->next_record ) {
                    $handle->push_write($record);
                }

                # Terminate connection if all done
                $handle->push_shutdown if $con->shutdown;
                ();
            }
        );
        ()
    };

    # finish
    $cv->recv;

=head1 DESCRIPTION

Protocol::TLS::Server is TLS server library. It's intended to make TLS-server
implementations on top of your favorite event loop.

=head1 LICENSE

Copyright (C) Vladimir Lettiev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Vladimir Lettiev E<lt>thecrux@gmail.comE<gt>

=cut

