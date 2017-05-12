use Test::More tests => 5;

use strict;
use warnings;
use FindBin;
use Path::Class;

BEGIN { use_ok('PDF::pdf2json') }

my $pdf = dir( $FindBin::Bin )->subdir('data')->file('test.pdf');
my $pages_count = 3;

my $data = PDF::pdf2json->pdf2json( "$pdf" );

is( @$data, $pages_count, 'correct length' );

is( $data->[0]{pages}, $pages_count, 'correct number of pages' );

# get the 2nd page
my $data_page_1 = PDF::pdf2json->pdf2json( "$pdf", page => 1 );

is( @$data_page_1, 1, 'correct length' );
is( $data_page_1->[0]{number}, 1, 'correct length' );

#use DDP; p $data;
#use DDP; p $data_page_1;

done_testing;
