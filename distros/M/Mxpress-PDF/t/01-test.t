use Test::More;

use_ok('Mxpress::PDF');

my @data = qw/Brian
Dougal
Dylan
Ermintrude
Florence
Zebedee/;

my $gen_text = sub { join( ' ', map { $data[int(rand(scalar @data))] } 0 .. int(rand(shift))) };

my $pdf = Mxpress::PDF->new_pdf('test',
	page => {
		background => '#000',
		padding => 15,
	},
	toc => {
		font => { colour => '#00f' },
	},
	title => {
		font => { 
			colour => '#f00',
		},
		margin_bottom => 3,
	},
	subtitle => {
		font => { 
			colour => '#0ff', 
		},
		margin_bottom => 3
	},
	subsubtitle => {
		font => { 
			colour => '#f0f',
		},
		margin_bottom => 3
	},
	text => {
		font => { align => 'justify', colour => '#fff' },
		margin_bottom => 3
	},
)->add_page->title->add(
	$gen_text->(5)
)->toc->placeholder;

$pdf->page->columns(2);

for (0 .. 100) {
	$pdf->toc->add( 
		[qw/title subtitle subsubtitle/]->[int(rand(3))] => $gen_text->(4) 
	)->text->add( $gen_text->(1000) );
}

$pdf->save;

done_testing();
