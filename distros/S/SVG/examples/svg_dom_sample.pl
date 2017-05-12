#!/usr/bin/perl -w
use strict;
use SVG(-indent=>"  ");

# subroutine to print out attributes
#
sub show_attributes ($) {
    my $node = shift;
    my $ref = $node->getAttributes();
    my @attrs = keys %$ref;
    print "This node has ".(scalar @attrs)." attributes:\n";
    foreach my $i (@attrs) {
        print "  $i=\"$ref->{$i}\"\n";
    }
}

my $s = SVG->new(width=>100,height=>50);
my $g1 = $s->group(id=>'group_1');
$g1->circle(width=>1,height=>1,id=>'test_id');
$g1->rect(id=>'id_2');
$g1->rect(id=>'id_3');
$g1->rect(id=>'id_4',x=>15,y=>150);
$g1->anchor(-xref=>'http://www.roitsystems.com/tutorial/',id=>'anchor_1')
    ->text(id=>'text_1',x=>15,y=>150,stroke=>'red')->cdata('Hello, World');

my $g2 = $s->group(id=>'group_2');
$g2->ellipse(id=>'id_5');
$g2->ellipse(id=>'id_6');
$g2->ellipse(id=>'id_7');

$s->ellipse(id=>'id_8');
$s->ellipse(id=>'id_9');

print "SVG::DOM Demonstration\n";
print "\n","="x40,"\n\n";
print "The example document looks like this:\n\n";
print $s->xmlify();
print "\n\n","="x40,"\n\n";

#
# Test of getElementName
#
print "The document element is of type \"".$s->getElementName()."\"\n";

#
# Test of getAttributes
#
show_attributes($s);

print "\n","-"x40,"\n\n";
print "Document contents by element type:\n";
#
# Test of getElements
#
my @e_names = qw/rect ellipse a g svg/;

foreach my $e_name (@e_names) {

    print "  There are ".scalar @{$s->getElements($e_name)}." '$e_name' elements\n";

    foreach my $e (@{$s->getElements($e_name)}) {
        if (my $e_id = $e->getElementID) {
            print "    $e has id \"$e_id\"\n";
            die "The id should always map back to the element"
                unless $s->getElementByID($e_id)==$e;
        } else {
            print "    $e has no id\n";
        }
    }

}

print "\n","-"x40,"\n\n";

my @kids = $s->getChildren();
print "The document element has ",scalar (@kids)," children (should be 1)\n";

foreach my $kid (@kids) {
    print "Found a <",$kid->getElementName(),"> child element:\n";
    show_attributes($kid);
}

# Test of getElementByID
#
my $group=$s->getElementByID("group_1");
print "Group 1 relocated by id group_1\n" if $group==$g1;

print "\n","="x40,"\n";

# Test of getChildren
#
my $children = $group->getChildren();
foreach my $v (0..$#{$children}) {
    # Test of getElementName on this child
    #
    my $name = $children->[$v]->getElementName;
    print "\nChild element $v is is a <$name> element.\n";

    print "It looks like this:\n\n"; 
    print $children->[$v]->xmlify();
    print "\n";

    # Test of getParent 
    #
    my $parent = $children->[$v]->getParent;
    my $parent_name = $parent->getElementName;
    print "Its parent is a <$parent_name> element\n";

    # Test of getChildIndex
    #
    print "It is index number ",$children->[$v]->getChildIndex()," in the parent.\n";

    # Test of getAttributes
    #
    my $ref = $children->[$v]->getAttributes();
    my @attrs = keys %$ref;
    print "It has ".(scalar @attrs)." attribute".($#attrs?"s":"").":\n";
    foreach my $attr (@attrs) {
        print "  $attr=\"$ref->{$attr}\"\n";
    }

    # Test of getPreviousSibling
    #
    if (my $prev = $children->[$v]->getPreviousSibling) {
        print "The element before it is a <".$prev->getElementName.">\n";
    } else {
        print "It is the first child element\n";
    }

    # Test of getNextSibling
    #
    if (my $next = $children->[$v]->getNextSibling) {
        print "The element after it is a <".$next->getElementName.">\n";
    } else {
        print "It is the last child element\n";
    }

    print "\n","-"x40,"\n";
}

# Test of getCDATA
#
my $text_element=$s->getElementByID("text_1");
print "\nAnd finally, element 'text_1' says ",$text_element->getCDATA(),"!\n";

print "\n","="x40,"\n";

