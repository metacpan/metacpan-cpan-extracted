package Net::Address::IP::Cipher 0.4;

use 5.012;
use strict;
use warnings FATAL => 'all';

use Carp;

use Net::IP qw(:PROC);
use Crypt::KeyDerivation qw(pbkdf2);
use Crypt::Cipher::AES;

=head1 NAME

Net::Address::IP::Cipher - IPv6 / IPv4 address encryption to a valid
address, for pseudo anonymization.

=head1 VERSION

Version 0.4

=head1 SYNOPSIS

Net::Address::IP::Cipher encrypts and decrypts IPv6 and IPv4 addresses
to another valid IPv6/v4 address, using a secret key, in a way that's
impossible to guess the original IP without the key.

    use Net::Address::IP::Cipher;

    my $ipcipher = Net::Address::IP::Cipher->new(
        password => 'super secret'
    );
    my $enc = $ipcipher->enc('::1');
    print $enc; # 3a3e:7137:6e36:5ecd:4d31:e516:cf47:ec1b

It's intended use is to pseudo-anonymize IPs from logs, packet captures,
and other analysis. By this way you benefit of having still valid IP
addresses and be able to group streams of several messagess, but without
revealing the source.

This module implements in native perl language the "ipcipher"
specification from:
   L<https://github.com/PowerDNS/ipcipher>


=head1 PREREQUISITES

This module requires L<Net::IP> for v6/v4 handling and L<CryptX> for
all crypto stuff (L<Crypt::KeyDerivation>, L<Crypt::Cipher::AES>).

=head1 METHODS

=head2 new

Creates a new Net::Address::IP::Cipher object. You must indicate
the secret key for encryption/decryption:

  my $ipcipher = Net::Address::IP::Cipher->new(password => 'super secret');

The key should be declared in either one of two formats:

  password => 'super secret'

for any string used as a password, or

  barekey => 'bb8dcd7be9a6f43b3304c640d7d7103c'

for an hexadecimal representation of a 128-bit key.

If you provide both, just the 'password' format will be used.

=cut

sub new {
    my $this = shift;
    my %params = @_;

    my $class = ref($this) || $this;

    my $key;

    if ($params{'password'}) {
        $key = pbkdf2($params{'password'}, 'ipcipheripcipher', 50000, 'SHA1', 16);
    }
    elsif ($params{'barekey'}) {
        $key = pack 'H*', $params{'barekey'};
        croak("If you provide a 'barekey' it should be in hexadecimal format, and its lenght should be 128 bits") unless length($key) == 16;
    }

    my $self = {};
    bless $self, $class;

    $self->{'PRIVKEY'} = $key;
    $self->{'CIPHER'} = Crypt::Cipher::AES->new($key)
        or die "Can't create AES cipher, please check your key!";

    return $self;
}

# PRIVATE FUNCTIONS

sub _xor4 {
    my $ps = shift;
    my $pk = shift;

    my @out;
    foreach my $i (0..3) {
        push @out, ($ps->[$i] ^ $pk->[$i]) & 0xff;
    }

    return @out;
}

sub _rotl {
    my ($b, $r) = @_;

    return (($b << $r) & 0xff) | ($b >> (8 - $r));
}

sub _permute_fwd {
    my $b = shift;

    $b->[0] += $b->[1];
    $b->[2] += $b->[3];
    $b->[0] &= 0xff;
    $b->[2] &= 0xff;
    $b->[1] = &_rotl($b->[1], 2);
    $b->[3] = &_rotl($b->[3], 5);
    $b->[1] ^= $b->[0];
    $b->[3] ^= $b->[2];
    $b->[0] = &_rotl($b->[0], 4);
    $b->[0] += $b->[3];
    $b->[2] += $b->[1];
    $b->[0] &= 0xff;
    $b->[2] &= 0xff;
    $b->[1] = &_rotl($b->[1], 3);
    $b->[3] = &_rotl($b->[3], 7);
    $b->[1] ^= $b->[2];
    $b->[3] ^= $b->[0];
    $b->[2] = &_rotl($b->[2], 4);

    return $b;
}

