use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Syntax::Kamelon::Format::ANSI') };

use Syntax::Kamelon;

my $reffile1 = './t/HTML/format-ansi-1.ansi';
my $reffile2 = './t/HTML/format-ansi-2.ansi';
my $samplefile = './t/Samples/codefolding.pm';
my $outfile1 = './t/HTML_OUT/format-ansi-1.ansi';
my $outfile2 = './t/HTML_OUT/format-ansi-2.ansi';

my $kam = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['ANSI',
	],
);

my $output = "";

ok(defined $kam->Formatter, 'Creation');

unless (open(OFILE, ">", $outfile1)) {
	die "Cannot open output $outfile1"
}

unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}

while (my $in = <IFILE>) {
	$kam->Parse($in);
}

&Out($kam->Format);

close IFILE;
close OFILE;

my $reftext = &LoadFile($reffile1);
ok($reftext eq $output, 'ANSI no line numbering');

$kam = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['ANSI',
		lineoffset => 1,
	],
);

$output = "";

unless (open(OFILE, ">", $outfile2)) {
	die "Cannot open output $outfile2"
}

unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}

while (my $in = <IFILE>) {
	$kam->Parse($in);
}

&Out($kam->Format);

close IFILE;
close OFILE;

$reftext = &LoadFile($reffile2);
ok($reftext eq $output, 'ANSI line numbering');

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

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

