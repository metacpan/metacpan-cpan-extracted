# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 38;
use Devel::Peek;
use Data::Dumper;
no warnings;
BEGIN { use_ok('Palm::Ztxt') };

#########################

my $ztxt;
ok($ztxt = new Palm::Ztxt, "new");
ok(($ztxt->set_title(undef) || 1), "set_title()");
ok(($ztxt->get_title() eq ""), "get_title()");

ok(($ztxt->set_data("  ") || 1), "set_data()");
ok(($ztxt->get_input() ||1), "get_input()");

my  $output;
ok($output = $ztxt->get_output(), "get_output");
my $ztxt1;

ok($ztxt1 = new Palm::Ztxt, "Init again");
ok($ztxt1->disect($output) ||1, "disect");
ok(($ztxt1->get_title()||1), "get_title");
ok(($ztxt1->get_input()||1), "get_input");

eval {$ztxt1->disect(undef)};
ok($@, "disect undef");
eval {$ztxt1->disect(\undef)};
ok($@, "disect \\undef");

#ok(eval{$ztxt1->disect(\"garbage")} ||1, "disect");

#ref to output;
ok($ztxt1->disect(\$output) ||1, "disect");
ok(($ztxt1->get_title()||1), "get_title");
ok(($ztxt1->get_input()||1), "get_input");

eval {$ztxt1->add_bookmark(undef, 12)};
ok($@, "Add bookmark with undef title");
ok(my $bookmarks = $ztxt1->get_bookmarks(), "get bookmark w/ no bookmark added");

eval {$ztxt1->set_title("01234567890"x10)};
ok($@, "Set Long title");


ok(0 == @$bookmarks, "No bookmark added");

eval {$ztxt1->add_annotation(undef, 12,"My Annotation");};
ok($@, "Add Annotation with undefined title");
ok(my $annotations = $ztxt1->get_annotations(), "get_annotations");
ok(0 == @$annotations, "Get annotation without add");

$ztxt1->add_annotation("Hi", 4,undef);
ok(1, "Add Annotation, undef Annotext");

$ztxt1->add_annotation("Hi", undef,"Hot Damn");
ok(1, "Add Annotation, undef Offset");

ok(1, "Last");
ok(my $annotations = $ztxt1->get_annotations(), "get_annotations");

ok($annotations->[1]{title} eq "Hi", 'annotation 1 title');
ok($annotations->[1]{annotation} eq "", 'annotatin 1 annotation');
ok(4 == $annotations->[1]{offset}, 'annotatin 1 offset' );

ok($annotations->[0]{title} eq "Hi", 'annotation 0 title');
ok($annotations->[0]{annotation} eq "Hot Damn", 'annotatin 0 annotation');
ok(0 == $annotations->[0]{offset}, 'annotatin 0 offset' );



$ztxt->delete_bookmark(undef,undef);
$ztxt->delete_annotation(undef,undef,undef);
$ztxt1->delete_annotation("Hi", 0, "Hot Damn");
ok($ztxt->get_annotations(), "Plain \$ztxt->get_annotations() --no assignment");

$ztxt1 = new Palm::Ztxt;
my $output2 = $ztxt1->get_output();
ok($ztxt1->get_output(), "Get output -- empty ztxt");

ok($ztxt1->get_title() eq '', "Get output -- empty ztxt");
$bookmarks = $ztxt1->get_bookmarks();
ok($bookmarks, "Get output -- empty ztxt");
$annotations = $ztxt1->get_annotations();
ok($annotations, "Get output -- empty ztxt");
#Dump($output2);








