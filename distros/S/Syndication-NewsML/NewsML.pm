# $Id: NewsML.pm,v 0.10 2002/02/13 14:01:18 brendan Exp $
# Syndication::NewsML.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.10 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:01:18 $ =~ m# (.*) $# );

$DEBUG = 1;

use NewsML::Node;
use NewsML::IdNode;
use NewsML::AssignmentNode;
use NewsML::CatalogNode;
use NewsML::CommentNode;
use NewsML::DataNode;
use NewsML::DateNode;
use NewsML::DOMUtils;
use NewsML::FormalNameNode;
use NewsML::OriginNode;
use NewsML::PartyNode;
use NewsML::PropertyNode;
use NewsML::References;
use NewsML::TopicNode;
use NewsML::TopicSetNode;
use NewsML::XmlLangNode;

use XML::DOM;

#
# Syndication::NewsML -- initial parser. Maybe this should be Syndication::NewsML::Parser or something?
# also grabs the first NewsML element to save time, is that a good idea?
# does it mean that you can't grab extra namespace/DTD declarations etc?
#
package Syndication::NewsML;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::TopicSetNode );

sub _init {
	my ($self, $filename) = @_;

	$self->{parser} = new XML::DOM::Parser;
	$self->{doc} = $self->{parser}->parsefile($filename);
	$self->{node} = $self->{doc}->getElementsByTagName("NewsML", 0)->item(0);

	$self->{_singleElements}{NewsEnvelope} = REQUIRED;
	$self->{_multiElements}{NewsItem} = ONEORMORE;

	return $self;
}

=pod

=head1 NAME

Syndication::NewsML -- Parser for NewsML documents

=head1 VERSION

Version $Revision: 0.10 $, released $Date: 2002/02/13 14:01:18 $

=head1 SYNOPSIS

 use Syndication::NewsML;

 my $newsml = new Syndication::NewsML("myNewsMLfile.xml");
 my $env = $newsml->getNewsEnvelope;

 my $dateAndTime = $env->getDateAndTime->getText;

 foreach my $newsitem ($newsml->getNewsItemList) {
   # do something with the news item
 }
 ...

=head1 DESCRIPTION

