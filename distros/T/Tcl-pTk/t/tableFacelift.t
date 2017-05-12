#!/usr/local/bin/perl -w

# Check that Table widget works with facelift

use Test;
use Tcl::pTk;
use Tcl::pTk::Table();
use Tcl::pTk::Facelift;



#use Tk;
#use Tk::Table;



my $mw = MainWindow->new;

# This will skip if Tktable not present
my $retVal = $mw->interp->pkg_require('Tktable');

unless( $retVal){
	plan test => 1;
        skip("Tktable Tcl package not available", 1);
        exit;
}

plan test => 2;

my $t  = $mw->Table(-columns => 6, -rows => 8, -fixedrows => 1, -scrollbars => 'se');
$t->grid(-column => 0, -columnspan => 2, -row => 0, -sticky => 'nsew');

sub Pressed
{
 my ($t,$i,$j) = @_;
 my $l = $t->Label(-text => "Pressed $i,$j",-relief => 'sunken');
 my $old = $t->put($i,$j,$l);
 $old->delete if ($old);
}

my $i;
my $saveWidget; # Widget to save for later
foreach $i (0..9)
 {
  my $j;
  foreach $j (0..9)
   {
    my $l = $t->Button(-text => "Entry $i,$j",
                       -command => [\&Pressed,$t,$i,$j]);
    $t->put($i,$j,$l);
    if( $i == 3 && $j == 4){ # Save widget for Posn test later
            $saveWidget = $l;
    }
   }
 }

my $sb;
my $rl = 1;
my $cl = 0;


#$t->configure(-fixedrows => 0);

$mw->Checkbutton(-text => 'Row labels', -variable => \$rl, -onvalue => 1, -offvalue => 0,
        -command => sub { $t->configure(-fixedrows => $rl) }
                )->grid(-column => 0, -row => 1);


$mw->Checkbutton(-text => 'Column labels', -variable => \$cl, -onvalue => 1,-offvalue => 0,
        -command => sub { $t->configure(-fixedcolumns => $cl) }
                )->grid(-column => 1, -row => 1);

$mw->gridRowconfigure(0, -weight => 1);
$mw->gridRowconfigure(1, -weight => 0);
$mw->gridColumnconfigure(0, -weight => 1);
$mw->gridColumnconfigure(1, -weight => 1);

$t->focus;
$t->update;

my ($row,$col) = $t->Posn($saveWidget);
#print "Row/Col = $row/$col\n";
ok("$row/$col", "3/4", "Posn Method Test");

$mw->after(1000, sub{ $t->clear() })  unless(@ARGV); # for debugging, don't clear if args on the command line
$mw->after(1500, sub{ $mw->destroy }) unless(@ARGV); # for debugging, don't exit if args on the command line

MainLoop;

ok(1);

