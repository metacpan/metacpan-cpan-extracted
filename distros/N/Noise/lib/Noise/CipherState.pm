use v5.42.0;
use feature 'class';
no warnings 'experimental::class';
#
class Noise::CipherState v0.0.1 {
    use Crypt::AuthEnc::ChaCha20Poly1305;
    use Crypt::AuthEnc::GCM;
    #
    field $k : reader;
    field $n : reader : writer(set_nonce) = 0;
    field $cipher : param //= 'ChaChaPoly';    # 'ChaChaPoly' or 'AESGCM'

    method set_key ($key) {
        $k = $key;
        $n = 0;
    }
    method has_key () { return defined $k; }

    method encrypt_with_ad ( $ad, $plaintext ) {
        return $plaintext unless defined $k;
        my $nonce;
        if ( $cipher eq 'ChaChaPoly' ) {

            # Noise: 32bit zeros + 64bit Little Endian counter
            $nonce = pack( 'L<', 0 ) . pack( 'Q<', $n++ );
            say "[DEBUG] Cipher encrypt: cipher=$cipher, k=" .
                unpack( 'H*', $k ) .
                ", nonce=" .
                unpack( 'H*', $nonce ) . ", ad=" .
                unpack( 'H*', $ad )
                if $ENV{NOISE_DEBUG};
            my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new( $k, $nonce );
            $ae->adata_add($ad);
            return $ae->encrypt_add($plaintext) . $ae->encrypt_done();
        }
        elsif ( $cipher eq 'AESGCM' ) {

            # Noise: 32bit zeros + 64bit Big Endian counter
            $nonce = pack( 'L>', 0 ) . pack( 'Q>', $n++ );
            say "[DEBUG] Cipher encrypt: cipher=$cipher, k=" .
                unpack( 'H*', $k ) .
                ", nonce=" .
                unpack( 'H*', $nonce ) . ', ad=' .
                unpack( 'H*', $ad )
                if $ENV{NOISE_DEBUG};
            my $ae = Crypt::AuthEnc::GCM->new( 'AES', $k, $nonce );
            $ae->adata_add($ad);
            return $ae->encrypt_add($plaintext) . $ae->encrypt_done();
        }
        else {
            die 'Unknown cipher: ' . $cipher;
        }
    }

    method decrypt_with_ad ( $ad, $ciphertext ) {
        return $ciphertext unless defined $k;
        my $nonce;
        if ( $cipher eq 'ChaChaPoly' ) {
            my $tag = substr( $ciphertext, -16 );
            my $ct  = substr( $ciphertext, 0, -16 );
            $nonce = pack( 'L<', 0 ) . pack( 'Q<', $n++ );
            say "[DEBUG] Cipher decrypt: cipher=$cipher, k=" .
                unpack( 'H*', $k ) .
                ", nonce=" .
                unpack( 'H*', $nonce ) . ', ad=' .
                unpack( 'H*', $ad )
                if $ENV{NOISE_DEBUG};
            my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new( $k, $nonce );
            $ae->adata_add($ad);
            my $plaintext = $ae->decrypt_add($ct);
            return $plaintext if $ae->decrypt_done($tag);
            die 'CipherState: Decryption failed';
        }
        elsif ( $cipher eq 'AESGCM' ) {
            my $tag = substr( $ciphertext, -16 );
            my $ct  = substr( $ciphertext, 0, -16 );
            $nonce = pack( 'L>', 0 ) . pack( 'Q>', $n++ );
            say "[DEBUG] Cipher decrypt: cipher=$cipher, k=" .
                unpack( 'H*', $k ) .
                ", nonce=" .
                unpack( 'H*', $nonce ) . ', ad=' .
                unpack( 'H*', $ad )
                if $ENV{NOISE_DEBUG};
            my $ae = Crypt::AuthEnc::GCM->new( 'AES', $k, $nonce );
            $ae->adata_add($ad);
            my $plaintext = $ae->decrypt_add($ct);
            return $plaintext if $ae->decrypt_done($tag);
            die 'CipherState: Decryption failed';
        }
        else {
            die 'Unknown cipher: ' . $cipher;
        }
    }

    method rekey () {
        my $nonce;
        if ( $cipher eq 'ChaChaPoly' ) {
            $nonce = pack( 'L<', 0 ) . pack( 'Q<', ~0 );
            my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new( $k, $nonce );
            $ae->adata_add('');
            my $new_k = $ae->encrypt_add( "\0" x 32 ) . $ae->encrypt_done();
            $k = substr( $new_k, 0, 32 );
        }
        elsif ( $cipher eq 'AESGCM' ) {
            $nonce = pack( 'L>', 0 ) . pack( 'Q>', ~0 );
            my $ae = Crypt::AuthEnc::GCM->new( 'AES', $k, $nonce );
            $ae->adata_add('');
            my $new_k = $ae->encrypt_add( "\0" x 32 ) . $ae->encrypt_done();
            $k = substr( $new_k, 0, 32 );
        }
    }
};
#
1;
