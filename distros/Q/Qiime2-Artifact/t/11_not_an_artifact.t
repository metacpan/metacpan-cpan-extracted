use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);
use File::Basename;
my $file = "$Bin/../data/non_artifact.zip";
my $basefile = basename($file);

SKIP: {
	skip "missing input file" unless (-e "$file");
	system('unzip > /dev/null');
	skip "\nunzip not found, but a path could be specified\nwhen creating the instance of Qiime2::Artifact\n" if ($?);

  eval {
   print STDERR "$basefile is not a valid artifact.\n";
	 my $artifact = Qiime2::Artifact->new({ filename => "$file" });
   print STDERR "\n";
  };

  ok($@, "$basefile is not an artifact");

}

done_testing();