B<Syndication::NewsML> parses XML files complying to the NewsML specification, created by the International
Press Telecommunications Council (http://www.iptc.org).

NewsML is a standard format for the markup of multimedia news content.
According to the newsml.org website, NewsML is
"An XML-based standard to represent and manage news throughout its lifecycle, including production,
interchange, and consumer use."

NewsML differs from simpler news markup and syndication standards such as RSS (see the XML::RSS module
on your local CPAN) in that RSS files contain B<links> to stories, whereas NewsML can be used to send
links or the story itself, plus any associated information such as images, video or audio files, PDF
documents, or any other type of data.

NewsML also offers much more metadata information than RSS, including links between associated content;
the ability to revoke, update or modify previously sent stories; support for sending the same story in
multiple languages and/or formats; and a method for user-defined metadata known as Topic Sets.

Theoretically you could use RSS to link to articles created in NewsML, although in reality news
providers and syndicators are more likely to use a more robust and traceable syndication transport
protocol such as ICE (see http://www.icestandard.org).

Syndication::NewsML is an object-oriented Perl interface to NewsML documents. It aims to let users manage
and create NewsML documents without any specialised NewsML or XML knowledge.

=head2 Initialization

At the moment the constructor can only take a filename as an argument, as follows:

  my $newsml = new Syndication::NewsML("file-to-parse.xml");

This attaches a parser to the file (using XML::DOM), and returns a reference to the first NewsML
tag. (I may decide that this is a bad idea and change it soon)

=head2 Reading objects

There are six main types of calls:

=over 4

=item *

Return a reference to an array of elements:

  my $topicsets = $newsml->getTopicSetList;

The array can be referenced as @$topicsets, or an individual element can be referenced as $topicsets->[N].

=item *

Return an actual array of elements:

  my @topicsets = $newsml->getTopicSetList;

The array can be referenced as @topicsets, or an individual element can be referenced as $topicsets[N].
In addition you can iterate through an array by saying something like

  foreach my $topicset ($newsml->getTopicSetList) {
    ...
  }

=item *

Return the size of a list of elements:

  my $topicsetcount = $newsml->getTopicSetCount;

=item *

Get an individual element:

  my $catalog = $topicsets->[0]->getCatalog;

=item *

Get an attribute of an element (as text):

  my $href = $catalog->getHref;

=item *

Get the contents of an element (ie the text between the opening and closing tags):

  my $urlnode = $catalog->getResourceList->[0]->getUrlList->[0];
  my $urltext = $urlnode->getText;

=back

Not all of these calls work for all elements: for example, if an element is defined in the NewsML DTD
as having zero or one instances in its parent element, and you try to call getXXXList, B<Syndication::NewsML>
will "croak" an error. Similarly when you call getXXX when the DTD specifies that an element can exist
more than once in that context, NewsML.pm will flag an error to the effect that you should be calling
getXXXList instead. (The error handling will be improved in the future so that it won't croak
fatally -- unless you want that to happen.)

The NewsML standard contains some "business rules" also written into the DTD: for example, a NewsItem
may contain nothing, a NewsComponent, one or more Update elements, or a TopicSet. For some of these
rules, the module is smart enough to detect errors and provide a warning. Again, these warnings will
be improved and extended in future versions of this module.

=head2 Documentation for all the classes

Each NewsML element is represented as a class. This means that you can traverse documents as Perl
objects, as seen above.

Full documentation of which classes can be used in which documents is beyond me right now (with over
120 classes to document), so for now you'll have to work with the examples in the B<examples/> and
B<t/> directories to see what's going on. You should be able to get a handle on it fairly quickly.

The real problem is that it's hard to know when to use B<getXXX()> and when to use B<GetXXXList()>
-- that is, when an element can have more than one entry and when it is a singleton. Quite often it
isn't obvious from looking at a NewsML document. For now, two ways to work this out are to try it and see
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

L<XML::DOM>, L<XML::RSS>, L<XML::XPath>, L<Syndication::NITF>

=head1 AUTHOR

Brendan Quinn, Clueful Consulting Pty Ltd
(brendan@clueful.com.au)

=head1 COPYRIGHT

Copyright (c) 2001, 2002, Brendan Quinn. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut

#
# Syndication::NewsML::Comment -- the actual comment
#
package Syndication::NewsML::Comment;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{TranslationOf} = IMPLIED;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::Catalog -- a container for Resource and TopicUse elements
#
package Syndication::NewsML::Catalog;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	# Child elements
	$self->{_multiElements}->{Resource} = ZEROORMORE;
	$self->{_multiElements}->{TopicUse} = ZEROORMORE;
	$self->{_attributes}->{Href} = IMPLIED;
}

#
# Syndication::NewsML::TransmissionId -- 
#
package Syndication::NewsML::TransmissionId;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}->{Repeat} = IMPLIED;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::Update -- modification to an existing NewsItem
#
package Syndication::NewsML::Update;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_multiElements}{InsertBefore} = ZEROORMORE;
	$self->{_multiElements}{InsertAfter} = ZEROORMORE;
	$self->{_multiElements}{Replace} = ZEROORMORE;
	$self->{_multiElements}{Delete} = ZEROORMORE;
}

#
# Syndication::NewsML::Delete -- instruction to delete an element in a NewsItem
#
package Syndication::NewsML::Delete;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_attributes}{DuidRef} = REQUIRED;
}

#
# Syndication::NewsML::DerivedFrom
#
package Syndication::NewsML::DerivedFrom;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_attributes}{NewsItem} = IMPLIED;
}

#
# Syndication::NewsML::AssociatedWith -- reference to associated NewsItem
#
package Syndication::NewsML::AssociatedWith;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_attributes}{NewsItem} = IMPLIED;
}

