#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Net::LibAsyncNS::Constants;

use strict;
use warnings;

our $VERSION = '0.02';

use Exporter 'import';

# Constants are loaded from Net::LibAsyncNS
use Net::LibAsyncNS;

=head1 NAME

C<Net::LibAsyncNS::Constants> - API constants for C<Net::LibAsyncNS>

=head1 DESCRIPTION

This module provides the numeric constants for the C<getaddrinfo> and
C<getnameinfo> resolution methods in L<Net::LibAsyncNS>. They are held in this
package to keep the object API clean.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
