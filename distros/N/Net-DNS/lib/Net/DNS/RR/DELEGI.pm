package Net::DNS::RR::DELEGI;

use strict;
use warnings;
our $VERSION = (qw$Id: DELEGI.pm 2043 2026-01-14 13:35:59Z willem $)[2];

use base qw(Net::DNS::RR::DELEG);


=head1 NAME

Net::DNS::RR::DELEGI - DNS DELEGI resource record

=cut


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;

=head1 DESCRIPTION

Extensible DNS delegation information.

This is a clone of the DELEG record and inherits all properties of
the Net::DNS::RR::DELEG class.

Please see the L<Net::DNS::RR::DELEG> documentation for details.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.



=head1 COPYRIGHT

Copyright (c)2026 Dick Franks. 

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

=cut
