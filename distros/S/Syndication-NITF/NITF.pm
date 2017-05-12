# $Id: NITF.pm,v 0.2 2001/12/19 05:30:13 brendan Exp $
# Syndication::NITF.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.2 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2001/12/19 05:30:13 $ =~ m# (.*) $# );

$DEBUG = 0;

#
# Syndication::NITF -- initial parser. Maybe this should be Syndication::NITF::Parser or something?
# also grabs the first NITF element to save time, is that a good idea?
# does it mean that you can't grab extra namespace/DTD declarations etc?
#
package Syndication::NITF;
use Carp;
use XML::DOM;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $filename) = @_;

	$self->{parser} = new XML::DOM::Parser;
	$self->{doc} = $self->{parser}->parsefile($filename);
	$self->{node} = $self->{doc}->getElementsByTagName("nitf", 0)->item(0);

	$self->{_singleElements}{head} = OPTIONAL;
	$self->{_singleElements}{body} = REQUIRED;

	$self->{_attributes}{uno} = IMPLIED; # unique identifier for this document
	$self->{_attributes}{baselang} = IMPLIED;
	$self->{_attributes}{class} = IMPLIED;

	return $self;
}

=pod

=head1 NAME

Syndication::NITF -- Parser for NITF v3.0 documents

=head1 VERSION

Version $Revision: 0.2 $, released $Date: 2001/12/19 05:30:13 $

=head1 SYNOPSIS

 use Syndication::NITF;

 my $nitf = new Syndication::NITF("myNITFfile.xml");
 my $head = $nitf->gethead;

 my $title = $head->gettitle->getText;

 my $tobject = $head->gettobject;
 if ($tobject->gettobjecttype eq "news") {
   my $items = $tobject->gettobjectsubjectList;
   foreach my $item (@$items) {
     # process each subject header
     ...
   }
 }
 ... etc ...

=head1 DESCRIPTION

B<Syndication::NITF> is an object-oriented Perl interface to NITF documents, allowing
you to manage (and one day create) NITF documents without any specialised NITF
or XML knowledge.

NITF is a standard format for the markup of textual news content (eg newspaper and
magazine articles), ratified by the International Press Telecommunications
Council (http://www.iptc.org).

This module supports the version 3.0 DTD of NITF. It makes no attempt to support eariler
versions of the DTD.

The module code is based on my B<Syndication::NewsML> module, and much of the functionality
is shared between the two (well actually it's copied from the NewsML module rather than
"shared" properly in the form of a separate module of shared classes -- this may be remedied
in the future).

=head2 Initialization

At the moment the constructor can only take a filename as an argument, as follows:

  my $nitf = new Syndication::NITF("file-to-parse.xml");

This attaches a parser to the file (using XML::DOM), and returns a reference to the first NITF
tag. (I may decide that this is a bad idea and change it soon)

=head2 Reading objects

There are five main types of calls:

=over 4

=item *

Get an individual element:

  my $head = $nitf->gethead;

=item *

Return a reference to an array of elements:

  my $identifiedcontentlist = $head->getdocdata->getidentifiedcontentList;

The array can be referenced as @$identifiedcontentlist, or an individual element can be
referenced as $identifiedcontentlist->[N].

=item *

Return the size of a list of elements:

  my $iclcount = $head->getdocdata->getidentifiedcontentCount;

=item *


Get an attribute of an element (as text):

  my $href = $catalog->getHref;

=item *

Get the contents of an element (ie the text between the opening and closing tags):

  my $urlnode = $catalog->getResourceList->[0]->getUrlList->[0];
  my $urltext = $urlnode->getText;

=back

Not all of these calls work for all elements: for example, if an element is defined in the NITF DTD
as having zero or one instances in its parent element, and you try to call getXXXList, B<Syndication::NITF>
will "croak" an error. (The error handling will be improved in the future so that it won't croak
fatally unless you want that to happen)

The NITF standard contains some "business rules" also written into the DTD: for example, a NewsItem
may contain nothing, a NewsComponent, one or more Update elements, or a TopicSet. For some of these
rules, the module is smart enough to detect errors and provide a warning. Again, these warnings will
be improved and extended in future versions of this module.

=head2 Documentation for all the classes

Each NITF element is represented as a class. This means that you can traverse documents as Perl
objects, as seen above.

Full documentation of which classes can be used in which documents is beyond me right now (with over
120 classes to document), so for now you'll have to work with the examples in the B<examples/> and
B<t/> directories to see what's going on. You should be able to get a handle on it fairly quickly.

The real problem is that it's hard to know when to use B<getXXX()> and when to use B<GetXXXList()>
-- that is, when an element can have more than one entry and when it is a singleton. Quite often it
isn't obvious from looking at a NITF document. For now, two ways to work this out are to try it and see
if you get an error, or to have a copy of the DTD in front of you. Obviously neither of these is
optimal, but documenting all 127 classes just so people can tell this difference is pretty scary as
well, and so much documentation would put lots of people off using the module. So I'll probably come
up with a reference document listing all the classes and methods, rather than docs for each class, in
a future release.  If anyone has any better ideas, please let me know.

=head1 BUGS

None that I know of, but there are probably many. The test suite isn't complete, so not every method
is tested, but the major ones (seem to) work fine. Of course, if you find bugs, I'd be very keen to
hear about them at B<brendan@clueful.com.au>. 

=head1 SEE ALSO

L<XML::DOM>, L<XML::RSS>, L<Syndication::NewsML>

=head1 AUTHOR

Brendan Quinn, Clueful Consulting Pty Ltd
(brendan@clueful.com.au)

=head1 COPYRIGHT

Copyright (c) 2001, Brendan Quinn. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut

#
# Syndication::NITF::DOMUtils -- a few helpful routines
#
package Syndication::NITF::DOMUtils;
use Carp;
$DEBUG = 0;

# walk the tree of descendents of $node to look for an attribute $attr with value $value.
# returns the matching node, or undef.
sub findElementByAttribute {
	my ($node, $attr, $value) = @_;
	my $tstattr = $node->getAttributeNode($attr);
	return $node if defined($tstattr) && ($tstattr->getValue eq $value);
	my $iternode;
	if ($node->hasChildNodes) {
		for my $child ($node->getChildNodes) {
			if ($child->getNodeType == XML::DOM::ELEMENT_NODE) {
				$iternode = findElementByAttribute($child, $attr, $value);
			}
			return $iternode if defined($iternode);
		}
	}
	return undef;
}

# return a reference to the NITF element at the top level of the document.
# will croak if not NITF element exists in the parent path of the given node.
sub getRootNode {
	my ($node) = @_;
	if (!defined($node)) {
		croak "Invalid document! getRootNode couldn't find a NITF element in parent path";
	} elsif ($node->getNodeName eq "NITF") {
		return $node;
	} else {
		return getRootNode($node->getParentNode);
	} 
}

#
# Syndication::NITF::References -- routines to follow references
# (any ideas for a better name?)
package Syndication::NITF::References;
use Carp;
$DEBUG = 0;

# find reference (based on NITF Toolkit Java version)
# get referenced data from within this document or possibly an external URL.
# parameter useExternal, if true, means we can look outside this document if necessary.
sub findReference {
	my ($node, $reference, $useExternal) = @_;
	# if reference starts with # it's in the local document (or should be)
	if ($reference =~ /^#/) {
		return $node->getElementByDuid(substr($reference, 1));
	} elsif ($useExternal) {
		# use LWP module to get the external document
		use LWP::UserAgent;
		my $ua = new LWP::UserAgent;
		$ua->agent("Syndication::NITF/0.04" . $ua->agent);
		my $req = new HTTP::Request GET => substr($reference, 1);
		my $response = $ua->request($req);
		if ($response->is_success) {
			return $response->content;
		}
	}
	# document is external but we're not allowed to go outside
	# or an error occured with the retrieval
	# maybe should flag error better than this??
	return undef;
}

#
# Syndication::NITF::Node -- superclass defining a few functions all these will need
#
package Syndication::NITF::Node;
use Carp;
@ISA = qw( XML::DOM::Node );
$DEBUG = 0;

sub new {
	my ($class, $node) = @_;
	my $self = bless {}, $class;

	use constant REQUIRED => 1;
	use constant IMPLIED => 2;
	use constant OPTIONAL => 3;
	use constant ZEROORMORE => 4;
	use constant ONEORMORE => 5;

	$self->{node} = $node;
	$self->{text} = undef;
	$self->{_tagname} = undef;

	# child elements we may want to access
	$self->{_singleElements} = {};
	$self->{_multiElements} = {};
	$self->{_attributes} = {};
	$self->{_hasText} = 0;

	$self->_init($node); # init will vary for different subclasses

	# call _init of ALL parent classes as well
	# thanks to Duncan Cameron <dcameron@bcs.org.uk> for suggesting how to get this to work!
	$_->($self, $node) for ( map {$_->can("_init")||()} @{"${class}::ISA"} );

	return $self;
}

sub _init { } # undef init, subclasses may want to use it

# get the contents of an element as as XML string (wrapper around XML::DOM::Node::toString)
# this *includes* the container tag of the current element.
sub getXML {
	my ($self) = @_;
	$self->{xml} = $self->{node}->toString;
}

# get the text of the element, if any
# now includes get text of all children, including elements, recursively!
sub getText {
	my ($self, $stripwhitespace) = @_;
	croak "Can't use getText on this element" unless $self->{_hasText};
	$self->{text} = "";
	$self->{text} = getTextRecursive($self->{node}, $stripwhitespace);
}

# special "cheat" method to get ALL text in ALL child elements, ignoring any markup tags.
# can use on any element, anywhere (if there's no text, it will just return an empty string
# or all whitespace)
sub getAllText {
	my ($self, $stripwhitespace) = @_;
	$self->{text} = "";
	$self->{text} = getTextRecursive($self->{node}, $stripwhitespace);
}

sub getTextRecursive {
	my ($node, $stripwhitespace) = @_;
	my $textstring;
	for my $child ($node->getChildNodes()) {
		if ( $child->getNodeType == XML::DOM::ELEMENT_NODE ) {
			$textstring .= getTextRecursive($child, $stripwhitespace);
		} else {
			my $tmpstring = $child->getData();
			if ($stripwhitespace && ($stripwhitespace eq "strip")) {
				$tmpstring =~ s/^\s+/ /; #replace with single space -- is this ok?
				$tmpstring =~ s/\s+$/ /; #replace with single space -- is this ok?
			}
			$textstring .= $tmpstring;
		}
	}
	$textstring =~ s/\s+/ /g if $stripwhitespace; #replace with single space -- is this ok?
	return $textstring;
}

# get the tag name of this element
sub getTagName {
	my ($self) = @_;
	$self->{_tagname} = $self->{node}->getTagName;
}

# get the path up to and including this element
sub getPath {
	my ($self) = @_;
	$self->getParentPath($self->{node});
}

# get the path of this node including all parent nodes (called by getPath)
sub getParentPath {
	my ($self, $parent) = @_;
	# have to look two levels up because XML::DOM treats "#document" as a level in the tree
	return $parent->getNodeName if !defined($parent->getParentNode->getParentNode);
	return $self->getParentPath($parent->getParentNode) . "->" . $parent->getNodeName;
}

# attempt to return an array of all children, in order, as instantiated nodes
sub getChildrenList {
	my ($self) = @_;
	my @childarray;
	foreach my $child ($self->{node}->getChildNodes) {
		if ($child->getNodeType == XML::DOM::ELEMENT_NODE) {
			my $nodename = $child->getNodeName;
			$nodename =~ s/[\-\.]//g; # remove dots and dashes from element names
            my $elementObject = "Syndication::NITF::$nodename"->new($child);
            push(@childarray, $elementObject);
		}
	}
	return @childarray;
}

use vars '$AUTOLOAD';

# Generic routine to extract child elements from node.
# handles "getParamaterName", "getParameterNameList"  and "getParameterNameCount"
sub AUTOLOAD {
	my ($self) = @_;

	if ($AUTOLOAD =~ /DESTROY$/) {
		return;
	}

	# extract attribute name
	$AUTOLOAD =~ /.*::get(\w+)/
		or croak "No such method: $AUTOLOAD";

	print "AUTOLOAD: method is $AUTOLOAD\n" if $DEBUG;
	my $call = $1;

	# we can't have method names with dots and dashes in them, but we need them for the
	# element/attribute names. So We use the kludge "_realname" hash to store the name inclusive
	# of dots and dashes
	my $oldname = $call;
	my $realname = $self->{_realname}->{$call};
	$realname = $call unless $realname;
	
	if ($call =~ /(\w+)Count$/) {

		# handle getXXXCount method
		my $oldvar = $1;
		$var = $self->{_realname}->{$oldvar} || $oldvar;
		if (!$self->{_multiElements}->{$var}) {
			croak "Can't use getCount on $var";
		}
		my $method = "get".$oldvar."List";
		$self->$method unless defined($self->{$var."Count"});
		return $self->{$var."Count"};
	} elsif ($call =~ /(\w+)List$/) {

		# handle getXXXList method for multi-element tags
		my $oldname = $1;
		my $elem = $self->{_realname}->{$oldname} || $oldname;

		if (!$self->{_multiElements}->{$elem}) {
			croak "No such method: $AUTOLOAD";
		}
		my $list = $self->{node}->getElementsByTagName($elem, 0);
		if (!$list && $self->{_multiElements}->{$elem} eq ONEORMORE) {
			croak "Error: required element $elem is missing";
		} 
        # set elemCount while we know what it is
        $self->{$elem."Count"} = $list->getLength;
        my @elementObjects;
        my $elementObject;
        for (my $i = 0; $i < $self->{$elem."Count"}; $i++) {
            $elementObject = "Syndication::NITF::$oldname"->new($list->item($i))
                if defined($list->item($i)); # if item is undef, push an undef to the array
            push(@elementObjects, $elementObject);
        }
        $self->{$elem} = \@elementObjects;
        return wantarray ? @elementObjects : $self->{$elem};
	} elsif ($self->{_singleElements}->{$realname}) {

		# handle getXXX method for single-element tags
		my $element = $self->{node}->getElementsByTagName($realname, 0);
		if (!$element && $self->{_singleElements}->{$realname} eq REQUIRED) {
			croak "Error: required element $realname is missing";
		} 
		# BQ altered 2001-12-05 so a non-existing element returns undef rather than an empty node
		$self->{$realname} = "Syndication::NITF::$oldname"->new($element->item(0));
		return $element->item(0)
			? $self->{$realname} = "Syndication::NITF::$oldname"->new($element->item(0))
			: undef;
	} elsif ($self->{_attributes}->{$realname}) {
		# return undef if self->node doesn't exist
		return undef unless defined($self->{node});
		return undef unless defined($self->{node}->getAttributeNode($realname));
		$self->{$realname} = $self->{node}->getAttributeNode($realname)->getValue;
		if (!$self->{$realname} && $self->{_attributes}->{$realname} eq REQUIRED) {
			croak "Error: $realname attribute is required";
		} 
		return $self->{$realname};
    } elsif ($self->{_multiElements}->{$realname}) {
        # flag error because multiElement needs to be called with "getBlahList"
        croak "$call can occur more than once: must call get".$call."List";
	} else {
		croak "No such method: $AUTOLOAD";
	}
}

#
# Syndication::NITF::GlobalAttributesNode -- standard attributes used in most elements
#
package Syndication::NITF::GlobalAttributesNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{id} = IMPLIED;
}

