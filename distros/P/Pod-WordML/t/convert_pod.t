#!perl
use strict;
use warnings;

use Test::More 0.98;

use File::Spec::Functions;
require './t/lib/transform_file.pl';

my @files =
	map { s|\Atest-corpus[\\/]||; $_ }
	glob( 'test-corpus/*.pod' )
	;

foreach my $file ( @files ) {
	subtest "$file" => sub { transform_file( $file ) };
	}

done_testing();
