# Local Drag/Drop Test

#use Tk;
#use Tk::DragDrop;
#use Tk::DropSite;

use Tcl::pTk;
use Tcl::pTk::DragDrop;
use Tcl::pTk::DropSite;

use Test;

plan test => 1;

use strict;
use vars qw($top $f $lb_src $lb_dest $dnd_token);

$top = MainWindow->new();

#$top->geometry('+300+300');


$top->Label(-text => "Drag items from the left listbox to the right one"
	   )->pack;
$f = $top->Frame->pack;
$lb_src  = $f->Listbox()->pack(-side => "left");
$lb_dest = $f->Listbox()->pack(-side => "left");

$lb_src->insert("end", map "Label$_", (1..5));

# Define the source for drags.
# Drags are started while pressing the left mouse button and moving the
# mouse. Then the StartDrag callback is executed.
$dnd_token = $lb_src->DragDrop
  (-event     => '<B1-Motion>',
   -sitetypes => ['Local'],
   -startcommand => sub { StartDrag($dnd_token) },
  );
# Define the target for drops.
$lb_dest->DropSite
  (-droptypes     => ['Local'],
   -dropcommand   => [ \&Drop, $lb_dest, $dnd_token ],
  );

#$lb_src->bind('<B1-Motion>', sub{print "lbl_src Motion\n"});
  
$top->update;


###### Simulate drag/dropping: ########
my $SimulatedDrag = 1; # Flag to indicate simulated Drag

my @coords = $lb_src->bbox(1);
#print "coords = ".join(", ", @coords)."\n";

# Get Src/Dest location, so we know where to stop dragging
my $srcX = $lb_src->rootx;
my $srcY = $lb_src->rooty;
my $destX = $lb_dest->rootx;
my $destY = $lb_dest->rooty;
#print "dest x/y = $destX/$destY\n";

my ($startX, $startY) = ($coords[0] + $srcX, $coords[1] + $srcY );
#print "StartX/Y = $startX/$startY\n";


### Mouse Drag
my ($X, $Y) = ($startX, $startY);
# We use direct calls to tcl so we can leave the window arg empty, which sends events
#  to the whole app
#$lb_src->focus();
$top->update;

# Start the drag
my $dragStarted; # Flag = 1 when drag started (set in Drag sub below)
while ( !$dragStarted ){
        $dnd_token->StartDrag($X+=5, => $Y);
}


# Drag over to the other area
while($X < $destX+10){
        $dnd_token->Drag($X+=5, => $Y);
	$top->update;
        $top->after(50);
        
}

$top->update();
##### Mouse Release / drop 
#$dnd_token->grabRelease;
#$lb_src->eventGenerate( '<B1-ButtonRelease>', -x => $X, -y => $Y, -warp => 1);
$dnd_token->Drop($X, $Y);
$top->update;

$SimulatedDrag = 0;
$dragStarted   = 0;

# Check that the item was dragged
my $destItem = $lb_dest->get(0);
#print "destItem = $destItem\n";
ok($destItem, 'Label2', "Unexpected value for dest label");


$top->after(1000, sub{ $top->destroy }) unless (@ARGV); # Persist if any args supplied, for debugging

MainLoop;

sub StartDrag {
    my($token) = @_;
    my $w = $token->parent; # $w is the source listbox
    
    # Get pointer x/y, Use global X/Y variables if simulating
    my ($X,$Y) = ($X, $Y);
    ($X, $Y) = $w->pointerxy unless( $SimulatedDrag);
        
    # print "In Start Drag\n";
    $dragStarted = 1;
    
    # Coords of root window
    my $rX = $w->rootx;  
    my $rY = $w->rooty;
    
    # Coords relative to root window
    my ($x, $y) = ( $X - $rX, $Y - $rY);

    my $idx = $w->nearest($y); # get the listbox entry under cursor
    
    
    if (defined $idx) {
	# Configure the dnd token to show the listbox entry
	$token->configure(-text => $w->get($idx));
	# Show the token
	$token->MoveToplevelWindow($X, $Y);
	$token->raise;
	$token->deiconify;
	$token->FindSite($X, $Y);
    }
}

# Accept a drop and insert a new item in the destination listbox.
sub Drop {
    my($lb, $dnd_source) = @_;
    $lb->insert("end", $dnd_source->cget(-text));
    $lb->see("end");
}

__END__

