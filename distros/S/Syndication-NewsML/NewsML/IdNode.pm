# $Id: IdNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::IdNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

#
# Syndication::NewsML::IdNode -- a node with Duid and/or Euid (or neither): most classes will inherit from this
#
package Syndication::NewsML::IdNode;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_attributes}->{Duid} = IMPLIED;
    $self->{_attributes}->{Euid} = IMPLIED;
    $self->{localid} = undef;
}

sub getLocalID {
    my ($self) = @_;
    $self->{localid} = $self->getDuid || $self->getEuid;
}

# Euid is an "Element-unique Identifier". Its value must be unique among elements
# of the same element-type and having the same parent element.

# This method retrieves a *sibling method* by its Euid attribute.
# we may need a more generic Euid method later on, possibly using XPath?
sub getElementByEuid {
    my ($self, $searchEuid) = @_;

    # start search at my parent
    Syndication::NewsML::DOMUtils::findElementByAttribute($self->{node}->parentNode,
        "Euid", $searchEuid);
}

# Duid is a "Document-unique Identifier". Its value must be unique within the entire document.
# (thus there is no point starting at a particular node)
sub getElementByDuid {
    my ($self, $searchDuid) = @_;
    my $rootNode = Syndication::NewsML::DOMUtils::getRootNode($self->{node});
    Syndication::NewsML::DOMUtils::findElementByAttribute($rootNode, "Duid", $searchDuid);
}

1;
