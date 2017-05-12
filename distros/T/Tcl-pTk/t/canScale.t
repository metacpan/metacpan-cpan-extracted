# vscale.pl

use Tcl::pTk;
use Test;

plan tests => 6;

my $TOP = MainWindow->new();


my $frame = $TOP->Frame(-borderwidth => 10)->pack;

my $canvas = $frame->Canvas(
qw/-width 50 -height 50 -borderwidth 0 -highlightthickness 0/);
my $id = $canvas->createPolygon(qw/0 0 1 1 2 2 -fill SeaGreen3 -tags poly/);
$canvas->createLine(qw/0 0 1 1 2 2 0 0 -fill black -tags line/);

my $scale = $frame->Scale(qw/-orient vertical -length 284 -from 0
-to 250 -tickinterval 50 -command/ => [\&vscale_height, $canvas]);
$scale->set(75);

$scale->pack(qw/-side left -anchor ne/);
$canvas->pack(qw/-side left -anchor nw -fill y/);

####### Create a text item, for testing ####
# Create dummy item, so we can see what font is used
my $dummyID = $canvas->createText( 100,25, -text => "You should never see this" );
my $defaultfont = $canvas->itemcget($dummyID,-font);

ok( ref($defaultfont), 'Tcl::pTk::Font', "itemcget -font return value check");

# Delete the dummy item
$canvas->delete($dummyID);


# Check return of 2-arg bind for items
$canvas->bind('line', '<Any-Enter>' => sub{ print "Line Entry\n"});
my $bindRet = $canvas->bind('line', '<Any-Enter>');
#print "bindRet = $bindRet\n";
ok(ref($bindRet), 'Tcl::pTk::Callback', "Canvas 2-arg bind returns callback");

# Check return of 1-arg bind for items
my @bindRet = $canvas->bind('line');
#print "bindRet = $bindRet\n";
ok(join(", ",@bindRet), '<Enter>', "Canvas 1-arg bind returns list of sequences");


$canvas->CanvasBind('<1>', sub{ print "Button1\n"});
$bindRet = $canvas->CanvasBind('<1>');
#print "bindRet = $bindRet\n";
ok(ref($bindRet), 'Tcl::pTk::Callback', "CanvasBind returns callback");


my $fill = $canvas->itemcget($id, -fill);
#print "fill = $fill\n";
ok($fill, 'SeaGreen3', "Canvas Fill Readback");

my $stipple = $canvas->itemcget($id, -stipple);
#print "stipple = '$stipple'\n";
# Readback of non-set option should return undef (compatible with perltk)
ok(!defined($stipple));

$TOP->after(1000,sub{$TOP->destroy});

MainLoop;

sub vscale_height {

    my($w, $height) = @_;

    $height += 21;
    my $y2 = $height - 30;
    $y2 = 21 if $y2 < 21;
    $w->coords('poly', 15, 20, 35, 20, 35, $y2, 45, $y2, 25, $height, 5, $y2,
	       15, $y2, 15, 20);
    $w->coords('line', 15, 20, 35, 20, 35, $y2, 45, $y2, 25, $height, 5, $y2,
	       15, $y2, 15, 20);

} # end vscale_height


