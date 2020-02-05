package Net::DNS::SEC::Digest;

#
# $Id: Digest.pm 1763 2020-02-02 21:48:03Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1763 $)[1];


=head1 NAME

Net::DNS::SEC::Digest - Message Digest Algorithms


=head1 SYNOPSIS

    require Net::DNS::SEC::Digest;

    $object = new Net::DNS::SEC::Digest::SHA(256);
    $object->add($text);
    $object->add($more);
    $digest = $object->digest;


=head1 DESCRIPTION

Interface package providing access to the message digest algorithm
implementations within the OpenSSL libcrypto library.

=cut


use strict;
use integer;
use warnings;

use constant libcrypto_available => Net::DNS::SEC::libcrypto->can('EVP_MD_CTX_new');

BEGIN { die 'Net::DNS::SEC not available' unless libcrypto_available }


my %sha = (
	1   => sub { Net::DNS::SEC::libcrypto::EVP_sha1() },
	224 => sub { Net::DNS::SEC::libcrypto::EVP_sha224() },
	256 => sub { Net::DNS::SEC::libcrypto::EVP_sha256() },
	384 => sub { Net::DNS::SEC::libcrypto::EVP_sha384() },
	512 => sub { Net::DNS::SEC::libcrypto::EVP_sha512() },
	);

my %sha3 = (
	224 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_224() },
	256 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_256() },
	384 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_384() },
	512 => sub { Net::DNS::SEC::libcrypto::EVP_sha3_512() },
	);


package Net::DNS::SEC::Digest::SHA;

sub new {
	my ( $class, $alg ) = @_;
	my $mdobj = Net::DNS::SEC::libcrypto::EVP_MD_CTX_new();
	my $evpmd = $sha{$alg};
	Net::DNS::SEC::libcrypto::EVP_DigestInit( $mdobj, &$evpmd );
	bless( \$mdobj, $class );
}

sub add {
	my $object = shift;
	Net::DNS::SEC::libcrypto::EVP_DigestUpdate( $$object, shift );
}


sub digest {
	my $object = shift;
	Net::DNS::SEC::libcrypto::EVP_DigestFinal($$object);
}

DESTROY {
	my $object = shift;
	Net::DNS::SEC::libcrypto::EVP_MD_CTX_free($$object);
}


package Net::DNS::SEC::Digest::SHA3;
our @ISA = qw(Net::DNS::SEC::Digest::SHA);

sub new {
	my ( $class, $alg ) = @_;
	my $mdobj = Net::DNS::SEC::libcrypto::EVP_MD_CTX_new();
	my $evpmd = $sha3{$alg};
	Net::DNS::SEC::libcrypto::EVP_DigestInit( $mdobj, &$evpmd );
	bless( \$mdobj, $class );
}


package Net::DNS::SEC::Digest::MD5;
our @ISA = qw(Net::DNS::SEC::Digest::SHA);

sub new {
	my ( $class, $alg ) = @_;
	my $mdobj = Net::DNS::SEC::libcrypto::EVP_MD_CTX_new();
	my $evpmd = sub { Net::DNS::SEC::libcrypto::EVP_md5() };
	Net::DNS::SEC::libcrypto::EVP_DigestInit( $mdobj, &$evpmd );
	bless( \$mdobj, $class );
}


1;

__END__

########################################

=head1 METHODS

=head2 new

    require Net::DNS::SEC::Digest;
    $object = new Net::DNS::SEC::Digest::SHA( $algorithm );

Creates and initialises a new digest object instance for the specified
algorithm.


=head2 add

    $object->add($text);
    $object->add($more);

Append specified text to digest stream.


=head2 digest

    $digest = $object->digest;

Returns the digest encoded as a binary string.


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

