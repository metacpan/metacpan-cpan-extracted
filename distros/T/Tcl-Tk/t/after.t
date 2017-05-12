#use Test::More (tests => 6);
use Test;
BEGIN {plan tests=>6}
use Tcl::Tk qw(:perlTk);
my $mw = MainWindow->new;
$mw->update;
my $start = time;
$mw->interp->after(1000,sub { my $t = time;
                      ok($t!=$start);
                      ok( $t >= $start+1);
                      ok( $t <= $start+2 ) });
$mw->interp->after(2000,sub { my $t = time;
                      ok( $t >= $start+2 );
                      ok( $t <= $start+3 ) });
$mw->interp->after(3000,sub{$mw->destroy});
MainLoop;
ok(time >= $start+3);

