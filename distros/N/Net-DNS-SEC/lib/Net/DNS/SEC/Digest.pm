package Net::DNS::SEC::Digest;

use strict;
use warnings;

our $VERSION = (qw$Id: Digest.pm 1807 2020-09-28 11:38:28Z willem $)[2];


=head1 NAME

Net::DNS::SEC::Digest - Message Digest Algorithms


=head1 SYNOPSIS

    require Net::DNS::SEC::Digest;

    $object = Net::DNS::SEC::Digest::SHA->new(256);
    $object->add($text);
    $object->add($more);
    $digest = $object->digest;


=head1 DESCRIPTION

Interface package providing access to the message digest algorithm
implementations within the OpenSSL libcrypto library.

=cut



use constant libcrypto_available => Net::DNS::SEC::libcrypto->can('EVP_MD_CTX_new');

BEGIN { die 'Net::DNS::SEC not available' unless libcrypto_available }


my %digest = (
	MD5 => sub { Net::DNS::SEC::libcrypto::EVP_md5() },

	SHA_1	=> sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	SHA_224 => sub { Net::DNS::SEC::libcrypto::EVP_sha224() },
	SHA_256 => sub { Net::DNS::SEC::libcrypto::EVP_sha256() },
	SHA_384 => sub { Net::DNS::SEC::libcrypto::EVP_sha384() },
	SHA_512 => sub { Net::DNS::SEC::libcrypto::EVP_sha512() },

	SHA3_224 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_224() },
	SHA3_256 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_256() },
	SHA3_384 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_384() },
	SHA3_512 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_512() },
	);


sub new {
	my ( $class, @param ) = @_;
	my ($index) = reverse split '::', join '_', $class, @param;
	my $evpmd   = $digest{$index};
	my $mdobj   = Net::DNS::SEC::libcrypto::EVP_MD_CTX_new();
	Net::DNS::SEC::libcrypto::EVP_DigestInit( $mdobj, &$evpmd );
	return bless( \$mdobj, $class );
}

sub add {
	my $object = shift;
	return Net::DNS::SEC::libcrypto::EVP_DigestUpdate( $$object, shift );
}

sub digest {
	my $object = shift;
	return Net::DNS::SEC::libcrypto::EVP_DigestFinal($$object);
}

DESTROY {
	my $object = shift;
	return Net::DNS::SEC::libcrypto::EVP_MD_CTX_free($$object);
}


## no critic ProhibitMultiplePackages
package Net::DNS::SEC::Digest::MD5;
our @ISA = qw(Net::DNS::SEC::Digest);

package Net::DNS::SEC::Digest::SHA;
our @ISA = qw(Net::DNS::SEC::Digest);

package Net::DNS::SEC::Digest::SHA3;
our @ISA = qw(Net::DNS::SEC::Digest);


1;

__END__

########################################

=head1 METHODS

=head2 new

    require Net::DNS::SEC::Digest;
    $object = Net::DNS::SEC::Digest::SHA->new(256);

Creates and initialises a new digest object instance for the specified
algorithm class.


=head2 add

    $object->add($data);
    $object->add($more);

Append specified data to the digest stream.


=head2 digest

    $digest = $object->digest;

Returns an octet string containing the calculated digest.


=head1 ACKNOWLEDGMENT

Thanks are due to Eric Young and the many developers and 
contributors to the OpenSSL cryptographic library.


=head1 COPYRIGHT

Copyright (c)2020 Dick Franks.

All rights reserved.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<Net::DNS>, L<Net::DNS::SEC>,
L<OpenSSL|http://www.openssl.org/docs>

=cut

