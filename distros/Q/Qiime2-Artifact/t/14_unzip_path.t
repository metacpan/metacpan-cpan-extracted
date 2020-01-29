use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);


my $file = "$Bin/../data/table.qza";
my $unzip_path = `which unzip`;
chomp($unzip_path);
print "Testing:\t$file\nWith:\t$unzip_path\n";



SKIP: {
	skip "Unable to guess unzip path" if ($? != 0 or (not $unzip_path));
	my $artifact = Qiime2::Artifact->new({
		filename => "$file",
		unzip    => "$unzip_path",
  });
	ok($artifact->{loaded} == 1, 'Artifact was loaded with custom unzip path');
}

eval {
	my $bad_artifact = Qiime2::Artifact->new({
		filename => "$file",
		unzip    => "/not/a/valid/unzip/path/",
	});
};

ok($@, 'Artifact *not* loaded when using invalid unzip path');

done_testing();
