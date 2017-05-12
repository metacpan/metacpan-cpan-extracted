# $Id: DOMUtils.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::DOMUtils.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

#
# Syndication::NewsML::DOMUtils -- a few helpful routines
#
package Syndication::NewsML::DOMUtils;
use Carp;

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

# return a reference to the NewsML element at the top level of the document.
# will croak if not NewsML element exists in the parent path of the given node.
sub getRootNode {
    my ($node) = @_;
    if (!defined($node)) {
        croak "Invalid document! getRootNode couldn't find a NewsML element in parent path";
    } elsif ($node->getNodeName eq "NewsML") {
        return $node;
    } else {
        return getRootNode($node->getParentNode);
    }
}

1;
