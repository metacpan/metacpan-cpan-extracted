package Net::DNS::SEC;

use strict;
use warnings;

our $VERSION;
$VERSION = '1.19';
our $SVNVERSION = (qw$Id: SEC.pm 1854 2021-10-11 10:43:36Z willem $)[2];


=head1 NAME

Net::DNS::SEC - DNSSEC extensions to Net::DNS

=head1 SYNOPSIS

    use Net::DNS::SEC;

=head1 DESCRIPTION

Net::DNS::SEC is installed as an extension to an existing Net::DNS
installation providing packages to support DNSSEC as specified in
RFC4033, RFC4034, RFC4035 and related documents.

It also provides support for SIG0 which is useful for dynamic updates.

Implements cryptographic signature generation and verification functions
using RSA, DSA, ECDSA, and Edwards curve algorithms.

The extended features are made available by replacing Net::DNS by
Net::DNS::SEC in the use declaration.

=cut


use base qw(Exporter DynaLoader);

use Net::DNS 1.01 qw(:DEFAULT);

our @EXPORT = ( @Net::DNS::EXPORT, qw(algorithm digtype key_difference) );

use integer;
use Carp;


=head1 UTILITY FUNCTIONS

=head2 algorithm

    $mnemonic = algorithm( 5 );
    $numeric  = algorithm( 'RSA-SHA1' );
    print "algorithm mnemonic\t", $mnemonic, "\n";
    print "algorithm number:\t",  $numeric,  "\n";

algorithm() provides conversions between an algorithm code number and
the corresponding mnemonic.

=cut

sub algorithm { return &Net::DNS::RR::DS::algorithm; }


=head2 digtype

    $mnemonic = digtype( 2 );
    $numeric  = digtype( 'SHA-256' );
    print "digest type mnemonic\t", $mnemonic, "\n";
    print "digest type number:\t",  $numeric,  "\n";

digtype() provides conversions between a digest type number and the
corresponding mnemonic.

=cut

sub digtype { return &Net::DNS::RR::DS::digtype; }


=head2 key_difference

    @result = key_difference( \@a, \@b );

Fills @result with all keys in array @a that are not in array @b.

=cut

sub key_difference {
	my $a = shift;
	my $b = shift;
	my $r = shift || [];		## 0.17 API

	local $SIG{__DIE__};
	my ($x) = grep { !$_->isa('Net::DNS::RR::DNSKEY') } @$a, @$b;
	croak sprintf( 'unexpected %s object in key list', ref $x ) if $x;

	my %index = map { ( $_->privatekeyname => 1 ) } @$b;
	return @$r = grep { !$index{$_->privatekeyname} } @$a;
}


########################################

eval { Net::DNS::SEC->bootstrap($VERSION) } || croak;


foreach (qw(DS CDS RRSIG)) {
	Net::DNS::RR->new( type => $_ );			# pre-load to access class methods
}


1;
__END__


=head1 COPYRIGHT

Copyright (c)2014-2021 Dick Franks

Copyright (c)2001-2005 RIPE NCC. Author Olaf M. Kolkman

All Rights Reserved


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
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

L<perl>, L<Net::DNS>, RFC4033, RFC4034, RFC4035,
L<OpenSSL|http://www.openssl.org/docs>

=cut

