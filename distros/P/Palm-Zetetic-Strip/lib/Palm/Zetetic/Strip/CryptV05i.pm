package Palm::Zetetic::Strip::CryptV05i;

use strict;
use Digest::MD5 qw(md5);
use Crypt::IDEA;

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
    $self->{cipher} = new IDEA($hashed_key);
    return $self;
}

sub get_hashed_key
{
    my ($self) = @_;
    return $self->{hashed_key};
}

sub encrypt
{
    my ($self, $plain_text) = @_;
    my $block;
    my $cipher_text;
    my $cipher;

    $cipher = $self->{cipher};
    $cipher_text = "";

    while(1)
    {
        $block = substr($plain_text, 0, 8, "");
        last if $block eq "";

        $cipher_text .= $cipher->encrypt($block);
    }

    return $cipher_text;
}


sub decrypt
{
    my ($self, $cipher_text) = @_;
    my $block;
    my $plain_text;
    my $cipher;

    $cipher = $self->{cipher};
    $plain_text = "";

    while(1)
    {
        $block = substr($cipher_text, 0, 8, "");
        last if $block eq "";

        $plain_text .= $cipher->decrypt($block);
    }

    return $plain_text;
}

sub hash
{
    my ($self, $string) = @_;
    return md5($string);
}


1;
