# $Id: Node.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::Node.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

#
# Syndication::NewsML::Node -- superclass defining a few functions all these will need
#
package Syndication::NewsML::Node;
use Carp;
use XML::DOM;
@ISA = qw( XML::DOM::Node );

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

# getChildXML is the same as the above but doesn't include the container tag.
sub getChildXML {
    my ($self) = @_;
    my $xmlstring = "";
    for my $child ($self->{node}->getChildNodes()) {
        $xmlstring .= $child->toString();
    }
    $self->{xml} = $xmlstring;
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
    my $textstring = "";
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
    if ($call =~ /(\w+)Count$/) {

        # handle getXXXCount method
        $var = $1;
        if (!$self->{_multiElements}->{$var}) {
            croak "Can't use getCount on $var";
        }
        my $method = "get".$var."List";
        $self->$method unless defined($self->{$var."Count"});
        return $self->{$var."Count"};
    } elsif ($call =~ /(\w+)List$/) {

        # handle getXXXList method for multi-element tags
        my $elem = $1;

        if (!$self->{_multiElements}->{$elem}) {
            croak "No such method: $AUTOLOAD";
        }

        # return undef if self->node doesn't exist
        return undef unless defined($self->{node});

        my $list = $self->{node}->getElementsByTagName($elem, 0);
        if (!$list && $self->{_multiElements}->{$elem} eq ONEORMORE) {
            croak "Error: required element $elem is missing";
        }
        # set elemCount while we know what it is
        $self->{$elem."Count"} = $list->getLength;
        my @elementObjects;
        my $elementObject;
        for (my $i = 0; $i < $self->{$elem."Count"}; $i++) {
            $elementObject = "Syndication::NewsML::$elem"->new($list->item($i))
                if defined($list->item($i)); # if item is undef, push an undef to the array
            push(@elementObjects, $elementObject);
        }
        $self->{$elem} = \@elementObjects;
        return wantarray ? @elementObjects : $self->{$elem};
    } elsif ($self->{_singleElements}->{$call}) {
        # return undef if self->node doesn't exist
        return undef unless defined($self->{node});

        # handle getXXX method for single-element tags
        my $element = $self->{node}->getElementsByTagName($call, 0);
        if (!$element) {
            if ($self->{_singleElements}->{$call} eq REQUIRED) {
                croak "Error: required element $call is missing";
            } else {
                return undef;
            }
        }
        $self->{$call} = "Syndication::NewsML::$call"->new($element->item(0))
            if defined($element->item(0));
        return $self->{$call};
    } elsif ($self->{_attributes}->{$call}) {
        # return undef if self->node doesn't exist
        return undef unless defined($self->{node});
        my $attr = $self->{node}->getAttributeNode($call);
        $self->{$call} = $attr ? $attr->getValue : '';
        if (!$attr && $self->{_attributes}->{$call} eq REQUIRED) {
            croak "Error: $call attribute is required";
        }
        return $self->{$call};
    } elsif ($self->{_multiElements}->{$call}) {
        # flag error because multiElement needs to be called with "getBlahList"
        croak "$call can be a multi-element field: must call get".$call."List";
    } else {
        croak "No such method: $AUTOLOAD";
    }
}

1;
