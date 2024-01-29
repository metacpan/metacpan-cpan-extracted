use Test::More tests=>1;
use strict;
use Tcl::Tk;

my $int = new Tcl::Tk;
use Tcl::Tk::Tkwidget::Tix;

$int->SetVar('::tix_library','library');

Tcl::Tk::Tkwidget::Tix::Tix_Init($int);

# TODO $int->source('../tests/all.tcl');

ok(1);

done_testing();
