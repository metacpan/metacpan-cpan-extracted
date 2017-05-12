# $Id: FormalNameNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::FormalNameNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::FormalNameNode -- superclass defining what to do with "formal name" attributes
#
package Syndication::NewsML::FormalNameNode;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_attributes}->{FormalName} = REQUIRED;
    $self->{_attributes}->{Vocabulary} = IMPLIED;
    $self->{_attributes}->{Scheme} = IMPLIED;
}

# get the associated vocabulary for a given FormalName.
# NOTE other nodes (NewsItemId and ProviderId) also have Vocabularies for their Schemes
# but are not FormalNameNodes), I guess we should handle them in the same way??
sub resolveTopicSet {
    my ($self) = @_;
    return Syndication::NewsML::References::findReference($self, $self->getVocabulary);
}

sub resolveTopicSetDescription {
    my ($self) = @_;
    # note that this findReference routine only returns a DOM node, not a NewsML one so we
    # have to use DOM functions to traverse it.
    my $dumbnode =  Syndication::NewsML::References::findReference($self, $self->getVocabulary);
    return $dumbnode->getElementsByTagName("Comment")->[0]->getFirstChild->getNodeValue;
}

sub resolveVocabularyDescription {
    my ($self) = @_;
    # get the topicset referred in the vocabulary of this element
    my $topicset =  Syndication::NewsML::Resources::findResource($self->getVocabulary);
    # find the topic with this FormalName in the given TopicSet
    # NOT FINISHED
}

1;
