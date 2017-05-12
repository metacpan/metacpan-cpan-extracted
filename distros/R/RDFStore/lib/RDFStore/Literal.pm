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
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.2
# *             - modified new() equals(), getLabel() methods accordingly to rdf-api-2000-10-30
# *		- modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- updated accordingly to rdf-api-2001-01-19
# *		- modified getLabel() and getURI() to return a lebel even if the Literal is a BLOB (using Storable)
# *		- updated equals() method to make a real comparison of BLOBs using Storable module
# *	version 0.41
# *		- added getDigest() to generate the digest using quotes and the label
# *     version 0.42
# *             - updated accordingly to new RDFStore API
# *		- removed BLOB support
# *

package RDFStore::Literal;
{
use vars qw ($VERSION);
use strict;

use Carp;
 
$VERSION = '0.42';

use Carp;
use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file
use RDFStore::RDFNode;

sub equals {
	return 0
                unless(defined $_[1]);

	return 0
		if ( ref($_[1]) =~ /^(SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE)/ ); #see perldoc perlfunc ref()

	my $label1 = $_[0]->getLabel();
        my $label2;
	if(	($_[1]) &&
		(ref($_[1])) && 
		($_[1]->isa("RDFStore::Literal")) ) {
		$label2 = $_[1]->getLabel();
	} else {
		$label2 = $_[1];
		};

        return ($label1 eq $label2) ? 1 : 0;
	};

1;
};

__END__

=head1 NAME

RDFStore::Literal - An RDF Literal Node implementation

=head1 SYNOPSIS

	use RDFStore::Literal;
	my $literal = new RDFStore::Literal('Tim Berners-Lee');
        my $literal1 = new RDFStore::Literal('Today is a sunny day, again :)');

        print $literal->toString." is ";
        print "not"
                unless $literal->equals($literal1);
        print " equal to ".$literal1->toString."\n";
 
=head1 DESCRIPTION

An RDF Literal Node implementation using Storable(3). A Literal object can either contain plain (utf8) strings. Such an implementation allows to create really generic RDF statements about Perl data-structures or objects for example. Generally an RDFStore::Literal can be thought like an atomic perl scalar.
XML well-formed literal values are supported simply by storing the resulting utf8 bytes into a perl scalar; none methods are being provided tomanage literals as XML (e.g. SAX2 events and stuff like that)

=head1 METHODS

=over 4

=item new ( LITERAL )

This is a class method, the constructor for RDFStore::Literal. The only parameter passed is either a plain perl scalar (LITERAL)

=item getParseType

Return the parseType of the RDF Literal; possible values are I<Literal> or I<Resource> (B<default>).

=item getLang

Return the language of the RDF Literal eventually coming from xml:lang attribute on parsing.

=item getDataType

Return the RDFStore::Resource representing the XMLSchema data type of the RDF Literal.

=item getLabel

Return the literal text of the node.

=item getDigest

Return a Cryptographic Digest (SHA-1 by default) of the RDF Literal; the actual digest message is guranteed to be different for URI representing RDF Resources or RDF Literals.

=item equals

Compare two literals.

=head1 SEE ALSO

RDFStore::RDFNode(3)

=head1 ABOUT RDF

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

=head1 BUGS

The language of the literal as recently specified by the RDF Core WG is not supported and the typed literals are not implemented; the latter is due mainly because perl is an untyped language and perhaps such data-typing abstractions should fit in a higher level application specific API.

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
