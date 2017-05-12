
use Tcl::pTk;
#use Tk;
use Test;

plan tests => 9;

my $TOP = MainWindow->new();


my $frame = $TOP->Frame(-borderwidth => 10)->pack;

my $canvas = $frame->Canvas(
qw/-width 100 -height 100 -borderwidth 0 -highlightthickness 0/);
my $id = $canvas->createPolygon(qw/0 0 10 10 20 10 -fill SeaGreen3 -tags poly/);
my $lineID = $canvas->createLine(qw/0 0 10 10 20 20 30 30 40 40 -fill black -tags line/);
my $textID = $canvas->createText(qw/40 40 -text TextItem/);
$canvas->pack(qw/-side left -anchor nw -fill both/);

my $index = $canvas->index($lineID, [10, 10]);

ok($index, 2, "Index Check 1");

$index = $canvas->index($lineID, '@10,10' );

ok($index, 2, "Index Check 2");

#print "index = $index\n";

# Check that coords returns an array
my @coords = $canvas->coords($lineID);
ok(scalar(@coords), 10, "Coords check");
#print "Coords = ".join(", ", @coords)."\n";

# Variables set when events fired
my $deletePressed = 0;
my $textDeletePressed = 0;


# Delete Key for the whole widget
$canvas->CanvasBind('<Delete>' =>  
        sub{ $deletePressed = 1;
             #print STDERR "Delete Key\n"
        }
);

                
# Delete Key for the text item in the canvas
$canvas->bind($textID, '<Delete>' =>  
        sub{ $textDeletePressed = 1;
             #print STDERR "text Delete Key\n"
        }
);

$canvas->CanvasFocus; # make the canvas have the focus, so that the delete key works
                
#$canvas->interp->invoke('focus', $canvas);
#$canvas->focus;

                
# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}

                
# Fire a delete event for the whole canvas and check variables
$canvas->eventGenerate('<Delete>');

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}


ok($deletePressed,     1, "Delete Key Check");
ok($textDeletePressed, 0, "Delete Key Check");

# Now focus on the textID and fire off another delete event
($deletePressed, $textDeletePressed) = (0, 0);
$canvas->focus($textID);
$canvas->CanvasFocus();


$canvas->eventGenerate('<Delete>');

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $TOP->update();
        $TOP->idletasks();
}

ok($deletePressed,     1, "Delete Key Check");
ok($textDeletePressed, 1, "Delete Key Check");

# Check return of focus
my $focusID = $canvas->focus();
ok($focusID, $textID, "Focus Return Check");

$focusID = $canvas->focus('');
ok($focusID, undef, "Focus Return Check 2");
 



