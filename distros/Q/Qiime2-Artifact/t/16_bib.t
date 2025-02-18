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
	ok($artifact->{loaded} == 1, 'Artifact was loaded');
	my $bibliography = $artifact->get_bib();
	ok(length($bibliography) > 0, 'Bibliography was retrieved');
	ok($bibliography =~ /^\@article/, 'Bibliography starts with @article');
	my $doi = '10.1038/s41587-019-0209-9';
	ok($bibliography =~ /$doi/, 'Bibliography contains DOI: '.$doi);
}


done_testing();
