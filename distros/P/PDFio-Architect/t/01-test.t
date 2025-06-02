use Test::More;

use PDFio::Architect;

my $architect = PDFio::Architect->new('test.pdf');

$architect->load_font("F1", "Courier");

my @sizes = (
	'A0',
	'A1',
	'A2',
	'A3',
	'A4',
	'A5',
	'A6',
	'Letter',
	'Legal',
	'Tabloid',
	'B5',
	'B4',
	'B3',
	'B2',
	'B1',
	'B0',
	'100x100'
);

$architect->add_page()->add_text({
	text => "Hello World",
	size => 55,
	bounding => $architect->new_rect(10, 10, 500, 400)
})->done;


my $page = $architect->add_page({ size => 'A4' });

$page->add_text({
	text => "This is multi line, " x 109,
	size => 18,
	bounding => $architect->new_rect(20, 20, $page->width - 20, $page->height - 20)
});

$page->done;

for (1..$#sizes) {
	$architect->add_page({ size => $sizes[$_] });
}

is($architect->total_pages, 18);

$architect->save();

done_testing();

1;
