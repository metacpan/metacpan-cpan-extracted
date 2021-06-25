package Net::Payment::CCAvenue;

use Moose;
use Digest::MD5 qw/md5_hex/;
use Crypt::Mode::CBC;
use URI;

=head1 NAME

Net::Payment::CCAvenue::NonSeamless - Processing orders using CCAvenue billing page!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 See More

=over 2

=item L<Net::Payment::CCAvenue::NonSeamless>
=item L<Net::Payment::CCAvenue::NonSeamless::Response>

=head1 Attributes

=head2 service_url

CCAVENUE service url.

=head2 encryption_key

Encryption key provided by CCAVENUE.

=head2 access_code

Access code provided by CCAVENUE.

=head2 merchant_id

Merchant identifier provided by CCAVENUE.

=cut

has service_url => (
    is         => 'ro',
    isa        => 'URI',
    lazy_build => 1
);

sub _build_service_url {
    my ($self) = @_;
    return URI->new('https://secure.ccavenue.ae/transaction/transaction.do');
}

has [ qw(encryption_key access_code merchant_id) ] => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=head2 encryption_key_md5

128-bit hash value of the encryption key.

=cut

has encryption_key_md5 => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_encryption_key_md5 {
    my ($self) = @_;
    return md5_hex $self->encryption_key;
}

=head2 encryption_key_bin

Binary format of 128 bit hash value of encryption key.

=cut

has encryption_key_bin => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_encryption_key_bin {
    my ($self) = @_;
    return pack("H*",$self->encryption_key_md5);
}

=head2 aes_cipher

AES encryption cipher.

=cut

has aes_cipher => (
    is         => 'ro',
    isa        => 'Crypt::Mode::CBC',
    lazy_build => 1
);

sub _build_aes_cipher {
    my ($self) = @_;
    return Crypt::Mode::CBC->new( 'AES', 1 );
}

=head2 init_vector

Init vector for AES encryption.

=cut

has init_vector => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return pack( "C*",
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
            0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f );
    }
);

=head1 SUBROUTINES/METHODS

=head2 encrypt_data

Data to be encrypted as 128 bit AES encryption.

=cut

sub encrypt_data {
    my ( $self, $data ) = @_;
    return unpack(
        'H*',
        $self->aes_cipher->encrypt(
            $data, $self->encryption_key_bin, $self->init_vector
        )
    );
}

=head2 decrypt_data

Decrypte the given encrypted data.

=cut

sub decrypt_data {
    my ( $self, $encrypted_data ) = @_;
    return $self->aes_cipher->decrypt(
        pack( 'H*', $encrypted_data ),
        $self->encryption_key_bin,
        $self->init_vector
    );
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-payment-ccavenue-nonseamless at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Payment-CCAvenue-NonSeamless>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Payment::CCAvenue::NonSeamless


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Payment-CCAvenue-NonSeamless>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Payment-CCAvenue-NonSeamless>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Payment-CCAvenue-NonSeamless>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Payment-CCAvenue-NonSeamless/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 Rakesh Kumar Shardiwal.

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

1; # End of Net::Payment::CCAvenue::NonSeamless
