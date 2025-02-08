
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

my $file = "$RealBin/../data/small_test.fa";
my $script = "$RealBin/../bin/n50";

if (-e "$file" and -e "$script") {

	my $output = `$^X "$script" --format custom --template "{N50}{tab}{path}" "$file"`;
	ok($? == 0, "'n50' script executed: exit=$?");
  chomp($output);
  my @fields = split /\t/, $output;
  ok($fields[0] == 65,  "N50==65 as expected: got $fields[0]");
  ok(defined $fields[1],  "Expected path in column 2: got $fields[1]");
  ok($#fields == 1,  "Expected no third column: got " . $#fields . " indexes");

}

done_testing();
