# Net::EANSearch

A Perl module for EAN and ISBN lookup and validation using the EAN / ISBN API on https://www.ean-search.org

You can
- lookup EAN barcodes
- lookup ISBNs (ISBN-10 or ISBN-13)
- search for products by name or keyword (eg. to find the EAN)
- search a product category by name or key word
- search for all EANs with a certain prefix
- verify if an EAN or ISBN-13 is valid
- lookup the country where an EAN was issued
- generate PNG barcode images

# INSTALLATION

Install from CPAN
```sh
cpan -i Net::EANSearch
```

Or do a manual install by typing the following:
```sh
   perl Makefile.PL
   make
   make test
   make install
```

# DEPENDENCIES

This module requires these other Perl modules:

- LWP
- JSON
- URL::Encode
- MIME::Base64
- Test::NoWarnings


# COPYRIGHT AND LICENCE

Copyright (C) 2024 by Relaxed Communications GmbH (info@relaxedcommunications.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


# EXAMPLE

```perl
#!/usr/bin/perl
use strict;
use warnings;

use Net::EANSearch;

my $API_TOKEN = $ENV{EAN_SEARCH_API_TOKEN};

my $eansearch = Net::EANSearch->new($API_TOKEN);

my $ean = '5099750442227';
my $isbn = '1119578884';

my $product = $eansearch->barcodeLookup($ean);

if (!defined($product)) {
	print "No product found for EAN $ean\n";
} else {
	print "EAN $ean is $product->{name}\n";
}

my $book = $eansearch->isbnLookup($isbn);

if (!defined($book)) {
	print "No book found for ISBN $isbn\n";
} else {
	print "ISBN $isbn is ISBN-13 $book->{ean} : $book->{name}\n";
}

my @product_list;
@product_list = $eansearch->barcodePrefixSearch('885909', $Net::EANSearch::ENGLISH);
foreach my $p (@product_list) {
	print "EAN $p->{ean} is $p->{name}\n";
}

my $page = 0;
do {
	$page++;
	@product_list = $eansearch->productSearch('Bananaboat', $Net::EANSearch::ALL_LANGUAGES, $page);

	foreach my $p (@product_list) {
		print "EAN $p->{ean} is $p->{name}\n";
	}
} while (@product_list == 10);

$page = 0;
do {
	$page++;
	@product_list = $eansearch->similarProductSearch('Apple iPhone 16 exotic keywords white', $Net::EANSearch::ENGLISH, $page);

	foreach my $p (@product_list) {
		print "EAN $p->{ean} is $p->{name}\n";
	}
} while (@product_list == 10);

my @book_list = $eansearch->categorySearch(15, 'iphone');

foreach my $p (@book_list) {
	print "$p->{ean} is $p->{name}\n";
}

my $country = $eansearch->issuingCountry($ean);
print "Issuing country for EAN $ean is $country\n";

my $img = $eansearch->barcodeImage($ean);
#print "Image for EAN $ean is $img\n";

my $ok = $eansearch->verifyChecksum($ean);
print "EAN $ean is " . ($ok ? 'valid' : 'invalid') . "\n";
$ean = '1234567890123';
$ok = $eansearch->verifyChecksum($ean);
print "EAN $ean is " . ($ok ? 'valid' : 'invalid') . "\n";
```