#
# Syndication::NewsML::UsageRights -- usage rights for a NewsComponent
#
package Syndication::NewsML::UsageRights;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_singleElements}{UsageType} = OPTIONAL;
	$self->{_singleElements}{Geography} = OPTIONAL;
	$self->{_singleElements}{RightsHolder} = OPTIONAL;
	$self->{_singleElements}{Limitations} = OPTIONAL;
	$self->{_singleElements}{StartDate} = OPTIONAL;
	$self->{_singleElements}{EndDate} = OPTIONAL;
}

#
# Syndication::NewsML::UsageType -- type of usage to which the rights apply
#
package Syndication::NewsML::UsageType;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::AssignmentNode Syndication::NewsML::XmlLangNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::TopicUse -- indication of where topic is used in the document
#
package Syndication::NewsML::TopicUse;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_attributes}{Topic} = REQUIRED;
	$self->{_attributes}{Context} = IMPLIED;
}

#
# Syndication::NewsML::Resource
#
package Syndication::NewsML::Resource;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_singleElements}{Urn} = OPTIONAL;
	$self->{_multiElements}{Url} = ZEROORMORE;
	$self->{_multiElements}{DefaultVocabularyFor} = ZEROORMORE;
}

#
# Syndication::NewsML::Url -- a URL that can be used to locate a resource
#
package Syndication::NewsML::Url;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::Urn
# A URN that provides a global identifier for a resource. This will typically (but
# not necessarily) be a NewsML URN as described in the comment to PublicIdentifier.
#
package Syndication::NewsML::Urn;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::TopicSetRef -- reference to another TopicSet somewhere
#
package Syndication::NewsML::TopicSetRef;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{TopicSet} = IMPLIED;
}

#
# Syndication::NewsML::TopicSet -- a container for Topics
#
package Syndication::NewsML::TopicSet;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode Syndication::NewsML::CatalogNode
           Syndication::NewsML::TopicNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_multiElements}{TopicSetRef} = ZEROORMORE;
}

#
# Syndication::NewsML::NewsEnvelope
#

package Syndication::NewsML::NewsEnvelope;
use Carp;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	croak "Error! A NewsML document must contain one and only one NewsEnvelope!" unless defined($node);
	$self->{_singleElements}{DateAndTime} = REQUIRED;
	$self->{_singleElements}{TransmissionId} = OPTIONAL;
	$self->{_singleElements}{SentFrom} = OPTIONAL;
	$self->{_singleElements}{SentTo} = OPTIONAL;
	$self->{_singleElements}{Priority} = OPTIONAL;
	$self->{_multiElements}{NewsService} = ZEROORMORE;
	$self->{_multiElements}{NewsProduct} = ZEROORMORE;
}

#
# Syndication::NewsML::NewsItem
#

package Syndication::NewsML::NewsItem;
use Carp;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::XmlLangNode );

sub _init {
	my ($self, $node) = @_;
	croak "Error! A NewsML document must contain at least one NewsItem!" unless defined($node);

	$self->{_singleElements}{Identification} = REQUIRED;
	$self->{_singleElements}{NewsManagement} = REQUIRED;
	$self->{_singleElements}{NewsComponent} = OPTIONAL;
	$self->{_singleElements}{TopicSet} = OPTIONAL;
	$self->{_multiElements}{Update} = ZEROORMORE;
}

# wow! a real method, not an autoload! :-)

# getType -- returns "NewsComponent", "Update", "TopicSet" or undef (none of the above)
sub getType {
	my ($self) = @_;
	return $self->{type} if $self->{type};
	# else have to check myself
	if ($self->{node}->getElementsByTagName("NewsComponent", 0)->item(0)) {
		return $self->{type} = "NewsComponent";
	} elsif ($self->{node}->getElementsByTagName("Update", 0)->item(0)) {
		return $self->{type} = "Update";
	} elsif ($self->{node}->getElementsByTagName("TopicSet", 0)->item(0)) {
		return $self->{type} = "TopicSet";
	}
	return undef;
}

#
# Syndication::NewsML::NewsComponent
#

