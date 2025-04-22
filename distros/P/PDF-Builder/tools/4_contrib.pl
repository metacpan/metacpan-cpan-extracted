#!/usr/bin/perl
# run contributions test suite
# roughly equivalent to contrib.bat
#   be sure to update the directory separator below
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

# command line:
# 

# for Linux and Unix systems, the directory separator is /
# for Windows systems, the directory separator is \\ (doubled again)
#my $dirSep = '/';      # Unixy
my $dirSep = '\\\\';   # Windows, inserted into string as \\
# only used in command path; can always use / in arguments

my $pause;

# check if any of the needed PDF files (from examples run) have been erased
# or not created yet.
my $noRun = 0;
my $createdAtTop = 0;

# combine_pdfs
fileCheck("examples/011_open_update.BASE.pdf");
fileCheck("examples/012_pages.pdf");
fileCheck("examples/011_open_update.UPDATED.pdf");

if ($noRun) {
    #die "One or more necessary files missing.\n";
    print "One or more necessary files are missing.\n";
    print "Shall I try to create them for you?[n]\n";
    $pause = <>;
    if ($pause =~ m/^y/i) {
	system("perl examples/011_open_update");
	system("perl examples/012_pages");
	$noRun = 0;
        $createdAtTop = 1;
    }
}
if ($noRun) { exit(1); }

print "===== run contrib/combine_pdfs.pl\n";
system("contrib".$dirSep."combine_pdfs.pl examples/011_open_update.BASE.pdf examples/012_pages.pdf examples/011_open_update.UPDATED.pdf combined.pdf");
print "combined.pdf should be 15 pages: \n";
print "  Hello World\n";
print "  page sequence i ii iii 1 9 2..8\n";
print "  Hello World and Hello World (2)\n";
print "Note that different page sizes are produced within combined.\n";
print "Press Enter to continue\n";
$pause = <>;

print "===== run contrib/pdf-debug.pl\n";
print " contrib/pdf-debug.pl combined.pdf\n";
print "  lists version, some other information:\n";
system("contrib".$dirSep."pdf-debug.pl combined.pdf");
print "Press Enter to continue\n";
$pause = <>;

print " contrib/pdf-debug.pl combined.pdf obj 2\n";
print "  describes a Pages type object:\n";
system("contrib".$dirSep."pdf-debug.pl combined.pdf obj 2");
print "Press Enter to continue\n";
$pause = <>;

print " contrib/pdf-debug.pl combined.pdf xref\n";
print "  lists the cross reference:\n";
system("contrib".$dirSep."pdf-debug.pl combined.pdf xref");
print "Press Enter to continue\n";
$pause = <>;

print "===== run contrib/pdf-deoptimize.pl\n";
print " contrib/pdf-deoptimize.pl combined.pdf combined.deopt.pdf\n";
print "  outputs combined.deopt.pdf, smaller than the original\n";
print "  other than it's a working PDF, no idea what \"de-optimize\" does\n";
system("contrib".$dirSep."pdf-deoptimize.pl combined.pdf combined.deopt.pdf");
print "Press Enter to continue\n";
$pause = <>;

print "===== run contrib/pdf-optimize.pl\n";
print " contrib/pdf-optimize.pl combined.pdf combined.opt.pdf\n";
print "  outputs combined.opt.pdf, same size as the original\n";
print "  other than it's a working PDF, no idea what \"optimize\" does\n";
system("contrib".$dirSep."pdf-optimize.pl combined.pdf combined.opt.pdf");
print "Press Enter to continue\n";
$pause = <>;

print "===== run contrib/text2pdf.pl\n";
print "  output to text2pdf.pl.pdf a paginated listing of itself\n";
system("contrib".$dirSep."text2pdf.pl contrib/text2pdf.pl");
print "Press Enter to continue\n";
$pause = <>;

print "I will NOT erase the input files from examples/ -- you have to do that\n";
print "\nIf you are done with the output files, should I erase them now?[n]\n";
$pause = <>;
if ($pause =~ m/^y/i) {
    if ($createdAtTop) {
        unlink("examples/011_open_update.BASE.pdf");
        unlink("examples/011_open_update.UPDATED.pdf");
        if (-f "examples/011_open_update.STRING.pdf") {
	    # left over from run of 011 at the top
            unlink("examples/011_open_update.STRING.pdf");
        }
        unlink("examples/012_pages.pdf");
    }

    unlink("combined.pdf");
    unlink("combined.deopt.pdf");
    unlink("combined.opt.pdf");
    unlink("text2pdf.pl.pdf");
}

# --------------------------------
sub fileCheck {
    my ($file) = @_;

    if (!-f $file || !-r $file) {
        print "$file either not created yet, or you erased it!\n";
        $noRun = 1;
    }
    return;
}
