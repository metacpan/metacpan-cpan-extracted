use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file = "$Bin/../data/table.qza";
my $id   = 'd27b6a68-5c6e-46d9-9866-7b4d46cca533';
my $version = "2018.6.0";


SKIP: {
	skip "missing input file" unless (-e "$file");
	my $artifact = Qiime2::Artifact->new({ filename => "$file" });
	print 'VERSION ', $Qiime2::Artifact::VERSION, "\n";
	ok($artifact->{imported} == 0, "Artifact is not imported (is derived)");
	ok($artifact->{parents_number}  == 1, 'Artifact has 1 parent: '. $artifact->{parents_number} );
}

done_testing();
