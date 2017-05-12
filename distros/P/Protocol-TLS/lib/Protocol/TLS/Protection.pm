package Protocol::TLS::Protection;
use strict;
use warnings;
use Protocol::TLS::Constants qw(:end_types :alert_desc const_name);
use Protocol::TLS::Trace qw(tracer bin2hex);

sub decode {
    my ( $ctx, $type, $version, $buf_ref, $buf_offset, $length ) = @_;
    my $sp = $ctx->{current_decode}->{securityParameters};
    my $kb = $ctx->{current_decode}->{key_block};

    my $crypto = $ctx->crypto;
    my $res;

    my ( $mkey, $ckey, $iv ) =
      !defined $sp                     ? ()
      : $sp->{connectionEnd} == SERVER ? (
        $kb->{client_write_MAC_key},
        $kb->{client_write_encryption_key},
        $kb->{client_write_IV}
      )
      : (
        $kb->{server_write_MAC_key},
        $kb->{server_write_encryption_key},
        $kb->{server_write_IV}
      );

    if ( defined $ckey && length $ckey ) {
        if ( $length < $sp->{fixed_iv_length} + $sp->{block_length} ) {
            tracer->debug("too short ciphertext: $length\n");
            return undef;
        }
        my $iv = substr $$buf_ref, $buf_offset, $sp->{fixed_iv_length};
        $res = $crypto->CBC_decode(
            $sp->{BulkCipherAlgorithm},
            $ckey, $iv,
            substr $$buf_ref,
            $buf_offset + $sp->{fixed_iv_length},
            $length - $sp->{fixed_iv_length}
        );
        my $pad_len = unpack 'C', substr $res, -1, 1;
        if ( $pad_len >= $length + 1 + $sp->{mac_length} ) {
            tracer->error("Padding length $pad_len too long");
            return undef;
        }

        # TODO: check padding
        my $pad = substr $res, -$pad_len - 1, $pad_len + 1, '';
    }

    if ( defined $mkey && length $mkey ) {
        unless ( defined $res ) {
            $res = substr $$buf_ref, $buf_offset, $length;
        }

        my $mac = substr $res, -$sp->{mac_length}, $sp->{mac_length}, '';

        my $seq      = $ctx->{seq_read}++;
        my $mac_orig = $crypto->MAC(
            $sp->{MACAlgorithm}, $mkey,

            # TODO: seq may overflow int32
            pack( 'N2Cn2', 0, $seq, $type, $version, length $res ) . $res
        );
        if ( $mac ne $mac_orig ) {
            tracer->error("error in comparing MAC\n");
            tracer->debug( const_name( "c_types", $type )
                  . " <- type of broken packet.\nLength: $length\n"
                  . "mkey: "
                  . bin2hex($mkey) . "\n" . "mac: "
                  . bin2hex($mac) . "\n"
                  . "mac_orig: "
                  . bin2hex($mac_orig)
                  . "\n" );
            $ctx->error(BAD_RECORD_MAC);
            return undef;
        }
    }

    $res ? $res : substr $$buf_ref, $buf_offset, $length;
}

sub encode {
    my ( $ctx, $version, $type, $payload ) = @_;
    my $sp     = $ctx->{current_encode}->{securityParameters};
    my $kb     = $ctx->{current_encode}->{key_block};
    my $crypto = $ctx->crypto;

    my ( $mkey, $ckey, $iv ) =
      !defined $sp                     ? ()
      : $sp->{connectionEnd} == CLIENT ? (
        $kb->{client_write_MAC_key},
        $kb->{client_write_encryption_key},
        $kb->{client_write_IV}
      )
      : (
        $kb->{server_write_MAC_key},
        $kb->{server_write_encryption_key},
        $kb->{server_write_IV}
      );

    my ( $mac, $res ) = ('') x 2;

    if ( defined $mkey && length $mkey ) {
        my $seq = $ctx->{seq_write}++;
        $mac = $crypto->MAC( $sp->{MACAlgorithm}, $mkey,
            pack( 'N2Cn2', 0, $seq, $type, $version, length $payload )
              . $payload );
    }

    if ( defined $ckey && length $ckey ) {
        if ( $sp->{CipherType} eq 'block' ) {
            my $pad_len =
              $sp->{block_length} -
              ( ( length($payload) + length($mac) + 1 ) % $sp->{block_length} );
            my $iv = $crypto->random( $sp->{fixed_iv_length} );
            $res = $iv
              . $crypto->CBC_encode( $sp->{BulkCipherAlgorithm},
                $ckey, $iv,
                $payload . $mac . pack( 'C', $pad_len ) x ( $pad_len + 1 ) );
        }
        else {
            die "Cipher type $sp->{CipherType} not implemented";
        }
    }

    $res ? $res : $payload . $mac;
}

1
