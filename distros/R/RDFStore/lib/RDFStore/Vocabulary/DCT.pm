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

package RDFStore::Vocabulary::DCT;
{
use vars qw ( $VERSION $Collection $Dataset $Event $Image $InteractiveResource $Service $Software $Sound $Text $PhysicalObject $StillImage $MovingImage );
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
$RDFStore::Vocabulary::DCT::_Namespace= "http://purl.org/dc/dcmitype/";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::DCT::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# A collection is an aggregation of items. The term    collection means that the resource is described as a    group; its parts may be separately described and navigated.
	$RDFStore::Vocabulary::DCT::Collection = createResource($_[0], "Collection");
	# A dataset is information encoded in a defined structure    (for example, lists, tables, and databases), intended to    be useful for direct machine processing.
	$RDFStore::Vocabulary::DCT::Dataset = createResource($_[0], "Dataset");
	# An event is a non-persistent, time-based occurrence.    Metadata for an event provides descriptive   information that is the basis for discovery of the   purpose, location, duration, responsible agents, and   links to related events and resources.  The resource   of type event may not be retrievable if the described   instantiation has expired or is yet to occur.   Examples - exhibition, web-cast, conference,   workshop, open-day, performance, battle, trial,   wedding, tea-party, conflagration.
	$RDFStore::Vocabulary::DCT::Event = createResource($_[0], "Event");
	# An image is a primarily symbolic visual representation    other than text. For example - images and photographs of    physical objects, paintings, prints, drawings, other    images and graphics, animations and moving pictures,    film, diagrams, maps, musical notation. Note that image    may include both electronic and physical representations.
	$RDFStore::Vocabulary::DCT::Image = createResource($_[0], "Image");
	# An interactive resource is a resource which requires    interaction from the user to be understood, executed,    or experienced. For example - forms on web pages, applets,    multimedia learning objects, chat services, virtual    reality.
	$RDFStore::Vocabulary::DCT::InteractiveResource = createResource($_[0], "InteractiveResource");
	# A service is a system that provides one or more    functions of value to the end-user. Examples include:    a photocopying service, a banking service, an    authentication service, interlibrary loans, a Z39.50    or Web server.
	$RDFStore::Vocabulary::DCT::Service = createResource($_[0], "Service");
	# Software is a computer program in source or    compiled form which may be available for installation    non-transiently on another machine. For software which    exists only to create an interactive environment, use    interactive instead.
	$RDFStore::Vocabulary::DCT::Software = createResource($_[0], "Software");
	# A sound is a resource whose content is primarily    intended to be rendered as audio. For example - a    music playback file format, an audio compact disc,    and recorded speech or sounds.
	$RDFStore::Vocabulary::DCT::Sound = createResource($_[0], "Sound");
	# A text is a resource whose content is primarily    words for reading. For example - books, letters,    dissertations, poems, newspapers, articles,    archives of mailing lists. Note that facsimiles    or images of texts are still of the genre text.
	$RDFStore::Vocabulary::DCT::Text = createResource($_[0], "Text");
	# An inanimate, three-dimensional object or substance.     For example -- a computer, the great pyramid, a    sculpture.  Note that digital representations    of, or surrogates for, these things should use Image,    Text or one of the other types.
	$RDFStore::Vocabulary::DCT::PhysicalObject = createResource($_[0], "PhysicalObject");
	# A static visual representation. Examples of         still images are: paintings, drawings, graphic designs,         plans and maps.
	$RDFStore::Vocabulary::DCT::StillImage = createResource($_[0], "StillImage");
	# A series of visual representations that,         when shown in succession, impart an impression         of motion.  Examples of moving images are:         animations, movies, television programs,         videos, zoetropes, or visual output from         a simulation.
	$RDFStore::Vocabulary::DCT::MovingImage = createResource($_[0], "MovingImage");
};
sub END {
	$RDFStore::Vocabulary::DCT::Collection = undef;
	$RDFStore::Vocabulary::DCT::Dataset = undef;
	$RDFStore::Vocabulary::DCT::Event = undef;
	$RDFStore::Vocabulary::DCT::Image = undef;
	$RDFStore::Vocabulary::DCT::InteractiveResource = undef;
	$RDFStore::Vocabulary::DCT::Service = undef;
	$RDFStore::Vocabulary::DCT::Software = undef;
	$RDFStore::Vocabulary::DCT::Sound = undef;
	$RDFStore::Vocabulary::DCT::Text = undef;
	$RDFStore::Vocabulary::DCT::PhysicalObject = undef;
	$RDFStore::Vocabulary::DCT::StillImage = undef;
	$RDFStore::Vocabulary::DCT::MovingImage = undef;
};
1;
};
