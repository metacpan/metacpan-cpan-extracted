package Net::DNS::RR::RESINFO;

use strict;
use warnings;
our $VERSION = (qw$Id: RESINFO.pm 2003 2025-01-21 12:06:06Z willem $)[2];

use base qw(Net::DNS::RR::TXT);


=head1 NAME

Net::DNS::RR::RESINFO - DNS RESINFO resource record

=cut

use integer;


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	my $target = 'resolver.example.net';

	my $resolver = Net::DNS::Resolver->new(
				nameserver => $target,
				recurse	   => 0
				);

	$resolver->send( $target, 'RESINFO' )->print;

	;; HEADER SECTION
	;;	id = 46638
	;;	qr = 1	aa = 1	tc = 0	rd = 0	opcode = QUERY
	;;	ra = 0	z  = 0	ad = 0	cd = 0	rcode  = NOERROR
	;;	do = 0	co = 0
	;;	qdcount = 1	ancount = 1
	;;	nscount = 0	arcount = 0

	;; QUESTION SECTION (1 record)
	;; resolver.example.net.	IN	RESINFO

	;; ANSWER SECTION (1 record)
	resolver.example.net.	7200	IN	RESINFO	(
		qnamemin exterr=15-17
		infourl=https://resolver.example.com/guide )

	;; AUTHORITY SECTION (0 records)

	;; ADDITIONAL SECTION (0 records)

=head1 DESCRIPTION

Class for DNS Resolver Information(RESINFO) resource records.

RESINFO is a clone of the Net::DNS::RR::TXT class.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 txtdata

	$string = $rr->txtdata;
	@list	 = $rr->txtdata;

When invoked in scalar context, $rr->txtdata() returns the resolver
properties as a single string, with elements separated by a single space.

In a list context, $rr->txtdata() returns a list of the text elements.


=head1 COPYRIGHT

Copyright (c)2024 Dick Franks.

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


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

L<perl> L<Net::DNS> L<Net::DNS::RR>
L<Net::DNS::RR::TXT>
L<RFC9606|https://iana.org/go/rfc9606>

=cut
