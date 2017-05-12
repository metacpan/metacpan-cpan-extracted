# $Id: RC4.pm,v 1.5 2001/05/04 08:58:22 btrott Exp $

package Net::SSH::Perl::Cipher::RC4;

use strict;
use warnings;

use Net::SSH::Perl::Cipher;
use base qw( Net::SSH::Perl::Cipher );

sub new {
    my $class = shift;
    my $ciph = bless { }, $class;
    $ciph->init(@_) if @_;
    $ciph;
}

sub init {
    my $ciph = shift;
    my($key, $iv) = @_;
    $ciph->{key} = substr($key, 0, $ciph->keysize);

    $key = substr($key, 0, $ciph->keysize);
    my @k = unpack 'C*', $key;
    my @s = 0..255;
    my($y) = (0);
    for my $x (0..255) {
        $y = ($k[$x % @k] + $s[$x] + $y) % 256;
        @s[$x, $y] = @s[$y, $x];
    }
    $ciph->{s} = \@s;
    $ciph->{x} = 0;
    $ciph->{y} = 0;
}

sub blocksize { 8 }
sub keysize { 16 }

sub encrypt {
    my($ciph, $text) = @_;
    $text = RC4($ciph, $text);
    $text;
}

sub decrypt {
    my($ciph, $text) = @_;
    $text = RC4($ciph, $text);
    $text;
}

sub RC4 {
    my($ciph, $text) = @_;
    my($x, $y, $trans) = ($ciph->{x}, $ciph->{y}, '');
    my $s = $ciph->{s};
    for my $c (unpack 'C*', $text) {
        $x = ($x + 1) % 256;
        $y = ( $s->[$x] + $y ) % 256;
        @$s[$x, $y] = @$s[$y, $x];
        $trans .= pack('C', $c ^= $s->[( $s->[$x] + $s->[$y] ) % 256]);
    }
    $ciph->{x} = $x;
    $ciph->{y} = $y;
    $trans;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::RC4 - RC4 encryption/decryption

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('RC4', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::RC4> provides RC4 (I<arcfour>)
encryption support for the SSH2 protocol implementation in
I<Net::SSH::Perl>. Unlike the other I<Net::SSH::Perl::Cipher>
objects, the I<RC4> module relies on no outside libraries;
the RC4 algorithm is implemented entirely in this module.

RC4 uses key sizes of 16 bytes.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
