use v5.42.0;
use feature 'class';
no warnings 'experimental::class';
#
class Noise::SymmetricState v0.0.1 {
    use Noise::CipherState;
    use Digest::SHA qw(sha256 sha512);
    use Crypt::Digest::BLAKE2b_512;
    use Crypt::Digest::BLAKE2s_256;
    use Crypt::Mac::HMAC qw[hmac];
    #
    field $h            : reader;
    field $ck           : reader;
    field $hash         : param //= 'SHA256';
    field $cipher       : param;
    field $cipher_state : reader = Noise::CipherState->new( cipher => $cipher );
    #
    method initialize_symmetric ($proto_name) {
        my $hash_len = $self->_hash_len();
        if ( length($proto_name) <= $hash_len ) {
            $h = $proto_name . ( "\0" x ( $hash_len - length($proto_name) ) );
        }
        else {
            $h = $self->_hash($proto_name);
        }
        $ck = $h;
        $cipher_state->set_key(undef);
    }

    method mix_key ($ikm) {
        my ( $next_ck, $temp_k ) = $self->_hkdf( $ck, $ikm );
        $ck = $next_ck;
        $cipher_state->set_key( substr( $temp_k, 0, 32 ) );
    }
    method mix_hash ($data) { $h = $self->_hash( $h . $data ) }

    method mix_key_and_hash ($ikm) {
        my ( $next_ck, $temp_h, $temp_k ) = $self->_hkdf_3( $ck, $ikm );
        $ck = $next_ck;
        $self->mix_hash($temp_h);
        $cipher_state->set_key( substr( $temp_k, 0, 32 ) );
    }

    method encrypt_and_hash ($plaintext) {
        my $ciphertext = $cipher_state->encrypt_with_ad( $h, $plaintext );
        $self->mix_hash($ciphertext);
        return $ciphertext;
    }

    method decrypt_and_hash ($ciphertext) {
        my $plaintext = $cipher_state->decrypt_with_ad( $h, $ciphertext );
        $self->mix_hash($ciphertext);
        return $plaintext;
    }

    method split () {
        my ( $out1, $out2 ) = $self->_hkdf( $ck, '' );
        my $c1 = Noise::CipherState->new( cipher => $cipher );
        $c1->set_key( substr( $out1, 0, 32 ) );
        my $c2 = Noise::CipherState->new( cipher => $cipher );
        $c2->set_key( substr( $out2, 0, 32 ) );
        return ( $c1, $c2 );
    }

    method _hash_len () {
        return 64 if $hash eq 'SHA512' || $hash eq 'BLAKE2b';
        return 32 if $hash eq 'SHA256' || $hash eq 'BLAKE2s';
        die 'Unknown hash: ' . $hash;
    }

    method _hash ($data) {
        return sha256($data)                                  if $hash eq 'SHA256';
        return sha512($data)                                  if $hash eq 'SHA512';
        return Crypt::Digest::BLAKE2s_256::blake2s_256($data) if $hash eq 'BLAKE2s';
        return Crypt::Digest::BLAKE2b_512::blake2b_512($data) if $hash eq 'BLAKE2b';
        die 'Unknown hash: ' . $hash;
    }

    method _hmac ( $key, $data ) {
        my $h_name = $hash;
        $h_name = 'BLAKE2s_256' if $hash eq 'BLAKE2s';
        $h_name = 'BLAKE2b_512' if $hash eq 'BLAKE2b';
        hmac( $h_name, $key, $data );
    }

    method _hkdf ( $salt, $ikm ) {
        my $prk  = $self->_hmac( $salt, $ikm );
        my $out1 = $self->_hmac( $prk,  "\x01" );
        my $out2 = $self->_hmac( $prk,  $out1 . "\x02" );
        return ( $out1, $out2 );
    }

    method _hkdf_3 ( $salt, $ikm ) {
        my $prk  = $self->_hmac( $salt, $ikm );
        my $out1 = $self->_hmac( $prk,  "\x01" );
        my $out2 = $self->_hmac( $prk,  $out1 . "\x02" );
        my $out3 = $self->_hmac( $prk,  $out2 . "\x03" );
        return ( $out1, $out2, $out3 );
    }
};
#
1;
