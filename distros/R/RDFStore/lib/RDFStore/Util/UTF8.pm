# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - Fri Apr 11 18:24:29 CEST 2003
# *

package RDFStore::Util::UTF8;
{
use strict;
use Carp;
use vars qw($VERSION);

use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file

require Exporter;

@RDFStore::Util::UTF8::ISA = qw(Exporter);

@RDFStore::Util::UTF8::EXPORT_OK = qw( cp_to_utf8 utf8_to_cp is_utf8 to_utf8 to_utf8_foldedcase utf8lc ); # symbols to export on request

$VERSION = '0.1';

sub utf8lc {
	to_utf8_foldedcase( @_ );
	};

1;
};

__END__

=head1 NAME

RDFStore::Util::UTF8 - Utility library to manage UTF8 strings

=head1 SYNOPSIS

	use RDFStore::Util::UTF8;

=head1 DESCRIPTION

Simple UTF8 library to manage strings in Unicode; a basic set of functions allow to convert Unicode Code Points to UTF8 and viceversa - convert any given string (in any encoding in principle) to UTF8

=head1 METHODS

=over 4

=item cp_to_utf8 ( CP )

Return the UTF8 byte sequence (string) representing the given Unicode Code Point CP (unsigned long)

=item utf8_to_cp ( UTF8_BUFF )

Return the Unicode Code Point (unsigned long) of the given UTF8_BUFF (char/string) passed

=item is_utf8 ( UTF8_BUFF )

Return true if the given UTF8_BUFF is a valid UTF8 byte sequence

=item to_utf8 ( STRING )

Convert a given STRING (in any encoding in principle) to its UTF8 byte sequence (string) representation

=item to_utf8_foldedcase ( STRING )

Convert a given STRING to its UTF8 case-folded (lang independent lowercase) byte sequence (string) representation

=item utf8lc ( STRING )

lc() for UTF8 chars i.e. using to_utf8_foldedcase() above

=head1 SEE ALSO

 perlunicode(1)

 http://www.unicode.org

 http://www.unicode.org/unicode/reports/tr21/#Caseless%20Matching (Unicode Case-folding)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
