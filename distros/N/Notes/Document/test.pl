# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..7\n"; }

use blib      '../Object'   ; # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;
use blib      '../View' ;
use blib      '../Document' ;

use        Notes::Session;    # note: inherits from Notes::Object
use        Notes::Database;   # note: inherits from Notes::Object
use        Notes::View;       # note: inherits from Notes::Object
use        Notes::Document;   # note: inherits from Notes::Object

use        Devel::Peek;


   # Test 1 - checks wether (dyna)loading the (XS) module works
print "ok 1\n";
$loaded = 1;
END { print "not ok 1\n" unless $loaded; }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $s  = new Notes::Session;

   # Test 2,3 - try to open a Notes database
   #            and check returned object and status in parent obj.
   #          - we choose names.nsf as it must always exists locally !
my      $db =  $s->get_database( '', 'NotesPMTest.nsf' );
defined $db
   ? print  "ok 2\n"
   : print  "not ok 2\n";
$s->status . $s->status_text eq '0No error' 
   ? print  "ok 3\n"
   : print  "not ok 3\n";
   
my $view = $db->get_view('AllFldTypesView');
defined $view
   ? print  "ok 4\n"
   : print  "not ok 4\n";

$doc = $view->get_first_document();

while (defined($doc))
{
	$doc = $view->get_next_document();
}
$doc = $view->get_last_document();
$doc = $view->get_nth_document(1);

print  "ok 5\n";

$doc->has_item("Text_field")
   ? print  "Text_field item is present\n" 
   : print "Text_field item is NOT present\n";

@val = $doc->get_item_value("NumberList_field");
$doc->replace_item_value("NumberList_field", \@val);
print join("|", $doc->get_item_value("NumberList_field")) , "\n";

@val = $doc->get_item_value("TextList_field");
print join("\n",@val);


$val[1] = undef;

$doc->replace_item_value("arrayfield", \@val);
print join("|", $doc->get_item_value("arrayfield")) , "\n";

$doc->replace_item_value("newfield", "2003/04/28");
print join("|", $doc->get_item_value("newfield")) , "\n";

$doc->remove_item("Text_field");

$doc = Notes::Document->new($db);
$doc->replace_item_value("Form", "Test");
$doc->replace_item_value("Title", "Notes::Document Test");
$doc->replace_item_value("Array", qw(0 1 2 3 4 5 6 7 8 9));
$doc->save(true);

print "\n";
undef $doc;
defined $doc 
   ? print  "not ok 6\n" 
   : print "ok 6\n";

undef $view;
undef $db;
undef $s;

print  "ok 7\n";