# id must me unique to the entire document.
sub getElementById {
	my ($self, $searchID) = @_;

	my $rootNode = Syndication::NITF::DOMUtils::getRootNode($self->{node});
	Syndication::NITF::DOMUtils::findElementByAttribute($rootNode, "Duid", $searchID);
}

#
# Syndication::NITF::CommonAttributesNode -- standard attributes used in most elements
#
package Syndication::NITF::CommonAttributesNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{id} = IMPLIED;
	$self->{_attributes}->{class} = IMPLIED;
	$self->{_attributes}->{style} = IMPLIED;
}

#
# Syndication::NITF::EnrichedTextNode -- standard "rich text" type node, has lots of possibilities
#
package Syndication::NITF::EnrichedTextNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{chron} = ZEROORMORE;
	$self->{_multiElements}->{classifier} = ZEROORMORE;
	$self->{_multiElements}->{copyrite} = ZEROORMORE;
	$self->{_multiElements}->{event} = ZEROORMORE;
	$self->{_multiElements}->{function} = ZEROORMORE;
	$self->{_multiElements}->{location} = ZEROORMORE;
	$self->{_multiElements}->{money} = ZEROORMORE;
	$self->{_multiElements}->{num} = ZEROORMORE;
	$self->{_realname}->{objecttitle} = "object.title";
	$self->{_multiElements}->{"object.title"} = ZEROORMORE;
	$self->{_multiElements}->{org} = ZEROORMORE;
	$self->{_multiElements}->{person} = ZEROORMORE;
	$self->{_multiElements}->{postaddr} = ZEROORMORE;
	$self->{_multiElements}->{virtloc} = ZEROORMORE;
	$self->{_multiElements}->{a} = ZEROORMORE;
	$self->{_multiElements}->{br} = ZEROORMORE;
	$self->{_multiElements}->{em} = ZEROORMORE;
	$self->{_multiElements}->{lang} = ZEROORMORE;
	$self->{_multiElements}->{pronounce} = ZEROORMORE;
	$self->{_multiElements}->{q} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::BlockContentNode -- nodes that include marked up content
#
package Syndication::NITF::BlockContentNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{p} = ZEROORMORE;
	$self->{_multiElements}->{hl2} = ZEROORMORE;
	$self->{_multiElements}->{table} = ZEROORMORE;
	$self->{_realname}->{nitftable} = "nitf-table";
	$self->{_multiElements}->{"nitf-table"} = ZEROORMORE;
	$self->{_multiElements}->{media} = ZEROORMORE;
	$self->{_multiElements}->{ol} = ZEROORMORE;
	$self->{_multiElements}->{uk} = ZEROORMORE;
	$self->{_multiElements}->{dl} = ZEROORMORE;
	$self->{_multiElements}->{bq} = ZEROORMORE;
	$self->{_multiElements}->{fn} = ZEROORMORE;
	$self->{_multiElements}->{note} = ZEROORMORE;
	$self->{_multiElements}->{pre} = ZEROORMORE;
	$self->{_multiElements}->{hr} = ZEROORMORE;
}

