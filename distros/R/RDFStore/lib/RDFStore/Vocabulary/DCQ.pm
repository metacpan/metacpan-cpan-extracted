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

package RDFStore::Vocabulary::DCQ;
{
use vars qw ( $VERSION $audience $alternative $tableOfContents $abstract $created $valid $available $issued $modified $extent $medium $isVersionOf $hasVersion $isReplacedBy $replaces $isRequiredBy $requires $isPartOf $hasPart $isReferencedBy $references $isFormatOf $hasFormat $conformsTo $spatial $temporal $mediator $dateAccepted $dateCopyrighted $dateSubmitted $educationLevel $accessRights $bibliographicCitation $license $rightsHolder $SubjectScheme $DateScheme $FormatScheme $LanguageScheme $SpatialScheme $TemporalScheme $TypeScheme $IdentifierScheme $RelationScheme $SourceScheme $LCSH $MESH $DDC $LCC $UDC $DCMIType $IMT $ISO639_2 $RFC1766 $URI $Point $ISO3166 $Box $TGN $Period $W3CDTF $RFC3066 );
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
$RDFStore::Vocabulary::DCQ::_Namespace= "http://purl.org/dc/terms/";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::DCQ::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# A class of entity for whom the resource is intended or useful.
	$RDFStore::Vocabulary::DCQ::audience = createResource($_[0], "audience");
	# Any form of the title used as a substitute or alternative    to the formal title of the resource.
	$RDFStore::Vocabulary::DCQ::alternative = createResource($_[0], "alternative");
	# A list of subunits of the content of the resource.
	$RDFStore::Vocabulary::DCQ::tableOfContents = createResource($_[0], "tableOfContents");
	# A summary of the content of the resource.
	$RDFStore::Vocabulary::DCQ::abstract = createResource($_[0], "abstract");
	# Date of creation of the resource.
	$RDFStore::Vocabulary::DCQ::created = createResource($_[0], "created");
	# Date (often a range) of validity of a resource.
	$RDFStore::Vocabulary::DCQ::valid = createResource($_[0], "valid");
	# Date (often a range) that the resource will become or did    become available.
	$RDFStore::Vocabulary::DCQ::available = createResource($_[0], "available");
	# Date of formal issuance (e.g., publication) of the resource.
	$RDFStore::Vocabulary::DCQ::issued = createResource($_[0], "issued");
	# Date on which the resource was changed.
	$RDFStore::Vocabulary::DCQ::modified = createResource($_[0], "modified");
	# The size or duration of the resource.
	$RDFStore::Vocabulary::DCQ::extent = createResource($_[0], "extent");
	# The material or physical carrier of the resource.
	$RDFStore::Vocabulary::DCQ::medium = createResource($_[0], "medium");
	# The described resource is a version, edition, or adaptation    of the referenced resource. Changes in version imply substantive    changes in content rather than differences in format.
	$RDFStore::Vocabulary::DCQ::isVersionOf = createResource($_[0], "isVersionOf");
	# The described resource has a version, edition, or adaptation,    namely, the referenced resource.
	$RDFStore::Vocabulary::DCQ::hasVersion = createResource($_[0], "hasVersion");
	# The described resource is supplanted, displaced, or    superseded by the referenced resource.
	$RDFStore::Vocabulary::DCQ::isReplacedBy = createResource($_[0], "isReplacedBy");
	# The described resource supplants, displaces, or supersedes    the referenced resource.
	$RDFStore::Vocabulary::DCQ::replaces = createResource($_[0], "replaces");
	# The described resource is required by the referenced resource,    either physically or logically.
	$RDFStore::Vocabulary::DCQ::isRequiredBy = createResource($_[0], "isRequiredBy");
	# The described resource requires the referenced resource to    support its function, delivery, or coherence of content.
	$RDFStore::Vocabulary::DCQ::requires = createResource($_[0], "requires");
	# The described resource is a physical or logical part of the    referenced resource.
	$RDFStore::Vocabulary::DCQ::isPartOf = createResource($_[0], "isPartOf");
	# The described resource includes the referenced resource either    physically or logically.
	$RDFStore::Vocabulary::DCQ::hasPart = createResource($_[0], "hasPart");
	# The described resource is referenced, cited, or otherwise    pointed to by the referenced resource.
	$RDFStore::Vocabulary::DCQ::isReferencedBy = createResource($_[0], "isReferencedBy");
	# The described resource references, cites, or otherwise points    to the referenced resource.
	$RDFStore::Vocabulary::DCQ::references = createResource($_[0], "references");
	# The described resource is the same intellectual content of    the referenced resource, but presented in another format.
	$RDFStore::Vocabulary::DCQ::isFormatOf = createResource($_[0], "isFormatOf");
	# The described resource pre-existed the referenced resource,    which is essentially the same intellectual content presented    in another format.
	$RDFStore::Vocabulary::DCQ::hasFormat = createResource($_[0], "hasFormat");
	# A reference to an established standard to which the resource conforms.
	$RDFStore::Vocabulary::DCQ::conformsTo = createResource($_[0], "conformsTo");
	# Spatial characteristics of the intellectual content of the resource.
	$RDFStore::Vocabulary::DCQ::spatial = createResource($_[0], "spatial");
	# Temporal characteristics of the intellectual content of the resource.
	$RDFStore::Vocabulary::DCQ::temporal = createResource($_[0], "temporal");
	# A class of entity that mediates access to the   resource and for whom the resource is intended or useful.
	$RDFStore::Vocabulary::DCQ::mediator = createResource($_[0], "mediator");
	# Date of acceptance of the resource (e.g. of thesis   by university department, of article by journal, etc.).
	$RDFStore::Vocabulary::DCQ::dateAccepted = createResource($_[0], "dateAccepted");
	# Date of a statement of copyright.
	$RDFStore::Vocabulary::DCQ::dateCopyrighted = createResource($_[0], "dateCopyrighted");
	# Date of submission of the resource (e.g. thesis,    articles, etc.).
	$RDFStore::Vocabulary::DCQ::dateSubmitted = createResource($_[0], "dateSubmitted");
	# A general statement describing the education or    training context.  Alternatively, a more specific    statement of the location of the audience in terms of    its progression through an education or training context.
	$RDFStore::Vocabulary::DCQ::educationLevel = createResource($_[0], "educationLevel");
	# Information about who can access the         resource or an indication of its security status.         
	$RDFStore::Vocabulary::DCQ::accessRights = createResource($_[0], "accessRights");
	# A bibliographic reference for the resource.         
	$RDFStore::Vocabulary::DCQ::bibliographicCitation = createResource($_[0], "bibliographicCitation");
	# A legal document giving official permission to do something         with the resource.
	$RDFStore::Vocabulary::DCQ::license = createResource($_[0], "license");
	# A person or organization owning or managing rights over the resource.         
	$RDFStore::Vocabulary::DCQ::rightsHolder = createResource($_[0], "rightsHolder");
	# A set of subject encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::SubjectScheme = createResource($_[0], "SubjectScheme");
	# A set of date encoding schemes and/or formats 
	$RDFStore::Vocabulary::DCQ::DateScheme = createResource($_[0], "DateScheme");
	# A set of format encoding schemes.
	$RDFStore::Vocabulary::DCQ::FormatScheme = createResource($_[0], "FormatScheme");
	# A set of language encoding schemes and/or formats.
	$RDFStore::Vocabulary::DCQ::LanguageScheme = createResource($_[0], "LanguageScheme");
	# A set of geographic place encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::SpatialScheme = createResource($_[0], "SpatialScheme");
	# A set of encoding schemes for       the coverage qualifier "temporal"
	$RDFStore::Vocabulary::DCQ::TemporalScheme = createResource($_[0], "TemporalScheme");
	# A set of resource type encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::TypeScheme = createResource($_[0], "TypeScheme");
	# A set of resource identifier encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::IdentifierScheme = createResource($_[0], "IdentifierScheme");
	# A set of resource relation encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::RelationScheme = createResource($_[0], "RelationScheme");
	# A set of source encoding schemes and/or formats
	$RDFStore::Vocabulary::DCQ::SourceScheme = createResource($_[0], "SourceScheme");
	# Library of Congress Subject Headings
	$RDFStore::Vocabulary::DCQ::LCSH = createResource($_[0], "LCSH");
	# Medical Subject Headings
	$RDFStore::Vocabulary::DCQ::MESH = createResource($_[0], "MESH");
	# Dewey Decimal Classification
	$RDFStore::Vocabulary::DCQ::DDC = createResource($_[0], "DDC");
	# Library of Congress Classification
	$RDFStore::Vocabulary::DCQ::LCC = createResource($_[0], "LCC");
	# Universal Decimal Classification
	$RDFStore::Vocabulary::DCQ::UDC = createResource($_[0], "UDC");
	# A list of types used to categorize the nature or genre            of the content of the resource.
	$RDFStore::Vocabulary::DCQ::DCMIType = createResource($_[0], "DCMIType");
	# The Internet media type of the resource.
	$RDFStore::Vocabulary::DCQ::IMT = createResource($_[0], "IMT");
	# ISO 639-2: Codes for the representation of names of languages.
	$RDFStore::Vocabulary::DCQ::ISO639_2 = createResource($_[0], "ISO639_2");
	# Internet RFC 1766 'Tags for the identification of Language'            specifies a two letter code taken from ISO 639, followed            optionally by a two letter country code taken from ISO 3166.
	$RDFStore::Vocabulary::DCQ::RFC1766 = createResource($_[0], "RFC1766");
	# A URI Uniform Resource Identifier
	$RDFStore::Vocabulary::DCQ::URI = createResource($_[0], "URI");
	# The DCMI Point identifies a point in space using its geographic coordinates.
	$RDFStore::Vocabulary::DCQ::Point = createResource($_[0], "Point");
	# ISO 3166 Codes for the representation of names of countries
	$RDFStore::Vocabulary::DCQ::ISO3166 = createResource($_[0], "ISO3166");
	# The DCMI Box identifies a region of space using its geographic limits.
	$RDFStore::Vocabulary::DCQ::Box = createResource($_[0], "Box");
	# The Getty Thesaurus of Geographic Names
	$RDFStore::Vocabulary::DCQ::TGN = createResource($_[0], "TGN");
	# A specification of the limits of a time interval.
	$RDFStore::Vocabulary::DCQ::Period = createResource($_[0], "Period");
	# W3C Encoding rules for dates and times - a profile based on ISO 8601
	$RDFStore::Vocabulary::DCQ::W3CDTF = createResource($_[0], "W3CDTF");
	# Internet RFC 3066 'Tags for the Identification of    Languages' specifies a primary subtag which   is a two-letter code taken from ISO 639 part   1 or a three-letter code taken from ISO 639   part 2, followed optionally by a two-letter   country code taken from ISO 3166.  When a   language in ISO 639 has both a two-letter and   three-letter code, use the two-letter code;   when it has only a three-letter code, use the   three-letter code.  This RFC replaces RFC   1766.
	$RDFStore::Vocabulary::DCQ::RFC3066 = createResource($_[0], "RFC3066");
};
sub END {
	$RDFStore::Vocabulary::DCQ::audience = undef;
	$RDFStore::Vocabulary::DCQ::alternative = undef;
	$RDFStore::Vocabulary::DCQ::tableOfContents = undef;
	$RDFStore::Vocabulary::DCQ::abstract = undef;
	$RDFStore::Vocabulary::DCQ::created = undef;
	$RDFStore::Vocabulary::DCQ::valid = undef;
	$RDFStore::Vocabulary::DCQ::available = undef;
	$RDFStore::Vocabulary::DCQ::issued = undef;
	$RDFStore::Vocabulary::DCQ::modified = undef;
	$RDFStore::Vocabulary::DCQ::extent = undef;
	$RDFStore::Vocabulary::DCQ::medium = undef;
	$RDFStore::Vocabulary::DCQ::isVersionOf = undef;
	$RDFStore::Vocabulary::DCQ::hasVersion = undef;
	$RDFStore::Vocabulary::DCQ::isReplacedBy = undef;
	$RDFStore::Vocabulary::DCQ::replaces = undef;
	$RDFStore::Vocabulary::DCQ::isRequiredBy = undef;
	$RDFStore::Vocabulary::DCQ::requires = undef;
	$RDFStore::Vocabulary::DCQ::isPartOf = undef;
	$RDFStore::Vocabulary::DCQ::hasPart = undef;
	$RDFStore::Vocabulary::DCQ::isReferencedBy = undef;
	$RDFStore::Vocabulary::DCQ::references = undef;
	$RDFStore::Vocabulary::DCQ::isFormatOf = undef;
	$RDFStore::Vocabulary::DCQ::hasFormat = undef;
	$RDFStore::Vocabulary::DCQ::conformsTo = undef;
	$RDFStore::Vocabulary::DCQ::spatial = undef;
	$RDFStore::Vocabulary::DCQ::temporal = undef;
	$RDFStore::Vocabulary::DCQ::mediator = undef;
	$RDFStore::Vocabulary::DCQ::dateAccepted = undef;
	$RDFStore::Vocabulary::DCQ::dateCopyrighted = undef;
	$RDFStore::Vocabulary::DCQ::dateSubmitted = undef;
	$RDFStore::Vocabulary::DCQ::educationLevel = undef;
	$RDFStore::Vocabulary::DCQ::accessRights = undef;
	$RDFStore::Vocabulary::DCQ::bibliographicCitation = undef;
	$RDFStore::Vocabulary::DCQ::license = undef;
	$RDFStore::Vocabulary::DCQ::rightsHolder = undef;
	$RDFStore::Vocabulary::DCQ::SubjectScheme = undef;
	$RDFStore::Vocabulary::DCQ::DateScheme = undef;
	$RDFStore::Vocabulary::DCQ::FormatScheme = undef;
	$RDFStore::Vocabulary::DCQ::LanguageScheme = undef;
	$RDFStore::Vocabulary::DCQ::SpatialScheme = undef;
	$RDFStore::Vocabulary::DCQ::TemporalScheme = undef;
	$RDFStore::Vocabulary::DCQ::TypeScheme = undef;
	$RDFStore::Vocabulary::DCQ::IdentifierScheme = undef;
	$RDFStore::Vocabulary::DCQ::RelationScheme = undef;
	$RDFStore::Vocabulary::DCQ::SourceScheme = undef;
	$RDFStore::Vocabulary::DCQ::LCSH = undef;
	$RDFStore::Vocabulary::DCQ::MESH = undef;
	$RDFStore::Vocabulary::DCQ::DDC = undef;
	$RDFStore::Vocabulary::DCQ::LCC = undef;
	$RDFStore::Vocabulary::DCQ::UDC = undef;
	$RDFStore::Vocabulary::DCQ::DCMIType = undef;
	$RDFStore::Vocabulary::DCQ::IMT = undef;
	$RDFStore::Vocabulary::DCQ::ISO639_2 = undef;
	$RDFStore::Vocabulary::DCQ::RFC1766 = undef;
	$RDFStore::Vocabulary::DCQ::URI = undef;
	$RDFStore::Vocabulary::DCQ::Point = undef;
	$RDFStore::Vocabulary::DCQ::ISO3166 = undef;
	$RDFStore::Vocabulary::DCQ::Box = undef;
	$RDFStore::Vocabulary::DCQ::TGN = undef;
	$RDFStore::Vocabulary::DCQ::Period = undef;
	$RDFStore::Vocabulary::DCQ::W3CDTF = undef;
	$RDFStore::Vocabulary::DCQ::RFC3066 = undef;
};
1;
};
