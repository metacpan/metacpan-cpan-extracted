# Test of the new Tk 8.5 wm manage and wm forget

use warnings;
use strict;

use Tcl::pTk;

use Test;



my $TOP = MainWindow->new;

my $version = $TOP->tclVersion;
# print "version = $version\n";

# Skip if Tcl/pTk version is < 8.5
if( $version < 8.5 ){
    print "1..0 # Skipped: Wm manage only works for Tcl >= 8.5\n";
    exit;
}
# Additionally skip for Tk Aqua pre-8.5.15
# (`wm manage` and `wm forget` are unimplemented)
elsif (
  ($TOP->windowingsystem eq 'aqua')
  and ($TOP->interp->Eval('package vcompare $tk_patchLevel 8.5.15') == -1)
) {
    print "1..0 # Skipped: Wm manage/forget unimplemented for Tk Aqua < 8.5.15\n";
    exit;
}

plan test => 3;

my $f = $TOP->Frame->pack(-fill => 'both',
                          -expand => 1,
                          -anchor => 'nw',
                          -side => 'top');
my $l = $TOP->Label(-text => 'Main Widget has been "popped"');
my $sf = $f->Frame;
my $e = $sf->Entry->pack(-fill => 'x',
                          -expand => 1);
my $b = $TOP->Button(-command => \&popup,
                     -text => 'Pop-Up')->pack;

my $popped = 0;
$sf->pack(-fill => 'both',
           -expand => 1);
          
	   
#
sub popup {
   if ($popped) {
     
     $sf->forget;

     ok( ref($sf), 'Tcl::pTk::Frame'); # Make sure it is a Frame

     $sf->pack(-in => $f,
               -fill => 'both',
               -expand => 1);
     $popped = 0;
   } else {
 
     $sf->packForget;

     # Have to use Full package name because $sf doesn't have Wm in its
     #   class inheritance (since it was't created as a toplevel)
     $sf->Tcl::pTk::Wm::manage();

     ok( ref($sf), 'Tcl::pTk::Toplevel'); # Make sure it is a toplevel
     $popped = 1;
   }
} 

# Release and capture the entry widget
$TOP->after(1000, sub{ 
                        popup();
                        $TOP->update;
                        $TOP->after(200); # wait 200mS
                        popup()
});


$TOP->after(2000, sub{ $TOP->destroy }) unless (@ARGV); # Persist if any args supplied, for debugging

MainLoop;

ok(1);