package Syndication::NewsML::NewsComponent;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::CommentNode
	Syndication::NewsML::TopicSetNode Syndication::NewsML::XmlLangNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_singleElements}{Role} = OPTIONAL;
	$self->{_singleElements}{NewsLines} = OPTIONAL;
	$self->{_singleElements}{AdministrativeMetadata} = OPTIONAL;
	$self->{_singleElements}{RightsMetadata} = OPTIONAL;
	$self->{_singleElements}{DescriptiveMetadata} = OPTIONAL;
	$self->{_multiElements}{Metadata} = ZEROORMORE;
	$self->{_multiElements}{BasisForChoice} = ZEROORMORE;
	$self->{_multiElements}{NewsItem} = ZEROORMORE;
	$self->{_multiElements}{NewsItemRef} = ZEROORMORE;
	$self->{_multiElements}{NewsComponent} = ZEROORMORE;
	$self->{_multiElements}{ContentItem} = ZEROORMORE;
}

# may be a nicer/more generic way of doing this, but this will do for now
sub getEssential {
	my ($self) = @_;
	my $ess = $self->{node}->getAttributeNode("Essential");
	$self->{"Essential"} = $ess ? $ess->getValue : 'no';
}

# may be a nicer/more generic way of doing this, but this will do for now
sub getEquivalentsList {
	my ($self) = @_;
	my $equiv = $self->{node}->getAttributeNode("EquivalentsList");
	$self->{"EquivalentsList"} = $equiv ? $equiv->getValue : 'no';
}

# should really do some sanity checking because a NewsComponent can't contain more than one type of
# NewsItem/NewsItemRef, NewsComponent, or ContentItem

## Metadata helpers -- so we don't have to delve too deep for not much reason

# Administrative Metadata
sub getFileName {
	my ($self) = @_;
	$self->{"FileName"} = $self->getAdministrativeMetadata->getFileName->getText;
}

sub getSystemIdentifier {
	my ($self) = @_;
	$self->{"SystemIdentifier"} = $self->getAdministrativeMetadata->getSystemIdentifier->getText;
}

# these two both return Topic objects
sub getProvider {
	my ($self) = @_;
	$self->{"Provider"} = $self->getAdministrativeMetadata->getProvider->getPartyList->[0]->resolveTopicRef;
}

sub getCreator {
	my ($self) = @_;
	$self->{"Creator"} = $self->getAdministrativeMetadata->getCreator->getPartyList->[0]->resolveTopicRef;
}

# source and contributor also exist in AdministrativeMetadata, but they both can be multiples
# and source can have an extra attr (NewsItem) so let's leave them alone for now

# Rights Metadata
# should this return text or (an array of) Topic object(s)?
sub getCopyrightHolder {
	my ($self) = @_;
	my @copyholders;
	foreach my $copyright ($self->getRightsMetadata->getCopyrightList) {
		my $text = $copyright->getCopyrightHolder->getText;
		# ignore text if it's just whitespace
		push(@copyholders, $text) if $text !~ /^\s*$/;
		foreach my $origin ($copyright->getCopyrightHolder->getOriginList) {
			# hard coding [0] here probably isn't good, but when do you have multiple Descriptions?
			push(@copyholders, $origin->resolveTopicRef->getDescriptionList->[0]->getText);
		}
	}
	$self->{"CopyrightHolder"} = \@copyholders;
	return wantarray ? @copyholders : join(',', @copyholders);
}

sub getCopyrightDate {
	my ($self) = @_;
	my @copydates;
	foreach my $copyright ($self->getRightsMetadata->getCopyrightList) {
		my $text = $copyright->getCopyrightDate->getText;
		# ignore text if it's just whitespace
		push(@copydates, $text) if $text !~ /^\s*$/;
		foreach my $origin ($copyright->getCopyrightDate->getOriginList) {
			# hard coding [0] here probably isn't good, but when do you have multiple Descriptions?
			push(@copydates, $origin->resolveTopicRef->getDescriptionList->[0]->getText);
		}
	}
	$self->{"CopyrightDate"} = \@copydates;
	return wantarray ? @copydates : join(',', @copydates);
}

# descriptive metadata
sub getLanguage {
	my ($self) = @_;
	$self->{"Language"} = $self->getDescriptiveMetadata->getLanguageList->[0]->getFormalName;
}

#
# Syndication::NewsML::NewsManagement
#

