use strict;
use warnings;
use lib 't/testlib';

use Test::More tests => 46;
use Syntax::Kamelon;
use KamTest qw(CompareFile InitWorkFolder ClearTimer Format GetTime Parse WriteCleanUp);


my $cycles = 5;

my %langs = (
	'.desktop' => "highlight.desktop",
	'AHDL' => "highlight.ahdl",
	'ASP' => "highlight.asp",
	'AVR Assembler' => "highlight.asm",
	'AWK' => "highlight.awk",
	'Bash' => "highlight.sh",
	'BibTeX' => "highlight.bib",
	'C++' => "highlight.cpp",
	'CMake' => "highlight.cmake",
	'CSS' => "highlight.css",
	'Clipper' => "highlight.prg",
	'Common Lisp' => "highlight.lisp",
	'Doxygen' => "highlight.dox",
	'Eiffel' => "highlight.e",
	'Euphoria' => "highlight.exu",
	'Fortran' => "highlight.f90",
	'GLSL' => "highlight.glsl",
	'HTML' => "highlight.html",
	'Haskell' => "highlight.hs",
	'Intel x86 (NASM)' => "highlight.asm",
	'JSP' => "highlight.jsp",
	'Java' => "highlight.java",
	'JavaScript' => "highlight.js",
	'LaTeX' => "highlight.tex",
	'Lex/Flex' => "highlight.lex",
	'Literate Haskell' => "highlight.hs",
	'Matlab' => "highlight.m",
	'Octave' => "highlight.m",
	'PHP/PHP' => "highlight.php",
	'POV-Ray' => "highlight.pov",
	'Perl' => "highlight.pl",
	'PicAsm' => "highlight.asm",
	'Pike' => "highlight.pike",
	'PostScript' => "highlight.ps",
	'PureBasic' => "highlight.pb",
	'Python' => "highlight.py",
	'Quake Script' => "highlight.rib",
	'Ruby' => "highlight.rb",
	'Scheme' => "highlight.scheme",
	'Spice' => "highlight.sp",
	'Stata' => "highlight.do",
	'Tcl/Tk' => "highlight.tcl",
	'UnrealScript' => "highlight.uc",
	'VRML' => "highlight.wrl",
	'XML' => "highlight.xml",
	'xslt' => "highlight.xsl",
);

my $k = Syntax::Kamelon->new(
	formatter => ['HTML4'],
);

my $workfolder = 't/Bench';

InitWorkFolder($workfolder);

my @langl = sort keys %langs;

my $minthroughput = '';
my $maxthroughput = 0;
my $totalthroughput = 0;

print "        Syntax              min time     max time     average      throughput\n";
my $num = 1;
foreach my $ln (@langl) {
	my $cycle = 1;
	my $sample = $langs{$ln};
	my $size = -s "$workfolder/samples/$sample";
	$k->Syntax($ln);
	my $mintime = '';
	my $maxtime = 0;
	my $totaltime = 0;
	while ($cycle <= $cycles) {
		$k->Reset;
		Parse($k, $sample);
		my $time = GetTime;
		ClearTimer;
		if ($time > $maxtime) { $maxtime = $time }
		if (($mintime eq '') or ($time < $mintime)) { $mintime = $time }
		$totaltime = $totaltime + $time;
		$cycle ++;
	}
	my $outfile = "benchtest-$num.html";
	Format($k, $outfile);
	my $avertime = $totaltime/$cycles;
	my $throughput = $size/$avertime;
	
	#composing message string
	my $message = $ln;
	if ($num < 10) {
		$message = $message . (" " x (21 - length($message)));
	} else {
		$message = $message . (" " x (20 - length($message)));
	}
	$message = $message . sprintf("%4f", $mintime);
	$message = $message . (" " x (33 - length($message)));
	$message = $message . sprintf("%4f", $maxtime);
	$message = $message . (" " x (46 - length($message)));
	$message = $message . sprintf("%4f", $avertime);
	$message = $message . (" " x (59 - length($message)));
	$message = $message . sprintf("%6d", $throughput);
	ok((CompareFile($outfile) eq 1), $message);
	$num++;
	if ($throughput > $maxthroughput) { $maxthroughput = $throughput }
	if (($minthroughput eq '') or ($throughput < $minthroughput)) { $minthroughput = $throughput }
	$totalthroughput = $totalthroughput + $throughput;
}

my $averagethroughput = $totalthroughput / $num;

print "\n";
print "number of cycles $cycles\n";
print "minimum throughput ", sprintf("%6d", $minthroughput), "\n";
print "maximum throughput ", sprintf("%6d", $maxthroughput), "\n";
print "average throughput ", sprintf("%6d", $averagethroughput), "\n";

WriteCleanUp;
