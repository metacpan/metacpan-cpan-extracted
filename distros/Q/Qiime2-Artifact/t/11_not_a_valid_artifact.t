use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);
use File::Basename;
my $file = "$Bin/../data/bad_artifact.zip";
my $basename = basename($file);

SKIP: {
	skip "missing input file" unless (-e "$file");
	system('unzip > /dev/null');
	skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);

  eval {
   print STDERR "Trying to load a bad artifact: $basename:\n";
	 my $artifact = Qiime2::Artifact->new({ filename => "$file" });
   print STDERR "\n";
  };

  ok($@, "$file is not an artifact");

}

done_testing();