package Syndication::NewsML::NewsManagement;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::PropertyNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_singleElements}{NewsItemType} = REQUIRED;
	$self->{_singleElements}{FirstCreated} = REQUIRED;
	$self->{_singleElements}{ThisRevisionCreated} = REQUIRED;
	$self->{_singleElements}{Status} = REQUIRED;
	$self->{_singleElements}{StatusWillChange} = OPTIONAL;
	$self->{_singleElements}{Urgency} = OPTIONAL;
	$self->{_singleElements}{RevisionHistory} = OPTIONAL;
	$self->{_multiElements}{DerivedFrom} = ZEROORMORE;
	$self->{_multiElements}{AssociatedWith} = ZEROORMORE;
	$self->{_multiElements}{Instruction} = ZEROORMORE;
}

#
# Syndication::NewsML::ContentItem
#

package Syndication::NewsML::ContentItem;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::CommentNode Syndication::NewsML::DataNode );
sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{MediaType} = OPTIONAL;
	$self->{_singleElements}{Format} = OPTIONAL;
	$self->{_singleElements}{MimeType} = OPTIONAL;
	$self->{_singleElements}{Notation} = OPTIONAL;
	$self->{_singleElements}{Characteristics} = OPTIONAL;
	$self->{_attributes}{Href} = IMPLIED;
}

#
# Syndication::NewsML::RevisionHistory -- pointer to a file containing the revision history of a NewsItem
#

package Syndication::NewsML::RevisionHistory;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_attributes}{Href} = REQUIRED;
}

#
# Syndication::NewsML::TopicOccurrence -- this topic appears in the NewsComponent
#

package Syndication::NewsML::TopicOccurrence;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Topic} = IMPLIED;
}

#
# Syndication::NewsML::MediaType -- media type of a ContentItem
#

package Syndication::NewsML::MediaType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Format -- format of a ContentItem
#

package Syndication::NewsML::Format;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::MimeType -- MIME type of a ContentItem
#

package Syndication::NewsML::MimeType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Notation -- Notation of a ContentItem
#

package Syndication::NewsML::Notation;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::LabelType -- a user-defined type of Label
#

package Syndication::NewsML::LabelType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Urgency -- urgency of a NewsItem
#

package Syndication::NewsML::Urgency;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::FutureStatus -- future status of a NewsItem
#

package Syndication::NewsML::FutureStatus;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::NewsItemType -- type of a NewsItem
#

package Syndication::NewsML::NewsItemType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::NewsLineType -- type of a NewsLine
#

package Syndication::NewsML::NewsLineType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::NewsProduct -- product to which these news items belong
#

package Syndication::NewsML::NewsProduct;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::NewsService -- service to which these news items belong
#

package Syndication::NewsML::NewsService;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Priority -- priority notation of this NewsItem
#

package Syndication::NewsML::Priority;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Role -- role this NewsComponent plays within its parent
#

package Syndication::NewsML::Role;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Status -- status of a NewsItem
#

package Syndication::NewsML::Status;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::SubjectCode -- container for Subject codes
#

package Syndication::NewsML::SubjectCode;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;

	$self->{_multiElements}{Subject} = ZEROORMORE;
	$self->{_multiElements}{SubjectMatter} = ZEROORMORE;
	$self->{_multiElements}{SubjectDetail} = ZEROORMORE;
	$self->{_multiElements}{SubjectQualifier} = ZEROORMORE;
}

#
# Syndication::NewsML::Subject -- subject of a NewsItem
#

package Syndication::NewsML::Subject;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::SubjectDetail -- subject detail (?) of a NewsItem
#

package Syndication::NewsML::SubjectDetail;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::SubjectMatter -- subject matter (?) of a NewsItem
#

package Syndication::NewsML::SubjectMatter;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::SubjectQualifier -- subject qualifier (?) of a NewsItem
#

package Syndication::NewsML::SubjectQualifier;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Relevance -- relevance of a NewsItem to a given target audience
#

package Syndication::NewsML::Relevance;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Genre -- genre of a NewsComponent
#

