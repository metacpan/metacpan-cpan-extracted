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
	system('unzip > /dev/null');
	skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);
	my $artifact = Qiime2::Artifact->new({ filename => "$file" });
	ok($artifact->{loaded} == 1, 'Artifact was loaded');
}



done_testing();
