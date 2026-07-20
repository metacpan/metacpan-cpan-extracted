use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
class Net::BitTorrent::Protocol::MSE v2.1.0 : isa(Net::BitTorrent::Emitter) {
    use Net::BitTorrent::Protocol::MSE::KeyExchange;
    use Digest::SHA qw[sha1];
    #
    field $infohash          : param = undef;
    field $is_initiator      : param = 0;
    field $on_infohash_probe : param = undef;
    field $allow_plaintext   : param = 1;
    field $kx;
    field $state      : reader;
    field $buffer_in  : reader = '';
    field $buffer_out : reader = '';
    field $wait_len      = 0;
    field $crypto_select = 0;
    #
    my $VC                        = "\0" x 8;
    my $CRYPTO_PLAINTEXT          = 0x01;
    my $CRYPTO_RC4                = 0x02;
    my $MAX_HANDSHAKE_BUFFER_SIZE = 32 * 1024;    # 32KB

    #
    method supported () {1}
    ADJUST {
        $kx = Net::BitTorrent::Protocol::MSE::KeyExchange->new( infohash => $infohash, is_initiator => $is_initiator );
        if ($is_initiator) {
            $buffer_out .= $kx->public_key;
            $buffer_out .= $self->_random_pad();
            $state = 'A_WAIT_PUBKEY';
        }
        else {
            $state = 'B_WAIT_PUBKEY';
        }
    }

    method _random_pad () {
        use Crypt::URandom qw[urandom];
        my $len_bytes = urandom(2);
        my $len       = unpack( 'n', $len_bytes ) % 513;
        return urandom($len);
    }

    method write_buffer () {
        my $tmp = $buffer_out;
        $buffer_out = '';
        return $tmp;
    }

    method decrypt_data ($data) {
        return $self->receive_data($data);
    }

    method encrypt_data ($data) {
        return $data unless $state eq 'PAYLOAD';
        return $kx->encrypt_rc4->crypt($data);
    }

    method receive_data ($data) {
        if ( $state eq 'PAYLOAD' ) {
            return $kx->decrypt_rc4->crypt($data);
        }
        $buffer_in .= $data;
        if ( length($buffer_in) > $MAX_HANDSHAKE_BUFFER_SIZE ) {
            $state = 'FAILED';
            return undef;
        }
        my $continue = 1;
        while ( $continue && $state ne 'PAYLOAD' && $state ne 'FAILED' && $state ne 'PLAINTEXT_FALLBACK' ) {
            $continue = 0;
            if    ( $state eq 'A_WAIT_PUBKEY' )  { $continue = $self->_a_wait_pubkey() }
            elsif ( $state eq 'A_WAIT_VC' )      { $continue = $self->_a_wait_vc() }
            elsif ( $state eq 'A_WAIT_SELECT' )  { $continue = $self->_a_wait_select() }
            elsif ( $state eq 'A_WAIT_PADD' )    { $continue = $self->_a_wait_padd() }
            elsif ( $state eq 'B_WAIT_PUBKEY' )  { $continue = $self->_b_wait_pubkey() }
            elsif ( $state eq 'B_WAIT_REQS' )    { $continue = $self->_b_wait_reqs() }
            elsif ( $state eq 'B_WAIT_VC' )      { $continue = $self->_b_wait_vc() }
            elsif ( $state eq 'B_WAIT_PROVIDE' ) { $continue = $self->_b_wait_provide() }
            elsif ( $state eq 'B_WAIT_PADC' )    { $continue = $self->_b_wait_padc() }
            elsif ( $state eq 'B_WAIT_IA_LEN' )  { $continue = $self->_b_wait_ia_len() }
            elsif ( $state eq 'B_WAIT_IA' )      { $continue = $self->_b_wait_ia() }
        }
        if ( $state eq 'PAYLOAD' && length($buffer_in) > 0 ) {
            my $decrypted = $kx->decrypt_rc4->crypt($buffer_in);
            $buffer_in = '';
            return $decrypted;
        }
        return undef;
    }

    method _a_wait_pubkey () {
        if ( $allow_plaintext && length($buffer_in) >= 1 && ord( substr( $buffer_in, 0, 1 ) ) == 19 ) {
            $state = 'PLAINTEXT_FALLBACK';
            return 0;
        }
        return 0 if length($buffer_in) < 96;
        my $remote_pub = substr( $buffer_in, 0, 96, '' );
        $kx->compute_secret($remote_pub);
        my ( $req1, $xor_part ) = $kx->get_sync_data();
        $buffer_out .= $req1 . $xor_part;
        $kx->init_rc4($infohash);
        my $payload = $VC;
        $payload    .= pack( 'N', $CRYPTO_RC4 | $CRYPTO_PLAINTEXT );
        $payload    .= pack( 'n', 0 );
        $payload    .= pack( 'n', 0 );
        $buffer_out .= $kx->encrypt_rc4->crypt($payload);
        $state = 'A_WAIT_VC';
        return 1;
    }

