use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file = "$Bin/../data/bad_artifact.zip";
SKIP: {
	skip "missing input file" unless (-e "$file");
	system('unzip > /dev/null');
	skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);

  eval {
   print STDERR "Not a valid artifact $file:\n";
	 my $artifact = Qiime2::Artifact->new({ filename => "$file" });
   print STDERR "\n";
  };

  ok($@, "$file is not an artifact");

}

done_testing();
