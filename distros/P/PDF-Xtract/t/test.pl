# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use PDF::Xtract;

$in="../Manual-PDF-Xtract.pdf";

@pages=(3); $pages=\@pages;

$pdf=new PDF::Xtract(
	PDFDoc=>"$in",
	PDFSaveAs=>"Xtract-Relevance.pdf",
	PDFPages=>$pages);

print STDERR "If you feel good after reading the page \"Xtract-Relevance.pdf\", then the test is PASS!\n";
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


