package Net::SSH::Perl::Cipher::DES3;

use strict;
use warnings;

use Net::SSH::Perl::Cipher;
use base qw( Net::SSH::Perl::Cipher );

use Net::SSH::Perl::Cipher::CBC;
use Crypt::Cipher::DES;

sub new {
    my $class = shift;
    my $ciph = bless { }, $class;
    $ciph->init(@_) if @_;
    $ciph;
}

sub keysize { 24 }
sub blocksize { 8 }

sub init {
    my $ciph = shift;
    my($key, $iv, $is_ssh2) = @_;
    $ciph->{is_ssh2} = defined $is_ssh2 ? $is_ssh2 : 0;

    if ($is_ssh2) {
        my $ede3 = Net::SSH::Perl::Cipher::DES3::EDE3->new($key);
        $ciph->{cbc} = Net::SSH::Perl::Cipher::CBC->new($ede3,
            substr($iv, 0, 8));
    }
    else {
        for my $i (1..3) {
            my $this_key = $i == 3 && length($key) <= 16 ?
                substr $key, 0, 8 :
                substr $key, 8*($i-1), 8;
            $ciph->{"cbc$i"} = Net::SSH::Perl::Cipher::CBC->new(
                Crypt::Cipher::DES->new($this_key)
            );
        }
    }
}

sub encrypt {
    my($ciph, $text) = @_;
    if ($ciph->{is_ssh2}) {
        return $ciph->{cbc}->encrypt($text);
    }
    else {
        return $ciph->{cbc3}->encrypt(
            $ciph->{cbc2}->decrypt(
                $ciph->{cbc1}->encrypt($text)
            )
        );
    }
}

sub decrypt {
    my($ciph, $text) = @_;
    if ($ciph->{is_ssh2}) {
        return $ciph->{cbc}->decrypt($text);
    }
    else {
        return $ciph->{cbc1}->decrypt(
            $ciph->{cbc2}->encrypt(
                $ciph->{cbc3}->decrypt($text)
            )
        );
    }
}

package Net::SSH::Perl::Cipher::DES3::EDE3;
use strict;

sub new {
    my $class = shift;
    my $ede3 = bless {}, $class;
    $ede3->init(@_) if @_;
    $ede3;
}

sub keysize { 24 }
sub blocksize { 8 }

sub init {
    my $ede3 = shift;
    my($key) = @_;
    for my $i (1..3) {
        my $k = substr $key, 8*($i-1), 8;
        $ede3->{"des$i"} = Crypt::Cipher::DES->new($k);
    }
}

sub encrypt {
    my($ede3, $block) = @_;
    $ede3->{des3}->encrypt(
        $ede3->{des2}->decrypt(
            $ede3->{des1}->encrypt($block)
        )
    );
}

sub decrypt {
    my($ede3, $block) = @_;
    $ede3->{des1}->decrypt(
        $ede3->{des2}->encrypt(
            $ede3->{des3}->decrypt($block)
        )
    );
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::DES3 - Wrapper for SSH 3DES support

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('DES3', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::DES3> provides 3DES encryption
support for I<Net::SSH::Perl>. To do so it wraps around
I<Crypt::Cipher::DES>, the CryptX implementation of the DES
algorithm.

The 3DES (three-key triple-DES) algorithm used here differs
based on the SSH protocol being used. SSH1 uses 3DES in
inner CBC mode, meaning that there are three CBC objects,
and each CBC object is paired with a DES object and key.

SSH2 uses 3DES in outer CBC mode; this uses one CBC object
wrapped around a DES-EDE3 object (also included in this
library); that object contains three DES ciphers with three
different keys. Each encrypt operation is actually
encrypt-decrypt-encrypt with the three DES keys; decrypt
is actually decrypt-encrypt-decrypt with the DES keys.

The key length for both implementations is 24 bytes.
The first 8 bytes of the key are used as the first DES
key, the second 8 bytes for the second key, etc. If the
key I<$key> that you pass to I<new> is only 16 bytes, the
first 8 bytes of I<$key> will be used as the key for both
the first and third DES ciphers.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
