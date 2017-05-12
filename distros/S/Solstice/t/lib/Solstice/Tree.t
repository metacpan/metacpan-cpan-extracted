#!/usr/local/bin/perl

use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => undef;

use Test::More;

plan(tests => 47);


use Solstice::Tree;

# Tree will look like this:
#
#   root
#   / \
#  1   2
#     /
#    3
#   /
#  4

#test initialization
ok (my $mommatree = new Solstice::Tree, "initializing new tree");
my $child1 = new Solstice::Tree;
my $child2 = new Solstice::Tree;
my $child3 = new Solstice::Tree;
my $child4 = new Solstice::Tree;

#test setValue()
ok ($child1->setValue("child1"), "setting value to child1 tree");
is ($child1->getValue(), "child1", "checking value of child1 tree");
$child2->setValue("child2");
$child3->setValue("child3");
$child4->setValue("child4");

#test addChild()
ok ($child3->addChild($child4), "adding child4 to child3");
ok ($child2->addChild($child3), "adding child3 to child2");
ok ($mommatree->addChild($child1), "adding child1 to root");
ok ($mommatree->addChild($child2), "adding child2 to root");

#test getChildCount()
is ($mommatree->getChildCount(), 2, "checking child count of root");
is ($child1->getChildCount(), 0, "checking child count of child1");
is ($child2->getChildCount(), 1, "checking child count of child2");
is ($child3->getChildCount(), 1, "checking child count of child3");
is ($child4->getChildCount(), 0, "checking child count of child4");

#test isRoot() & isLeaf()
ok ($mommatree->isRoot(), "verifying root tree is the root");
is ($mommatree->getParent(), $mommatree, "mommatree is her own parent");
isnt ($mommatree->isLeaf(), 1, "verifying root is NOT a leaf");
isnt ($child1->isRoot(), 1, "verifying child1 is NOT a root");
ok ($child1->isLeaf(), "verifying child1 is a leaf");
isnt ($child2->isRoot(), 1, "verifying child2 is NOT a root");
isnt ($child2->isLeaf(), 1, "verifying child2 is NOT a leaf");
isnt ($child4->isRoot(), 1, "verifying child4 is NOT a root");
ok ($child4->isLeaf(), "verifying child4 is a leaf"); 

#test getChildren()
ok (my @allmychildren = $mommatree->getChildren(), "getting children of root");
is (scalar(@allmychildren), 2, "checking length of allmychildren array");
is ($allmychildren[0], $child1, "checking root's first child");
is ($allmychildren[1], $child2, "checking root's second child");
is ($mommatree->getChild(0), $child1, "checking root's first child again");
is ($mommatree->getChild(1), $child2, "checking root's second child again");
 
isnt (my @emptychildren = $child1->getChildren(), 1, "getting children of leaf node");
is (scalar(@emptychildren), 0, "checking length of emptychildren array");

#test removeChild()
ok ($child3->removeChild(0), "remove child4 from child3");
is ($child3->getChildCount(), 0, "make sure child3's num of children is 0");
ok ($child3->isLeaf(), "make sure child3 is a leaf");

#test getValue()
ok ($mommatree->setValue("big momma"), "setting value to root tree");
is ($mommatree->getValue(), "big momma", "checking value of root");

#test getParent()
ok (my $parent = $child3->getParent(), "getting parent tree of child3");
is ($parent, $child2, "verifying that parent tree of child3 is child2");

#other miscellaneous stuff
ok ($mommatree->childExists(0), "verifying that root has child at 0");
ok ($mommatree->childExists(1), "verifying that root has child at 1");
ok ($child1->isFirstChild(), "verifying that child1 is the first child");
ok ($child3->isLastChild(), "verifying that child3 is the last child");
is ($mommatree->getTotalChildCount(), 3, "checking that total children is 3");
is ($child2->getPosition(), 1, "checking that child2 is at position 2");
ok ($mommatree->moveChild(1, 0), "move is successful!");
#ok ($child4->destroy(), "destroying child4");

#test bad commands
is (eval { my $nullchild = $child3->getChild(0); }, undef, "child3 has no child");
is (eval { my $nullchild2 = $mommatree->getChild(343); }, undef, "root has 2 direct children");
isnt ($child3->removeChild(0), 1, "child3 has no children to remove");
is (eval { my $child4->destroy(); }, undef, "destroy child4");
exit 0;


=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
