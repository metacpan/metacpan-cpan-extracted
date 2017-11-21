#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Tangence;

use strict;
use warnings;

# This package contains no code other than a declaration of the version.
# It is provided simply to keep CPAN happy:
#   cpan -i Tangence

our $VERSION = '0.24';

=head1 NAME

C<Tangence> - attribute-oriented server/client object remoting framework

=head1 DESCRIPTION

Like CORBA only much smaller, lighter, and with heavy emphasis on attributes
of remoted objects, including notifications of modification and atomic update
operations.

=head1 TODO

Docs. Other languages. Static metadata. Other metadata backend generation -
L<Moose>?

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
