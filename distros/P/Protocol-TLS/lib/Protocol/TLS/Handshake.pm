package Protocol::TLS::Handshake;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer);
use Protocol::TLS::Constants
  qw(const_name :versions :hs_types :c_types :alert_desc);

my %handshake_types = (
    &HSTYPE_HELLO_REQUEST       => 'hello_request',
    &HSTYPE_CLIENT_HELLO        => 'client_hello',
    &HSTYPE_SERVER_HELLO        => 'server_hello',
    &HSTYPE_CERTIFICATE         => 'certificate',
    &HSTYPE_SERVER_KEY_EXCHANGE => 'server_key_exchange',
    &HSTYPE_CERTIFICATE_REQUEST => 'certificate_request',
    &HSTYPE_SERVER_HELLO_DONE   => 'server_hello_done',
    &HSTYPE_CERTIFICATE_VERIFY  => 'certificate_verify',
    &HSTYPE_CLIENT_KEY_EXCHANGE => 'client_key_exchange',
    &HSTYPE_FINISHED            => 'finished',
);

my %decoder =
  map { $_ => \&{ $handshake_types{$_} . '_decode' } }
  keys %handshake_types;

my %encoder =
  map { $_ => \&{ $handshake_types{$_} . '_encode' } }
  keys %handshake_types;

sub decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    return 0 if length($$buf_ref) - $buf_offset < 4;
    my ( $type, $length_high, $length_low ) = unpack "x${buf_offset}CCn",
      $$buf_ref;

    my $h_len = $length_high * 256**3 + $length_low;
    return 0 if $h_len > $length - 4;

    # Unknown handshake type
    if ( !exists $handshake_types{$type} ) {
        tracer->debug("Unknown handshake type: $type\n");
        $ctx->error(DECODE_ERROR);
        return undef;
    }
    tracer->debug( 'Got ' . const_name( 'hs_types', $type ) . "\n" );

    my $len = $decoder{$type}->( $ctx, $buf_ref, $buf_offset + 4, $h_len );
    return undef unless defined $len;

    # Save handshake data
    push @{ $ctx->{pending}->{hs_messages} }, substr $$buf_ref, $buf_offset,
      $h_len + 4
      if $type != HSTYPE_HELLO_REQUEST;

    # Arrived record may change state of stream
    $ctx->state_machine( 'recv', CTYPE_HANDSHAKE, $type );

    return $h_len + 4;
}

sub encode {
    my ( $ctx, $type ) = splice @_, 0, 2;
    my $encoded = pack 'CC n/a*', $type, 0, $encoder{$type}->( $ctx, @_ );
    push @{ $ctx->{pending}->{hs_messages} }, $encoded
      if $type != HSTYPE_HELLO_REQUEST;
    $encoded;
}

sub hello_request_decode {
    0;
}

sub hello_request_encode {
    '';
}

sub client_hello_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    my ( $tls_version, $random, $session_id, $ciphers_l ) =
      unpack "x$buf_offset na32 C/a n", $$buf_ref;

    my $sess_l = length($session_id) || 0;

    # Length error
    if ( $sess_l > 32 ) {
        tracer->debug("Session_id length error: $sess_l\n");
        $ctx->error(DECODE_ERROR);
        return undef;
    }

    # Ciphers error
    if ( !$ciphers_l || $ciphers_l % 2 ) {
        tracer->debug("Cipher suites length error\n");
        $ctx->error(DECODE_ERROR);
        return undef;
    }

    my $offset = 37 + $sess_l;

    my @ciphers = unpack 'x' . ( $buf_offset + $offset ) . 'n' . $ciphers_l / 2,
      $$buf_ref;

    $offset += $ciphers_l;

    my @compr = unpack 'x' . ( $buf_offset + $offset ) . 'C/C*', $$buf_ref;

    # Compression length error
    if ( !@compr ) {
        tracer->debug("Compression methods not defined\n");
        $ctx->error(DECODE_ERROR);
        return undef;
    }
    $offset += 1 + @compr;

    # Extensions
    my $ext_result;
    if ( $length > $offset ) {
        my $len = $ctx->ext_decode(
            \$ext_result, $buf_ref,
            $buf_offset + $offset,
            $length - $offset
        );
        return undef unless defined $len;
        $offset += $len;
    }

    # TODO: need sane result handling
    my $res = $ctx->validate_client_hello(
        ciphers     => \@ciphers,
        compression => \@compr,
        session_id  => $session_id,
        tls_version => $tls_version,
        random      => $random,
        extensions  => $ext_result,
    );

    return $res ? $offset : undef;
}

sub client_hello_encode {
    my ( $ctx, $data_ref ) = @_;

    my $ext = '';
    if ( exists $data_ref->{extensions} ) {

        # TODO extenions
    }

    pack(
        'na32 C/a* n'
          . ( @{ $data_ref->{ciphers} } + 1 ) . 'C'
          . ( @{ $data_ref->{compression} } + 1 ),
        $data_ref->{tls_version},
        $ctx->{pending}->{securityParameters}->{client_random},
        $data_ref->{session_id},
        2 * @{ $data_ref->{ciphers} },
        @{ $data_ref->{ciphers} },
        scalar @{ $data_ref->{compression} },
        @{ $data_ref->{compression} }
    ) . $ext;
}