#
# Syndication::NITF::DateNode -- superclass defining an extra method for elements
#                             that contain ISO8601 formatted dates
# NEEDS TO BE CHANGED because most ISO8601 date "nodes" are actually attributes in NITF
package Syndication::NITF::DateNode;
use Carp;

# convert ISO8601 date/time into Perl internal date/time.
# always returns perl internal date, in UTC timezone.
sub getDatePerl {
	my ($self, $timezone) = @_;
	use Time::Local;
	my $dateISO8601 = $self->getText;
	my ($yyyy, $mm, $dd, $hh, $mi, $ss, $tzsign, $tzhh, $tzmi) = ($dateISO8601 =~ qr/(\d\d\d\d)(\d\d)(\d\d)T?(\d\d)?(\d\d)?(\d\d)?([+-])?(\d\d)?(\d\d)?/);
	my $perltime = timegm($ss, $mi, $hh, $dd, $mm-1, $yyyy);
	if ($tzhh) {
		my $deltasecs = 60 * ($tzsign eq "-") ? -1*($tzhh * 60 + $tzmi) : ($tzhh * 60 + $tzmi);
		$perltime += $deltasecs;
	}
	return $perltime;
}

#
# Syndication::NITF::head -- header of a document
#
package Syndication::NITF::head;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{title} = OPTIONAL;
	$self->{_multiElements}->{meta} = ZEROORMORE;
	$self->{_singleElements}->{tobject} = OPTIONAL;
	$self->{_singleElements}->{iim} = OPTIONAL;
	$self->{_singleElements}->{docdata} = OPTIONAL;
	$self->{_multiElements}->{pubdata} = ZEROORMORE;
	$self->{_realname}->{revisionhistory} = "revision-history";
	$self->{_multiElements}->{"revision-history"} = ZEROORMORE;
}

#
# Syndication::NITF::title -- document title
#
package Syndication::NITF::title;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# attribute is an enumeration so we must handle separately
sub gettype { # type of title
	my ($self) = @_;
	my @possiblevalues = qw(main subtitle parttitle alternate abbrev other);
	my $attr = $self->{node}->getAttributeNode("type");
	$self->{"type"} = $attr ? $attr->getValue : "";
	if ($self->{type} && grep !/$self->{type}/, "@possiblevalues") {
		croak "Illegal value ".$self->{type}." for attribute type";
	}
	return $self->{type};
}

#
# Syndication::NITF::meta -- generic metadata
#
package Syndication::NITF::meta;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{httpequiv} = "http-equiv";
	$self->{_attributes}->{"http-equiv"} = IMPLIED;  # HTTP response header name
	$self->{_attributes}->{name} = IMPLIED;  # Name of this piece of metadata
	$self->{_attributes}->{content} = REQUIRED;  # Name of this piece of metadata
}

#
# Syndication::NITF::tobject -- subject code
#
package Syndication::NITF::tobject;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{tobjectproperty} = "tobject.property";
	$self->{_multiElements}->{"tobject.property"} = ZEROORMORE;
	$self->{_realname}->{tobjectsubject} = "tobject.subject";
	$self->{_multiElements}->{"tobject.subject"} = ZEROORMORE;
	$self->{_realname}->{tobjecttype} = "tobject.type";
	$self->{_attributes}->{"tobject.type"} = IMPLIED;
}

# this attribute has a default so we have to handle it separately
sub gettobjecttype {
	my ($self) = @_;
	my $attr = $self->{node}->getAttributeNode("tobject.type");
	$self->{"tobjecttype"} = $attr ? $attr->getValue : "news";
}

#
# Syndication::NITF::tobject.property -- subject code
#  we introduced a hack to handle this: these class names leave out the dot from the element name
#
package Syndication::NITF::tobjectproperty;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{tobjectpropertytype} = "tobject.property.type";
	$self->{_attributes}->{"tobject.property.type"} = IMPLIED;
}

# this attribute has a default so we have to handle it separately
sub gettobjectpropertytype {
	my ($self) = @_;
	my $attr = $self->{node}->getAttributeNode("tobject.property.type");
	$self->{"tobjectpropertytype"} = $attr ? $attr->getValue : "current";
}

#
# Syndication::NITF::tobject.subject -- subject classification
#  we introduced a hack to handle this: these class names leave out the dot from the element name
#
package Syndication::NITF::tobjectsubject;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{tobjectsubjectipr} = "tobject.subject.ipr";
	$self->{_attributes}->{"tobject.subject.ipr"} = IMPLIED;
	$self->{_realname}->{tobjectsubjectrefnum} = "tobject.subject.refnum";
	$self->{_attributes}->{"tobject.subject.refnum"} = REQUIRED;
	$self->{_realname}->{tobjectsubjectcode} = "tobject.subject.code";
	$self->{_attributes}->{"tobject.subject.code"} = IMPLIED;
	$self->{_realname}->{tobjectsubjecttype} = "tobject.subject.type";
	$self->{_attributes}->{"tobject.subject.type"} = IMPLIED;
	$self->{_realname}->{tobjectsubjectmatter} = "tobject.subject.matter";
	$self->{_attributes}->{"tobject.subject.matter"} = IMPLIED;
	$self->{_realname}->{tobjectsubjectdetail} = "tobject.subject.detail";
	$self->{_attributes}->{"tobject.subject.detail"} = IMPLIED;
}

# this attribute has a default so we have to handle it separately
sub gettobjectsubjectipr {
	my ($self) = @_;
	my $attr = $self->{node}->getAttributeNode("tobject.subject.ipr");
	$self->{"tobjectsubjectipr"} = $attr ? $attr->getValue : "IPTC";
}

#
# Syndication::NITF::iim -- IIM Record 2 Data Container
#
package Syndication::NITF::iim;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{ds} = ZEROORMORE;
	$self->{_attributes}->{ver} = IMPLIED; # IIM version number
}

#
# Syndication::NITF::ds -- IIM Record 2 dataset information
#
package Syndication::NITF::ds;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{ds} = ZEROORMORE;
	$self->{_attributes}->{num} = REQUIRED; # IIM field number
	$self->{_attributes}->{value} = IMPLIED; # IIM field value
}

#
# Syndication::NITF::docdata -- Document metadata
#
package Syndication::NITF::docdata;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{correction} = ZEROORMORE;
	$self->{_multiElements}->{evloc} = ZEROORMORE;
	$self->{_realname}->{docid} = "doc-id";
	$self->{_multiElements}->{"doc-id"} = ZEROORMORE;
	$self->{_realname}->{dellist} = "del-list";
	$self->{_multiElements}->{"del-list"} = ZEROORMORE;
	$self->{_multiElements}->{urgency} = ZEROORMORE;
	$self->{_multiElements}->{fixture} = ZEROORMORE;
	$self->{_realname}->{dateissue} = "date.issue";
	$self->{_multiElements}->{"date.issue"} = ZEROORMORE;
	$self->{_realname}->{daterelease} = "date.release";
	$self->{_multiElements}->{"date.release"} = ZEROORMORE;
	$self->{_realname}->{dateexpire} = "date.expire";
	$self->{_multiElements}->{"date.expire"} = ZEROORMORE;
	$self->{_realname}->{docscope} = "doc-scope";
	$self->{_multiElements}->{"doc-scope"} = ZEROORMORE;
	$self->{_multiElements}->{series} = ZEROORMORE;
	$self->{_realname}->{edmsg} = "ed-msg";
	$self->{_multiElements}->{"ed-msg"} = ZEROORMORE;
	$self->{_realname}->{dukey} = "du-key";
	$self->{_multiElements}->{"du-key"} = ZEROORMORE;
	$self->{_realname}->{doccopyright} = "doc.copyright";
	$self->{_multiElements}->{"doc.copyright"} = ZEROORMORE;
	$self->{_realname}->{docrights} = "doc.rights";
	$self->{_multiElements}->{"doc.rights"} = ZEROORMORE;
	$self->{_realname}->{keylist} = "key-list";
	$self->{_multiElements}->{"key-list"} = ZEROORMORE;
	$self->{_realname}->{identifiedcontent} = "identified-content";
	$self->{_multiElements}->{"identified-content"} = ZEROORMORE;
}

#
# Syndication::NITF::correction -- Correction information
#
package Syndication::NITF::correction;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{info} = IMPLIED; # Message or instructions
	$self->{_realname}->{idstring} = "id-string";
	$self->{_attributes}->{"id-string"} = IMPLIED; # Document ID string
	$self->{_attributes}->{regsrc} = IMPLIED; # Identifies source of correction
}

#
# Syndication::NITF::evloc -- Event location (where an event took place, not where story was written)
#
package Syndication::NITF::evloc;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{isocc} = "iso-cc";
	$self->{_attributes}->{"iso-cc"} = IMPLIED; # Country code (ISO 3166)
	$self->{_realname}->{stateprov} = "state-prov";
	$self->{_attributes}->{"state-prov"} = IMPLIED; # State or province
	$self->{_realname}->{countydist} = "county-dist";
	$self->{_attributes}->{"county-dist"} = IMPLIED; # County or district
	$self->{_attributes}->{city} = IMPLIED; # City or municipality
}

#
# Syndication::NITF::doc-id -- Registered identification for document
#
package Syndication::NITF::docid;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{idstring} = "id-string";
	$self->{_attributes}->{"id-string"} = IMPLIED; # Document ID string
	$self->{_attributes}->{regsrc} = IMPLIED; # Identifies source of correction
}

