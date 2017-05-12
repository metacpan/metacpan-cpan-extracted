use blib;
use PDLA;
use PDLA::Graphics::TriD;
use PDLA::Graphics::TriD::Graph;
use PDLA::Graphics::TriD::MathGraph;
use PDLA::Graphics::TriD::Labels;

$g = PDLA::Graphics::TriD::get_new_graph();
$g->default_axes();

$coords = [
 [ 0,-1,0 ],
 [ -1,-1,-2],
 [3,5,2],
 [2,1,-3],
 [1,3,1],
 [1,1,2],
];


$from = PDLA->pdl([0,1,2,3,4,4,4,5,5,5]);
$to = PDLA->pdl([1,2,3,1,0,2,3,0,1,2]);

for(@$coords) {
	push @$names,join ",",@$_;
}

$e = new PDLA::GraphEvolver(scalar @$coords);
$e->set_links($from,$to,PDLA->ones(1));
$c = $e->getcoords;

$g->add_dataseries($lab = new PDLA::Graphics::TriD::Labels($c,{Strings => $names}),
	"foo1");
$g->bind_default("foo1");

$g->add_dataseries($lin = new PDLA::Graphics::TriD::MathGraph(
	$c, {From => $from, To => $to}),"foo2");
$g->bind_default("foo2");

$g->scalethings();

nokeeptwiddling3d();
twiddle3d();
while(1) {
	$e->step();
	if(++$ind%2 == 0) {
		$lab->data_changed();
		$lin->data_changed();
		$g->scalethings() if (($ind % 200) == 0 or 1);
		print "C: $c\n" if $verbose;
		twiddle3d();
	}

}
