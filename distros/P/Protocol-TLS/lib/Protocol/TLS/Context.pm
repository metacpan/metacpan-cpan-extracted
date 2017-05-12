package Protocol::TLS::Context;
use 5.008001;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer bin2hex);
use Protocol::TLS::RecordLayer;
use Protocol::TLS::Extension;
use Protocol::TLS::Crypto;
use Protocol::TLS::Constants
  qw(:end_types :state_types :alert_types :alert_desc :versions
  :c_types :hs_types is_tls_version cipher_type const_name);

# Mixin
our @ISA = qw(Protocol::TLS::RecordLayer Protocol::TLS::Extension);

my %sp = (
    connectionEnd       => undef,      # CLIENT, SERVER
    PRFAlgorithm        => undef,      # tls_prf_sha256
    BulkCipherAlgorithm => undef,      # null, rc4, 3des, aes
    CipherType          => undef,      # stream, block, aead
    enc_key_length      => undef,
    block_length        => undef,
    fixed_iv_length     => undef,
    record_iv_length    => undef,
    MACAlgorithm        => undef,      # sha1, sha256
    mac_length          => undef,
    mac_key_length      => undef,
    CompressionMethod   => undef,      # null
    master_secret       => ' ' x 48,
    client_random       => ' ' x 32,
    server_random       => ' ' x 32,
);

my %kb = (
    client_write_MAC_key        => undef,
    server_write_MAC_key        => undef,
    client_write_encryption_key => undef,
    server_write_encryption_key => undef,
    client_write_IV             => undef,
    server_write_IV             => undef,
);

sub copy_pending {
    my $ctx  = shift;
    my $p    = $ctx->{pending};
    my $copy = {
        cipher             => $p->{cipher},
        securityParameters => { %{ $p->{securityParameters} } },
        tls_version        => $p->{tls_version},
        session_id         => $p->{session_id},
        compression        => $p->{compression},
    };
    delete $copy->{securityParameters}->{client_random};
    delete $copy->{securityParameters}->{server_random};
    $copy;
}

sub clear_pending {
    my $ctx = shift;
    $ctx->{pending} = {
        securityParameters => {%sp},
        key_block          => {%kb},
        tls_version        => undef,
        session_id         => undef,
        cipher             => undef,
        hs_messages        => [],
        compression        => undef,
    };
    $ctx->{pending}->{securityParameters}->{connectionEnd} = $ctx->{type};
}

sub new {
    my ( $class, %args ) = @_;
    croak "Connection end type must be specified: CLIENT or SERVER"
      unless exists $args{type}
      && ( $args{type} == CLIENT
        || $args{type} == SERVER );

    my $self = bless {
        type           => $args{type},
        crypto         => Protocol::TLS::Crypto->new,
        proposed       => {},
        pending        => {},
        current_decode => {},
        current_encode => {},
        session_id     => undef,
        tls_version    => undef,
        seq_read       => 0,                            # 2^64-1
        seq_write      => 0,                            # 2^64-1
        queue          => [],
        state          => STATE_IDLE,
        fragment       => '',
    }, $class;
    $self->clear_pending;
    $self->load_extensions('ServerName');

    $self->{pending}->{securityParameters}->{connectionEnd} = $args{type};
    $self->{pending}->{securityParameters}
      ->{ $args{type} == SERVER ? 'server_random' : 'client_random' } =
      pack( 'N', time ) . $self->crypto->random(28);
    $self;
}

# Crypto backend object
sub crypto {
    shift->{crypto};
}

sub error {
    my $self = shift;
    tracer->debug("called error: @_\n");
    if ( @_ && !$self->{shutdown} ) {
        $self->{error} = shift;
        $self->{on_error}->( $self->{error} ) if exists $self->{on_error};
        $self->finish;
    }
    $self->{error};
}

sub finish {
    my $self = shift;
    $self->enqueue( [ CTYPE_ALERT, FATAL, $self->{error} ] )
      unless $self->shutdown;
    $self->shutdown(1);
}

sub close {
    my $self = shift;
    $self->enqueue( [ CTYPE_ALERT, FATAL, CLOSE_NOTIFY ] )
      unless $self->shutdown;
    $self->shutdown(1);
}

sub shutdown {
    my $self = shift;
    $self->{shutdown} = shift if @_;
    $self->{shutdown};
}

