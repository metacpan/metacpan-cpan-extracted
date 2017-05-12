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
# *             - modified getDigest() equals() methods accordingly to rdf-api-2000-10-30
# *     version 0.4
# *             - updated accordingly to rdf-api-2001-01-19
# *		- fixed bug in hashCode() to avoid bulding the digest each time
# *		- added inheritance from RDFStore::Digest::Digestable
# *     version 0.41
# *		- updated accordingly to new RDFStore API
# *		- removed BLOB support
# *                 

package RDFStore::RDFNode;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.41';

use Carp;
use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file
use RDFStore::Digest::Digestable;

sub toString {
	return $_[0]->getLabel();
};

sub equals {
	return 0
                unless( (defined $_[1]) &&
			(ref($_[1])) &&
                        ($_[1]->isa("RDFStore::RDFNode")) );

        return ( $_[0]->getDigest() eq $_[1]->getDigest() ) ? 1 : 0
		if($_[1]->can('getDigest'));

        return ( $_[0]->getLabel() eq $_[1]->getLabel() ) ? 1 : 0;
};

1;
};

__END__

=head1 NAME

RDFStore::RDFNode - An RDF graph node

=head1 SYNOPSIS

	package myNode;

	use RDFStore::RDFNode;
	@myNode::ISA = qw ( RDFStore::RDFNode );

	sub new {
		my $self = $_[0]->SUPER::new();
		$self->{mylabel} = $_[1];
		bless $self,$_[0];
	};

	sub getLabel {
		return $_[0]->{mylabel};
	};

	package main;

	my $node = new myNode('My generic node');
	my $node1 = new myNode('Your generic node');

	print $node->toString." is ";
	print "not "
		unless $node->equals($node1);
	print " equal to ".$node1->toString."\n";
	

=head1 DESCRIPTION

RDFStore::RDFNode is the base abstract class for RDFStore::Literal and RDFStore::Resource.

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for RDFStore::RDFNode.

=item getLabel

Return the label of the RDFNode as perl scalar

=item toString

Return the textual represention of the RDFNode

=item getDigest

Return a Cryptographic Digest (SHA-1 by default) of the node label - see RDFStore::Digest::Digestable(3)

=item equals

Compare two RDFNodes.

=head1 SEE ALSO

RDFStore::Literal(3) RDFStore::Resource(3) RDFStore(3) RDFStore::Digest::Digestable(3)

=head1 ABOUT RDF

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
