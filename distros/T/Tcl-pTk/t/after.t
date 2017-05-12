#use Test::More (tests => 6);
use Test;
BEGIN {plan tests=>8}
use Tcl::pTk;
my $mw = MainWindow->new;
$mw->update;
my $start = time;
$mw->interp->after(1500,sub { my $t = time;
                      ok($t!=$start);
                      ok( $t >= $start+1);
                      ok( $t <= $start+2 ) });
$mw->interp->after(2000,sub { my $t = time;
                      ok( $t >= $start+2 );
                      ok( $t <= $start+3 ) });
$mw->interp->after(3000,sub{
        # Do a after with no callback
        my $start2 = time();
        $mw->after(1500);
        ok(time >= $start2+1);
        
        }
        
        );

$mw->interp->after(4000,sub{
        # Do a after with no callback
        my $start2 = time();
        Tcl::pTk->after(1500);
        ok(time >= $start2+1);
        
        $mw->destroy;
        }
        
        );

MainLoop;
ok(time >= $start+5);


