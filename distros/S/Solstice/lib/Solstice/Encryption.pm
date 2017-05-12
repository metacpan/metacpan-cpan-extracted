package Solstice::Encryption;

# $Id: Encryption.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Encryption - Solstice's standard two-way encryption library.

=head1 SYNOPSIS

  use Solstice::Encryption;

  my $encrypter = Solstice::Encryption->new;

  my $ciphertext = $encrypter->encrypt($string);

  my $string = $encrypter->decrypt($ciphertext);

=head1 DESCRIPTION

Will encrypt/decrypt a string using the Rijndael algorithm (aes).

=cut

use 5.006_000;
use strict;
use warnings;

use Crypt::Rijndael;
use MIME::Base64;
use URI::Escape;
use Solstice::Configure;
use Unicode::String;

our $private_key;
use constant DIVISOR => 16;
our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut



=item new()

Constructor.  Returns an encrypter object.

=cut

sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;

    if (!defined $private_key) {
        my $config = Solstice::Configure->new();
        $private_key = $config->getEncryptionKey();
    }

    $self->_setCipher(Crypt::Rijndael->new($private_key));

    return $self;
}

=item encrypt(plain_text_string)

Returns the encrypted version of the plain_text_string in URL safe text.

=cut

sub encrypt {
    my $self = shift;
    my $pt   = shift;
    return uri_escape(encode_base64($self->_encrypt($pt)));
}

=item encryptHex(plain_text_string)
Returns the encrypted version of the plain_text_string escaped as hex.
=cut

sub encryptHex {
    my $self = shift;
    my $pt   = shift;
    return unpack "H*", $self->_encrypt($pt);
}

=item _encrypt()
=cut

sub _encrypt {
    my $self = shift;
    my $pt   = shift;  # text to encode

    # require a parameter
    return undef unless (defined $pt && $pt);

    # make sure that our data is a multiple of DIVISOR bytes.
    my $length = length(Unicode::String->new($pt)->as_string());
    if ($length % DIVISOR != 0) {
        $pt = ' ' x (DIVISOR - ($length % DIVISOR)) . $pt;
    }
    return $self->_getCipher()->encrypt($pt);
}

=item decrypt(encrypted_string)

Returns the decrypted version of the encrypted_string

=cut

sub decrypt {
    my $self   = shift;
    my $cipher = shift;  # text to decode

    # required parameter
    return undef unless (defined $cipher && $cipher);
    my $base64 = uri_unescape($cipher);
    my $crypted = decode_base64($base64);
    if ((length($crypted) % DIVISOR) != 0) {
        return undef;
    }

    return $self->_decrypt(decode_base64($base64));

}

=item decryptHex(encrypted_string)
Returns the decrypted version of the encrypted string.
=cut

sub decryptHex {
    my $self = shift;
    my $cipher = shift;
    return undef unless (defined $cipher && $cipher);
    return $self->_decrypt(pack "H*", $cipher);
}

=item _decrypt()
=cut

sub _decrypt {
    my $self = shift;
    my $et   = shift;
    my $padded;
    eval{
        $padded = $self->_getCipher()->decrypt($et);
    };

    $padded =~ s/^[ ]*//;
    return $padded;
}

=back

=head2 Private Methods

=over 4

=cut

=item _setCipher($cipher)

=cut

sub _setCipher {
    my $self = shift;
    $self->{'_cipher'} = shift;
}

=item _getCipher()

=cut

sub _getCipher {
    my $self   = shift;
    return $self->{'_cipher'};
}


1;
__END__

=back

=head2 Modules Used

L<Crypt::Rijndael|Crypt::Rijndael>,
L<MIME::Base64|MIME::Base64>,
L<URI::Escape|URI::Escape>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
