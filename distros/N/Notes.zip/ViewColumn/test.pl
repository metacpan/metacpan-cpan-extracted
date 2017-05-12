# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..3\n"; }

use blib      '../Object'   ;     # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;
use blib      '../View' ;
use blib      '../ViewColumn' ;

use        Notes::Session;     # note: inherits from Notes::Object
use        Notes::Database;    # note: inherits from Notes::Object
use        Notes::View;        # note: inherits from Notes::Object
use        Notes::ViewColumn;  # note: inherits from Notes::Object

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
   
my $view = $db->get_view('People');
defined $view
   ? print  "ok 4\n"
   : print  "not ok 4\n";

my $col = $view->columns(1);
defined $col
   ? print  "ok 5\n"
   : print  "not ok 5 - ", $view->status_text, "\n";

#print "=" x 80, "\n";
#Dump($col,25);
print "=" x 80, "\n";

print "Title:             ", $col->{Title},            "\n";
print "ItemName:          ", $col->{ItemName},         "\n";
print "Formula:           ", $col->{Formula},          "\n";
#print "Addr822Phrase:    ", $col->{Addr822Phrase},    "\n";
#print "ADMD:             ", $col->{ADMD},             "\n";
#print "Canonical:        ", $col->{Canonical},        "\n";
#print "Common:           ", $col->{Common},           "\n";
#print "Country:          ", $col->{Country},          "\n";
#print "Domain:           ", $col->{Domain},           "\n";
#print "Generation:       ", $col->{Generation},       "\n";
#print "Given:            ", $col->{Given},            "\n";
#print "Initials:         ", $col->{Initials},         "\n";
#print "Language:         ", $col->{Language},         "\n";
#print "Organization:     ", $col->{Organization},     "\n";
#print "PRMD:             ", $col->{PRMD},             "\n";
#print "Surname:          ", $col->{Surname},          "\n\n";

print "=" x 80, "\n";

undef $col;
undef $view;
undef $db;
undef $s;

print "ok 6\n";