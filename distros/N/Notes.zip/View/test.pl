# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Start with black magic to print on failure.

BEGIN { $| = 1; print "1..7\n"; }

use blib      '../Object'   ; # needed cause of inheritance (see below)
use blib      '../Session'  ;
use blib      '../Database' ;
use blib      '../View' ;

use        Notes::Session;    # note: inherits from Notes::Object
use        Notes::Database;   # note: inherits from Notes::Object
use        Notes::View;       # note: inherits from Notes::Object

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

my $spacing = ($view->spacing() == VW_SPACING_SINGLE) ? "VIEW_TABLE_SINGLE_SPACE" :
	      ($view->spacing() == VW_SPACING_ONE_POINT_25) ? "VIEW_TABLE_ONE_POINT_25_SPACE" : 
	      ($view->spacing() == VW_SPACING_ONE_POINT_50) ? "VIEW_TABLE_ONE_POINT_50_SPACE" :	  
	      ($view->spacing() == VW_SPACING_ONE_POINT_75) ? "VIEW_TABLE_ONE_POINT_75_SPACE" :
	      ($view->spacing() == VW_SPACING_DOUBLE) ? "VIEW_TABLE_DOUBLE_SPACE" : "";

print "View Name:             ", $view->name(), "\n";
print "View Alias(es):        ", $view->aliases(), "\n";
print "View UNID:             ", $view->universalid(), "\n";
print "View Created Date:     ", $view->created(), "\n";
print "View Added to file:    ", $view->added(), "\n";
print "View Last Modified:    ", $view->last_modified(), "\n";
print "View Last Accessed:    ", $view->last_accessed(), "\n";
print "View Background Color: ", $view->background_color(), "\n";
print "View lines per row:    ", $view->row_lines(), "\n";
print "View lines per header: ", $view->header_lines(), "\n";
print "View spacing:          ", $spacing, "\n";
print "View has:              ", $view->column_count(), " column(s).\n";
print "View contains:         ", $view->top_level_entry_count(), " entries.\n";
print "Column Names:          ", join("|",$view->column_names()), ".\n\n";
print "Readers:               ", join("|",$view->readers()), ".\n\n";

$view->is_default()
   ? print "View is the default view.\n"
   : print "View is not the default view.\n";
$view->has_date_formula()
   ? print "View has date selection formula.\n"
   : print "View selection formula is not date based.\n";
$view->is_calendar()
   ? print "View is a calendar view.\n"
   : print "View is a normal (non-calendar) view.\n";
$view->is_conflict()
   ? print "View is enabled for conflict checking.\n"
   : print "View is NOT enabled for conflict checking.\n";
$view->is_private()
   ? print "View is private.\n"
   : print "View is NOT private.\n";
$view->is_hierarchical()
   ? print "View is hierarchical.\n"
   : print "View is NOT hierarchical.\n";
$view->auto_update()
   ? print "View is set for auto-update.\n"
   : print "View is NOT set for auto-update.\n";

undef $view;
defined $view 
   ? print  "not ok 5\n" 
   : print "ok 5\n";


undef $db;
undef $s;

print  "ok 6\n";