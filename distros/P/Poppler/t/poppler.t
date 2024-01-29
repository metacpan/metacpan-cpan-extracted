#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use Scalar::Util qw/blessed/;
use Poppler;

chdir $FindBin::Bin;

require_ok ("Poppler");

my $fn1 = 'test.pdf';

ok (my $pdf = Poppler::Document->new_from_file($fn1),
    "loaded new Document from filename");
ok ($pdf->get_author   eq 'Jane Doe',          "author matched");
ok ($pdf->get_creator  eq 'John Doe',          "creator matched");
ok ($pdf->get_producer eq 'some-program',      "producer matched");
ok ($pdf->get_title    eq 'A Test Document',   "title matched");
ok ($pdf->get_subject  eq 'Testing',           "subject matched");
ok ($pdf->get_keywords eq 'test poppler perl', "keywords matched");
ok ($pdf->get_n_pages == 2,                    "page count matched");
ok (my $p1 = $pdf->get_page(0),                "fetched first page");

# check both interfaces
my ($w, $h) = $p1->get_size;
ok ($w == 288 && $h == 288,                    "dimensions matched");

my $dim = $p1->get_size;
ok (blessed($dim) && $dim->isa("Poppler::Page::Dimension"),
    "get_size returned obj in scalar context");
ok ($dim->get_width  == 288,                    "object width matched");
ok ($dim->get_height == 288,                    "object height matched");

my $rect = $p1->find_text('BAR');
ok (int($rect->x1) == 126,                     "text find x1 matched");
ok (int($rect->y2) == 48,                      "text find y2 matched");
ok (my $p2 = $pdf->get_page(1),                "fetched second page");
ok (! $p2->find_text('BAR'),                   "no match second page");
ok ($p2->find_text('BAZ'),                     "yes match second page");

# test new_from_data()
my $size = -s $fn1;
open my $in, '<:raw', $fn1 or die "Error opening test file for reading: $@";
my $r = read($in, my $data, $size) or die "Error reading raw data: $@";
ok ($pdf = Poppler::Document->new_from_data($data),
    "loaded new Document from data");
ok ($pdf->get_author   eq 'Jane Doe', "author matched");

done_testing();
exit;
