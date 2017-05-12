# -*- perl -*-
BEGIN { $|=1; $^W=1; }
use strict;
use Test;

BEGIN
  {
   plan test => 7;
  };

use Tcl::pTk;

my $mw;
eval {$mw = MainWindow->new();};
ok($@, "", "can't create MainWindow");
ok(Tcl::pTk::Exists($mw), 1, "MainWindow creation failed");

my $tfr = $mw->LabelFrame(-label => "labelframe")
  ->pack(-fill => "both", -expand => 1);
ok($tfr->cget("-label"), "labelframe");

my $tfrb = $tfr->Button(-text => "Inside labelframe")->pack;

$mw->deiconify;
$mw->update;
$mw->raise;
my @kids = $mw->children;
ok(@kids, 1);
my $txt = $kids[0]->cget("-text");
ok($txt , "labelframe");

$mw->configure(-title=>'new title',-cursor=>'star');
ok($mw->cget('-title'), 'new title');
ok($mw->cget('-cursor'), 'star');

$mw->after(3000,sub{$mw->destroy});
MainLoop;
