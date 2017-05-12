
#use Tk;


$| = 1;

use Test;
use Tcl::pTk;

plan tests => 1;

my $TOP = MainWindow->new;


	my $b = $TOP->Button( Name => 'btn',
            -text    => "Repeat Test",
            -width   => 10,
        )->pack;

my $repeatCount = 0;
my $afterObj;
$afterObj = $TOP->repeat(750, [sub{
                my $afterObjRef = shift;
                $repeatCount++;
                if( $repeatCount > 3 ){ # Cancel repeat
                        $$afterObjRef->cancel;
                        $TOP->destroy;
                }
                else{
                        my $color = ($repeatCount % 2) ? "red" : "green";
                        $b->configure(-bg => $color);
                }
}, \$afterObj]);

MainLoop;

ok(1);
