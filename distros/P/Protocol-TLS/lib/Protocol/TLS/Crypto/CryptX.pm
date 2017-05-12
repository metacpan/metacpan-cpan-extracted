package Protocol::TLS::Crypto::CryptX;
use strict;
use warnings;
use Crypt::PK::RSA;
use Crypt::Mac::HMAC qw(hmac);
use Crypt::Digest::SHA256 qw(sha256);
use Crypt::PRNG qw(random_bytes);
use Crypt::Mode::CBC;
use Crypt::X509;

sub new {
    bless {}, shift;
}

sub PRF {
    my ( $self, $secret, $label, $seed, $len ) = @_;

    $seed = $label . $seed;

    my $data = '';
    my $a    = $seed;
    while ( length($data) < $len ) {
        $a = hmac( 'SHA256', $secret, $a );
        $data .= hmac( 'SHA256', $secret, $a . $seed );
    }
    substr $data, 0, $len;
}

sub PRF_hash {
    sha256( $_[1] );
}

sub MAC {
    my ( $self, $type ) = splice @_, 0, 2;
    hmac( $type eq 'SHA' ? 'SHA1' : $type, @_ );
}

sub CBC_encode {
    my ( $self, $type, $key, $iv, $plaintext ) = @_;
    $type =
        $type =~ /AES/ ? 'AES'
      : $type =~ /DES/ ? 'DES_EDE'
      :                  die "unsupported CBC cipher $type\n";
    my $m = Crypt::Mode::CBC->new( $type, 0 );
    $m->encrypt( $plaintext, $key, $iv );
}

sub CBC_decode {
    my ( $self, $type, $key, $iv, $ciphertext ) = @_;
    $type =
        $type =~ /AES/ ? 'AES'
      : $type =~ /DES/ ? 'DES_EDE'
      :                  die "unsupported CBC cipher $type\n";
    my $m = Crypt::Mode::CBC->new( $type, 0 );
    $m->decrypt( $ciphertext, $key, $iv );
}

sub random {
    random_bytes( $_[1] );
}

sub rsa_encrypt {
    my ( $self, $der, $message ) = @_;
    my $pub = Crypt::PK::RSA->new( \$der );
    $pub->encrypt( $message, 'v1.5' );
}

sub rsa_decrypt {
    my ( $self, $der, $message ) = @_;
    my $priv = Crypt::PK::RSA->new( \$der );
    $priv->decrypt( $message, 'v1.5' );
}

sub rsa_sign {
    my ( $self, $der, $hash, $message ) = @_;
    my $priv = Crypt::PK::RSA->new( \$der );
    $priv->sign_message( $message, $hash, 'v1.5' );
}

sub cert_pubkey {
    my $cert = Crypt::X509->new( cert => $_[1] );
    $cert ? $cert->pubkey : undef;
}

sub cert_pubkeyalg {
    my $cert = Crypt::X509->new( cert => $_[1] );
    $cert ? $cert->PubKeyAlg : undef;
}

1
