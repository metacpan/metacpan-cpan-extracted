package Palm::Zetetic::Strip::CryptV10;

use strict;
use Carp;
use Digest::SHA256;
use Crypt::Rijndael;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Palm::Raw);
$VERSION = "1.02";

sub new
{
    my $class = shift;
    my ($plaintext_key) = @_;
    my $hashed_key;
    my $self = {};

    bless $self, $class;
    $hashed_key = $self->hash($plaintext_key);

    $self->{hashed_key} = $hashed_key;
    $self->{cipher} = new Crypt::Rijndael($hashed_key);
    return $self;
}

sub get_hashed_key
{
    my ($self) = @_;
    return $self->{hashed_key};
}

sub encrypt
{
    confess("Not yet implemented");
}


# Use Cipher Block Chaining (CBC) to decrypt

sub decrypt
{
    my ($self, $ciphertext) = @_;
    my $feedback;
    my $encrypted_block;
    my $decrypted_block;
    my $plaintext;
    my $cipher;

    $cipher = $self->{cipher};
    # Initialize feedback from first block
    $feedback = substr($ciphertext, 0, 16, "");

    $plaintext = "";
    while(1)
    {
        $encrypted_block = substr($ciphertext, 0, 16, "");
        last if ($encrypted_block eq "");
        $decrypted_block = $cipher->decrypt($encrypted_block);
        $decrypted_block = $decrypted_block ^ $feedback;
        $plaintext .= $decrypted_block;
        $feedback = $encrypted_block;
    }

    return $plaintext;
}

sub hash
{
    my ($self, $string) = @_;
    my $hash;

    if ($Digest::SHA256::VERSION == "0.01")
    {
        my $digest;

        $digest = Digest::SHA256::new();
        $hash = $digest->hash($string);

        # For some reason SHA256 returns 512 bits. Truncate to
        # 256 bits.  The last 256 bits appear to be garbage.
        $hash = substr($hash, 0, 32);
    }

    return $hash;
}


1;
