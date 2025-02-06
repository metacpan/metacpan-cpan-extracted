use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing qw(numeric);

my @values = qw(
	3
	8
	2
	0
	1
	3
	7
	5
	bee
	4
	ark
	9
	code
	6
	20
	10
	123string
  123trip
  123String
  123Trip
	100
	1000
	1001
	001000
  123String
  123Trip
	123string
  123trip
);

@values = sort numeric @values;

is join(',', @values), '0,1,2,3,3,4,5,6,7,8,9,10,20,100,123String,123String,123string,123string,123Trip,123Trip,123trip,123trip,1000,001000,1001,ark,bee,code', 'numeric sort';

@values = qw(
	book_1_page_3
	book_1_page_1
	book_1_page_2
	book_1_page_03
	book_1_page_01
	book_1_page_02
	book_01_page_3
	book_01_page_1
	book_01_page_2
	book_10_page_3
	book_10_page_3z
	Book_01_page_1
	Book_01_page_2
	book_10_page_3a
	book_10_page_3k
	book_01_Page_1
	book_01_Page_2
	book_010_page_1
	book_0010_page_2
);
@values = sort numeric @values;
is join(',', @values), 'Book_01_page_1,book_01_Page_1,book_01_page_1,book_1_page_01,book_1_page_1,Book_01_page_2,book_01_Page_2,book_01_page_2,book_1_page_02,book_1_page_2,book_01_page_3,book_1_page_03,book_1_page_3,book_010_page_1,book_0010_page_2,book_10_page_3,book_10_page_3a,book_10_page_3k,book_10_page_3z', 'middle numbering sort';

@values = (
  "v1.0",
  "v1.0.1",
  "v1.0.2",
  "v1.0.3",
  "v1.0.4",
  "v1.1.1",
  "v1.1.2",
  "v1.1.3",
  "v1.2.1",
  "v1.1",
  "v1.2",
  "v1.3",
  "v2.0",
  "v2.0.1",
  "v2.2.1",
  "v2.3.1",
  "v2.13.1",
  "v2.2",
  "v2.1",
  "v2.10",
  "v2.11",
  "v2.12",
  "v2.13",
  "v2.14",
  "v2.14.01",
  "v2.14.1",
  "v2.14.010",
  "v2.14.0100",
  "v2.14.01",
  "v2.14.10",
  "v2.2",
  "v2.3",
  "v2.4",
  "v2.5",
  "v2.6",
  "v2.7",
  "v2.8",
  "v2.9",
  '00100',
  100,
);
@values = sort numeric @values;
is join(',', @values), '100,00100,v1.0,v1.1,v1.2,v1.3,v2.0,v2.1,v2.10,v2.11,v2.12,v2.13,v2.14,v2.2,v2.2,v2.3,v2.4,v2.5,v2.6,v2.7,v2.8,v2.9,v1.0.1,v1.0.2,v1.0.3,v1.0.4,v1.1.1,v1.1.2,v1.1.3,v1.2.1,v2.0.1,v2.2.1,v2.3.1,v2.13.1,v2.14.01,v2.14.01,v2.14.010,v2.14.0100,v2.14.1,v2.14.10', 'version type sorting';

