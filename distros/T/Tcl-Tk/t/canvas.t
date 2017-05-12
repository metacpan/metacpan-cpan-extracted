# very simplistic, must be much more complex soon

use Test;
BEGIN {plan tests=>1}
use Tcl::Tk;
my $mw = Tcl::Tk::MainWindow->new;
my $c = $mw->Canvas(qw/-relief flat -bd 0 -width 500 -height 350/)->pack(qw/-side top -fill both -expand 1/);

my $id0 = $c->_createRectangle(qw/55 90 255 205 -outline black -fill red/);
my $id1 = $c->create(qw/text 45 95 -text/, 'this is some text in canvas');

# test raise, lower canvas methods

$mw->interp->after(500,sub{$c->lower($id0)});
$mw->interp->after(800,sub{$c->lower($id1)});
$mw->interp->after(1200,sub{$c->raise($id1)});
$mw->interp->after(1600,sub{$c->raise($id0)});

$mw->update;
ok(1);
$mw->interp->after(2000,sub{$mw->destroy});
Tcl::Tk::MainLoop;


