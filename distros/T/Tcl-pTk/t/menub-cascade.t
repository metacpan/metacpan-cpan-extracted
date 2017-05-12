# Balloon, pop up help window when mouse lingers over widget.

use Tcl::pTk;
#use Tk;
#use English;
use Carp;

use Test;
plan tests => 1;

my $lmsg = "";

my $top = MainWindow->new;

# create the widgets to be explained
my $mb = $top->Menubutton(-relief => 'raised',
			  -text => 'Menu button')->pack;
my $xxx = 0;
$mb->checkbutton(-label => 'checkbutton',
		 -variable => \$xxx);
$mb->cascade(-label => 'cascade entry');
my $menu = $mb->cget(-menu);
my $cm = $menu->Menu(-tearoff => 0);
$mb->entryconfigure('cascade entry', -menu => $cm);
$cm->command(-label => 'first');
$cm->command(-label => 'second');
$mb->separator;
$mb->command(-label => 'Close',
	     -command => sub {$top->destroy;});

#$mb->interp->icall($mb.".m", 'add', 'cascade', -label, "cascade entry");

$top->after(1000, sub{ $top->destroy});
MainLoop;

ok(1);
