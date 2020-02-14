use Test::More;

use_ok('Mxpress::PDF');

ok(my $pdf = Mxpress::PDF->new_pdf('test',
	page => {
		background => '#000',
		padding => 5
	}
)->add_page, 'add a page');

my $page = $pdf->page;

test_attributes($page,
	padding => 5,
	page_size => 'A4',
        background => '#000',
	num => 1,
	current => 'PDF::API2::Page',
	is_rotated => 0,
	x => 14,
	y => 827,
	w => 580,
	h => 799
);

ok($page->rotate(), 'rotate page');

test_attributes($page,
	is_rotated => 1,
	x => 14,
	y => 580,
	w => 827,
	h => 552
);

ok($pdf->add_page(), 'add another page');

ok($page = $pdf->page, 'current page');

test_attributes($page,
	padding => 5,
	page_size => 'A4',
        background => '#000',
	num => 2,
	current => 'PDF::API2::Page',
	is_rotated => 1,
	x => 14,
	y => 580,
	w => 827,
	h => 552
);

ok($pdf->add_page(padding => 0), 'add another page with no padding');

ok($page = $pdf->page, 'current page');

test_attributes($page,
	padding => 0,
	page_size => 'A4',
        background => '#000',
	num => 3,
	current => 'PDF::API2::Page',
	is_rotated => 1,
	x => 0,
	y => 595,
	w => 842,
	h => 595
);

sub test_attributes {
	my $page = shift;
	while ( @_ ) {
		my ($key, $value) = (shift, shift);
		my $attr = $page->$key;
		if (ref $attr ) {
			if (!ref $value) {
				is(ref $attr, $value, $key);
			} else {
				is_deeply($attr, $value, $key);
			}
		} else {
			if ($attr =~ m/[^\d\.]/) {
				is($attr, $value, $key);
			} else {
				is(int($attr), $value, $key);
			}

		}
	}
}


done_testing();
