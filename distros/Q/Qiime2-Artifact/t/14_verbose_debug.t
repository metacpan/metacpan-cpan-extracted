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
		filename   => "$file",
		verbose    => 1,
  });
	ok($artifact->{loaded} == 1, 'Artifact was loaded with verbose attribute');

	my $debug = Qiime2::Artifact->new({
		filename   => "$file",
		debug    => 1,
  });
	ok($debug->{loaded} == 1, 'Artifact was loaded with verbose attribute');

	eval {
		my $param_check = Qiime2::Artifact->new({
			filename   => "$file",
			debug      => 1,
			bad_param  => 1,
	  });
	
	};
	ok($@, "Artifact was not loaded because new() had an invalid parameter");
}


done_testing();
