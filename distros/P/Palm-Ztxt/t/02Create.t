# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 6;
use strict;
use Test::More tests => 23;
use Devel::Peek;
use Data::Dumper;
no warnings;
BEGIN { use_ok('Palm::Ztxt') };

#########################

my $ztxt;
ok($ztxt = new Palm::Ztxt, "new");
ok(($ztxt->set_title("Foo") || 1), "set_title()");
ok(($ztxt->get_title() eq "Foo"), "get_title()");
ok(($ztxt->set_data("This is my book of Foo") || 1), "set_data()");
ok(($ztxt->get_input() eq "This is my book of Foo"), "get_input()");
my  $output;
$ztxt->{method} = 0;
ok($output = $ztxt->get_output(), "get_output");
open FH, ">", "TestOutput" or die $!;
print FH $output;
close FH;
my $ztxt1;
ok($ztxt1 = new Palm::Ztxt, "Init again");
ok($ztxt1->disect($output) ||1, "disect");
ok(($ztxt1->get_title() eq "Foo"), "get_title");
ok(($ztxt1->get_input() eq "This is my book of Foo"), "get_input");
$ztxt1->add_bookmark("Foo", 12);
ok(1, "add_bookmark");
ok(my $bookmarks = $ztxt1->get_bookmarks(), "get_bookmarks");
#print Data::Dumper::Dumper($bookmarks);

ok($bookmarks->[0]{title} eq "Foo", 'book mark title');
ok($bookmarks->[0]{offset} == 12, 'bookmark offset' );


$ztxt1->add_annotation("Foo", 12,"My Annotation");
$ztxt1->add_annotation("Foo", 4,"My Annotation1");
ok(1, "add_annotations");

ok(my $annotations = $ztxt1->get_annotations(), "get_annotations");
ok($annotations->[1]{title} eq "Foo", 'annotation 0 title');
ok($annotations->[1]{annotation} eq "My Annotation", 'annotatin 0 annotation');
ok($annotations->[1]{offset} == 12, 'annotatin 0 offset' );

ok($annotations->[0]{title} eq "Foo", 'annotation 1 title');
ok($annotations->[0]{annotation} eq "My Annotation1", 'annotatin 1 annotation');
ok($annotations->[0]{offset} == 4, 'annotatin 1 offset' );

#print Data::Dumper::Dumper($ztxt1->get_annotations());

my $hi_there = new Palm::Ztxt;
my $output2 = $hi_there->get_output();
#Dump($output2);

