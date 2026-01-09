# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Net-EANSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More qw( no_plan );
use Test::NoWarnings;
BEGIN { use_ok('Net::EANSearch') };

#########################

my $eansearch = Net::EANSearch->new('invalid-token');
ok(defined($eansearch));

# additional unit tests if we have an API token available
if ($ENV{EAN_SEARCH_API_TOKEN}) {
	$eansearch = Net::EANSearch->new($ENV{EAN_SEARCH_API_TOKEN});

	my $credits_before = $eansearch->creditsRemaining();
	ok($credits_before > 0, 'has credits');

	my $product = $eansearch->barcodeLookup('5099750442227');
	ok(defined($product), 'has result');
	like($product->{name}, qr/Thriller/, 'correct product');
	is($product->{ean}, '5099750442227', 'same EAN');
	is($product->{issuingCountry}, 'UK', 'issuingCountry');

	my $book = $eansearch->isbnLookup('1119578884');
	ok(defined($book), 'has result');
	like($book->{name}, qr/Linux Bible/, 'correct book');
	is($book->{ean}, '9781119578888', 'correct ISBN-13');
	is($book->{issuingCountry}, '', 'issuingCountry');

	my @product_list = $eansearch->productSearch('Bananaboat', $Net::EANSearch::ALL_LANGUAGES);

	foreach my $p (@product_list) {
		like($p->{name}, qr/Bananaboat/, 'matching name');
	}

	my $credits_after = $eansearch->creditsRemaining();
	ok($credits_after < $credits_before, 'has used credits');
}

