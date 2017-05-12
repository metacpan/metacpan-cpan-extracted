#!perl

use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use File::Basename;

use PerlIO::Util;
print "PerlIO::Util/$PerlIO::Util::VERSION\n\n";

my $perlbin = -d '/usr/bin' ? '/usr/bin' : dirname $^X;

my $count = do{
	my $n = 0;
	open my $dir, '<:dir', $perlbin or die $!;
	$n++ while defined(my $d = <$dir>);
	$n;
};
print "Number of files: $count\n";

cmpthese timethese -1 => {
	layer => sub{
		open my $dir, '<:dir', $perlbin or die $!;
		chomp while <$dir>;
	},
	core => sub{
		opendir my $dir, $perlbin or die $!;
		1 while defined($_ = readdir $dir);
	},
};