#
# Syndication::NITF::del-list -- Delivery trail of delivery services
#
package Syndication::NITF::dellist;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{fromsrc} = "from-src";
	$self->{_multiElements}->{"from-src"} = IMPLIED; # Country code (ISO 3166)
}

#
# Syndication::NITF::from-src -- Delivery service identifier
#
package Syndication::NITF::fromsrc;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{srcname} = "src-name";
	$self->{_attributes}->{"src-name"} = IMPLIED; # The entity moving the document
	$self->{_realname}->{levelnumber} = "level-number";
	$self->{_attributes}->{"level-number"} = IMPLIED; # position in the transmission path
}

#
# Syndication::NITF::urgency -- News importance
#
package Syndication::NITF::urgency;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{edurg} = "ed-urg";
	$self->{_attributes}->{"ed-urg"} = IMPLIED; # 1=most, 5=normal, 8=least
}

#
# Syndication::NITF::fixture -- Reference to a constant but regularly updated document
#
package Syndication::NITF::fixture;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{fixid} = "fix-id";
	$self->{_attributes}->{"fix-id"} = IMPLIED; # name of the fixture
}

#
# Syndication::NITF::date.issue -- Date/time document was issued
#
package Syndication::NITF::dateissue;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # date normalised to ISO8601 format and UTC timezone
}

#
# Syndication::NITF::date.release -- Date/time document can be released (in future => embargoed)
#
package Syndication::NITF::daterelease;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # date normalised to ISO8601 format and UTC timezone
}

#
# Syndication::NITF::date.expire -- Date/time document has no validity (none == infinity)
#
package Syndication::NITF::dateexpire;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # date normalised to ISO8601 format and UTC timezone
}

#
# Syndication::NITF::doc-scope -- Area where document may be of interest
#
package Syndication::NITF::docscope;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{scope} = IMPLIED; # "halfway between a Keyword and a Category"
}

#
# Syndication::NITF::series -- Identifies article within a series
#
package Syndication::NITF::series;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{seriesname} = "series.name";
	$self->{_attributes}->{"series.name"} = IMPLIED; # "halfway between a Keyword and a Category"
}

# this attribute has a default so we have to handle it separately
sub getseriespart { # number of this article in the series
	my ($self) = @_;
	my $attr = $self->{node}->getAttributeNode("series.part");
	$self->{"seriespart"} = $attr ? $attr->getValue : "0";
}

# this attribute has a default so we have to handle it separately
sub getseriestotalpart { # expected number of articles in series (0 = unknown/infinite)
	my ($self) = @_;
	my $attr = $self->{node}->getAttributeNode("series.totalpart");
	$self->{"seriestotalpart"} = $attr ? $attr->getValue : "0";
}

#
# Syndication::NITF::ed-msg -- Non-publishable editorial message
#
package Syndication::NITF::edmsg;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{msgtype} = "msg-type";
	$self->{_attributes}->{"msg-type"} = IMPLIED; # message type
	$self->{_attributes}->{info} = IMPLIED; # actual message
}

#
# Syndication::NITF::du-key -- Dynamic Use key groups and updates versions of stories
#
package Syndication::NITF::dukey;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{generation} = IMPLIED; # du-key generation level. Increments each send.
	$self->{_attributes}->{part} = IMPLIED; # part within the du-key structure.
	$self->{_attributes}->{version} = IMPLIED; # version of a particular use of the du-key.
	$self->{_attributes}->{key} = IMPLIED; # actual key value.
}

#
# Syndication::NITF::doc.copyright -- Copyright info for doc header.
#
package Syndication::NITF::doccopyright;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{year} = IMPLIED; # year of doc copyright
	$self->{_attributes}->{holder} = IMPLIED; # copyright holder.
}

#
# Syndication::NITF::doc.rights -- Rights info for use of the document.
#
package Syndication::NITF::docrights;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{owner} = IMPLIED; # owner of specified rights
	$self->{_attributes}->{startdate} = IMPLIED; # start end date/time for asserted rights
	$self->{_attributes}->{enddate} = IMPLIED; # end date/time for asserted rights
	$self->{_attributes}->{agent} = IMPLIED; # rights agent
	$self->{_attributes}->{geography} = IMPLIED; # geographic area where rights are asserted
	$self->{_realname}->{locationcode} = "location-code";
	$self->{_attributes}->{"location-code"} = IMPLIED; # Coded location from standard list
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source of coded list (location?) information 
	$self->{_attributes}->{type} = IMPLIED; # Kind of rights being asserted
	$self->{_attributes}->{limitations} = IMPLIED; # Limitations associated with document rights.
}

#
# Syndication::NITF::key-list -- List of keywords
#
package Syndication::NITF::keylist;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{keyword} = ZEROORMORE;
}

#
# Syndication::NITF::keyword -- keyword/phrase
#
package Syndication::NITF::keyword;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{key} = IMPLIED; # actual keyword
}

#
# Syndication::NITF::identified-content -- Content identifiers that can apply to the whole document.
#
package Syndication::NITF::identifiedcontent;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{person} = ZEROORMORE;
	$self->{_multiElements}->{org} = ZEROORMORE;
	$self->{_multiElements}->{location} = ZEROORMORE;
	$self->{_multiElements}->{event} = ZEROORMORE;
	$self->{_multiElements}->{function} = ZEROORMORE;
	$self->{_realname}->{objecttitle} = "object.title";
	$self->{_multiElements}->{"object.title"} = ZEROORMORE;
	$self->{_multiElements}->{virtloc} = ZEROORMORE;
	$self->{_multiElements}->{classifier} = ZEROORMORE;
}

#
# Syndication::NITF::pubdata -- Metadata about this news object
#
package Syndication::NITF::pubdata;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{type} = IMPLIED; # see below
	$self->{_realname}->{itemlength} = "item-length";
	$self->{_attributes}->{"item-length"} = IMPLIED; # length of item (see also unit-of-measure)
	$self->{_realname}->{unitofmeasure} = "unit-of-measure";
	$self->{_attributes}->{"unit-of-measure"} = IMPLIED; # see below
	$self->{_realname}->{datepublication} = "date.publication";
	$self->{_attributes}->{"date.publication"} = IMPLIED; # normalised date/time object was used
	$self->{_attributes}->{name} = IMPLIED; # title of publication
	$self->{_attributes}->{issn} = IMPLIED; # issn of publication containing news item.
	$self->{_attributes}->{volume} = IMPLIED; # volume of above publication in which item occurred
	$self->{_attributes}->{number} = IMPLIED; # publication number (possibly assoc with volume number)
	$self->{_attributes}->{issue} = IMPLIED; # name of issue ("June", "Summer", "Olympic Special" etc)
	$self->{_realname}->{editionname} = "edition.name";
	$self->{_attributes}->{"edition.name"} = IMPLIED; # name of edition ("Metro", "Late" etc)
	$self->{_realname}->{editionarea} = "edition.area";
	$self->{_attributes}->{"edition.area"} = IMPLIED; # Area / zone in which news object was distributed
	$self->{_realname}->{positionsection} = "position.section";
	$self->{_attributes}->{"position.section"} = IMPLIED; # section where news object appeared (eg Business)
	$self->{_realname}->{positionsequence} = "position.sequence";
	$self->{_attributes}->{"position.sequence"} = IMPLIED; # where news object appeared (eg page number)
	$self->{_realname}->{exref} = "ex-ref";
	$self->{_attributes}->{"ex-ref"} = IMPLIED; # external reference to published news object (as a URN)
}

# attribute is an enumeration so we must handle separately
sub gettype { # transport medium
	my ($self) = @_;
	my @possiblevalues = qw(print audio video web appliance other);
	my $attr = $self->{node}->getAttributeNode("type");
	$self->{"type"} = $attr ? $attr->getValue : "";
	if ($self->{type} && grep !/$self->{type}/, "@possiblevalues") {
		croak "Illegal value ".$self->{type}." for attribute type";
	}
	return $self->{type};
}

# attribute is an enumeration so we must handle separately
sub getunitofmeasure { # measure associated with item-length
	my ($self) = @_;
	my @possiblevalues = qw(word character byte inch pica cm hour minute second other);
	my $attr = $self->{node}->getAttributeNode("unit-of-measure");
	$self->{"unit-of-measure"} = $attr ? $attr->getValue : "";
	if ($self->{"unit-of-measure"} && grep !/$self->{"unit-of-measure"}/, "@possiblevalues") {
		croak "Illegal value ".$self->{"unit-of-measure"}." for attribute unit-of-measure";
	}
	return $self->{"unit-of-measure"};
}

#
# Syndication::NITF::revision-history -- audit trail of document
#
package Syndication::NITF::revisionhistory;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{name} = IMPLIED; # person who made the revision
	$self->{_attributes}->{function} = IMPLIED; # function of named person
	$self->{_attributes}->{norm} = IMPLIED; # normalised date/time of revision
	$self->{_attributes}->{comment} = IMPLIED; # reason for the revision
}

# attribute is an enumeration so we must handle separately
sub getfunction { # function of person named in "name"
	my ($self) = @_;
	my @possiblevalues = qw( writer-author editor producer archivist videographer graphic-artist photographer statistician other);
	my $attr = $self->{"function"} = $self->{node}->getAttributeNode("function")->getValue;
	$self->{"function"} = $attr ? $attr->getValue : "";
	if ($self->{function} && grep !/$self->{function}/, "@possiblevalues") {
		croak "Illegal value ".$self->{function}." for attribute function";
	}
	return $self->{function};
}

