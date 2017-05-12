use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Perlmazing;

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
	100
	1000
	1001
	001000
);

@values = sort numeric @values;

is join(',', @values), '0,1,2,3,3,4,5,6,7,8,9,10,20,100,001000,1000,1001,123string,ark,bee,code', 'numeric sort';

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
	book_10_page_3a
	book_10_page_3k
	book_010_page_1
	book_0010_page_2
);
@values = sort numeric @values;
is join(',', @values), 'book_01_page_1,book_1_page_01,book_1_page_1,book_01_page_2,book_1_page_02,book_1_page_2,book_01_page_3,book_1_page_03,book_1_page_3,book_010_page_1,book_0010_page_2,book_10_page_3,book_10_page_3a,book_10_page_3k,book_10_page_3z', 'middle numbering sort';
