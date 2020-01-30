use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);


my $file = "$Bin/../data/reads.qzv";

SKIP: {
	skip "Artifact not found" if (! -e "$file");
	my $artifact = Qiime2::Artifact->new({
		filename => "$file",
  });
	ok($artifact->{loaded} == 1, 'Artifact was loaded with custom unzip path');
	ok($artifact->{visualization}, 'Artifact is a visualization');
}


done_testing();