### END OF "head" ELEMENTS ###
 
#
# Syndication::NITF::body -- body of story
#
package Syndication::NITF::body;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{bodyhead} = "body.head";
	$self->{_singleElements}->{"body.head"} = OPTIONAL;
	$self->{_realname}->{bodycontent} = "body.content";
	$self->{_multiElements}->{"body.content"} = ZEROORMORE;
	$self->{_realname}->{bodyend} = "body.end";
	$self->{_singleElements}->{"body.end"} = OPTIONAL;
}

#
# Syndication::NITF::body.head -- metadata to be displayed to the reader
#
package Syndication::NITF::bodyhead;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{hedline} = OPTIONAL; # this is not a typo!
	$self->{_multiElements}->{note} = ZEROORMORE;
	$self->{_singleElements}->{rights} = OPTIONAL;
	$self->{_multiElements}->{byline} = ZEROORMORE;
	$self->{_singleElements}->{distributor} = OPTIONAL;
	$self->{_multiElements}->{dateline} = ZEROORMORE;
	$self->{_singleElements}->{abstract} = OPTIONAL;
	$self->{_singleElements}->{series} = OPTIONAL;
}

#
# Syndication::NITF::hedline [sic] -- encapsulates headline of story
#
package Syndication::NITF::hedline;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{hl1} = REQUIRED;
	$self->{_multiElements}->{hl2} = ZEROORMORE;
}

#
# Syndication::NITF::hl1 -- main headline of story
#
package Syndication::NITF::hl1;
use Carp;
@ISA = qw( Syndication::NITF::EnrichedTextNode Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::hl2 -- "subordinate" headline of story
#
package Syndication::NITF::hl2;
use Carp;
@ISA = qw( Syndication::NITF::EnrichedTextNode Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::note -- document cautionary note
#
package Syndication::NITF::note;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{bodycontent} = "body.content";
	$self->{_multiElements}->{"body.content"} = ONEORMORE;
	$self->{_attributes}->{noteclass} = IMPLIED; # see below
	$self->{_attributes}->{type} = IMPLIED; # see below
}

# attribute is an enumeration so we must handle separately
sub getnoteclass { # category of note
	my ($self) = @_;
	my @possiblevalues = qw( cpyrt end hd editorsnote trademk undef );
	my $attr = $self->{node}->getAttributeNode("noteclass");
	return "" unless $attr;
	$self->{"noteclass"} = $attr->getValue;
	if ($self->{noteclass} && grep !/$self->{noteclass}/, "@possiblevalues") {
		croak "Illegal value ".$self->{noteclass}." for attribute noteclass";
	}
	return $self->{"noteclass"};
}

# attribute is an enumeration so we must handle separately
sub gettype { # one of standards, publishable advisory, non-publishable advisory
	my ($self) = @_;
	my @possiblevalues = qw( std pa npa );
	my $attr = $self->{node}->getAttributeNode("type");
	return "" unless $attr;
	$self->{"type"} = $attr->getValue;
	if ($self->{type} && grep !/$self->{type}/, "@possiblevalues") {
		croak "Illegal value ".$self->{type}." for attribute type";
	}
	return $self->{"type"};
}

#
# Syndication::NITF::rights -- information on rights holder
#
package Syndication::NITF::rights;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{rightsowner} = "rights.owner";
	$self->{_multiElements}->{"rights.owner"} = ZEROORMORE;
	$self->{_realname}->{rightsstartdate} = "rights.startdate";
	$self->{_multiElements}->{"rights.startdate"} = ZEROORMORE;
	$self->{_realname}->{rightsenddate} = "rights.enddate";
	$self->{_multiElements}->{"rights.enddate"} = ZEROORMORE;
	$self->{_realname}->{rightsagent} = "rights.agent";
	$self->{_multiElements}->{"rights.agent"} = ZEROORMORE;
	$self->{_realname}->{rightsgeography} = "rights.geography";
	$self->{_multiElements}->{"rights.geography"} = ZEROORMORE;
	$self->{_realname}->{rightstype} = "rights.type";
	$self->{_multiElements}->{"rights.type"} = ZEROORMORE;
	$self->{_realname}->{rightslimitations} = "rights.limitations";
	$self->{_multiElements}->{"rights.limitations"} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.owner -- owner of rights
#
package Syndication::NITF::rightsowner;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{contact} = IMPLIED; # contact information for the owner
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.startdate -- date that rights start
#
package Syndication::NITF::rightsstartdate;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # normalised date
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.enddate -- date that rights finish
#
package Syndication::NITF::rightsenddate;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # normalised date
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.agent -- agent that holds rights
#
package Syndication::NITF::rightsagent;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{contact} = IMPLIED; # contact info for agent
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.geography -- area to which rights apply
#
package Syndication::NITF::rightsgeography;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{locationcode} = "location-code";
	$self->{_attributes}->{"location-code"} = IMPLIED; # coded location from standard list
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # source for the location code (URN?)
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.type -- type of rights claimed
#
package Syndication::NITF::rightstype;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::rights.limitations -- type of rights claimed
#
package Syndication::NITF::rightslimitations;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::byline -- container for byline information
#
package Syndication::NITF::byline;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{person} = ZEROORMORE;
	$self->{_multiElements}->{byttl} = ZEROORMORE;
	$self->{_multiElements}->{location} = ZEROORMORE;
	$self->{_multiElements}->{virtloc} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::byttl -- Byline title, perhaps with organisation
#
package Syndication::NITF::byttl;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{org} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::distributor -- Information distributor
#
package Syndication::NITF::distributor;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{org} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::dateline -- Container for dateline information
#
package Syndication::NITF::dateline;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{location} = ZEROORMORE;
	$self->{_realname}->{storydate} = "story.date";
	$self->{_multiElements}->{"story.date"} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::story.date -- Date of story
#
package Syndication::NITF::storydate;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # normalised date and time
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::abstract -- Story abstact/synopsis
#
package Syndication::NITF::abstract;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::copyrite [sic] -- Container for copyright information
#
package Syndication::NITF::copyrite;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{copyriteyear} = "copyrite.year";
	$self->{_multiElements}->{"copyrite.year"} = ZEROORMORE;
	$self->{_realname}->{copyriteholder} = "copyrite.holder";
	$self->{_multiElements}->{"copyrite.holder"} = ZEROORMORE;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::copyrite.year [sic] -- Year of copyright
#
package Syndication::NITF::copyriteyear;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::copyrite.holder [sic] -- Year of copyright
#
package Syndication::NITF::copyriteholder;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::body.content -- Actual body content
#
package Syndication::NITF::bodycontent;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{block} = ZEROORMORE;
}

#
# Syndication::NITF::block -- "A group of related containers"
#
package Syndication::NITF::block;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
	# block.start entity (didn't make into a Node as it's only used once)
	$self->{_singleElements}->{tobject} = OPTIONAL;
	$self->{_realname}->{keylist} = "key-list";
	$self->{_singleElements}->{"key-list"} = OPTIONAL;
	$self->{_multiElements}->{classifier} = ZEROORMORE;
	$self->{_singleElements}->{byline} = OPTIONAL;
	$self->{_singleElements}->{dateline} = OPTIONAL;
	$self->{_singleElements}->{copyrite} = OPTIONAL;
	$self->{_singleElements}->{abstract} = OPTIONAL;
	$self->{_multiElements}->{block} = ZEROORMORE;
	# block.content entity included with BlockContentNode
	# block.end entity
	$self->{_singleElements}->{datasource} = OPTIONAL;
}

#
# Syndication::NITF::p -- Paragraph
#
package Syndication::NITF::p;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{lede} = IMPLIED; # [sic] indicates "lead" paragraph
	$self->{_attributes}->{summary} = IMPLIED;
	$self->{_realname}->{optionaltext} = "optional-text";
	$self->{_attributes}->{"optional-text"} = IMPLIED;
}

# really need a "boolean" type, but...
sub getlede {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("lede");
    $self->{"lede"} = $attr ? $attr->getValue : 'no';
}

sub getsummary {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("summary");
    $self->{"summary"} = $attr ? $attr->getValue : 'no';
}

sub getoptionaltext {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("optional-text");
    $self->{"optional-text"} = $attr ? $attr->getValue : 'no';
}

#
# Syndication::NITF::table -- table
#
package Syndication::NITF::table;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{caption} = OPTIONAL;
	$self->{_multiElements}->{col} = ZEROORMORE;
	$self->{_multiElements}->{colgroup} = ZEROORMORE;
	$self->{_singleElements}->{thead} = OPTIONAL;
	$self->{_singleElements}->{tfoot} = OPTIONAL;
	$self->{_multiElements}->{tbody} = ZEROORMORE; 
	$self->{_multiElements}->{tr} = ZEROORMORE; 
	$self->{_attributes}->{tabletype} = IMPLIED; # holds style information
	$self->{_attributes}->{align} = IMPLIED; # left | center | right
	$self->{_attributes}->{width} = IMPLIED; # width
	$self->{_attributes}->{cols} = IMPLIED; # number of columns
	$self->{_attributes}->{border} = IMPLIED; # style information
	$self->{_attributes}->{frame} = IMPLIED; # void | above | below | hsides | lhs | rhs | vsides | box | border
	$self->{_attributes}->{rules} = IMPLIED; # none | basic | rows | cols | all
	$self->{_attributes}->{cellspacing} = IMPLIED; # no of pixels between cells
	$self->{_attributes}->{cellpadding} = IMPLIED; # no of pixels between cell border and contents
}

