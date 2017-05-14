# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..9\n"; }

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

my      $db =  $s->get_database( '', 'names.nsf' );
Dump($db);

#print "Server is: ", $db->server eq "" ? "Local" : $db->server, "\n";
#print "CurrentAccessLevel is: ", join(",", $db->current_access_level()), "\n";

#print "Compacting database: ", join(" -> ", $db->compact()), "\n";

undef $db;
undef $s;