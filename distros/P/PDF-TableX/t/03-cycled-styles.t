#!perl -T

use Test::More tests => 2;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(5,10);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

$table
	->padding(20)
	->cycle_background_color('#FFE100','#FF001E', '#9EFF00');

$table->col(2)->background_color('blue');

is($table->[0]->background_color(), '#FFE100');
is($table->[3]->background_color(), '#FFE100');

$table->[2][2]
	->border_width(10)
	->background_color('#cccccc')
	->font_color('black')
	->content('LOREM IPSUM')
	->font_size(20)
	->text_align('center')
	->font('Helvetica-Bold');
	
$table->draw($pdf, $page);
$pdf->saveas('t/03-cycled-styles.pdf');

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

done_testing;