#
# Syndication::NITF::media -- Year of copyright
#
package Syndication::NITF::media;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{mediametadata} = "media-metadata";
	$self->{_multiElements}->{"media-metadata"} = ZEROORMORE;
	$self->{_realname}->{mediareference} = "media-reference";
	$self->{_multiElements}->{"media-reference"} = ONEORMORE;
	$self->{_realname}->{mediaobject} = "media-object";
	$self->{_multiElements}->{"media-object"} = ZEROORMORE;
	$self->{_realname}->{mediacaption} = "media-caption";
	$self->{_multiElements}->{"media-caption"} = ZEROORMORE;
	$self->{_realname}->{mediaproducer} = "media-producer";
	$self->{_singleElements}->{"media-producer"} = OPTIONAL;
	$self->{_realname}->{mediatype} = "media-type";
	$self->{_attributes}->{"media-type"} = IMPLIED; # see below
}

# attribute is an enumeration so we must handle separately
sub getmediatype {
	my ($self) = @_;
	my @possiblevalues = qw( text audio image video data application other );
	my $attr = $self->{node}->getAttributeNode("media-type");
	$self->{"media-type"} = $attr ? $attr->getValue : "";
	if ($self->{"media-type"} && (grep !/$self->{"media-type"}/, "@possiblevalues")) {
		croak "Illegal value ".$self->{"media-type"}." for attribute media-type";
	}
	return $self->{"media-type"};
}

#
# Syndication::NITF::media-reference -- Media reference
#
package Syndication::NITF::mediareference;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
	$self->{_attributes}->{source} = IMPLIED; # URL of external media file
	$self->{_attributes}->{name} = IMPLIED; # Alternate name or description
	$self->{_realname}->{mimetype} = "mime-type";
	$self->{_attributes}->{"mime-type"} = REQUIRED; # Mime type of external file
	$self->{_attributes}->{coding} = IMPLIED; # How info is coded
	$self->{_attributes}->{time} = IMPLIED; # length of media
	$self->{_realname}->{timeunitofmeasure} = "time-unit-of-measure";
	$self->{_attributes}->{"time-unit-of-measure"} = IMPLIED; # unit of length
	$self->{_attributes}->{outcue} = IMPLIED; # spoken information that ends an audio clip
	$self->{_realname}->{sourcecredit} = "source-credit";
	$self->{_attributes}->{"source-credit"} = IMPLIED; # source-credit
	$self->{_attributes}->{copyright} = IMPLIED; # copyright owner
	$self->{_realname}->{alternatetext} = "alternate-text";
	$self->{_attributes}->{"alternate-text"} = IMPLIED; # Plain-text substitute text
	$self->{_attributes}->{height} = IMPLIED; # height of media object
	$self->{_attributes}->{width} = IMPLIED; # width of media object
	$self->{_attributes}->{units} = IMPLIED; # units of height and width (default pixels)
	$self->{_attributes}->{imagemap} = IMPLIED; # whether object has an imagemap
	$self->{_attributes}->{noflow} = IMPLIED; # can informatino flow around figure
}

sub getunits {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("units");
    $self->{"units"} = $attr ? $attr->getValue : 'pixels';
}

sub getnoflow {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("noflow");
    $self->{"noflow"} = $attr ? $attr->getValue : 'no';
}

#
# Syndication::NITF::media-metadata -- Media reference
#
package Syndication::NITF::mediametadata;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{name} = REQUIRED; # name of meta item
	$self->{_attributes}->{value} = IMPLIED; # value of meta item
}

#
# Syndication::NITF::media-object -- Media object (eg clip) may be encoded binary.
#
package Syndication::NITF::mediaobject;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
	$self->{_attributes}->{encoding} = REQUIRED; # format of encoded data
}

#
# Syndication::NITF::media-caption -- (Publishable) Text describing media
#
package Syndication::NITF::mediacaption;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::media-producer -- Byline of media producer
#
package Syndication::NITF::mediaproducer;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::ol -- HTML-style ordered list
#
package Syndication::NITF::ol;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{li} = ONEORMORE; # list elements
	$self->{_attributes}->{seqnum} = IMPLIED; # sequence number
}

#
# Syndication::NITF::ul -- HTML-style unordered list
#
package Syndication::NITF::ul;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{li} = ONEORMORE; # list elements
}

#
# Syndication::NITF::li -- list item
#
package Syndication::NITF::li;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::dl -- definition list
#
package Syndication::NITF::dl;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{dt} = ZEROORMORE; # definition term
	$self->{_multiElements}->{dd} = ZEROORMORE; # definition data
}

#
# Syndication::NITF::dt -- definition term
#
package Syndication::NITF::dt;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::dd -- definition data
#
package Syndication::NITF::dd;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{block} = ZEROORMORE; # content
}

#
# Syndication::NITF::bq -- blockquote
#
package Syndication::NITF::bq;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{block} = ZEROORMORE; #
	$self->{_multiElements}->{credit} = ZEROORMORE; # 
	$self->{_attributes}->{nowrap} = IMPLIED; # content
	$self->{_realname}->{quotesource} = "quote-source";
	$self->{_attributes}->{"quote-source"} = IMPLIED; # content
}

# hmm this is actually supposed to be "if this attr exists, the value must be "nowrap"
# which isn't quite what this code does
sub getnowrap {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("nowrap");
    $self->{"nowrap"} = $attr ? $attr->getValue : 'nowrap';
}

#
# Syndication::NITF::credit -- source of a block quote
#
package Syndication::NITF::credit;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::fn -- footnote
#
package Syndication::NITF::fn;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::BodyContentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::pre -- HTML-style preformatted text
#
package Syndication::NITF::pre;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::hr -- HTML-style horizontal rule
#
package Syndication::NITF::hr;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::datasource -- Source of info in a block element
#
package Syndication::NITF::datasource;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

### table elements ###

# nodes for table elements, used several times

#
# Syndication::NITF::CellAlignNode -- attributes for cell alignment
#
package Syndication::NITF::CellAlignNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{align} = IMPLIED;
	$self->{_attributes}->{char} = IMPLIED;
	$self->{_attributes}->{charoff} = IMPLIED;
}

# attribute is an enumeration so we must handle separately
sub getalign {
	my ($self) = @_;
	my @possiblevalues = qw( left center right justify char );
	my $attr = $self->{node}->getAttributeNode("align");
	$self->{"align"} = $attr ? $attr->getValue : "";
	if ($self->{align} && grep !/$self->{align}/, "@possiblevalues") {
		croak "Illegal value ".$self->{align}." for attribute align";
	}
	return $self->{"align"};
}

#
# Syndication::NITF::CellVAlignNode -- attributes for vertical cell alignment
#
package Syndication::NITF::CellVAlignNode;
use Carp;
@ISA = qw( Syndication::NITF::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{valign} = IMPLIED;
}

# attribute is an enumeration so we must handle separately
sub getvalign {
	my ($self) = @_;
	my @possiblevalues = qw( top middle bottom baseline );
	my $attr = $self->{node}->getAttributeNode("valign");
	$self->{"valign"} = $attr ? $attr->getValue : "";
	if ($self->{valign} && grep !/$self->{valign}/, "@possiblevalues") {
		croak "Illegal value ".$self->{valign}." for attribute valign";
	}
	return $self->{"valign"};
}

#
# Syndication::NITF::caption -- Text for the caption of a table
#
package Syndication::NITF::caption;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode Syndication::NITF::BlockContentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{align} = IMPLIED; # alignment of caption in table
}

# attribute is an enumeration so we must handle separately
sub getalign {
	my ($self) = @_;
	my @possiblevalues = qw( top bottom left right );
	my $attr = $self->{node}->getAttributeNode("align");
	$self->{"align"} = $attr ? $attr->getValue : "";
	if ($self->{align} && grep !/$self->{align}/, "@possiblevalues") {
		croak "Illegal value ".$self->{align}." for attribute align";
	}
	return $self->{"align"};
}

#
# Syndication::NITF::col -- Formatting for a table column
#
package Syndication::NITF::col;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{span} = IMPLIED; # how many cells wide this column should be
	$self->{_attributes}->{width} = IMPLIED; # width of column in pixels
}

# default value of 1
sub getspan {
    my ($self) = @_;
    my $attr = $self->{span}->getAttributeNode("span");
    $self->{"span"} = $attr ? $attr->getValue : '1';
}

#
# Syndication::NITF::colgroup -- Column group
#
package Syndication::NITF::colgroup;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{col} = ONEORMORE;
}

#
# Syndication::NITF::thead -- Table heading
#
package Syndication::NITF::thead;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{tr} = ONEORMORE;
}

#
# Syndication::NITF::tbody -- Table body
#
package Syndication::NITF::tbody;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{tr} = ONEORMORE;
}

#
# Syndication::NITF::tfoot -- Table footer
#
package Syndication::NITF::tfoot;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{tr} = ONEORMORE;
}

