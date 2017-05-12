
use Tcl::pTk;
#use Tk;
use Test;

plan tests => 1;

my $TOP = MainWindow->new();


my $frame = $TOP->Frame(-borderwidth => 10)->pack;

my $canvas = $frame->Canvas(
qw/-width 100 -height 100 -borderwidth 0 -highlightthickness 0/);
my $id = $canvas->createPolygon(qw/0 0 10 10 20 10 -fill SeaGreen3 -tags poly/);
my $lineID1 = $canvas->createLine(qw/0 0 10 10 20 20 30 30 40 40 -fill black -tags line/);
my $lineID2 = $canvas->createLine(qw/5 15 15 25 25 35 35 45 45 55 -fill black -tags line/);
$canvas->pack(qw/-side left -anchor nw -fill both/);

my @ids = $canvas->find('withtag', 'line');


ok(scalar(@ids), 2, "canvas find returns list");

#print "ids returned '".join("', '", @ids)."'\n";


                
MainLoop if(@ARGV);