sub server_hello_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    my ( $version, $rand, $sess_id, $cipher, $compr ) =
      unpack "x$buf_offset n a32 C/a n C", $$buf_ref;

    my $offset = 35 + length($sess_id) + 2 + 1;

    # Extensions
    my $ext_result;
    if ( $length > $offset ) {
        my $len = $ctx->ext_decode(
            \$ext_result, $buf_ref,
            $buf_offset + $offset,
            $length - $offset
        );
        return undef unless defined $len;
        $offset += $len;
    }

    # TODO: need sane result handling
    my $res = $ctx->validate_server_hello(
        cipher      => $cipher,
        compression => $compr,
        session_id  => $sess_id,
        version     => $version,
        random      => $rand,
        extensions  => $ext_result,
    );

    return $res ? $offset : undef;
}

sub server_hello_encode {
    my ( $ctx, $data_ref ) = @_;

    my $ext = '';
    if ( exists $data_ref->{extensions} ) {

        # TODO extenions
    }

    pack( "n a32 C/a* n C",
        $data_ref->{tls_version}, $data_ref->{server_random},
        $data_ref->{session_id},  $data_ref->{cipher},
        $data_ref->{compression} )
      . $ext;
}

sub certificate_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    my $list_len = unpack 'N', "\0" . substr $$buf_ref, $buf_offset, 3;
    my $offset = 3;

    if ( $list_len > $length - $offset ) {
        tracer->debug("list too long: $list_len\n");
        $ctx->error(DECODE_ERROR);
        return undef;
    }

    while ( $offset < $list_len ) {
        my $cert_len = unpack 'N', "\0" . substr $$buf_ref,
          $buf_offset + $offset, 3;
        if ( $cert_len > $length - $offset - 3 ) {
            tracer->debug("cert length too long: $cert_len\n");
            $ctx->error(DECODE_ERROR);
            return undef;
        }
        $ctx->{pending}->{cert} ||= [];
        push @{ $ctx->{pending}->{cert} }, substr $$buf_ref,
          $buf_offset + $offset + 3, $cert_len;
        $offset += 3 + $cert_len;
    }

    return $offset;
}

sub certificate_encode {
    my $ctx = shift;

    my $res = '';
    for my $cert (@_) {
        $res .= pack 'C n/a*', 0, $cert;
    }

    pack( 'Cn', 0, length($res) ) . $res;
}

sub server_key_exchange_decode {
    die "not implemented";
}

sub server_key_exchange_encode {
    die "not implemented";
}

sub certificate_request_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;

    # Client certificate types
    my @cct = unpack "x$buf_offset C/C*", $$buf_ref;

    my $offset = @cct + 1;

    # Signature and hash algorithms
    my @sah = unpack 'x' . ( $buf_offset + $offset ) . 'n/C*', $$buf_ref;

    $offset += @sah + 2;

    # DistinguishedName certificate_authorities
    my $dn_len = unpack 'x' . ( $buf_offset + $offset ) . 'n', $$buf_ref;
    $offset += 2;
    my @dn;

    while ( $offset < $length ) {
        my $dn = unpack 'x' . ( $buf_offset + $offset ) . 'n/a*', $$buf_ref;
        last unless $dn;
        $offset += 2 + length($dn);
        push @dn, $dn;
    }

    if ( $offset != $length ) {
        tracer->debug( "certificate request decoding error:"
              . "expected length $length != $offset" );
        $ctx->error(DECODE_ERROR);
        return undef;
    }

    $ctx->{pending}->{client_cert} = {
        cct => [@cct],
        sah => [@sah],
        dn  => [@dn],
    };

    $offset;
}

sub certificate_request_encode {
    die "not implemented";
}

sub server_hello_done_decode {
    0;
}

sub server_hello_done_encode {
    '';
}

sub certificate_verify_encode {
    pack 'C2n/a', $_[1], $_[2], $_[3];
}

sub certificate_verify_decode {
    die "not implemented";
}

sub client_key_exchange_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    my ($encoded_pkey) = unpack "x$buf_offset n/a", $$buf_ref;
    unless ( defined $encoded_pkey && length($encoded_pkey) == $length - 2 ) {
        tracer->error( "broken key length: "
              . ( $length - 2 ) . " vs "
              . ( length($encoded_pkey) || 0 )
              . "\n" );
        $ctx->error(DECODE_ERROR);
        return undef;
    }

    unless ( $ctx->validate_client_key($encoded_pkey) ) {
        tracer->error("client key validation failed");
        $ctx->error(DECODE_ERROR);
        return undef;
    }
    $length;
}

sub client_key_exchange_encode {
    pack 'n/a*', $_[1];
}

sub finished_encode {
    $_[1];
}

sub finished_decode {
    my ( $ctx, $buf_ref, $buf_offset, $length ) = @_;
    my $message = substr $$buf_ref, $buf_offset, $length;
    return $ctx->validate_finished($message) ? $length : undef;
}

1
