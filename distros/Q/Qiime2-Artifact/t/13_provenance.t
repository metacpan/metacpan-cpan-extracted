use strict;
use warnings;
use Qiime2::Artifact;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);

my $file_original = "$Bin/../data/tree-imported.qza";
my $file_derived  = "$Bin/../data/tree-derived.qza";



SKIP: {
	skip "missing imported input file" unless (-e "$file_original");
	skip "missing derived input file" unless (-e "$file_derived");
	system('unzip > /dev/null');
	skip "unzip not found, but a path could be specified when creating the instance of Qiime2::Artifact\n" if ($?);
	my $original = Qiime2::Artifact->new({ filename => "$file_original" });
	my $derived  = Qiime2::Artifact->new({ filename => "$file_derived" });
	print 'VERSION ', $Qiime2::Artifact::VERSION, "\n";
	ok($derived->{imported}  == 0, "Derived Artifact is not imported (is derived)");
	ok($original->{imported} == 1, "Imported Artifact detected as imported (not derived)");
	ok($derived->{parents_number}  > 1, 'Derived Artifact has > 1 parent: '. $derived->{parents_number} );
	ok($original->{parents_number}  == 1, 'Artifact has exactly 1 parent: '. $original	->{parents_number} );
}

done_testing();
