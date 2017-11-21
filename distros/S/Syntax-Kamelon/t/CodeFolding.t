use strict;
use warnings;

use Test::More tests => 1;
my $skip = 1;

use Syntax::Kamelon;

my $reffile = './t/HTML/codefolding.txt';
my $samplefile = './t/Samples/codefolding.pm';
my $outdir = './t/HTML_OUT';
my @attributes = Syntax::Kamelon->AvailableAttributes;

my %formtab = ();
for (@attributes) {
	$formtab{$_} = ["<font class=\"$_\">", "</font>"]
}

my $hl = new Syntax::Kamelon(
	formatter => ['Base',
		foldingdepth => 1,
	],
	syntax => 'Perl',
);

my $output = "";


my $outfile = "$outdir/codefolding.txt";
unless (open(OFILE, ">", $outfile)) {
	die "Cannot open output $outfile"
}
unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}
while (my $in = <IFILE>) {
	$hl->Parse($in);
}


my $foldingpoints = $hl->Formatter->{FOLDS};

for (sort keys %$foldingpoints) {
	my $p = $foldingpoints->{$_};
	my %o = %$p;
	&Out("$_ => [\n");
	for (sort keys %o) {
		&Out("   $_ => " . $o{$_} . ",\n");
	}
	&Out("]\n");
}

close IFILE;
close OFILE;

my $reftext = &LoadFile($reffile);
ok(($reftext eq $output), 'Codefolding');

# sub FoldBegin {
# 	my $region = shift;
# 	$hl->SnippetParse("<$region>", $doctag);
# }
# 
# sub FoldEnd {
# 	my $region = shift;
# 	$hl->SnippetParse("</$region>", $doctag);
# }

sub LoadFile {
	my $file = shift;
	my $text = '';
	unless (open(IFILE, "<", $file)) {
		die "Cannot open $file"
	}
	while (my $in = <IFILE>) {
		$text = $text . $in
	}
	close IFILE;
	return $text;
}

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