sub enqueue {
    my ( $self, @records ) = @_;
    for (@records) {
        tracer->debug(
                "enqueue "
              . const_name( 'c_types', $_->[0] )
              . (
                $_->[0] == CTYPE_HANDSHAKE
                ? "/" . const_name( 'hs_types', $_->[1] )
                : ''
              )
              . "\n"
        );
        push @{ $self->{queue} }, $self->record_encode( TLS_v12, @$_ );
        $self->state_machine( 'send', $_->[0],
            $_->[0] == CTYPE_HANDSHAKE ? $_->[1] : () );
    }
}

sub dequeue {
    my $self = shift;
    shift @{ $self->{queue} };
}

sub application_data {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    if ( exists $ctx->{on_data} && $ctx->state == STATE_OPEN ) {
        $ctx->{on_data}->( $ctx, substr $$buf_ref, $buf_offset, $length );
    }
    $length;
}

sub send {
    my ( $ctx, $data ) = @_;
    if ( $ctx->state == STATE_OPEN ) {
        $ctx->enqueue( [ CTYPE_APPLICATION_DATA, $data ] );
    }
}

sub state_machine {
    my ( $ctx, $action, $c_type, $hs_type ) = @_;
    my $prev_state = $ctx->state;

    if ( $c_type == CTYPE_ALERT ) {

    }
    elsif ( $c_type == CTYPE_APPLICATION_DATA ) {
        if ( $prev_state != STATE_OPEN ) {
            tracer->error("Handshake was not complete\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # IDLE state (waiting for ClientHello)
    elsif ( $prev_state == STATE_IDLE ) {
        if ( $c_type != CTYPE_HANDSHAKE && $hs_type != HSTYPE_CLIENT_HELLO ) {
            tracer->error("Only ClientHello allowed in IDLE state\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
        else {
            $ctx->state(STATE_HS_START);
        }
    }

    # Start Handshake (waiting for ServerHello)
    elsif ( $prev_state == STATE_HS_START ) {
        if ( $c_type != CTYPE_HANDSHAKE && $hs_type != HSTYPE_SERVER_HELLO ) {
            tracer->error(
                "Only ServerHello allowed at Handshake Start state\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
        elsif ( defined $ctx->{proposed}->{session_id}
            && $ctx->{proposed}->{session_id} eq $ctx->{pending}->{session_id} )
        {
            $ctx->state(STATE_SESS_RESUME);
        }
        else {
            $ctx->state(STATE_SESS_NEW);
        }
    }

    # STATE_SESS_RESUME
    elsif ( $prev_state == STATE_SESS_RESUME ) {
        if ( $c_type == CTYPE_HANDSHAKE ) {
            if ( $hs_type == HSTYPE_FINISHED ) {
                $ctx->state(STATE_HS_RESUME);
            }
        }
        elsif ( $c_type == CTYPE_CHANGE_CIPHER_SPEC ) {
            $ctx->change_cipher_spec($action);
        }
        else {
            tracer->error("Unexpected Handshake type\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # STATE_HS_RESUME
    elsif ( $prev_state == STATE_HS_RESUME ) {
        if ( $c_type == CTYPE_HANDSHAKE && $hs_type == HSTYPE_FINISHED ) {
            $ctx->state(STATE_OPEN);
        }
        elsif ( $c_type == CTYPE_CHANGE_CIPHER_SPEC ) {
            $ctx->change_cipher_spec($action);
        }
        else {
            tracer->error("Unexpected Handshake type\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # STATE_SESS_NEW
    elsif ( $prev_state == STATE_SESS_NEW ) {
        if ( $c_type == CTYPE_HANDSHAKE ) {
            if ( $hs_type == HSTYPE_SERVER_HELLO_DONE ) {
                $ctx->state(STATE_HS_HALF);
            }
        }
        else {
            tracer->error("Unexpected Handshake type\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # STATE_HS_HALF
    elsif ( $prev_state == STATE_HS_HALF ) {
        if ( $c_type == CTYPE_HANDSHAKE ) {
            if ( $hs_type == HSTYPE_FINISHED ) {
                $ctx->state(STATE_HS_FULL);
            }
        }
        elsif ( $c_type == CTYPE_CHANGE_CIPHER_SPEC ) {
            $ctx->change_cipher_spec($action);
        }
        else {
            tracer->error("Unexpected Handshake type\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # STATE_HS_FULL
    elsif ( $prev_state == STATE_HS_FULL ) {
        if ( $c_type == CTYPE_HANDSHAKE ) {
            if ( $hs_type == HSTYPE_FINISHED ) {
                $ctx->state(STATE_OPEN);
            }
        }
        elsif ( $c_type == CTYPE_CHANGE_CIPHER_SPEC ) {
            $ctx->change_cipher_spec($action);
        }
        else {
            tracer->error("Unexpected Handshake type\n");
            $ctx->error(UNEXPECTED_MESSAGE);
        }
    }

    # TODO: ReNegotiation
    elsif ( $prev_state == STATE_OPEN ) {
        tracer->warning("ReNegotiation is not yet supported\n");
    }
}

sub generate_key_block {
    my $ctx = shift;
    my $sp  = $ctx->{pending}->{securityParameters};
    my $kb  = $ctx->{pending}->{key_block};
    ( my $da, $sp->{BulkCipherAlgorithm}, $sp->{MACAlgorithm} ) =
      cipher_type( $ctx->{pending}->{cipher} );

    tracer->debug( "Generating key block for cipher "
          . const_name( 'ciphers', $ctx->{pending}->{cipher} ) );

    $sp->{mac_length} = $sp->{mac_key_length} =
        $sp->{MACAlgorithm} eq 'SHA'    ? 20
      : $sp->{MACAlgorithm} eq 'SHA256' ? 32
      : $sp->{MACAlgorithm} eq 'MD5'    ? 16
      :                                   0;

    (
        $sp->{CipherType},      $sp->{enc_key_length},
        $sp->{fixed_iv_length}, $sp->{block_length}
      )
      =
        $sp->{BulkCipherAlgorithm} eq 'AES_128_CBC'  ? ( 'block', 16, 16, 16 )
      : $sp->{BulkCipherAlgorithm} eq 'AES_256_CBC'  ? ( 'block', 32, 16, 16 )
      : $sp->{BulkCipherAlgorithm} eq '3DES_EDE_CBC' ? ( 'block', 24, 8,  8 )
      : $sp->{BulkCipherAlgorithm} eq 'RC4_128' ? ( 'stream', 16, 0, undef )
      :                                           ( 'stream', 0,  0, undef );

    (
        $kb->{client_write_MAC_key},
        $kb->{server_write_MAC_key},
        $kb->{client_write_encryption_key},
        $kb->{server_write_encryption_key},
        $kb->{client_write_IV},
        $kb->{server_write_IV}
      )
      = unpack sprintf(
        'a%i' x 6,
        ( $sp->{mac_key_length} ) x 2,
        ( $sp->{enc_key_length} ) x 2,
        ( $sp->{fixed_iv_length} ) x 2,
      ),
      $ctx->crypto->PRF(
        $sp->{master_secret},
        "key expansion",
        $sp->{server_random} . $sp->{client_random},
        $sp->{mac_key_length} * 2 +
          $sp->{enc_key_length} * 2 +
          $sp->{fixed_iv_length} * 2
      );

    ();
}

sub change_cipher_spec {
    my ( $ctx, $action ) = @_;
    tracer->debug("Apply cipher spec $action...\n");

    my $sp = $ctx->{pending}->{securityParameters};
    my $kb = $ctx->{pending}->{key_block};
    $ctx->generate_key_block unless defined $kb->{client_write_MAC_key};
    my $cur =
      $action eq 'recv' ? $ctx->{current_decode} : $ctx->{current_encode};
    $cur->{securityParameters}->{$_} = $sp->{$_} for keys %$sp;
    $cur->{key_block}->{$_}          = $kb->{$_} for keys %$kb;
}

sub state {
    my $ctx = shift;
    if (@_) {
        my $state = shift;
        $ctx->{on_change_state}->( $ctx, $ctx->{state}, $state )
          if exists $ctx->{on_change_state};

        $ctx->{state} = $state;

        # Exec callbacks for new state
        if ( exists $ctx->{cb} && exists $ctx->{cb}->{$state} ) {
            for my $cb ( @{ $ctx->{cb}->{$state} } ) {
                $cb->($ctx);
            }
        }
    }
    $ctx->{state};
}

sub state_cb {
    my ( $ctx, $state, $cb ) = @_;
    push @{ $ctx->{cb}->{$state} }, $cb;
}

sub validate_server_hello {
    my ( $ctx, %h ) = @_;
    my $tls_v = is_tls_version( $h{version} );
    if ( !defined $tls_v ) {
        tracer->error("server TLS version $h{version} not recognized\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }
    my $p   = $ctx->{pending};
    my $pro = $ctx->{proposed};

    if ( $tls_v < $pro->{tls_version} ) {
        tracer->error("server TLS version $tls_v is not supported\n");
        $ctx->error(PROTOCOL_VERSION);
        return undef;
    }

    if ( !grep { $h{compression} == $_ } @{ $pro->{compression} } ) {
        tracer->error("server compression not supported\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }

    if ( !grep { $h{cipher} == $_ } @{ $pro->{ciphers} } ) {
        tracer->error("server cipher not accepted\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }

    $p->{tls_version}                             = $tls_v;
    $p->{securityParameters}->{server_random}     = $h{random};
    $p->{session_id}                              = $h{session_id};
    $p->{securityParameters}->{CompressionMethod} = $p->{compression} =
      $h{compression};
    $p->{cipher} = $h{cipher};
    1;
}

sub validate_client_hello {
    my ( $ctx, %h ) = @_;
    my $tls_v = is_tls_version( $h{tls_version} );
    if ( !defined $tls_v ) {
        tracer->error(
            "client's TLS version $h{tls_version} is not recognized\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }
    my $p   = $ctx->{pending};
    my $pro = $ctx->{proposed};

    if ( $tls_v < $pro->{tls_version} ) {
        tracer->error("client's TLS version $tls_v is not supported\n");
        $ctx->error(PROTOCOL_VERSION);
        return undef;
    }

    for my $c ( @{ $pro->{compression} } ) {
        next unless grep { $c == $_ } @{ $h{compression} };
        $p->{securityParameters}->{CompressionMethod} = $c;
        last;
    }

    if ( !exists $p->{securityParameters}->{CompressionMethod} ) {
        tracer->error("client's compression not supported\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }

    $p->{tls_version}                         = $tls_v;
    $p->{securityParameters}->{client_random} = $h{random};
    $p->{session_id}                          = $h{session_id};

    # Choose first defined cipher
    for my $cipher ( @{ $pro->{ciphers} } ) {
        next unless grep { $cipher == $_ } @{ $h{ciphers} };
        $p->{cipher} = $cipher;
        last;
    }

    if ( !exists $p->{cipher} ) {
        tracer->error("client's ciphers not supported\n");
        $ctx->error(HANDSHAKE_FAILURE);
        return undef;
    }

    1;
}

sub validate_client_key {
    my ( $ctx, $pkey ) = @_;
    my $p  = $ctx->{pending};
    my $sp = $p->{securityParameters};
    my ( $da, $ca, $mac ) = cipher_type( $p->{cipher} );

    if ( $da eq 'RSA' ) {
        my $preMasterSecret = $ctx->crypto->rsa_decrypt( $ctx->{key}, $pkey );

        $sp->{master_secret} = $ctx->crypto->PRF(
            $preMasterSecret,
            "master secret",
            $sp->{client_random} . $sp->{server_random}, 48
        );

    }
    else {
        die "not implemented";
    }

}

sub peer_finished {
    my $ctx = shift;
    $ctx->_finished( $ctx->{type} == CLIENT ? SERVER : CLIENT );
}

sub finished {
    my $ctx = shift;
    $ctx->_finished( $ctx->{type} == CLIENT ? CLIENT : SERVER );
}

sub _finished {
    my ( $ctx, $type ) = @_;
    $ctx->crypto->PRF(
        $ctx->{pending}->{securityParameters}->{master_secret},
        ( $type == CLIENT ? 'client' : 'server' ) . ' finished',
        $ctx->crypto->PRF_hash( join '', @{ $ctx->{pending}->{hs_messages} } ),
        12
    );
}

sub validate_finished {
    my ( $ctx, $message ) = @_;

    my $p      = $ctx->{pending};
    my $sp     = $p->{securityParameters};
    my $crypto = $ctx->crypto;

    my $finished = $ctx->peer_finished;
    tracer->debug( "finished expected: " . bin2hex($finished) );
    tracer->debug( "finished received: " . bin2hex($message) );

    if ( $finished ne $message ) {
        tracer->error("finished not match");
        $ctx->error(HANDSHAKE_FAILURE);
        return;
    }
    1;
}

1
