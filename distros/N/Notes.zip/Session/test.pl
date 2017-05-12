# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use blib      '../Object'   ; # needed here, because of inheritance
use blib      '../Session'  ;
use Test;
use Devel::Peek 'Dump';

BEGIN { plan tests => 10 };

use Notes::Session;
ok(1); # If we made it this far, we're ok.


   # Test 2 - checks wether object ref
   #          is created and blessed into correct package
my $s1 = new Notes::Session;

ref $s1 eq 'Notes::Session'
   ? print "ok 2\n"
   : print "not ok 2\n";

   # Test 3 - checks wether session counter got incremented in new()
$s1->session_count == 1
   ? print "ok 3\n"
   : print "not ok 3\n";

   # Test 4 and 5 - checks minimally wether object destructor works
{ 
   my $s2 = new Notes::Session;
   $s2->session_count == 2
      ? print "ok 4\n"
      : print "not ok 4\n";
}
$s1->session_count == 1
   ? print "ok 5\n"
   : print "not ok 5\n";

   # Test 6 - checks wether all session objects use the same
   #          global sesssion counter C variable
   #          and 
   #          wether the session count is properly handled
   #          during creation and destruction
   #          of multiple sessions when entering and leaving scopes
my        @counts =    $s1->session_count;
my        $s2     =    new Notes::Session;
push      @counts,     $s1->session_count;
push      @counts,     $s2->session_count;
{
   my     $s3     =    new Notes::Session;
   push   @counts,     $s1->session_count;
   push   @counts,     $s2->session_count;
   push   @counts,     $s3->session_count;
}
push      @counts,     $s1->session_count;
push      @counts,     $s2->session_count;
undef     $s2;
{ 1; }    # empty block to enforce $s2->DESTROY via ENTER/LEAVE (scope)
push      @counts,     $s1->session_count;
join(':', @counts) eq '1:2:2:3:3:3:2:2:1'
   ? print "ok 6\n"
   : print "not ok 6\n";


   # Test 7 - check wether perl subclassing from XS-class will work
   #          (code borrowed from Dean Roehrich's (XS-)CookBookA::Ex1)
@counts_subcl =              $s1->session_count;
my        $s2 =              new Notes::Session;
push      @counts_subcl,     $s1->session_count;
push      @counts_subcl,     $s2->session_count;
{
   package     Notes::Session::Subclass;
   @ISA =  qw( Notes::Session );

   sub DESTROY { 
      my  $s_subcl = shift;
      $s_subcl->SUPER::DESTROY;   # SUPER::DESTROY( @_ ) didn't work !
      print "ok 7\n";             # we must get here to prove success !
   }

   package main;
   my     $s3_subcl =       new Notes::Session::Subclass;
   push   @counts_subcl,    $s1      ->session_count;
   push   @counts_subcl,    $s2      ->session_count;
   push   @counts_subcl,    $s3_subcl->session_count;
}
# note: if we do not get here, this means C<print "not ok 7\n";>

push      @counts_subcl,    $s1->session_count;
push      @counts_subcl,    $s2->session_count;
undef     $s2;
push      @counts_subcl,    $s1->session_count;
join(':', @counts_subcl) eq '1:2:2:3:3:3:2:2:1'
   ? print "ok 8\n"
   : print "not ok 8\n";



   # Test 9,10 - test our Notes status code and status text functions
   #           - note: this also tests Notes::Object (XS-inheritance)
my   $s2 =  new Notes::Session;
#print "\nDump of s2 before set_status:\n\n";
#Dump($s2);

$s2->set_status( hex( '0x0420' ) );

#print "\nDump of s2 after set_status:\n\n";
#Dump($s2);


$s2->status ==   hex( '0x0420' )
   ? print "ok 9\n"
   : print "not ok 9";
$s2->status_text eq 'Access control list version is unsupported'
   ? print "ok 10\n"
   : print "not ok 10";

$s2->set_status( hex( '0x0' ) );

print "Effective User Name: ", $s2->effective_user_name(), "\n";
print "Data Directory:      ", $s2->data_directory(),      "\n";
print "Exec Directory:      ", $s2->exec_directory(),      "\n";
print "Notes API Version:   ", $s2->notes_api_version(),   "\n";
print "Notes Build Version: ", $s2->notes_build_version(), "\n";

print "ok 11\n";

print "Value of NAMES variable:     ", $s2->get_environment_string('NAMES'),     "\n";
print "Value of Directory variable: ", $s2->get_environment_string('Directory'), "\n";

print "Setting env. variable TEST=1...\n";
$s2->set_environment_var('TEST', '1');
print "Value of TEST variable:      ", $s2->get_environment_value('TEST'),     "\n";

print "ok 12\n";

@ab = $s2->address_books('');
print join("\n", @ab);

print "ok 13\n";

   # Test xx - test failure of Notes::Session->new
   #           in creation of first session thru
   #           (a) searching of Notes.ini in ENV{PATH}
   #           (b) renaming  of Notes.ini
   #           (c) installing a $SIG{__WARN__} handler
   #           (d) calling      Notes::Session->new
   #           (e) storing and analyzing the warning output
   #               of Notes::Session->new
   #           (f) recorrecting Notes.ini
   #           (g) doing (c) to (f) again as a second test