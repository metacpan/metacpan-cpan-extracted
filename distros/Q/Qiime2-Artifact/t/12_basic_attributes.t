use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);


my $file = "$Bin/../data/table.qza";
my $id   = 'd27b6a68-5c6e-46d9-9866-7b4d46cca533';
my $version = "2018.6.0";
my $archive = 4;
print "$file\n";

SKIP: {
	skip "missing input file" unless (-e "$file");
	system('unzip > /dev/null');
	skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);
	my $artifact = Qiime2::Artifact->new({ filename => "$file" });
	ok($artifact->{loaded} == 1, 'Artifact was loaded');
	ok($artifact->{id} eq "$id", 'Artifact has correct ID ' . $id);
	ok($artifact->{visualization} == 0, 'Artifact is not a visualization, but visualization is set');
	if ($^O eq 'linux' or $^O eq 'darwin') {
		ok(substr($artifact->{filename}, 0, 1) eq '/', '{filename} Artifact filename is absolute path (Linux/MacOS)');
	}
	ok($artifact->{version} eq $version, '{version} Artifact has correct version: '. $artifact->{version} );
	ok($artifact->{archive} eq $archive, '{archive} Artifact has correct archive version: '. $artifact->{archive} );


	ok($artifact->{imported} == 0, '{imported} Artifact is derived, not original');
	ok($artifact->{data}[0], "Artifact contains data");
}

done_testing();
