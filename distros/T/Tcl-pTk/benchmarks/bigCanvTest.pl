# Benchmark of creating a lot of lines on a canvas

use Tcl::pTk;

$MW = MainWindow->new;

my $c = $MW->Canvas(-width, 400, -height, 400);

$c->pack;

$| = 1; # Pipes hot

my $t0 = time();
#$MW->geometry('400x400');
@coords = map int(rand() * 200)+100, (0..19);

my $i;
for ( $i=0; $i<100000; $i++){

	
	$c->createLine(@coords,  -fill => 'black');
	#$rect = $c->create('rect', @coords, -fill => 'white');
	#$c->raise($rect);
	#$c->raise($text);
}

my $t1 = time();
print "total time = ".($t1-$t0)."\n";

MainLoop;


