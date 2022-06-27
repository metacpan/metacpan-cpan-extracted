
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;
use Proch::N50;
use Test::More;
use FindBin qw($RealBin);
use Data::Dumper;
my $file = "$RealBin/../data/sim2.fa";
my $script = "$RealBin/../bin/n50";

if (-e "$file" and -e "$script") {
	my $output = `$^X "$script" "$file" 2>/dev/null`;
	ok($? == 0, '"n50" script executed');
	chomp($output);
	ok(defined $output, "Output from the n50 script is defined");
	ok($output == 493,  "N50==493 as expected: got $output");

	# TSV FORMAT
	$output = undef;

	$output = `$^X "$script" --format tsv "$file" 2>/dev/null`;
	ok($? == 0, '"n50" script executed');
	chomp($output);

	my @data = split /\t/, $output;
	ok($#data >= 10,  "Tabular output produced");
	ok($data[0] =~/^#/, "Header produced");
	ok($data[10] == 7_530, "Total size is 7,530: $data[10]") || print Dumper \@data;


	# THOUSAND SEPARATOR
	$output = undef;

	$output = `$^X "$script" --format tsv -q "$file" 2>/dev/null`;
	ok($? == 0, '"n50" script executed');
	chomp($output);

	@data = split /\t/, $output;
	ok($#data >= 10,  "Tabular output produced");
	ok($data[0] =~/^#/, "Header produced");
	ok($data[10] eq "7,530", "Total size is 7,530 with thousand separator: $data[10]");
}

done_testing();
