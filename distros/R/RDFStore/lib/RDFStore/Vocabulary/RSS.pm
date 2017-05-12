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

package RDFStore::Vocabulary::RSS;
{
use vars qw ( $VERSION $channel $image $item $items $textinput $title $link $url $description $name );
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
$RDFStore::Vocabulary::RSS::_Namespace= "http://purl.org/rss/1.0/";
use RDFStore::NodeFactory;
&setNodeFactory(new RDFStore::NodeFactory());

sub createResource {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );

	return $_[0]->createResource($RDFStore::Vocabulary::RSS::_Namespace,$_[1]);
};
sub setNodeFactory {
	croak "Factory ".$_[0]." is not an instance of RDFStore::NodeFactory"
		unless( (defined $_[0]) &&
                	( (ref($_[0])) && ($_[0]->isa("RDFStore::NodeFactory")) ) );
	# An information syndication channel
	$RDFStore::Vocabulary::RSS::channel = createResource($_[0], "channel");
	$RDFStore::Vocabulary::RSS::image = createResource($_[0], "image");
	# An item for syndication.
	$RDFStore::Vocabulary::RSS::item = createResource($_[0], "item");
	# A collection of items.
	$RDFStore::Vocabulary::RSS::items = createResource($_[0], "items");
	# A text input for syndication.
	$RDFStore::Vocabulary::RSS::textinput = createResource($_[0], "textinput");
	# A descriptive title for the channel.
	$RDFStore::Vocabulary::RSS::title = createResource($_[0], "title");
	# The URL to which an HTML rendering of the channel title will link.
	$RDFStore::Vocabulary::RSS::link = createResource($_[0], "link");
	# The URL of the image to used in the 'src' attribute of the channel's image tag when rendered as HTML.
	$RDFStore::Vocabulary::RSS::url = createResource($_[0], "url");
	# The URL to which an HTML rendering of the channel title will link.
	$RDFStore::Vocabulary::RSS::description = createResource($_[0], "description");
	# The text input field's (variable) name.
	$RDFStore::Vocabulary::RSS::name = createResource($_[0], "name");
};
sub END {
	$RDFStore::Vocabulary::RSS::channel = undef;
	$RDFStore::Vocabulary::RSS::image = undef;
	$RDFStore::Vocabulary::RSS::item = undef;
	$RDFStore::Vocabulary::RSS::items = undef;
	$RDFStore::Vocabulary::RSS::textinput = undef;
	$RDFStore::Vocabulary::RSS::title = undef;
	$RDFStore::Vocabulary::RSS::link = undef;
	$RDFStore::Vocabulary::RSS::url = undef;
	$RDFStore::Vocabulary::RSS::description = undef;
	$RDFStore::Vocabulary::RSS::name = undef;
};
1;
};
