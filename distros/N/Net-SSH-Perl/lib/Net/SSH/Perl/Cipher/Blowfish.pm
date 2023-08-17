package Net::SSH::Perl::Cipher::Blowfish;

use strict;
use warnings;

use Net::SSH::Perl::Cipher;
use base qw( Net::SSH::Perl::Cipher );

use Crypt::Cipher::Blowfish;
use Net::SSH::Perl::Cipher::CBC;

sub new {
    my $class = shift;
    my $ciph = bless { }, $class;
    $ciph->init(@_) if @_;
    $ciph;
}

sub keysize { 16 }
sub blocksize { 8 }

sub init {
    my $ciph = shift;
    my($key, $iv, $is_ssh2) = @_;
    $key = substr($key, 0, 16);
    my $blow = Crypt::Cipher::Blowfish->new($key);
    $ciph->{cbc} = Net::SSH::Perl::Cipher::CBC->new($blow,
        $iv ? substr($iv, 0, 8) : undef);
    $ciph->{is_ssh2} = defined $is_ssh2 ? $is_ssh2 : 0;
}

sub encrypt {
    my($ciph, $text) = @_;
    $ciph->{is_ssh2} ?
        $ciph->{cbc}->encrypt($text) :
        _swap_bytes($ciph->{cbc}->encrypt(_swap_bytes($text)));
}

sub decrypt {
    my($ciph, $text) = @_;
    $ciph->{is_ssh2} ?
        $ciph->{cbc}->decrypt($text) :
        _swap_bytes($ciph->{cbc}->decrypt(_swap_bytes($text)));
}

sub _swap_bytes {
    my $str = $_[0];
    $str =~ s/(.{4})/reverse $1/sge;
    $str;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::Blowfish - Wrapper for SSH Blowfish support

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('Blowfish', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::Blowfish> provides Blowfish encryption
support for I<Net::SSH::Perl>. To do so it wraps around
I<Crypt::Cipher::Blowfish> from the CryptX module.

The blowfish used here is in CBC filter mode with a key length
of 32 bytes.

SSH1 adds an extra wrinkle with respect to its blowfish algorithm:
before and after encryption/decryption, we have to swap the bytes
in the string to be encrypted/decrypted. The byte-swapping is done
four bytes at a time, and within each of those four-byte blocks
we reverse the bytes. So, for example, the string C<foobarba>
turns into C<boofabra>. We swap the bytes in this manner in the
string before we encrypt/decrypt it, and swap the
encrypted/decrypted string again when we get it back.

This byte-swapping is not done when Blowfish is used in the
SSH2 protocol.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