#
# Syndication::NITF::tr -- Table row
#
package Syndication::NITF::tr;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{th} = ZEROORMORE;
	$self->{_multiElements}->{td} = ZEROORMORE;
}

#
# Syndication::NITF::th -- Table header cell
#
package Syndication::NITF::th;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode Syndication::NITF::BlockContentNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{axis} = IMPLIED; # HTML formatting attribute (???)
	$self->{_attributes}->{axes} = IMPLIED; # HTML formatting attribute (???)
	$self->{_attributes}->{nowrap} = IMPLIED; # Directive not to wrap text in cell
	$self->{_attributes}->{rowspan} = IMPLIED; # Number of horizontal rows to span
	$self->{_attributes}->{colspan} = IMPLIED; # Number of vertical columns to span
}

# the rule here is "if this attr exists, the value must be "nowrap"
sub getnowrap {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("nowrap");
    croak "Illegal value for attribute nowrap" if ($attr && $attr->getValue ne "nowrap");
    $self->{"nowrap"} = $attr ? $attr->getValue : undef;
}

# handle default value
sub getrowspan {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("rowspan");
    $self->{"rowspan"} = $attr ? $attr->getValue : "1";
}

# handle default value
sub getcolspan {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("colspan");
    $self->{"colspan"} = $attr ? $attr->getValue : "1";
}

#
# Syndication::NITF::td -- Table data cell
#
package Syndication::NITF::td;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode Syndication::NITF::BlockContentNode Syndication::NITF::CellAlignNode Syndication::NITF::CellVAlignNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{axis} = IMPLIED; # HTML formatting attribute (???)
	$self->{_attributes}->{axes} = IMPLIED; # HTML formatting attribute (???)
	$self->{_attributes}->{nowrap} = IMPLIED; # Directive not to wrap text in cell
	$self->{_attributes}->{rowspan} = IMPLIED; # Number of horizontal rows to span
	$self->{_attributes}->{colspan} = IMPLIED; # Number of vertical columns to span
}

# the rule here is "if this attr exists, the value must be "nowrap"
sub getnowrap {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("nowrap");
    croak "Illegal value for attribute nowrap" if ($attr && $attr->getValue ne "nowrap");
    $self->{"nowrap"} = $attr ? $attr->getValue : undef;
}

# handle default value
sub getrowspan {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("rowspan");
    $self->{"rowspan"} = $attr ? $attr->getValue : "1";
}

# handle default value
sub getcolspan {
    my ($self) = @_;
    my $attr = $self->{node}->getAttributeNode("colspan");
    $self->{"colspan"} = $attr ? $attr->getValue : "1";
}

### Text elements ###

#
# Syndication::NITF::chron -- Date and time
#
package Syndication::NITF::chron;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{norm} = IMPLIED; # normalised date and time
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::event -- An event considered newsworthy
#
package Syndication::NITF::event;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{startdate} = "start-date";
	$self->{_attributes}->{"start-date"} = IMPLIED; # ISO Date
	$self->{_realname}->{enddate} = "end-date";
	$self->{_attributes}->{"end-date"} = IMPLIED; # ISO Date
	$self->{_attributes}->{idsrc} = IMPLIED; # Source (taxonomy) for value attribute
	$self->{_attributes}->{value} = IMPLIED; # ID Code or symbol for the element
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::function -- Role played by a person
#
package Syndication::NITF::function;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{idsrc} = IMPLIED; # Source (taxonomy) for value attribute
	$self->{_attributes}->{value} = IMPLIED; # ID Code or symbol for the element
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::location -- Significant place mentioned in an article
#
package Syndication::NITF::location;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{sublocation} = ZEROORMORE;
	$self->{_multiElements}->{city} = ZEROORMORE;
	$self->{_multiElements}->{state} = ZEROORMORE;
	$self->{_multiElements}->{region} = ZEROORMORE;
	$self->{_multiElements}->{country} = ZEROORMORE;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{locationcode} = "location-code";
	$self->{_attributes}->{"location-code"} = IMPLIED; # ID of location
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source (taxonomy) for location-code attribute
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::sublocation -- Named region within city or state
#
package Syndication::NITF::sublocation;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{locationcode} = "location-code";
	$self->{_attributes}->{"location-code"} = IMPLIED; # ID of location
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source (taxonomy) for location-code attribute
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::city -- City, town, village, etc
#
package Syndication::NITF::city;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{citycode} = "city-code";
	$self->{_attributes}->{"city-code"} = IMPLIED; # ID of location
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source (taxonomy) for location-code attribute
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::state -- State, province, region
#
package Syndication::NITF::state;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{statecode} = "state-code";
	$self->{_attributes}->{"state-code"} = IMPLIED; # ID of location
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source (taxonomy) for location-code attribute
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::region -- Geographic area
#
package Syndication::NITF::region;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{regioncode} = "region-code";
	$self->{_attributes}->{"region-code"} = IMPLIED; # ID of location
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source (taxonomy) for location-code attribute
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::country -- Geographic area with a government
#
package Syndication::NITF::country;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_realname}->{isocc} = "iso-cc";
	$self->{_attributes}->{"iso-cc"} = IMPLIED; # ISO 3166 country code
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::money -- Monetary item
#
package Syndication::NITF::money;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{unit} = IMPLIED; # Currency used (source taxonomy??)
	$self->{_attributes}->{date} = IMPLIED; # ISO date for currency value quote
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::num -- Numeric data (used to normalise numbers)
#
package Syndication::NITF::num;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{frac} = ZEROORMORE;
	$self->{_multiElements}->{sub} = ZEROORMORE;
	$self->{_multiElements}->{sup} = ZEROORMORE;
	$self->{_attributes}->{units} = IMPLIED; # Units the number is in
	$self->{_realname}->{decimalch} = "decimal-ch";
	$self->{_attributes}->{"decimal-ch"} = IMPLIED; # character used to separate decimal portion
	$self->{_realname}->{thousandsch} = "thousands-ch";
	$self->{_attributes}->{"thousands-ch"} = IMPLIED; # character used to separate thousands groups
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::frac -- fraction
#
package Syndication::NITF::frac;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{numer} = ZEROORMORE;
	$self->{_realname}->{fracsep} = "frac-sep";
	$self->{_multiElements}->{"frac-sep"} = OPTIONAL;
	$self->{_multiElements}->{denom} = ZEROORMORE;
}

#
# Syndication::NITF::numer -- Numerator of a fraction
#
package Syndication::NITF::numer;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}


#
# Syndication::NITF::frac-sep -- Separator of a fraction
#
package Syndication::NITF::fracsep;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::denom -- Denominator of a fraction
#
package Syndication::NITF::denom;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::sub -- Subscript
#
package Syndication::NITF::sub;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::sup -- Superscript
#
package Syndication::NITF::sup;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::object.title -- title of inline object (song, book etc)
#
package Syndication::NITF::objecttitle;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy of identifying code
	$self->{_attributes}->{value} = IMPLIED; # identifying code
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::org -- organisation (public, private, non-profit)
#
package Syndication::NITF::org;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy of identifying code
	$self->{_attributes}->{value} = IMPLIED; # identifying code
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::alt-code -- alternative identifying code for an item
#
package Syndication::NITF::altcode;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy of identifying code
	$self->{_attributes}->{value} = IMPLIED; # identifying code
}

#
# Syndication::NITF::person -- a human individual
#
package Syndication::NITF::person;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{namegiven} = "name.given";
	$self->{_multiElements}->{"name.given"} = ZEROORMORE;
	$self->{_realname}->{namefamily} = "name.family";
	$self->{_multiElements}->{"name.family"} = ZEROORMORE;
	$self->{_multiElements}->{function} = ZEROORMORE;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy of identifying code
	$self->{_attributes}->{value} = IMPLIED; # identifying code
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::name.given -- person's given (Western, first) name
#
package Syndication::NITF::namegiven;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::name.family -- person's family (Western, last) name
#
package Syndication::NITF::namefamily;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::postaddr -- postal address
#
package Syndication::NITF::postaddr;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{addressee} = REQUIRED;
	$self->{_realname}->{deliverypoint} = "delivery.point";
	$self->{_singleElements}->{"delivery.point"} = OPTIONAL;
	$self->{_multiElements}->{postcode} = ZEROORMORE;
	$self->{_realname}->{deliveryoffice} = "delivery.office";
	$self->{_multiElements}->{"delivery.office"} = ZEROORMORE;
	$self->{_multiElements}->{region} = ZEROORMORE;
	$self->{_multiElements}->{country} = ZEROORMORE;
}

#
# Syndication::NITF::virtloc -- virtual location
#
package Syndication::NITF::virtloc;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy of identifying code
	$self->{_attributes}->{value} = IMPLIED; # identifying code
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::a -- HTML-like anchor
#
package Syndication::NITF::a;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{href} = IMPLIED; # URL
	$self->{_attributes}->{name} = IMPLIED; # Alternate name for link
	$self->{_attributes}->{rel} = IMPLIED; # describes relationship from source to target
	$self->{_attributes}->{rev} = IMPLIED; # describe relationship from target to source
	$self->{_attributes}->{title} = IMPLIED; # title of document to be linked to
}

#
# Syndication::NITF::br -- HTML-style line break
#
package Syndication::NITF::br;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::em -- HTML-like emphasis
#
package Syndication::NITF::em;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::lang -- Language identifier
#
package Syndication::NITF::lang;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NITF::pronounce -- Pronunciation information
#
package Syndication::NITF::pronounce;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{guide} = IMPLIED; # Source used to create pronunciation
	$self->{_attributes}->{phonetic} = IMPLIED; # Phonetic pronunciation of a phrase
}

