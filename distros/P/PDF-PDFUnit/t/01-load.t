#############################################################################
#                                                                           #
# PDF::PDFUnit - Wrapper for PDFUnit-Java                                   #
#                                                                           #
# Copyright (C) 2016 Axel Miesen                                            #
#                                                                           #
# This file is part of the Perl wrapper "PDF:PDFUnit" for the commercial    #
# library PDFUnit-Java. The Perl modul PDF::PDFUnit is license free.        #
#                                                                           #
# URL in CPAN: http://search.cpan.org/dist/PDF-PDFUnit/                     #
# Contact for PDFUnit-Java: info[at]pdfunit.com                             #
#                                                                           #
#############################################################################
#
# The methods in this file check that PDF documents can be loaded.
#
#############################################################################

use strict;
use utf8;
use warnings;
use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;


my $resources_dir = File::Spec->catfile($FindBin::Bin, 'resources');
my $pdfUnderTest = "$resources_dir/doc-under-test.pdf";


########
# Tests:
########

BEGIN {
    use_ok('PDF::PDFUnit', qw(:skip_on_error));
}


lives_ok {
    AssertThat->document( $pdfUnderTest )
} "loading a PDF from file";


lives_ok {
    my $pdfDocument = _getPDFAsByteArray();

    AssertThat
        ->document($pdfDocument)
        ->hasText()
        ->containing("Hello, World!")
        ;
} "loading a PDF from byte array";


lives_ok {
    my $pdfFile = File->new($pdfUnderTest);
    my $inputStream = FileInputStream->new($pdfFile);

    AssertThat
        ->document($inputStream)
        ->hasLessPagesThan(5)
        ;
} "loading a PDF from input stream";


lives_ok {
    use Cwd qw(abs_path);
    my $abspath = abs_path($pdfUnderTest);
    my $file_url = "file:///$abspath";
    my $url = URL->new($file_url);

    AssertThat
        ->document($url)
        ;
} "loading a PDF from URL";


diag $@->getMessage() if $@;

dies_ok {
    AssertThat->document( "$0" )
} "loading a non-PDF file";


done_testing();


###############
# Some helpers:
###############

sub _getPDFAsByteArray() {
    my $pdfAsString = 
      "%PDF-1.3\n%âãÏÓ\n"
    . "1 0 obj \n<<\n/Kids [2 0 R]\n/Count 1\n/Type /Pages\n>>\nendobj \n"
    . "2 0 obj \n<<\n/Parent 1 0 R\n/Resources 3 0 R\n/MediaBox [0 0 595 842]\n/Contents [4 0 R]\n/Type /Page\n>>\nendobj \n"
    . "3 0 obj \n<<\n/Font \n<<\n/F0 \n<<\n/BaseFont /Times-Italic\n/Subtype /Type1\n/Type /Font\n>>\n>>\n>>\nendobj \n"
    . "4 0 obj \n<<\n/Length 66\n>>\nstream\n1. 0. 0. 1. 190. 500. cm\nBT\n  /F0 36. Tf\n  (Hello, World!) Tj\nET\n\nendstream \nendobj \n"
    . "5 0 obj \n<<\n/Pages 1 0 R\n/Type /Catalog\n>>\nendobj xref\n0 6\n0000000000 65535 f \n0000000015 00000 n \n0000000074 00000 n \n0000000182 00000 n \n0000000281 00000 n \n0000000400 00000 n \n"
    . "trailer\n\n<<\n/Root 5 0 R\n/Size 6\n>>\n"
    . "startxref\n450\n"
    . "%%EOF\n"
    ;
    return [ unpack("c*", $pdfAsString) ];
  }

