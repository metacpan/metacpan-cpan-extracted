package Net::DNS::RR::DELEG;

use strict;
use warnings;
our $VERSION = (qw$Id: DELEG.pm 1965 2024-02-14 09:19:32Z willem $)[2];

use base qw(Net::DNS::RR::SVCB);


=head1 NAME

Net::DNS::RR::DELEG - DNS DELEG resource record

=cut


1;
__END__


=head1 SYNOPSIS

    use Net::DNS;
    $rr = Net::DNS::RR->new('alias  DELEG 0 target');
    $rr = Net::DNS::RR->new('domain DELEG 1 nameserver ipv6hint=2001:db8::f00');

=head1 DESCRIPTION

DNS DELEG resource record

The DELEG record appears in, and is logically a part of,
the parent zone to mark the delegation point for a child zone.
It advertises, directly or indirectly, transport methods
available for connection to nameservers serving the child zone.

The DELEG class is derived from, and inherits all properties of,
the Net::DNS::RR::SVCB class.

Please see the L<Net::DNS::RR::SVCB> documentation for details.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.



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
L<Net::DNS::RR::SVCB>

L<RFC9460|https://tools.ietf.org/html/rfc9460>

=cut