#
# Syndication::NITF::q -- quotation
#
package Syndication::NITF::q;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{quotesource} = "quote-source";
	$self->{_attributes}->{"quote-source"} = IMPLIED; # who said or wrote the quotation
}

### postaddr elements ###

#
# Syndication::NITF::addressee -- recipient of a postal item (used in postal address)
#
package Syndication::NITF::addressee;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{person} = REQUIRED;
	$self->{_singleElements}->{function} = OPTIONAL;
	$self->{_realname}->{careof} = "care.of";
	$self->{_singleElements}->{"care.of"} = OPTIONAL;
}

#
# Syndication::NITF::care.of -- Poste restante
#
package Syndication::NITF::careof;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::delivery.point -- street / po box no
#
package Syndication::NITF::deliverypoint;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{br} = ZEROORMORE;
	$self->{_realname}->{pointcode} = "point-code";
	$self->{_attributes}->{"point-code"} = IMPLIED; # Coded location for a delivery point
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source of coded list information
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::postcode -- postal/zip code
#
package Syndication::NITF::postcode;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source of coded list information
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::delivery.office -- city or town where post office is located
#
package Syndication::NITF::deliveryoffice;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{br} = ZEROORMORE;
	$self->{_realname}->{officecode} = "office-code";
	$self->{_attributes}->{"office-code"} = IMPLIED; # Coded location for a delivery office
	$self->{_realname}->{codesource} = "code-source";
	$self->{_attributes}->{"code-source"} = IMPLIED; # Source of coded list information
	$self->{_hasText} = 1;
}

### body end ###

#
# Syndication::NITF::body.end -- information at end of article body
#
package Syndication::NITF::bodyend;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}->{tagline} = OPTIONAL;
	$self->{_singleElements}->{bibliography} = OPTIONAL;
}

#
# Syndication::NITF::tagline -- Byline at the end of a story
#
package Syndication::NITF::tagline;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode Syndication::NITF::EnrichedTextNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{type} = IMPLIED; # type of notice
}

# attribute is an enumeration so we must handle separately
sub gettype {
	my ($self) = @_;
	my @possiblevalues = qw( std pa npa ); # standard, publishable advisory, non-publishable advisory
	my $attr = $self->{node}->getAttributeNode("type");
	$self->{"type"} = $attr ? $attr->getValue : "";
	if ($self->{type} && grep !/$self->{type}/, "@possiblevalues") {
		croak "Illegal value ".$self->{type}." for attribute type";
	}
	return $self->{"type"};
}

#
# Syndication::NITF::bibliography -- Free-form bibliographic data
#
package Syndication::NITF::bibliography;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::classifier -- Generic container for metadata
#
package Syndication::NITF::classifier;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{altcode} = "alt-code";
	$self->{_multiElements}->{"alt-code"} = ZEROORMORE;
	$self->{_attributes}->{type} = IMPLIED; # type of classifier (eg concept)
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy for the element's value
	$self->{_attributes}->{value} = IMPLIED; # the value itself
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::nitf-table -- Holder for a table and metadata
#
package Syndication::NITF::nitftable;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{nitftablemetadata} = "nitf-table-metadata";
	$self->{_singleElements}->{"nitf-table-metadata"} = REQUIRED;
	$self->{_singleElements}->{table} = OPTIONAL;
	$self->{_realname}->{customtable} = "custom-table";
	$self->{_singleElements}->{"custom-table"} = OPTIONAL;
	$self->{_realname}->{tablereference} = "table-reference";
	$self->{_multiElements}->{"table-reference"} = ZEROORMORE;
}

# return how many columns this table contains. Try a number of methods to work it out.
sub getColumnCount {
	my ($self) = @_;
	# if the column count is given in the metadata, let's believe it
	my $count = 0;
	$count = $self->getnitftablemetadata->getcolumncount;
	if (!$count) {
		foreach my $coltag ($self->getnitftablemetadata->{node}->getElementsByTagName("nitf-col", 0)) {
			$count += $coltag->getAttributeNode("occurrences")
				? $coltag->getAttributeNode("occurrences")->getValue
				: 1;
		}
		foreach my $colgrouptag ($self->getnitftablemetadata->{node}->getElementsByTagName("nitf-colgroup", 0)) {
			my $occurrences = $colgrouptag->getAttributeNode("occurrences")->getValue
				if $colgrouptag->getAttributeNode("occurrences");
			my $subcount = 0;
			foreach my $coltag ($colgrouptag->getElementsByTagName("nitf-col", 0)) {
				$subcount += $coltag->getAttributeNode("occurrences")
					? $coltag->getAttributeNode("occurrences")->getValue
					: 1;
			}
			$count += $subcount * $occurrences;
		}
	}
	return $count;
}

# return how many rows this table contains. Try a number of methods to work it out.
sub getRowCount {
	my ($self) = @_;
	# if the rows count is given in the metadata, let's believe it
	my $count = 0;
	$count = $self->getnitftablemetadata->getrowcount;
	# otherwise do a simple count of all the <tr> elements in the main table
	if (!$count) {
		foreach my $rowtag ($self->gettable->{node}->getElementsByTagName("tr", 0)) {
			$count += 1;
		}
	}
	return $count;
}

#
# Syndication::NITF::custom-table -- holder for a namespaced XML fragment for custom-tagged metadata
#
package Syndication::NITF::customtable;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NITF::table-reference -- pointer to a table elsewhere in the document
#
package Syndication::NITF::tablereference;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{idref} = REQUIRED; # ID for referenced table
}

#
# Syndication::NITF::nitf-table-metadata -- holder for namespaced XML fragment for custom-tagged metadata
#
package Syndication::NITF::nitftablemetadata;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{nitftablesummary} = "nitf-table-summary";
	$self->{_singleElements}->{"nitf-table-summary"} = OPTIONAL;
	$self->{_realname}->{nitfcolgroup} = "nitf-colgroup";
	$self->{_multiElements}->{"nitf-colgroup"} = ZEROORMORE;
	$self->{_realname}->{nitfcol} = "nitf-col";
	$self->{_multiElements}->{"nitf-col"} = ZEROORMORE;
	$self->{_attributes}->{subclass} = IMPLIED; # further refinement of class attribute (see CommonAttributes)
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy used for referenced value
	$self->{_attributes}->{value} = IMPLIED; # actual value
	$self->{_attributes}->{status} = IMPLIED; # see below
	$self->{_realname}->{columncount} = "column-count";
	$self->{_attributes}->{"column-count"} = IMPLIED; #  Num of columns in entire table
	$self->{_realname}->{rowcount} = "row-count";
	$self->{_attributes}->{"row-count"} = IMPLIED; #  Num of rows in entire table
}

# attribute is an enumeration so we must handle separately
sub getstatus {
	my ($self) = @_;
	my @possiblevalues = qw( pre snap-shot interim final official );
	my $attr = $self->{node}->getAttributeNode("status");
	$self->{"status"} = $attr ? $attr->getValue : "";
	if ($self->{status} && grep !/$self->{status}/, "@possiblevalues") {
		croak "Illegal value ".$self->{status}." for attribute status";
	}
	return $self->{"status"};
}

#
# Syndication::NITF::nitf-table-summary -- Textual description of the table
#
package Syndication::NITF::nitftablesummary;
use Carp;
@ISA = qw( Syndication::NITF::CommonAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}->{p} = ZEROORMORE; # paragraphs
}

#
# Syndication::NITF::nitf-colgroup -- Collection of nitf-col elements
#
package Syndication::NITF::nitfcolgroup;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_realname}->{nitfcol} = "nitf-col";
	$self->{_multiElements}->{"nitf-col"} = ONEORMORE;
	$self->{_attributes}->{occurrences} = IMPLIED; # Count. Default is 1 (but not written into DTD?)
}

#
# Syndication::NITF::nitf-col -- Holder for namespaced XML fragment for custom-tagged data
#
package Syndication::NITF::nitfcol;
use Carp;
@ISA = qw( Syndication::NITF::GlobalAttributesNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{order} = IMPLIED; # position of column within table (means metadata may be out of order)
	$self->{_attributes}->{idsrc} = IMPLIED; # taxonomy for the value attribute
	$self->{_attributes}->{value} = IMPLIED; # the value itself
	$self->{_attributes}->{occurrences} = IMPLIED; # number of occurrences (default 1)
	$self->{_realname}->{datatype} = "data-type";
	$self->{_attributes}->{"data-type"} = IMPLIED; # general type of data in the column
	$self->{_realname}->{dataformat} = "data-format";
	$self->{_attributes}->{"data-format"} = IMPLIED; # expanded definition of the data
}

# attribute is an enumeration so we must handle separately
sub getdatatype {
	my ($self) = @_;
	my @possiblevalues = qw( text number graphic other );
	my $attr = $self->{node}->getAttributeNode("data-type");
	$self->{"data-type"} = $attr ? $attr->getValue : "";
	if ($self->{"data-type"} && grep !/$self->{"data-type"}/, "@possiblevalues") {
		croak "Illegal value ".$self->{"data-type"}." for attribute data-type";
	}
	return $self->{"data-type"};
}