package Syndication::NewsML::Genre;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Language -- a language used in a content item
#

package Syndication::NewsML::Language;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
}

#
# Syndication::NewsML::Limitations -- terms and conditions of usage rights
#

package Syndication::NewsML::Limitations;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::AssignmentNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::Characteristics -- physical characteristics of a ContentItem
#

package Syndication::NewsML::Characteristics;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::PropertyNode);

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{SizeInBytes} = OPTIONAL;
}

#
# Syndication::NewsML::SizeInBytes -- size of a ContentItem (within Characteristics)
#

package Syndication::NewsML::SizeInBytes;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::SystemIdentifier -- system ID for a NewsItem
#

package Syndication::NewsML::SystemIdentifier;
@ISA = qw ( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::ThisRevisionCreated -- date (and possibly time)
#

package Syndication::NewsML::ThisRevisionCreated;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::DateNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

#
# Syndication::NewsML::MetadataType -- media type of a ContentItem
#

package Syndication::NewsML::MetadataType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Encoding -- the actual encoding
#
package Syndication::NewsML::Encoding;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::DataNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Notation} = REQUIRED;
}

# Syndication::NewsML::DataContent -- the actual datacontent
#
package Syndication::NewsML::DataContent;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# stuff to do with parties (yeah!) (oh, not that kind of party)

# Syndication::NewsML::Party -- the actual party
#
package Syndication::NewsML::Party;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Topic} = IMPLIED;
}

sub resolveTopicRef {
	my ($self) = @_;
	my $refnode = Syndication::NewsML::References::findReference($self, $self->getTopic, 0);
	return new Syndication::NewsML::Topic($refnode);
}

# Syndication::NewsML::Contributor
#
package Syndication::NewsML::Contributor;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::Creator
#
package Syndication::NewsML::Creator;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::Provider
#
package Syndication::NewsML::Provider;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::SentFrom
#
package Syndication::NewsML::SentFrom;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::SentTo
#
package Syndication::NewsML::SentTo;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::Source
#
package Syndication::NewsML::Source;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PartyNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{NewsItem} = IMPLIED;
}

# Syndication::NewsML::Topic

# Syndication::NewsML::Topic -- "information about a thing" according to the DTD ;-)
#
package Syndication::NewsML::Topic;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode Syndication::NewsML::CatalogNode Syndication::NewsML::PropertyNode);

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}{TopicType} = ONEORMORE;
	$self->{_multiElements}{Description} = ZEROORMORE;
	$self->{_multiElements}{FormalName} = ZEROORMORE;
	$self->{_attributes}{Details} = IMPLIED;
}

# Syndication::NewsML::TopicType -- type of a topic (amazing huh?)
#

package Syndication::NewsML::TopicType;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
}

# Syndication::NewsML::Description -- formal name as an element, not an attribute, for Topics
#

package Syndication::NewsML::Description;
@ISA = qw ( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Variant} = IMPLIED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::FormalName -- formal name as an element, not an attribute, for Topics
#
package Syndication::NewsML::FormalName;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Scheme} = IMPLIED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::DefaultVocabularyFor
#
package Syndication::NewsML::DefaultVocabularyFor;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Context} = REQUIRED;
	$self->{_attributes}{Scheme} = IMPLIED;
}

# Syndication::NewsML::NameLabel -- label to help users identify a NewsItem
#
package Syndication::NewsML::NameLabel;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::NewsItemId -- identifier for a NewsItem (combination of NewsItemId and DateId must
#                            be unique amongst all NewsItems from this provider)
#
package Syndication::NewsML::NewsItemId;
# subclass Node instead of IdNode as this doesn't have a %localid
@ISA = qw( Syndication::NewsML::Node );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Vocabulary} = IMPLIED;
	$self->{_attributes}{Scheme} = IMPLIED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::NewsItemRef -- reference to another NewsItem somewhere
#
package Syndication::NewsML::NewsItemRef;
# actually this may need more than just CommentNode as it can have zero or more comments...
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{NewsItem} = IMPLIED;
}

