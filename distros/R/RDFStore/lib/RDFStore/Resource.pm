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
# *             - modified new() getURI() getLabel() and added getNamespace() 
# *		  getLocalName()methods accordingly to rdf-api-2000-10-30
# *             - modified toString()
# *     version 0.3
# *             - fixed bugs when checking references/pointers (defined and ref() )
# *     version 0.4
# *		- added check on local name when create a new Resource
# *		- updated accordingly to rdf-api-2001-01-19
# *		- allow creation of resources from URI(3) objects or strings using XMLNS LocalPart
# *		- hashCode() and getDigest() return separated values for localName and namespace if requested
# * 	version 0.41
# *		- added anonymous resources support - see also RDFStore::NodeFactory(3) and RDFStore::Model(3)
# *		- added isAnonymous() and isbNode()
# *             - updated accordingly to new RDFStore API
# *             - removed BLOB support
# *

package RDFStore::Resource;
{
use vars qw ($VERSION);
use strict;
 
$VERSION = '0.41';

use Carp;
use RDFStore; # load the underlying C code in RDFStore.xs because it is all in one module file
use RDFStore::RDFNode;

sub isbNode {
	return $_[0]->isAnonymous;
};

sub getURI {
	return
		if($_[0]->isAnonymous); #bNodes do not have a URI

	return $_[0]->getLabel;
};

sub getNodeID {
        return
                unless($_[0]->isAnonymous);

        return $_[0]->getLabel;
	};

sub equals {
	return 0
                unless(defined $_[1]);

	return 0
                if ( ref($_[1]) =~ /^(SCALAR|ARRAY|HASH|CODE|REF|GLOB|LVALUE)/ ); #see perldoc perlfunc ref()

	return 0
		unless(	(defined $_[1]) &&
			(ref($_[1])) &&
			($_[1]->isa("RDFStore::Resource")) );

	return ( $_[0]->isAnonymous && $_[1]->isAnonymous ) ? ( $_[0]->getNodeID eq $_[1]->getNodeID ) : $_[0]->SUPER::equals($_[1])
        	if(	($_[0]->isAnonymous) ||
			($_[1]->isAnonymous) );

	# resources are equal if $_[0]->getURI() eq $_[1]->getURI() unless anonymous; then the digest is checked instead - see RDFStore::RDFNode(3)
	unless( $_[0]->getNamespace() ) {
        	unless($_[1]->getNamespace()) {
			return ( $_[0]->getLocalName() eq $_[1]->getLocalName() ) ? 1 : 0;
		} else { # maybe $_[1] did not detect names
			return ($_[0]->getLocalName() eq $_[1]->getURI()) ? 1 : 0;
			};
	} else {
        	if($_[1]->getNamespace()) {
			return (	( $_[0]->getLocalName() eq $_[1]->getLocalName() ) &&
					( $_[0]->getNamespace() eq $_[1]->getNamespace()) ) ? 1 : 0;
		} else { # maybe $_[1] did not detect names
			return ($_[0]->getURI() eq $_[1]->getURI()) ? 1 : 0;
			};
		};
        return $_[0]->SUPER::equals($_[1]);
};

1;
};

__END__

=head1 NAME

RDFStore::Resource - An RDF Resource Node implementation

=head1 SYNOPSIS

	use RDFStore::Resource;
	my $resource = new RDFStore::Resource("http://pen.jrc.it/index.html");
	my $resource1 = new RDFStore::Resource("http://pen.jrc.it/","index.html");

	print $resource->toString." is ";
        print "not"
        	unless $resource->equals($resource1);
        print " equal to ".$resource1->toString."\n";

	# or from URI object	
	use URI;
	$resource = new RDFStore::Resource("http://www.w3.org/1999/02/22-rdf-syntax-ns#","Description");
	$resource1 = new RDFStore::Resource( new URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#Description") );

	print $resource->toString." is ";
        print "not"
        	unless $resource->equals($resource1);
        print " equal to ".$resource1->toString."\n";

	my $resource = new RDFStore::Resource([ a,{ d => 'value'}, [ 1,2,3] ]);
 
        print $resource->toString." is ";
        print "not"
                unless($resource->isbNode);
        print " anonymous\n";

=head1 DESCRIPTION

An RDF Resource Node implementation which support the so called anonymous-resources or bNodes (blankNodes)

=head1 METHODS

=over 4

=item new ( LOCALNAME_NAMESPACE [, LOCALNAME ] )

This is a class method, the constructor for RDFStore::Resource. In case the method is called with a single perl scalar as parameter a new RDF Resource is created with the string passed as indentifier (LOCALNAME); a fully qualified RDF resource can be constructed by invoching the constructor with B<two> paramters where the former is the NAMESPACE and the latter is the LOCALNAME. By RDF definition we assume that B<LOCALNAME can not be undefined>. If LOCALNAME is a perl reference the new Resource is flagged as anonymous-resource or bNode :)

bNodes can be created either passing a perl reference to the constructor or by using the RDFStore::NodeFactory(3) createbNode() or createAnonymousResource() methods; the latter is actually setting the RDFStore::Resource internal bNode flag.

=item isAnonymous

Return true if the RDF Resource is anonymous or is a bNode

=item isbNode

Return true if the RDF Resource is anonymous or is a bNode

=item getURI

Return the URI identifing the RDF Resource; an undefined values i returned if the node is blank or anonymous.

=item getNamespace

Return the Namespace identifier of the Resource

=item getLocalName

Return the LocalName identifier of the Resource; if the Resource is anonymous (bNode) the Storable(3) representation of the label is returned instead. This will allow to distinguish bNodes between normal resources and give them a kind of unique identity. B<NOTE> See RDFStore::Model(3) to see how actually bNodes are being stored and retrieved in RDFStore(3).

=item getLabel

Return the URI identifing the RDF Resource.

=item equals

Compare two RDF Resources either textual

=item getNodeID

Return the rdf:nodeID if the Resource is anonymous (bNode).

=item getbNode

Return the bNode conent.

=head1 SEE ALSO

RDFStore::RDFNode(3)

=head1 ABOUT RDF

 http://www.w3.org/TR/rdf-primer/

 http://www.w3.org/TR/rdf-mt

 http://www.w3.org/TR/rdf-syntax-grammar/

 http://www.w3.org/TR/rdf-schema/

 http://www.w3.org/TR/1999/REC-rdf-syntax-19990222 (obsolete)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
