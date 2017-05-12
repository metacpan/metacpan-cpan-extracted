package RDF::Closure::DatatypeTuple;

use 5.008;
use strict;
use utf8;

use overload
	q[""] => 'to_string';

our $VERSION = '0.001';

sub new
{
	my ($class, @values) = @_;
	bless [ @values ], $class;
}

sub to_string
{
	my ($self) = @_;
	return $self->[0];
}

1;

package RDF::Closure::DatatypeTuple::Boolean;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Decimal;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::URI;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Base64Binary;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::HexBinary;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Double;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Float;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::DateTime;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Date;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::Time;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::GYearMonth;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::GYear;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::GMonthDay;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::GDay; #Mate
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::GMonth;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::XMLLiteral;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::PlainLiteral;
use base qw[RDF::Closure::DatatypeTuple];
1;

package RDF::Closure::DatatypeTuple::String;
use base qw[RDF::Closure::DatatypeTuple];
1;

=head1 NAME

RDF::Closure::DatatypeTuple - classes used internally by DatatypeHandling.pm

=head1 SEE ALSO

L<RDF::Closure>, L<RDF::Closure::DatatypeHandling>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