# Syndication::NewsML::NewsLine -- line of arbitrary text
#
package Syndication::NewsML::NewsLine;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{NewsLineType} = REQUIRED;
	$self->{_multiElements}{NewsLineText} = ONEORMORE;
}

# Syndication::NewsML::NewsLines -- container for lines of news in a NewsComponent
#
package Syndication::NewsML::NewsLines;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}{HeadLine} = ZEROORMORE;
	$self->{_multiElements}{SubHeadLine} = ZEROORMORE;
	$self->{_multiElements}{ByLine} = ZEROORMORE;
	$self->{_multiElements}{DateLine} = ZEROORMORE;
	$self->{_multiElements}{CreditLine} = ZEROORMORE;
	$self->{_multiElements}{CopyrightLine} = ZEROORMORE;
	$self->{_multiElements}{RightsLine} = ZEROORMORE;
	$self->{_multiElements}{SeriesLine} = ZEROORMORE;
	$self->{_multiElements}{SlugLine} = ZEROORMORE;
	$self->{_multiElements}{KeywordLine} = ZEROORMORE;
	$self->{_multiElements}{NewsLine} = ZEROORMORE;
}

# Syndication::NewsML::AdministrativeMetadata -- the "provenance" of a NewsComponent
#
package Syndication::NewsML::AdministrativeMetadata;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::PropertyNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{FileName} = OPTIONAL;
	$self->{_singleElements}{SystemIdentifier} = OPTIONAL;
	$self->{_singleElements}{Provider} = OPTIONAL;
	$self->{_singleElements}{Creator} = OPTIONAL;
	$self->{_multiElements}{Source} = ZEROORMORE;
	$self->{_multiElements}{Contributor} = ZEROORMORE;
}

# Syndication::NewsML::DescriptiveMetadata -- describes the content of a NewsComponent
#
package Syndication::NewsML::DescriptiveMetadata;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::PropertyNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{Genre} = OPTIONAL;
	$self->{_multiElements}{Language} = ZEROORMORE;
	$self->{_multiElements}{SubjectCode} = ZEROORMORE;
	$self->{_multiElements}{OfInterestTo} = ZEROORMORE;
	$self->{_multiElements}{TopicOccurrence} = ZEROORMORE;
}

# Syndication::NewsML::Metadata -- user-defined type of metadata
#
package Syndication::NewsML::Metadata;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::PropertyNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{MetadataType} = REQUIRED;
}

# Syndication::NewsML::RightsMetadata -- user-defined type of metadata
#
package Syndication::NewsML::RightsMetadata;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CatalogNode Syndication::NewsML::PropertyNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}{Copyright} = ZEROORMORE;
	$self->{_multiElements}{UsageRights} = ZEROORMORE;
}

# Syndication::NewsML::BasisForChoice -- XPATH info to help choose between ContentItems
#
package Syndication::NewsML::BasisForChoice;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Rank} = IMPLIED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Origin
#
package Syndication::NewsML::Origin;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::OriginNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Href} = IMPLIED;
}

sub resolveTopicRef {
	my ($self) = @_;
	my $refnode = Syndication::NewsML::References::findReference($self, $self->getHref, 0);
	return new Syndication::NewsML::Topic($refnode);
}

# Syndication::NewsML::ByLine -- author/creator in natural language
#
package Syndication::NewsML::ByLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Copyright
#
package Syndication::NewsML::Copyright;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::CommentNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{CopyrightHolder} = REQUIRED;
	$self->{_singleElements}{CopyrightDate} = REQUIRED;
}

