package Protocol::TLS::Client;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer bin2hex);
use Protocol::TLS::Utils qw(load_cert load_priv_key);
use Protocol::TLS::Context;
use Protocol::TLS::Connection;
use Protocol::TLS::Constants qw(const_name :state_types :end_types :c_types
  :versions :hs_types :ciphers cipher_type :alert_desc :hash_alg :sign_alg);

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless { %opts, sid => {} }, $class;
    if ( exists $opts{cert_file} && exists $opts{key_file} ) {
        $self->{cert} = load_cert( $opts{cert_file} );
        $self->{key}  = load_priv_key( $opts{key_file} );
    }
    $self;
}

sub new_connection {
    my ( $self, $server_name, %opts ) = @_;
    croak "Specify server name of host" unless defined $server_name;

    my $ctx = Protocol::TLS::Context->new( type => CLIENT );
    $ctx->{key}  = $self->{key}  if exists $self->{key};
    $ctx->{cert} = $self->{cert} if exists $self->{cert};

    my $con = Protocol::TLS::Connection->new($ctx);

    # Grab random session_id from cache (if exists)
    if ( exists $self->{sid}->{$server_name} ) {
        my $s   = $self->{sid}->{$server_name};
        my $sid = ( keys %$s )[0];

        $ctx->{proposed} = {
            session_id  => $sid,
            tls_version => $s->{$sid}->{tls_version},
            ciphers     => [ $s->{$sid}->{cipher} ],
            compression => [ $s->{$sid}->{compression} ],
        };
    }
    else {
        $ctx->{proposed} = {
            session_id => '',
            ciphers    => [
                TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_NULL_SHA256,
                TLS_RSA_WITH_NULL_SHA,
            ],
            tls_version => TLS_v12,
            compression => [0],
        };
    }

    if ( exists $opts{on_data} ) {
        $ctx->{on_data} = $opts{on_data};
    }

    $ctx->enqueue( [ CTYPE_HANDSHAKE, HSTYPE_CLIENT_HELLO, $ctx->{proposed} ] );

    $ctx->{on_change_state} = sub {
        my ( $ctx, $prev_state, $new_state ) = @_;
        tracer->debug( "State changed from "
              . const_name( 'state_types', $prev_state ) . " to "
              . const_name( 'state_types', $new_state ) );
    };

    # New session
    $ctx->state_cb(
        STATE_HS_HALF,
        sub {
            my $ctx    = shift;
            my $p      = $ctx->{pending};
            my $pro    = $ctx->{proposed};
            my $sp     = $p->{securityParameters};
            my $crypto = $ctx->crypto;

            # Server invalidate our session
            if ( $pro->{session_id} ne '' ) {
                delete $self->{sid}->{$server_name}->{ $pro->{session_id} };
            }

            my $pub_key = $crypto->cert_pubkey( $p->{cert}->[0] );

            if ( exists $p->{client_cert} ) {
                $ctx->enqueue(
                    [
                        CTYPE_HANDSHAKE,
                        HSTYPE_CERTIFICATE,
                        exists $ctx->{cert} ? $ctx->{cert} : ()
                    ]
                );
            }

            my ( $da, $ca, $mac ) = cipher_type( $p->{cipher} );

            if ( $da eq 'RSA' ) {
                my $preMasterSecret =
                  pack( "n", $p->{tls_version} ) . $crypto->random(46);

                $sp->{master_secret} = $crypto->PRF(
                    $preMasterSecret,
                    "master secret",
                    $sp->{client_random} . $sp->{server_random}, 48
                );

                my $encoded =
                  $crypto->rsa_encrypt( $pub_key, $preMasterSecret );
                $ctx->enqueue(
                    [ CTYPE_HANDSHAKE, HSTYPE_CLIENT_KEY_EXCHANGE, $encoded ] );
            }
            else {
                die "not implemented";
            }

            if ( exists $p->{client_cert} && exists $ctx->{cert} ) {
                my ( $sign, $hash_n, $alg_n, $hash, $alg );

                $alg = $crypto->cert_pubkeyalg( $ctx->{cert} );

                if ( $alg && exists &{"SIGN_$alg"} ) {
                    no strict 'refs';
                    $alg_n = &{"SIGN_$alg"};
                }
                elsif ($alg) {
                    die "algotithm $alg not implemented";
                }
                else {
                    die "cert error";
                }

                my $sah = $p->{client_cert}->{sah};

                for my $i ( 0 .. @$sah / 2 - 1 ) {
                    if ( $sah->[ $i * 2 + 1 ] == $alg_n ) {
                        $hash_n = $sah->[ $i * 2 ];
                        $hash = const_name( 'hash_alg', $sah->[ $i * 2 ] );
                        $hash =~ s/HASH_//;
                        tracer->debug("Selected $alg, $hash");
                        last;
                    }
                }

                if ( $alg eq 'RSA' ) {
                    $sign = $crypto->rsa_sign( $ctx->{key}, $hash,
                        join '', @{ $p->{hs_messages} } );
                }
                else {
                    die "algotithm $alg not implemented";
                }

                $ctx->enqueue(
                    [
                        CTYPE_HANDSHAKE, HSTYPE_CERTIFICATE_VERIFY,
                        $hash_n,         $alg_n,
                        $sign
                    ]
                );
            }

            $ctx->enqueue( [CTYPE_CHANGE_CIPHER_SPEC],
                [ CTYPE_HANDSHAKE, HSTYPE_FINISHED, $ctx->finished ] );
        }
    );

    $ctx->state_cb( STATE_SESS_RESUME,
        sub {
            my $ctx = shift;
            my $p   = $ctx->{pending};

            #my $pro    = $ctx->{proposed};
            my $sp = $p->{securityParameters};

            my $s = $self->{sid}->{$server_name}->{ $p->{session_id} };
            $p->{tls_version} = $s->{tls_version};
            $p->{cipher}      = $s->{cipher};
            $sp->{$_}         = $s->{securityParameters}->{$_}
              for keys %{ $s->{securityParameters} },

              tracer->debug( "Resume session: " . bin2hex( $p->{session_id} ) );
        }
    );

    $ctx->state_cb( STATE_HS_RESUME,
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

            # add sid to client's cache
            $self->{sid}->{$server_name}->{ $p->{session_id} } =
              $ctx->copy_pending;
            tracer->debug( "Saved sid:\n" . bin2hex( $p->{session_id} ) );
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

Protocol::TLS::Client - pure Perl TLS Client

=head1 SYNOPSIS

    use Protocol::TLS::Client;

    # Create client object
    my $client = Protocol::TLS::Client->new();

    # You must create tcp connection yourself
    my $cv = AE::cv;
    tcp_connect 'example.com', 443, sub {
        my $fh = shift or do {
            warn "error: $!\n";
            $cv->send;
            return;
        };
        
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


        # Create new TLS-connection object
        my $con = $client->new_connection(

            # SERVER NAME (FQDN)
            'example.com',

            # Callback executed when TLS-handshake finished
            on_handshake_finish => sub {
                my ($tls) = @_;

                # Send some application data
                $tls->send("hi there\n");
            },
            
            # Callback executed when application data received
            on_data => sub {
                my ( $tls, $data ) = @_;
                print $data;
                
                # send close notify and close application level connection
                $tls->close;
            }
        );

        # Handshake start
        # Send TLS records to socket
        while ( my $record = $con->next_record ) {
            $h->push_write($record);
        }

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
        ();
    };

    # finish
    $cv->recv;

=head1 DESCRIPTION

Protocol::TLS::Client is TLS client library. It's intended to make TLS-client
implementations on top of your favorite event loop.

=head1 METHODS

=head2 new

Initialize new client object

    my $client = Procotol::TLS::Client->new( %options );

Availiable options:

=over

=item cert_file => /path/to/cert.crt

Path to client certificate to perform client to server authentication

=item key_file => /path/to/cert.key

Path to private key for client certificate

=back

=head2 new_connection

Create new TLS-connection object

    my $con = $client->new_connection( 'F.Q.D.N', %options );

'F.Q.D.N' - fully qualified domain name

%options  - options hash

Availiable options:

=over

=item on_handshake_finish => sub { ... }

Callback invoked when TLS handshake completed

    on_handshake_finish => sub {
        my ($tls) = @_;

        # Send some application data
        $tls->send("hi there\n");
    },

=item on_data => sub { ... }

Callback executed when application data received

    on_data => sub {
        my ( $tls, $data ) = @_;
        print $data;

        # send close notify and close application level connection
        $tls->close;
    }

=back

=head1 LICENSE

Copyright (C) Vladimir Lettiev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Vladimir Lettiev E<lt>thecrux@gmail.comE<gt>

=cut

