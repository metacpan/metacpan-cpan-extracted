# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..7\n"; }

use blib      '../Object'   ;     # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;

use        Notes::Session;     # note: inherits from Notes::Object
use        Notes::Database;    # note: inherits from Notes::Object
use        Notes::Replication; # note: inherits from Notes::Object

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
my      $db =  $s->get_database('', 'names.nsf');
defined $db
   ? print  "ok 2\n"
   : print  "not ok 2\n";
$s->status . $s->status_text eq '0No error' 
   ? print  "ok 3\n"
   : print  "not ok 3\n";

print "Title: "          , $db->title, "\n";
print "Categories: "     , $db->categories, "\n";
print "Template: "       , $db->template, "\n";
print "Design Template: ", $db->inherited_template, "\n";
print "Canonical Path: " , $db->canonical_path, "\n";
print "Expanded Path: "  , $db->expanded_path, "\n";

$repl = $db->replication_info();
defined $repl
   ? print  "ok 4\n"
   : print  "not ok 4\n";

print "Dumping repl...\n";
Dump($repl);

print "Cutoff Interval: ", $repl->cutoff_interval_days, "\n";
$interval = $repl->cutoff_interval_days;
$repl->set_cutoff_interval_days( $interval + 5 );
print "Cutoff Interval: ", $repl->cutoff_interval_days, "\n";
$repl->set_cutoff_interval_days( $interval - 5 );

print "ok 5\n";

$repl->is_browsable ? print( "Database is browsable\n" ) : print( "Database is NOT browsable\n" );
print "Changing the browsable flag on database...\n";
$repl->is_browsable ? $repl->set_not_browsable : $repl->set_browsable;
$repl->is_browsable ? print( "Database is browsable\n" ) : print( "Database is NOT browsable\n" );
print "Reverting the browsable flag to it's original status...\n";
$repl->is_browsable ? $repl->set_not_browsable : $repl->set_browsable;
$repl->is_browsable ? print( "Database is browsable\n" ) : print( "Database is NOT browsable\n" );

print "ok 6\n";

my @hist = $repl->gethistory();
print "Replication history of database:\n\n";
foreach $entry (@hist)
{
	print $entry, "\n";
}

print "\nok 7\n";

undef $repl;
undef $db;
undef $s;

print "ok 8\n";