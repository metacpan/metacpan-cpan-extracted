use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Syntax::Kamelon::Format::HTML4') };

use Syntax::Kamelon;

my $reffile = './t/HTML/format-html4';
my $samplefile = './t/Samples/codefolding.pm';
my $outfile = './t/HTML_OUT/format-html4';

my $kam1 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		title => "Testing Plain/Theme DarkGray",
	],
);

my $kam2 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		lineoffset => 1,
		title => "Testing line numbers",
	],
);

my $kam3 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		sections => 1,
		title => "Testing sections",
	],
);

my $kam4 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		lineoffset => 1,
		theme => 'Gray',
		title => "Testing theme Gray",
	],
);

my $kam5 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		lineoffset => 1,
		theme => 'LightGray',
		title => "Testing theme LightGray",
	],
);

my $kam6 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		lineoffset => 1,
		theme => 'Black',
		title => "Testing theme Black",
	],
);

my $kam7 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		lineoffset => 1,
		theme => 'White',
		title => "Testing theme Black",
	],
);

my $kam8 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		scrolled => 1,
		title => "Testing scrolled",
	],
);

my $kam9 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
		foldmarkers => 1,
		title => "Testing code folding",
	],
);

my @tests = (
	$kam1 => 'Plain', 
	$kam2 => 'Line Numbers/Theme DarkGray',
	$kam3 => 'Sections',
	$kam4 => 'Theme Gray',
	$kam5 => 'Theme LightGray',
	$kam6 => 'Theme Black',
	$kam7 => 'Theme White',
	$kam8 => 'Scrolled',
	$kam9 => 'Fold markers',
);

my $testnum = 1;
while (@tests) {
	my $kam = shift @tests;
	my $identifier = shift @tests;
	my $output = "";

	ok(defined $kam->Formatter, "$testnum Creation $identifier");

	my $ofile = "$outfile-$testnum.html";
	unless (open(OFILE, ">", $ofile)) {
		die "Cannot open output $ofile"
	}

	unless (open(IFILE, "<", $samplefile)) {
		die "Cannot open input $samplefile"
	}

	while (my $in = <IFILE>) {
		$kam->Parse($in);
	}

	my $out = $kam->Format;
	$output = $output . $out;
	print OFILE $out;

	close IFILE;
	close OFILE;

	my $rfile = "$reffile-$testnum.html";
# 	my $reftext = &LoadFile($rfile);
# 	ok($reftext eq $output, "$testnum Parsing $identifier");
	$testnum ++;
}

sub LoadFile {
	my $file = shift;
	my $text = '';
	unless (open(AFILE, "<", $file)) {
		die "Cannot open $file"
	}
	while (my $in = <AFILE>) {
		$text = $text . $in
	}
	close AFILE;
	return $text;
}
