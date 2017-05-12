package RDF::Closure::XsdDatatypes;

use 5.008;
use strict;
use utf8;

use RDF::Trine qw[statement];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];

use base qw[Exporter];

our $VERSION = '0.001';

our @EXPORT = qw[];
our @EXPORT_OK = qw[
	$RDFS_Datatypes
	$OWL_RL_Datatypes
	$RDFS_Datatype_Subsumptions
	$OWL_Datatype_Subsumptions
	];

#: The basic XSD types used everywhere; this means not the complete set of day/month types
our $_Common_XSD_Datatypes = [
	$XSD->integer, $XSD->decimal, $XSD->nonNegativeInteger, $XSD->nonPositiveInteger,
	$XSD->negativeInteger, $XSD->positiveInteger, $XSD->long, $XSD->int, $XSD->short,
	$XSD->byte, $XSD->unsignedLong, $XSD->unsignedInt, $XSD->unsignedShort,
	$XSD->unsignedByte, $XSD->float, $XSD->double, $XSD->string, $XSD->normalizedString,
	$XSD->token, $XSD->language, $XSD->Name, $XSD->NCName, $XSD->NMTOKEN,
	$XSD->boolean, $XSD->hexBinary, $XSD->base64Binary, $XSD->anyURI,
	$XSD->dateTimeStamp, $XSD->dateTime, $XSD->time, $XSD->date,
	$RDFS->Literal, $RDF->XMLLiteral
];

#: RDFS Datatypes: the basic ones plus the complete set of day/month ones
our $RDFS_Datatypes   = [ @$_Common_XSD_Datatypes,
	$XSD->gYearMonth, $XSD->gMonthDay, $XSD->gYear, $XSD->gDay, $XSD->gMonth ];

#: OWL RL Datatypes: the basic ones plus plain literal
our $OWL_RL_Datatypes = [ @$_Common_XSD_Datatypes, $RDF->PlainLiteral ];

#: XSD Datatype subsumptions
our $_Common_Datatype_Subsumptions = {
	$XSD->dateTimeStamp->uri        => [ $XSD->dateTime ],
	$XSD->integer->uri              => [ $XSD->decimal ],
	$XSD->long->uri                 => [ $XSD->integer, $XSD->decimal ],
	$XSD->int->uri                  => [ $XSD->long, $XSD->integer, $XSD->decimal ],
	$XSD->short->uri                => [ $XSD->int, $XSD->long, $XSD->integer, $XSD->decimal ],
	$XSD->byte->uri                 => [ $XSD->short, $XSD->int, $XSD->long, $XSD->integer, $XSD->decimal ],
	$XSD->nonNegativeInteger->uri   => [ $XSD->integer, $XSD->decimal ],
	$XSD->positiveInteger->uri      => [ $XSD->nonNegativeInteger, $XSD->integer, $XSD->decimal ],
	$XSD->unsignedLong->uri         => [ $XSD->nonNegativeInteger, $XSD->integer, $XSD->decimal ],
	$XSD->unsignedInt->uri          => [ $XSD->unsignedLong, $XSD->nonNegativeInteger, $XSD->integer, $XSD->decimal ],
	$XSD->unsignedShort->uri        => [ $XSD->unsignedInt, $XSD->unsignedLong, $XSD->nonNegativeInteger, $XSD->integer, $XSD->decimal ],
	$XSD->unsignedByte->uri         => [ $XSD->unsignedShort, $XSD->unsignedInt, $XSD->unsignedLong, $XSD->nonNegativeInteger, $XSD->integer, $XSD->decimal ],
	$XSD->nonPositiveInteger->uri   => [ $XSD->integer, $XSD->decimal ],
	$XSD->negativeInteger->uri      => [ $XSD->nonPositiveInteger, $XSD->integer, $XSD->decimal ],
	$XSD->normalizedString->uri     => [ $XSD->string ],
	$XSD->token->uri                => [ $XSD->normalizedString, $XSD->string ],
	$XSD->language->uri             => [ $XSD->token, $XSD->normalizedString, $XSD->string ],
	$XSD->Name->uri                 => [ $XSD->token, $XSD->normalizedString, $XSD->string ],
	$XSD->NCName->uri               => [ $XSD->Name, $XSD->token, $XSD->normalizedString, $XSD->string ],
	$XSD->NMTOKEN->uri              => [ $XSD->Name, $XSD->token, $XSD->normalizedString, $XSD->string ],
};

#: RDFS Datatype subsumptions: at the moment, there is no extra to XSD
our $RDFS_Datatype_Subsumptions	= $_Common_Datatype_Subsumptions;

#: OWL Datatype subsumptions: at the moment, there is no extra to XSD
our $OWL_Datatype_Subsumptions	= $_Common_Datatype_Subsumptions;

1;

=head1 NAME

RDF::Closure::XsdDatatypes - exports lists of datatypes

=head1 ANALOGOUS PYTHON

RDFClosure/XsdDatatypes.py

=head1 SEE ALSO

L<RDF::Closure>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2011 Ivan Herman

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

