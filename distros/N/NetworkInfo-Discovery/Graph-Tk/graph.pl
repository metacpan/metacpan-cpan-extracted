#!/usr/bin/perl

use strict;
use warnings;

use Tk;
use Tk::Label;
use lib qw(.);
use TkGraph;

my $STEP = 200; # in miliseconds
my $WINDOWX = 700;
my $WINDOWY = 500;
my $STATUSBAR = "this is the status";
my $OBJECTBAR = "this is the status\nand more stuf";

my $mw = new MainWindow(
                -title  =>  "This is a test",
                -width  =>  $WINDOWX,
                -height =>  $WINDOWY,
            );

$mw->bind('<q>' => sub { exit; });
$mw->bind('<Escape>' => sub { exit; });

my $object_detail = $mw->Label(
	        -textvariable   => \$OBJECTBAR,
		-relief => 'sunken',
		-anchor =>'w',
	    )->pack( 
		-side => 'left',
		-fill => "both"
	    );

my $canvas = $mw->Canvas(
                -bg     =>  "black",
                -width  =>  $WINDOWX,
                -height =>  $WINDOWY
            )->pack();

$canvas->CanvasBind('<Button-1>' => \&display_coordinates);

my $status_label = $mw->Label(
		-textvariable   => \$STATUSBAR,
		-relief => 'sunken',
		-anchor => 'w',
	    )->pack( 
		-fill => "both"
	    );


my $g = new TkGraph(
    canvas => $canvas,
    file   => "/tmp/test.xml",
);


#$g->circular_map;
$g->random_map;
bind_nodes($g);

$canvas->repeat($STEP, sub { $g->show_verts; } );


MainLoop();

sub display_coordinates {
    my($canvas) = @_;
    my $e = $canvas->XEvent;
    my($x, $y) = ($e->x, $e->y);
    $STATUSBAR = "Plot x = $x, Plot y = $y.";
}


sub bind_nodes {
    my $graph = shift;

    foreach my $v ($graph->vertices) {
	my $objstr ="";
	my %attr = $graph->get_attributes($v);
	print "doing $attr{'id'}\n";
	foreach my $k (  keys %attr ) {
	    $objstr .= "$k => " . $attr{$k} ."\n" if (exists $attr{$k} && defined $attr{$k});
	}
	$graph->canvas->bind($attr{'id'}, 
	    '<Button-1>' =>  sub {
		$OBJECTBAR = $objstr;
	    }
	);
    }
#    $self->canvas->bind($id, '<Button-1>' => sub {  print "clicked $id\n";} );

}
