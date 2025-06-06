package Net::DNS::RR::NULL;

use strict;
use warnings;
our $VERSION = (qw$Id: NULL.pm 2002 2025-01-07 09:57:46Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::NULL - DNS NULL resource record

=cut


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	$rr = Net::DNS::RR->new('name NULL \# length hexdata ...');

=head1 DESCRIPTION

Class for DNS null (NULL) resource records.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 rdlength

	$rdlength = $rr->rdlength;

Returns the length of the record data section.

=head2 rdata

	$rdata = $rr->rdata;
	$rr->rdata( $rdata );

Returns the record data section as binary data.


=head1 COPYRIGHT

Copyright (c)1997 Michael Fuhr.

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
L<RFC1035(3.3.10)|https://iana.org/go/rfc1035#section-3.3.10>

=cut
