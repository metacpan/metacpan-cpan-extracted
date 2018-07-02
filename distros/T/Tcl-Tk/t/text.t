# very simplistic
BEGIN { $|=1; $^W=1; }
use Test;
use Tcl::Tk;

my $mw = Tcl::Tk::MainWindow->new;

if (!$mw->interp->pkg_require('snit')) {
    print "1..0 # skip: no snit extension available\n";
    exit;
}

if (!$mw->interp->pkg_require('scrolledwindow')) {
    print "1..0 # skip: no tklib extension available\n";
    exit;
}

plan tests=>3;

my $tw = $mw->Scrolled('Text',-font=>32)->pack;
ok(1);
$tw->_insert('end',qq/\n/);
for ('000'..'180') {
    $tw->_insertEnd(qq/brown fox \x{263A}\x{2460}\x{2461}\x{2462}\x{2463}\x{2464}\x{2465}\x{2466}\x{2467} $_\n/);
    $tw->_seeEnd;
    $mw->update;
}
ok(2);
$tw->_tagAddSel('160.5','170.15');
ok(3);
$mw->interp->after(2000, sub{$mw->destroy});
$mw->interp->MainLoop;

