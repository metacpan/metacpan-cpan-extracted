# very simplistic, must be much more complex soon

use Test;
BEGIN {plan tests=>1}
use Tcl::pTk;
my $mw = MainWindow->new;
my $tw = $mw->Text(-font=>32)->pack;
$tw->insert('end',qq/brown fox \x{263A}\x{2460}\x{2461}\x{2462}\x{2463}\x{2464}\x{2465}\x{2466}\x{2467}/);
$mw->update;
ok(1);
$mw->interp->after(2000,sub{$mw->destroy});
MainLoop;


