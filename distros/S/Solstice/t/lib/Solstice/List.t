#!/usr/local/bin/perl

use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => 0;

use Solstice::List;
use Test::More;

plan(tests => 78);

my $list = new Solstice::List;
my $badlist = new Solstice::List;
my $newlist = new Solstice::List;

### Tests to check normal functionality ###

$list->add("this");
ok ($list->get(0) eq "this", "check initial add");
$list->add("is");
ok ($list->get(0) eq "this", "check next add--first element still the same");
ok ($list->get(1) eq "is", "check next add--new element is at right index");

$list->add("mary's");
$list->add("first");
$list->add("test");
isnt ($list->isEmpty(), 1, "ensure not empty after adds");
ok ($list->size() == 5, "ensure list size");
ok ($list->get(0) eq "this", "check element at index 0");
ok ($list->get(4) eq "test", "check element at index 4");

$list->add(0, "w00t!");    
ok ($list->get(0) eq "w00t!", "check new element @ index 0");
ok ($list->get(1) eq "this", "ensure former index 0 element is in right place");
ok ($list->get(5) eq "test", "make sure this index is valid");

my $return = $list->remove(0);
cmp_ok ($return, 'eq', 'w00t!', "removed element was returned");
ok ($list->get(0) eq "this", "check that the remove was valid");

$list->move(0, 3);
ok ($list->get(3) eq "this", "move - check that index has new element");
ok ($list->get(0) eq "is", "move - check that old index still has old element");
ok ($list->size() == 5, "ensure list size after move");

$return = $list->remove(0);
cmp_ok ($return, 'eq', 'is', "removed element was returned");
ok ($list->get(0) eq "mary's", "check that remove worked right yet again");
ok ($list->size() == 4, "ensure list size after 2nd remove");
ok ($list->exists(3) == 1, "check that index 3 exists in the list");
is ($list->exists(4), 0, "check that index 4 does not exist in list");

$return = $list->replace(1, 'second');
cmp_ok ($return, 'eq', 'first', "replaced element was returned");
cmp_ok ($list->get(1), 'eq', 'second', "new element is in correct position");
ok ($list->size() == 4, "ensure list size after replace");


#
# Iterator tests
# 

my $iterator_list = Solstice::List->new();
$iterator_list->addList([qw(5 6 7 8 9 10 11 12)]);

my $counter = 0;

ok (my $iterator = $iterator_list->iterator(), "initializing iterator");
cmp_ok($iterator->index(), '==', $counter, "list index is at first position");

my $match   = 5;
while (my $element = $iterator->next()) {
    cmp_ok($element, '==', $match, "next() returns next list element");
    cmp_ok($iterator->index(), '==', $counter, "index() return current list index");
    $counter++;
    $match++;
}

cmp_ok($iterator->index(), '==', $iterator_list->size() - 1, "list index is at last position");
ok(!$iterator->hasNext(), "list cursor is at end of list");

#
# Iterator sort test
#

my $iterator_sort_list = Solstice::List->new();
$iterator_sort_list->addList([qw(1 3 2 5 6 4)]);
my $iterator_sorted = $iterator_sort_list->iterator();
$iterator_sorted->sort(sub { return $a <=> $b; });

my $sorted_counter = 1;
while (my $element = $iterator_sorted->next()) {
    cmp_ok($element, '==', $sorted_counter, "next() returns next sorted list element");
    $sorted_counter++;
}

#
# Clear a list
#

$list->clear();
ok ($list->isEmpty() eq 1, "make sure list is actually empty");

#
# push,pop,shift,unshift tests
#
#
$list = Solstice::List->new();
for my $item (qw(orange yellow green blue indigo)){
    $list->add($item);
}

ok ($list->size() == 5, "ensure initial list size");
$list->push('violet');
ok ($list->size() == 6, "ensure list size after push");
ok ($list->get($list->size() - 1) eq 'violet', "ensure that push inserted into last position");
$list->unshift('red');
ok ($list->size() == 7, "ensure list size after unshift");
ok ($list->get(0) eq 'red', "ensure that unshift inserted into first position");
my $str = $list->pop();
ok ($list->size() == 6, "ensure list size after pop");
ok ($str eq 'violet', "ensure that pop returned item in last position");
$str = $list->shift();
ok ($list->size() == 5, "ensure list size after shift");
ok ($str eq 'red', "ensure that shift returned item in first position");


#getall tests
my @original = qw(1 2 3 4 5 6);
my $get_all_list = Solstice::List->new();
for my $item (@original){
    $get_all_list->add($item);
}
my @newlist;
ok (@newlist = @{$get_all_list->getAll()}, "check that getAll() actually works");
ok (@newlist eq @original, "check that the new list is the same as the old");
ok (scalar @newlist == 6, "ensure that new list is of correct size");
ok ($newlist[0] eq 1, "check that element at index 0 is correct");
ok ($newlist[4] eq 5, "check that last index has correct element");

# reverse tests
$get_all_list->reverse();
my @revlist = @{$get_all_list->getAll()};
ok (scalar @revlist == 6, "ensure that reversed list is of correct size");
ok ($revlist[0] eq 6, "check that element at index 0 is correct");
ok ($revlist[5] eq 1, "check that element at index 5 is correct");

### Tests to check things don't blow up ###
 
is (eval { my $item = $badlist->get(3); }, undef, "empty list - eval test");
is ($badlist->clear(), 1, "empty list - clear test");
is (eval { $badlist->remove(0); }, undef, "empty list - remove test");
is (eval { $badlist->move(1, 4); }, undef, "empty list - move test");
is ($badlist->size(), 0, "empty list - size test");
is ($badlist->exists(5), 0, "empty - exists test");

### addList tests

my $start_list = Solstice::List->new();
my $add_list = Solstice::List->new();

$start_list->add("a");
$start_list->add("b");
$start_list->add("c");
$add_list->add("d");
$add_list->add("e");
$add_list->add("f");
my @add_array = qw(h i j);

is($start_list->size, 3, "Start list original size");

$start_list->addList($add_list);

is($start_list->size, 6, "New size is good");
is($start_list->get(4), "e", "An appended item checks out");

$start_list->addList(\@add_array);

is($start_list->size, 9, "New size is good");
is($start_list->get(7), "i", "An appended item checks out");



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