    method _a_wait_vc () {
        return 0 if length($buffer_in) < 8;
        my $pad_len = $kx->scan_for_vc($buffer_in);
        if ( $pad_len >= 0 ) {
            substr( $buffer_in, 0, $pad_len, '' );
            my $vc_enc = substr( $buffer_in, 0, 8, '' );
            $kx->decrypt_rc4->crypt($vc_enc);
            $state = 'A_WAIT_SELECT';
            return 1;
        }
        if ( length($buffer_in) > 600 ) {
            $state = 'FAILED';
        }
        return 0;
    }

    method _a_wait_select () {
        return 0 if length($buffer_in) < 6;
        my $dec     = $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, 6, '' ) );
        my $select  = unpack( 'N', substr( $dec, 0, 4 ) );
        my $pad_len = unpack( 'n', substr( $dec, 4, 2 ) );
        if ( !( $select & $CRYPTO_RC4 ) ) {
            $state = 'FAILED';
            return 0;
        }
        $wait_len = $pad_len;
        $state    = 'A_WAIT_PADD';
        return 1;
    }

    method _a_wait_padd () {
        return 0 if length($buffer_in) < $wait_len;
        if ( $wait_len > 0 ) {
            $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, $wait_len, '' ) );
        }
        $self->_emit( 'infohash_identified', $infohash );
        $state = 'PAYLOAD';
        return 0;
    }

    method _b_wait_pubkey () {
        return 0 if length($buffer_in) < 96;
        my $pub_a = substr( $buffer_in, 0, 96, '' );
        $kx->compute_secret($pub_a);
        $buffer_out .= $kx->public_key;
        $buffer_out .= $self->_random_pad();
        $state = 'B_WAIT_REQS';
        return 1;
    }

    method _b_wait_reqs () {
        my $s         = $kx->get_secret;
        my $req1_hash = sha1( 'req1' . $s );
        my $idx       = index( $buffer_in, $req1_hash );
        if ( $idx == -1 ) {
            if ( length($buffer_in) > 600 ) { $state = 'FAILED'; }
            return 0;
        }
        substr( $buffer_in, 0, $idx + 20, '' );
        if ( length($buffer_in) < 20 ) { return 0; }
        my $xor_block = substr( $buffer_in, 0, 20, '' );
        if ( defined $infohash ) {
            if ( !$kx->verify_skey( $xor_block, $infohash ) ) {
                $state = 'FAILED';
                return 0;
            }
        }
        elsif ($on_infohash_probe) {
            my $req3_hash = sha1( 'req3' . $s );

            # FIX: Use ^. for string XOR
            my $target = $xor_block^.$req3_hash;
            $infohash = $on_infohash_probe->( $self, $target );
            if ( !$infohash ) {
                $state = 'FAILED';
                return 0;
            }
        }
        else {
            $state = 'FAILED';
            return 0;
        }
        $kx->init_rc4($infohash);
        $self->_emit( 'infohash_identified', $infohash );
        $state = 'B_WAIT_VC';
        return 1;
    }

    method _b_wait_vc () {
        return 0 if length($buffer_in) < 8;
        my $vc_check = $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, 8, '' ) );
        my $ok       = 0;
        for my $i ( 0 .. 7 ) {
            $ok |= ord( substr( $vc_check, $i, 1 ) ) ^ ord( substr( $VC, $i, 1 ) );
        }
        if ( $ok != 0 ) {
            $state = 'FAILED';
            return 0;
        }
        $state = 'B_WAIT_PROVIDE';
        return 1;
    }

    method _b_wait_provide () {
        return 0 if length($buffer_in) < 6;
        my $dec     = $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, 6, '' ) );
        my $provide = unpack( 'N', substr( $dec, 0, 4 ) );
        my $len     = unpack( 'n', substr( $dec, 4, 2 ) );
        unless ( $provide & $CRYPTO_RC4 ) {
            $state = 'FAILED';
            return 0;
        }
        $wait_len = $len;
        $state    = 'B_WAIT_PADC';
        return 1;
    }

    method _b_wait_padc () {
        return 0 if length($buffer_in) < $wait_len;
        if ( $wait_len > 0 ) {
            $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, $wait_len, '' ) );
        }
        $state = 'B_WAIT_IA_LEN';
        return 1;
    }

    method _b_wait_ia_len () {
        return 0 if length($buffer_in) < 2;
        my $dec = $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, 2, '' ) );
        $wait_len = unpack( 'n', $dec );
        $state    = 'B_WAIT_IA';
        return 1;
    }

    method _b_wait_ia () {
        return 0 if length($buffer_in) < $wait_len;
        if ( $wait_len > 0 ) {
            $kx->decrypt_rc4->crypt( substr( $buffer_in, 0, $wait_len, '' ) );
        }
        my $res = $VC;
        $res .= pack( 'N', $CRYPTO_RC4 );
        $res .= pack( 'n', 0 );
        $buffer_out .= $kx->encrypt_rc4->crypt($res);
        $state = 'PAYLOAD';
        return 0;
    }
};
1;
