#!perl -T

use Test::More tests => 10;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(8,8);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

is_deeply( $table->padding, [1,1,1,1], 'Default padding settings');
is_deeply( { $table->properties }, {
	'padding'          => [1,1,1,1],
	'border_width'     => [1,1,1,1],
	'border_color'     => ['black','black','black','black'],
	'border_style'     => ['solid','solid','solid','solid'],
	'background_color' => '',
	'text_align'       => 'left',
	'font_size'        => 12,
	'font'             => 'Times',
	'font_color'       => 'black',
	'margin'           => [10/25.4*72,10/25.4*72,10/25.4*72,10/25.4*72],
}, 'Check all default style values' );

$table->padding(10);
is_deeply( $table->padding, [10,10,10,10], 'Convert scalar to array_ref');

$table->padding([20,1,30,1]);
is_deeply( $table->[0]->padding, [20,1,30,1], 'Check attributes propagation');
is_deeply( $table->[0][0]->padding, [20,1,30,1], 'Check attributes propagation');

isa_ok($table->[0], 'PDF::TableX::Row');
isa_ok($table->[0][0], 'PDF::TableX::Cell');

isa_ok($table->col(0), 'PDF::TableX::Column');
isa_ok($table->col(0)->[0], 'PDF::TableX::Cell');

for my $i (0..$table->rows-1) {
	for my $j (0..$table->cols-1) {
		if (($i+$j) % 2) {
			$table->[$i][$j]
				->background_color('black')
				->content('black')
				->font_color('white')
				->font_size(10)
				->text_align('right');
		} else {
			$table->[$i][$j]
				->content('white')
				->font_color('black')
				->font_size(10)
				->text_align('center');
		}
	}
}

is($table->[0][1]->font_color, 'white');

$table->draw($pdf, $page);
$pdf->saveas('t/01-simple-mesh.pdf');

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

done_testing;