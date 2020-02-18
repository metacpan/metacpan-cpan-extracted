use Test::More;

use_ok('Mxpress::PDF');

my @data = qw/aaaaaa
bbbbb
cccc
eeee
ooooo
sssss/;

my $gen_text = sub { join( ' ', map { $data[int(rand(scalar @data))] } 0 .. int(rand(shift))) };

my $pdf = Mxpress::PDF->new_pdf('test',
	page => {
		background => '#000',
		padding => 10,
		columns => 2,
		rows => 2,
	},
	cover => {
		rows => 1,
		columns => 1,
		padding => 10,
	},
	toc => {
		font => { colour => '#00f' },
	},
	title => {
		font => { 
			colour => '#f00',
		},
	},
	subtitle => {
		font => { 
			colour => '#0ff', 
		},
	},
	subsubtitle => {
		font => { 
			colour => '#f0f',
		},
	},
	text => {
		font => { align => 'justify', colour => '#fff' },
		align => 'justify'
	},
);

$pdf->cover->add->title->add(
	'Add a cover page'
)->image->add(
	't/hand-cross.png'
)->cover->add(
	cb => ['text', 'add', q|you're welcome|]
);

#->cover->add(
#	cb => ['text', 'add', q|You're welcome|, %title_args]
$pdf->cover->end;

$pdf->page->header->add(
	show_page_num => 'right',
	page_num_text => "page {num}",
	cb => ['text', 'add', 'Header of the page', align => 'center', font => Mxpress::PDF->font($pdf, colour => '#f00') ],
	h => $pdf->mmp(10),
	padding => 10
);

$pdf->page->footer->add(
	show_page_num => 'left',
	cb => ['text', 'add', 'Footer of the page', align => 'center', font => Mxpress::PDF->font($pdf, colour => '#f00') ],
	h => $pdf->mmp(10),
	padding => 10
);

$pdf->title->add(
	$gen_text->(5)
)->toc->placeholder;

$pdf->page->rows(2);

for (0 .. 100) {
	$pdf->toc->add( 
		[qw/title subtitle subsubtitle/]->[int(rand(3))] => $gen_text->(4) 
	)->text->add( $gen_text->(1000) );
}

$pdf->save;

done_testing();
