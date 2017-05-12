# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..12\n"; }

use blib      '../Object'   ; # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;

use        Notes::Session;    # note: inherits from Notes::Object
use        Notes::Database;   # note: inherits from Notes::Object

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
my      $db =  $s->get_database( '', 'names.nsf' );
defined $db
   ? print  "ok 2\n"
   : print  "not ok 2\n";
$s->status . $s->status_text eq '0No error' 
   ? print  "ok 3\n"
   : print  "not ok 3\n";
   
   # Test 4,5,6,7,8 - test integrity of reference chain
   #                  Notes::Database
   #                    ==>Notes::Session
   #                       ==>undef(Notes::Root)
print "\n";
ref  $db eq  'Notes::Database'
   ? print  "ok 4\n"
   : print  "not ok 4\n";
ref  $$db   eq  'REF'
   ? print  "ok 5\n"
   : print  "not ok 5\n";
ref  $$$db  eq  'Notes::Session'
   ? print  "ok 6\n"
   : print  "not ok 6\n";
not ref     $$$$db
   ? print  "ok 7\n"
   : print  "not ok 7\n";
not defined $$$$db
   ? print  "ok 8\n"
   : print  "not ok 8\n";

   # ideas for more test that could be implemented for Notes::Database
   #
   # Test xx - test ref count of objects in reference chain
   #           i.e. check that Notes::Session obj has ref count >= 2
   # Test xx - test protection of deref'ed objects thru SvREADONLY
   #           against implicit conversion in rvalue context
   #           (see lines below)
   # Test xx - test protection of deref'ed objects thru SvREADONLY
   #           with eval and $@ in lvalue context
   #           (try to modify PL_LN_OBJ_PUSH_NEW in ln_defs.h
   #           to see, wether we can SvREADONLY() the _complete_
   #           chain of references from leaf obj to root obj)
   #           Pro of more SvREADONLY: ref chain secured
   #           Con of more SvREADONLY: semantic change under the hood



   # the following code should be changed to canonical tests

print "Title: "          , $db->title, "\n";
print "Categories: "     , $db->categories, "\n";
print "Template: "       , $db->template, "\n";
print "Design Template: ", $db->inherited_template, "\n";
print "Canonical Path: " , $db->filename, "\n";
print "Expanded Path: "  , $db->filepath, "\n\n";
print $db->is_public_address_book() ? "Database is a public address book\n" :
      $db->is_personal_address_book() ? "Database is a personal address book\n" :
      "Database is not an address book\n";

$db->is_encrypted() ? print "Database is encrypted.\n" : print "Database is not encrypted.\n";

print "ok 9\n";

undef $db;

my $db = $s->get_database('EDST05/GCOS/EDS/CA','schema50.nsf');

my $copy = $db->create_copy('', 'copyofschema50.nsf');
defined $db
   ? print  "ok 10,  Copy -> Title: ", $db->title, "\n"
   : print  "not ok 10: ", $s->status_text(), "\n";

undef $copy;
undef $db;

my      $db = $s->create_database('', 'dbtest.nsf', false);
defined $db
   ? print  "ok 11, Created DB Canonical path: ", $db->canonical_path, "\n"
   : print  "not ok 11: ", $s->status_text(), "\n";

undef $db;
unlink 'c:/lotus/notes/data/dbtest.nsf';

print  "ok 12\n";

undef $s;