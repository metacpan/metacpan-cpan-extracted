use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 1;
use Syntax::Kamelon;
use KamTest qw(CompareFile InitWorkFolder OutPut Parse WriteCleanUp);

InitWorkFolder('t/Codefolding');


my $reffile = 'codefolding.txt';
my $samplefile = 'codefolding.pm';

my $kam = new Syntax::Kamelon(
	formatter => ['Base',
		foldingdepth => 1,
	],
	syntax => 'Perl',
);

Parse($kam, $samplefile);

my $foldingpoints = $kam->Formatter->{FOLDS};

my $out = "";
for (sort keys %$foldingpoints) {
	my $p = $foldingpoints->{$_};
	my %o = %$p;
	$out = $out . "$_ => [\n";
	for (sort keys %o) {
		$out = $out . "   $_ => " . $o{$_} . ",\n";
	}
	$out = $out . "]\n";
}

OutPut($out, $reffile);
ok((CompareFile($reffile) eq 1), 'Codefolding');

WriteCleanUp;
