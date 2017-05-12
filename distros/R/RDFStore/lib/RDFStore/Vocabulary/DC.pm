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

package RDFStore::Vocabulary::DC;
{
use vars qw ( $VERSION $title $creator $subject $description $publisher $contributor $date $type $format $identifier $source $language $relation $coverage $rights );
$VERSION='0.41';
use strict;
use RDFStore::Model;
use Carp;

# 
# This package provides convenient access to schema information.
# DO NOT MODIFY THIS FILE.
# It was generated automatically by RDFStore::Vocabulary::Generator
#

# Namespace URI of this schema
$RDFStore::Vocabulary::DC::_Namespace= "http://purl.org/dc/elements/1.1/";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::DC::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# A name given to the resource.
	$RDFStore::Vocabulary::DC::title = createResource($_[0], "title");
	# An entity primarily responsible for making the content    of the resource.
	$RDFStore::Vocabulary::DC::creator = createResource($_[0], "creator");
	# The topic of the content of the resource.
	$RDFStore::Vocabulary::DC::subject = createResource($_[0], "subject");
	# An account of the content of the resource.
	$RDFStore::Vocabulary::DC::description = createResource($_[0], "description");
	# An entity responsible for making the resource available
	$RDFStore::Vocabulary::DC::publisher = createResource($_[0], "publisher");
	# An entity responsible for making contributions to the   content of the resource.
	$RDFStore::Vocabulary::DC::contributor = createResource($_[0], "contributor");
	# A date associated with an event in the life cycle of the   resource.
	$RDFStore::Vocabulary::DC::date = createResource($_[0], "date");
	# The nature or genre of the content of the resource.
	$RDFStore::Vocabulary::DC::type = createResource($_[0], "type");
	# The physical or digital manifestation of the resource.
	$RDFStore::Vocabulary::DC::format = createResource($_[0], "format");
	# An unambiguous reference to the resource within a given context.
	$RDFStore::Vocabulary::DC::identifier = createResource($_[0], "identifier");
	# A reference to a resource from which the present resource   is derived.
	$RDFStore::Vocabulary::DC::source = createResource($_[0], "source");
	# A language of the intellectual content of the resource.
	$RDFStore::Vocabulary::DC::language = createResource($_[0], "language");
	# A reference to a related resource.
	$RDFStore::Vocabulary::DC::relation = createResource($_[0], "relation");
	# The extent or scope of the content of the resource.
	$RDFStore::Vocabulary::DC::coverage = createResource($_[0], "coverage");
	# Information about rights held in and over the resource.
	$RDFStore::Vocabulary::DC::rights = createResource($_[0], "rights");
};
sub END {
	$RDFStore::Vocabulary::DC::title = undef;
	$RDFStore::Vocabulary::DC::creator = undef;
	$RDFStore::Vocabulary::DC::subject = undef;
	$RDFStore::Vocabulary::DC::description = undef;
	$RDFStore::Vocabulary::DC::publisher = undef;
	$RDFStore::Vocabulary::DC::contributor = undef;
	$RDFStore::Vocabulary::DC::date = undef;
	$RDFStore::Vocabulary::DC::type = undef;
	$RDFStore::Vocabulary::DC::format = undef;
	$RDFStore::Vocabulary::DC::identifier = undef;
	$RDFStore::Vocabulary::DC::source = undef;
	$RDFStore::Vocabulary::DC::language = undef;
	$RDFStore::Vocabulary::DC::relation = undef;
	$RDFStore::Vocabulary::DC::coverage = undef;
	$RDFStore::Vocabulary::DC::rights = undef;
};
1;
};