sub _permute_bwd {
    my $b = shift;

    $b->[2] = &_rotl($b->[2], 4);
    $b->[1] ^= $b->[2];
    $b->[3] ^= $b->[0];
    $b->[1] = &_rotl($b->[1], 5);
    $b->[3] = &_rotl($b->[3], 1);
    $b->[0] -= $b->[3];
    $b->[2] -= $b->[1];
    $b->[0] &= 0xff;
    $b->[2] &= 0xff;
    $b->[0] = &_rotl($b->[0], 4);
    $b->[1] ^= $b->[0];
    $b->[3] ^= $b->[2];
    $b->[1] = &_rotl($b->[1], 6);
    $b->[3] = &_rotl($b->[3], 3);
    $b->[0] -= $b->[1];
    $b->[2] -= $b->[3];
    $b->[0] &= 0xff;
    $b->[2] &= 0xff;

    return $b;
}


sub _encrypt {
    my ($key, $ip) = @_;

    my @key = map {unpack('C', $_) } split //, $key;
    my @state = split /\./, $ip;

    my @pedazo = @key[0..3];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_fwd(\@state)};
    @pedazo = @key[4..7];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_fwd(\@state)};
    @pedazo = @key[8..11];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_fwd(\@state)};
    @pedazo = @key[12..15];
    @state = &_xor4(\@state, \@pedazo);

    return join '.', @state;
}

sub _decrypt {
    my ($key, $ip) = @_;

    my @key = map {unpack('C', $_) } split //, $key;
    my @state = split /\./, $ip;

    my @pedazo = @key[12..15];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_bwd(\@state)};
    @pedazo = @key[8..11];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_bwd(\@state)};
    @pedazo = @key[4..7];
    @state = &_xor4(\@state, \@pedazo);
    @state = @{&_permute_bwd(\@state)};
    @pedazo = @key[0..3];
    @state = &_xor4(\@state, \@pedazo);

    return join '.', @state;
}


=head2 enc

Receive an IPv6 or IPv4 string address, in any valid format
for Net::IP, and returns the encrypted version as string.

    my $enc = $ipcipher->enc('::1');
    print $enc;  # b733:fb7:c957:82fc:3d67:e7c3:a667:28da

=cut

sub enc {
    my $self = shift;
    my $ipin = shift;

    my $out;

    my $ipvx = new Net::IP($ipin) or croak 'IP not valid: ' . (Net::IP::Error());

    if ($ipvx->version == 6) {
        my $ciphertext = $self->{'CIPHER'}->encrypt(pack('B*', $ipvx->binip));

        my $enc = new Net::IP(ip_bintoip(unpack('B*', $ciphertext), 6));
        $out = $enc->short;
    }
    else {
        $out = &_encrypt($self->{'PRIVKEY'}, $ipin);
    }

    return $out;
}

=head2 dec

Receive and IPv6 or IPv4 string address in its encrypted version,
and returns the decrypted IP string.

    my $dec = $ipcipher->dec('b733:fb7:c957:82fc:3d67:e7c3:a667:28da');
    print $dec;  # ::1

=cut

sub dec {
    my $self = shift;
    my $ipin = shift;

    my $out;

    my $ipvx = new Net::IP($ipin) or croak 'IP not valid: ' . (Net::IP::Error());

    if ($ipvx->version == 6) {
        my $plain = $self->{'CIPHER'}->decrypt(pack('B*', $ipvx->binip));
        my $dec = new Net::IP(ip_bintoip(unpack('B*', $plain), 6));
        $out = $dec->short;
    }
    else {
        $out = &_decrypt($self->{'PRIVKEY'}, $ipin);
    }

    return $out;
}

=head1 AUTHOR

Hugo Salgado, C<< <hsalgado at vulcano.cl> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-address-ip-cipher at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Address-IP-Cipher>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Address::IP::Cipher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Address-IP-Cipher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Address-IP-Cipher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Address-IP-Cipher>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Address-IP-Cipher/>

=back

=head1 REPOSITORY

L<https://github.com/huguei/p5-Net-Address-IP-Cipher>

=head1 ACKNOWLEDGEMENTS

The v4 version is based on the original ipcrypt python version from
Jean-Philippe Aumasson:
   L<https://github.com/veorq/ipcrypt>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Hugo Salgado.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::Address::IP::Cipher
