#!perl -T

use Test::More tests => 4;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(2,2);
my $pdf = PDF::API2->new();
$pdf->mediabox('a4');
my $page = $pdf->page;

$table->[0][0]->content("Lorem ipsum dolor sit amet\nsome other text\nand some more");
$table->[0][1]->content("Lorem ipsum dolor sit amet\nsome other text\nand some more");
$table->[1][0]->content("Lorem ipsum dolor sit amet\nsome other text\nand some more");
$table->[1][1]->content("Lorem ipsum dolor sit amet\nsome other text\nand some more");

is($table->rows, 2);
is($table->cols, 2);
is(scalar @{$table}, 2);
is($table->[0][0]->content, "Lorem ipsum dolor sit amet\nsome other text\nand some more");

$table->[1][1]->font_color('red');
$table->[0][1]->font_color('green');
$table->[1][0]->font_color('#0000ff');

$table->[0]
	->padding([10,1,10,1])
	->border_width(5);

$table->draw($pdf, $page);
$pdf->saveas('t/02-place-text.pdf');

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );

done_testing;