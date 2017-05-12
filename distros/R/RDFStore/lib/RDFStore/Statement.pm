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
# *             - added getNamespace() getLocalName() methods accordingly to rdf-api-2000-10-30
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- changed way to return undef in subroutines
# *		- fixed warning in getDigest()
# *             - updated new() equals() and added hashCode() accordingly to rdf-api-2001-01-19
# *		- updated accordingly to rdf-api-2001-01-19
# *		- Devon Smith <devon@taller.pscl.cwru.edu> changed getDigest to generate digests and hashes 
# *		  that match Stanford java ones exactly
# *     version 0.41
# *		- updated toString() and getDigest()
# *     version 0.42
# *		- updated accordingly to new RDFStore API
# *             - added statements reification and context support
# *

package RDFStore::Statement;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.42';

use Carp;
use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file
use RDFStore::Resource;

sub isAnonymous {
	return 0;
	};

sub getNamespace {
        return undef;
};

sub getLocalName {
        return $_[0]->getLabel();
};

sub getURI {
	return $_[0]->getLabel();
};

sub equals {
	return 0
		unless(defined $_[1]);

	if( $_[0]->context and $_[1]->context ) {
		return	(	($_[0]->subject->getLabel eq $_[1]->subject->getLabel) &&
				($_[0]->predicate->getLabel eq $_[1]->predicate->getLabel) &&
				($_[0]->object->getLabel eq $_[1]->object->getLabel) &&
				($_[0]->context->getLabel eq $_[1]->context->getLabel) );
	} else {
		return	(	($_[0]->subject->getLabel eq $_[1]->subject->getLabel) &&
				($_[0]->predicate->getLabel eq $_[1]->predicate->getLabel) &&
				($_[0]->object->getLabel eq $_[1]->object->getLabel) );
		};
};

1;
};

__END__

=head1 NAME

RDFStore::Statement - An RDF Statement implementation

=head1 SYNOPSIS

	use RDFStore::Statement;
	use RDFStore::Literal;
	use RDFStore::Resource;
	my $statement = new RDFStore::Statement(
  				new RDFStore::Resource("http://www.w3.org/Home/Lassila"),
  				new RDFStore::Resource("http://description.org/schema/","Creator"),
  				new RDFStore::Literal("Ora Lassila") );
	my $statement1 = new RDFStore::Statement(
  				new RDFStore::Resource("http://www.w3.org"),
  				new RDFStore::Resource("http://description.org/schema/","Publisher"),
  				new RDFStore::Literal("World Wide Web Consortium") );

	my $subject = $statement->subject;
	my $predicate = $statement->predicate;
	my $object = $statement->object;

	print $statement->toString." is ";
        print "not"
                unless $statement->equals($statement1);
        print " equal to ".$statement1->toString."\n";


=head1 DESCRIPTION

An RDF Statement implementation.

=head1 METHODS

=over 4

=item new ( SUBJECT, PREDICATE, OBJECT )

This is a class method, the constructor for RDFStore::Statement. SUBJECT and PREDICATE must be two RDFStore::Resource while OBJECT is RDFStore::RDFNode

=item subject

Return the RDFStore::Resource that is the RDF Subject/Resource of the Statement

=item predicate

Return the RDFStore::Resource that is the RDF Predicate/Property of the Statement/Resource

=item object

Return the RDFStore::RDFNode that is the RDF Object/Property-Value of the Statement/Resource

=item getURI

Return the URI identifing the RDF Statement; this is useful either for RDF reification (if ever it will be used :) and to treat RDF Statement as resources and then make "composite" statements....somehow ;)


=item getNamespace

Return undef

=item getLocalName

Return the label of the RDF Statement as a URN identifier with the digest hex encoded i.e. "urn:rdf:SHA-1:12uf2229829289229eee"

=item getLabel

Return the label of the RDF Statement as a URN identifier with the digest hex encoded i.e. "urn:rdf:SHA-1:12uf2229829289229eee"

=item toString

Return the textual represention of the RDF Statement i.e. triple("http://blaa.org", "http://purl.org/dc/elements/1.1/title", "Crapy site")

=item getDigest

Return a Cryptographic Digest (SHA-1 by default) of the Statement as defined in http://nestroy.wi-inf.uni-essen.de/rdf/sum_rdf_api/#K31

=item equals

Compare two RDF Statements.

=head1 SEE ALSO

RDFStore::Literal(3) RDFStore::Resource(3) RDFStore(3) RDFStore::Digest::Digestable(3) RDFStore::RDFNode(3)

=head1 ABOUT RDF

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