# Syndication::NewsML::CopyrightDate
#
package Syndication::NewsML::CopyrightDate;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::CopyrightHolder
#
package Syndication::NewsML::CopyrightHolder;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::CopyrightLine
#
package Syndication::NewsML::CopyrightLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::CreditLine
#
package Syndication::NewsML::CreditLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::DateAndTime
#
package Syndication::NewsML::DateAndTime;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::DateNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::DateId
#
package Syndication::NewsML::DateId;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::DateNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::DateLabel
#
package Syndication::NewsML::DateLabel;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::DateLine
#
package Syndication::NewsML::DateLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::EndDate
#
package Syndication::NewsML::EndDate;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::AssignmentNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::StartDate
#
package Syndication::NewsML::StartDate;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::AssignmentNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::FileName
#
package Syndication::NewsML::FileName;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::FirstCreated
#
package Syndication::NewsML::FirstCreated;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::DateNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Geography
#
package Syndication::NewsML::Geography;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::AssignmentNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::HeadLine
#
package Syndication::NewsML::HeadLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::KeywordLine
#
package Syndication::NewsML::KeywordLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::NewsLineText
#
package Syndication::NewsML::NewsLineText;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::RightsHolder
#
package Syndication::NewsML::RightsHolder;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::AssignmentNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::RightsLine
#
package Syndication::NewsML::RightsLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::SeriesLine
#
package Syndication::NewsML::SeriesLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::SlugLine
#
package Syndication::NewsML::SlugLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::SubHeadLine
#
package Syndication::NewsML::SubHeadLine;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::XmlLangNode Syndication::NewsML::OriginNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Label
#
package Syndication::NewsML::Label;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{LabelType} = REQUIRED;
	$self->{_singleElements}{LabelText} = REQUIRED;
}

# Syndication::NewsML::LabelText
#
package Syndication::NewsML::LabelText;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::ProviderId -- should be a domain name apparently
#
package Syndication::NewsML::ProviderId;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Vocabulary} = IMPLIED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::PublicIdentifier
#
package Syndication::NewsML::PublicIdentifier;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::NewsIdentifier
#
package Syndication::NewsML::NewsIdentifier;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{ProviderId} = REQUIRED;
	$self->{_singleElements}{DateId} = REQUIRED;
	$self->{_singleElements}{NewsItemId} = REQUIRED;
	$self->{_singleElements}{RevisionId} = REQUIRED;
	$self->{_singleElements}{PublicIdentifier} = REQUIRED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::RevisionId -- integer representing division
#
package Syndication::NewsML::RevisionId;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{PreviousRevision} = REQUIRED;
	$self->{_attributes}{Update} = REQUIRED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::InsertAfter -- content to insert after a designated element
#
package Syndication::NewsML::InsertAfter;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{DuidRef} = REQUIRED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::InsertBefore -- content to insert before a designated element
#
package Syndication::NewsML::InsertBefore;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{DuidRef} = REQUIRED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Replace -- content to replace a designated element
#
package Syndication::NewsML::Replace;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{DuidRef} = REQUIRED;
	$self->{_hasText} = 1;
}

# Syndication::NewsML::Property
#
package Syndication::NewsML::Property;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::PropertyNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_attributes}{Value} = IMPLIED;
	$self->{_attributes}{ValueRef} = IMPLIED;
	$self->{_attributes}{AllowedValues} = IMPLIED;
}

# Syndication::NewsML::OfInterestTo
#
package Syndication::NewsML::OfInterestTo;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode Syndication::NewsML::AssignmentNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{Relevance} = OPTIONAL;
}

# Syndication::NewsML::RevisionStatus
#
package Syndication::NewsML::RevisionStatus;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{Status} = REQUIRED;
	$self->{_attributes}{Revision} = IMPLIED;
}

# Syndication::NewsML::StatusWillChange
#
package Syndication::NewsML::StatusWillChange;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{FutureStatus} = REQUIRED;
	$self->{_singleElements}{DateAndTime} = REQUIRED;
}

# Syndication::NewsML::Identification
#
package Syndication::NewsML::Identification;
@ISA = qw( Syndication::NewsML::IdNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_singleElements}{NewsIdentifier} = REQUIRED;
	$self->{_singleElements}{NameLabel} = OPTIONAL;
	$self->{_singleElements}{DateLabel} = OPTIONAL;
	$self->{_multiElements}{Label} = ZEROORMORE;
}

#
# Syndication::NewsML::Instruction
#
package Syndication::NewsML::Instruction;
@ISA = qw( Syndication::NewsML::IdNode Syndication::NewsML::FormalNameNode );

sub _init {
	my ($self, $node) = @_;
	$self->{_multiElements}{RevisionStatus} = ZEROORMORE;
}
