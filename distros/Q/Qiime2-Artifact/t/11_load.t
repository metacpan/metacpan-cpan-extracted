use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);


my $file = "$Bin/../data/table.qza";
my $id   = 'd27b6a68-5c6e-46d9-9866-7b4d46cca533';
my $version = "2018.6.0";
print "$file\n";

SKIP: {
	skip "missing input file" unless (-e "$file");
	my $artifact = Qiime2::Artifact->new({ filename => "$file" });
	ok($artifact->{loaded} == 1, 'Artifact was loaded');
	ok($artifact->{id} eq "$id", 'Artifact has correct ID ' . $id);
	ok($artifact->{visualization} == 0, 'Artifact is not a visualization, but visualization is set');
	if ($^O eq 'linux' or $^O eq 'darwin') {
		ok(substr($artifact->{filename}, 0, 1) eq '/', 'Artifact filename is absolute path (Linux/MacOS)');
	}

	ok($artifact->{data}[0], "Artifact contains data");
	ok($artifact->{version} eq $version, 'Artifact has correct version: '. $artifact->{version} );
}

done_testing();
