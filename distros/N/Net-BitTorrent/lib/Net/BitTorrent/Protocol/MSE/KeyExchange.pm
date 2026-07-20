use v5.40;
use feature 'class';
no warnings qw[experimental::class experimental::builtin];
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Protocol::MSE::KeyExchange v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use Digest::SHA qw[sha1];
    use Crypt::URandom qw[urandom];
    use Math::BigInt try => 'GMP';

    # Parameters
    field $infohash     : param : reader;
    field $is_initiator : param : reader;

    # Internal state
    field $private_key;
    field $public_key : reader;
    field $shared_secret;

    # Cipher state
    field $encrypt_rc4 : reader;
    field $decrypt_rc4 : reader;

    # Store the initial state (post-discard) for the decryptor
    # to optimize the scan_for_vc loop.
    field $decrypt_restore_point;

    # 768-bit Safe Prime (Big Endian)
    my $P_STR
        = 'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74' .
        '020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F1437' .
        '4FE1356D6D51C245E485B576625E7EC6F44C42E9A63A36210000000000090563';
    ADJUST {
        my $p = Math::BigInt->from_hex($P_STR);
        my $g = Math::BigInt->new(2);

        # Private Key: Random 160 bits
        $private_key = Math::BigInt->from_bytes( urandom(20) );

        # Public Key: Y = G^X mod P
        my $pub_val = $g->copy->bmodpow( $private_key, $p );
        $public_key = $self->_int_to_bytes($pub_val);
    }

    method _int_to_bytes ($num) {
        my $hex = $num->to_hex;
        $hex =~ s/^0x//i;
        $hex = "0$hex" if length($hex) % 2;
        my $bin = pack( 'H*', $hex );
        if ( length($bin) < 96 ) {
            $bin = ( "\0" x ( 96 - length($bin) ) ) . $bin;
        }
        elsif ( length($bin) > 96 ) {
            $bin = substr( $bin, -96 );
        }
        return $bin;
    }

    method compute_secret ($remote_pub_bytes) {
        if ( length($remote_pub_bytes) != 96 ) {
            $self->_emit_log( 'fatal', 'Remote public key must be 96 bytes' );
            return undef;
        }
        my $p          = Math::BigInt->from_hex($P_STR);
        my $remote_val = Math::BigInt->from_bytes($remote_pub_bytes);

        # Reject degenerate keys that defeat forward secrecy (RFC 2631 / FIPS 186-4)
        my $two       = Math::BigInt->new(2);
        my $p_minus_2 = $p->copy->bsub($two);
        if ( $remote_val < $two || $remote_val > $p_minus_2 ) {
            $self->_emit_log( 'fatal', 'Remote public key out of valid range [2, P-2]' );
            return undef;
        }

        # S = Y_remote ^ X_local mod P
        my $s_val = $remote_val->copy->bmodpow( $private_key, $p );
        $shared_secret = $self->_int_to_bytes($s_val);
        return $shared_secret;
    }
    method get_secret () { return $shared_secret }

    method get_sync_data ( $override_ih = undef ) {
        my $ih = $override_ih // $infohash;
        return undef unless $ih;
        my $s         = $shared_secret;
        my $sk        = $ih;
        my $req1_hash = sha1( 'req1' . $s );
        my $req2_hash = sha1( 'req2' . $sk );
        my $req3_hash = sha1( 'req3' . $s );
        my $xor_mask  = $req2_hash^.$req3_hash;
        return ( $req1_hash, $xor_mask );
    }

    method verify_skey ( $xor_block, $candidate_ih ) {
        my $s           = $shared_secret;
        my $req3_hash   = sha1( 'req3' . $s );
        my $target_req2 = $xor_block^.$req3_hash;
        my $check       = sha1( 'req2' . $candidate_ih );
        #
        my $ok = 0;
        for my $i ( 0 .. 19 ) {
            $ok |= ord( substr( $check, $i, 1 ) ) ^ ord( substr( $target_req2, $i, 1 ) );
        }
        return $ok == 0;
    }

    method init_rc4 ($ih) {
        $infohash = $ih;
        my $keyA = sha1( 'keyA' . $shared_secret . $infohash );
        my $keyB = sha1( 'keyB' . $shared_secret . $infohash );
        my ( $key_enc, $key_dec );
        if ($is_initiator) {
            $key_enc = $keyA;
            $key_dec = $keyB;
        }
        else {
            $key_enc = $keyB;
            $key_dec = $keyA;
        }

        # Initialize Encryptor
        $encrypt_rc4 = Net::BitTorrent::Protocol::MSE::RC4->new( key => $key_enc );
        $encrypt_rc4->discard(1024);

        # Initialize Decryptor
        $decrypt_rc4 = Net::BitTorrent::Protocol::MSE::RC4->new( key => $key_dec );
        $decrypt_rc4->discard(1024);

        # Save state for efficient scanning
        $decrypt_restore_point = $decrypt_rc4->snapshot();
    }

    method scan_for_vc ($buffer) {
        my $limit = length($buffer) - 8;
        $limit = 512 if $limit > 512;

        # Use a temporary RC4 instance to avoid messing up the main decryptor
        # during the brute force attempts.
        my $trial_rc4 = Net::BitTorrent::Protocol::MSE::RC4->new( key => 'dummy' );
        for my $offset ( 0 .. $limit ) {

            # Restore state to the "post-discard" point instantly (no math involved)
            $trial_rc4->restore($decrypt_restore_point);
            my $ciphertext = substr( $buffer, $offset, 8 );
            my $plaintext  = $trial_rc4->crypt($ciphertext);
            if ( $plaintext eq "\0\0\0\0\0\0\0\0" ) {

                # Found it! We need to ensure the MAIN decryptor is now
                # advanced by these 8 bytes so subsequent calls work.
                # However, the padding (0..$offset) is plaintext garbage.
                # We skip the padding, then decrypt the VC to sync state.
                # Note: The caller handles substr($buffer, ...) logic.
                # We just return the offset found.
                # The caller MUST call $decrypt_rc4->crypt($vc_bytes)
                # to sync the main object.
                return $offset;
            }
        }
        return -1;
    }
    }

    # Pure Perl RC4 Implementation
    class Net::BitTorrent::Protocol::MSE::RC4 v2.0.0 : isa(Net::BitTorrent::Emitter) {
    field @S;
    field $x = 0;
    field $y = 0;
    field $key : param;
    ADJUST {
        # KSA (Key Scheduling Algorithm)
        @S = 0 .. 255;
        my $len = length($key);
        my @k   = unpack( 'C*', $key );
        my $j   = 0;
        for my $i ( 0 .. 255 ) {
            $j = ( $j + $S[$i] + $k[ $i % $len ] ) & 0xFF;
            @S[ $i, $j ] = @S[ $j, $i ];
        }
    }

    method discard ($bytes) {

        # Discard loop (PRGA without output)
        for ( 1 .. $bytes ) {
            $x = ( $x + 1 ) & 0xFF;
            $y = ( $y + $S[$x] ) & 0xFF;
            @S[ $x, $y ] = @S[ $y, $x ];
        }
    }

    method crypt ($data) {
        my $out = '';

        # Use split for simple iteration over bytes
        for my $c ( split //, $data ) {
            $x = ( $x + 1 ) & 0xFF;
            $y = ( $y + $S[$x] ) & 0xFF;
            @S[ $x, $y ] = @S[ $y, $x ];

            # String XOR (^.) available in 5.40
            $out .= $c^. chr( $S[ ( $S[$x] + $S[$y] ) & 0xFF ] );
        }
        return $out;
    }

    # Create a lightweight state snapshot (Array ref + 2 ints)
    method snapshot () {
        return [ [@S], $x, $y ];
    }

    # Restore state from snapshot
    method restore ($snap) {
        @S = $snap->[0]->@*;
        $x = $snap->[1];
        $y = $snap->[2];
    }
    } 1;
