use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Perlmazing;
use File::Spec;

my $path = 'test_file.txt';
unless (-f $path) {
	my $other_path;
	unless (-f ($other_path = File::Spec->catfile('t', $path))) {
		die "Cannot find file $path nor $other_path in the current working directory";
	}
	$path = $other_path;
}

is md5_file($path), '86fb269d190d2c85f6e0468ceca42a20', 'right md5 for content';
isnt md5_file($0), '86fb269d190d2c85f6e0468ceca42a20', 'right md5 for content';
