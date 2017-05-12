#!/usr/bin/perl -w

use File::Basename;
use File::Copy qw|cp|;
use File::Compare;
use Cwd;

my $here = getcwd;
my $outdir = $here;
my $tempfile = "$outdir/.Makefile.am.tmpfile";

# Update list of source files in $outdir/Makefile.am
open( MAKEFILE, "<$outdir/Makefile.am" ) or die;
my $makeFileData = '';
my $found = 0;
while (<MAKEFILE>) {
	if (/^libsmokeqt_la_SOURCES/)
	{
		$found = 1;
		$makeFileData .= "libsmokeqt_la_SOURCES = smokedata.cpp";
	}
	$makeFileData .= $_ if (!$found);
}
close MAKEFILE;

die "libsmokeqt_la_SOURCES not found" if (!$found);

open( MAKEFILE, ">$tempfile" ) or die;
print MAKEFILE $makeFileData;

my $count = 0;
opendir (FILES, $outdir) or die;
foreach $filename (readdir(FILES)) {
	if ( $filename =~ /^x_.*\.cpp$/ ) {
		if ( $count++ == 7 ) {
			$count = 0;
			print MAKEFILE " \\\n";
		}
		print MAKEFILE " $filename";
	}
}

print MAKEFILE "\n";
close MAKEFILE;
closedir FILES;

if (compare("$tempfile", "$outdir/Makefile.am")) {
    cp("$tempfile", "$outdir/Makefile.am");
    print STDERR "Makefile.am updated.\n";
}
else {
    print STDERR "Makefile.am unchanged.\n";
}
unlink $tempfile;

exit 0;
