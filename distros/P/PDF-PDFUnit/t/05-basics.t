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
# The tests in this file cover typical functions of PDFUnit-Java.
#
#############################################################################

use strict;
use utf8;
use warnings;
use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;
use PDF::PDFUnit qw(:skip_on_error);


my $resources_dir = File::Spec->catfile($FindBin::Bin, 'resources');

my $pdfUnderTest = "$resources_dir/doc-under-test.pdf";
my $pdfReference = "$resources_dir/reference.pdf";
my $pdfZugferd   = "$resources_dir/ZUGFeRD_1p0_BASIC_Einfach.pdf";


########
# Tests:
########

lives_ok {
    my $expectedText = "Chapter 3 - QR code and Text in Images";
    my $page2        = PagesToUse->getPage(2);
    
    AssertThat
        ->document($pdfUnderTest)
        ->restrictedTo($page2)
        ->hasText()
        ->containing($expectedText)
        ;
} "validate text on individual page";


lives_ok {
    my $pages1To3 = PagesFromTo->spanningFrom(1)->to(3);
    my $textBody = _createBodyRegion();

    my $chapter2Header = "Text Running Over Two Pages";
    my $chapter3Header = "QR code and Text in Images";
    my $chapter2BodyPart =
        "Huck Finn is drawn from life; "
        . "Tom Sawyer also, but not from an "
        . "individual -- he is a combination "
        . "of the characteristics of three boys";

    AssertThat
        ->document($pdfUnderTest)
        ->restrictedTo($pages1To3)
        ->restrictedTo($textBody)
        ->hasText()
            ->first($chapter2Header)
            ->then($chapter2BodyPart)
            ->then($chapter3Header)
        ;
} "validate ordered text in page pody spanning over multiple pages";


lives_ok {
    my $textBody = _createBodyRegion();
    
    AssertThat
        ->document($pdfUnderTest)
        ->restrictedTo(LAST_PAGE)
        ->restrictedTo($textBody)
        ->hasNoImage()
        ->hasNoText()
        ;
} "validate empty page region";


lives_ok {
    my $expectedText = "hello, world";
    my $page2        = PagesToUse->getPage(2);
    my $firstQRCodeRegion = _createQRCodeRegion();
    
    AssertThat
        ->document($pdfUnderTest)
        ->restrictedTo($page2)
        ->restrictedTo($firstQRCodeRegion)
        ->hasImage()
        ->withQRCode()
        ->equalsTo($expectedText)
        ;
} "validate QR code";


lives_ok {
    my $nodeIBAN = XMLNode->new("ram:IBANID");
    my $regionIBAN = _createIBANRegion();

    AssertThat
        ->document($pdfZugferd)
        ->restrictedTo(FIRST_PAGE)
        ->restrictedTo($regionIBAN)
        ->hasText()
        ->containingZugferdData($nodeIBAN)
        ;
} "validate IBAN in ZUGFeRD data";


lives_ok {
    my $helloWorld_ar = "مرحبا، العالم";
    my $helloWorld_cn = "你好，世界！";
    my $helloWorld_jp = "こんにちは世界";
    my $helloWorld_ru = "Здравствуйте мир!";
    my $page3 = PagesToUse->getPage(3);

    AssertThat
        ->document($pdfReference)
        ->hasText()
        ->containing($helloWorld_ar)
        ->containing($helloWorld_cn)
        ->containing($helloWorld_jp)
        ->containing($helloWorld_ru)
        ;
} "validate right-to-left text";


lives_ok {
    AssertThat
        ->document($pdfUnderTest)
        ->compliesWith()
        ->pdfStandard(Standard->PDFA_1B)
        ;
} "validate PDF/A-1b";


lives_ok {
    my $pages12 = PagesToUse->getPages( [1, 2] );
    
    AssertThat
        ->document($pdfUnderTest)
        ->and($pdfReference)
        ->restrictedTo($pages12)
        ->haveSameText()
        ->haveSameAppearance()
        ;
} "compare a PDF with a reference";


dies_ok {    
    AssertThat
        ->document($pdfUnderTest)
        ->and($pdfReference)
        ->haveSameBookmarks()
        ;
} "compare bookmarks of a PDF with a reference, mismatch expected";


lives_ok {
    my $expectedText = "This text is rotated by 90 degrees.";
    my $page4 = PagesToUse->getPage(4);

    AssertThat
        ->document($pdfReference)
        ->restrictedTo($page4)
        ->hasText()
        ->containing($expectedText, WhitespaceProcessing->IGNORE) 
        ;
} "demo using whitespaces processing parameter";


lives_ok {
    my $expectedText = "This text is rotated by 90 degrees.";
    my $page4 = PagesToUse->getPage(4);

    AssertThat
        ->document($pdfReference)
        ->restrictedTo($page4)
        ->hasText()
        ->containing($expectedText, IGNORE_WHITESPACES) 
        ;
} "demo using whitespaces processing parameter (another syntax)";


# Every PDF document in the folder that matches the filter
# has to fulfill the test.
lives_ok {
    my $folder = File->new($resources_dir);
    my $allPdfunitFiles =
        FilenameMatchingFilter->new('.*(doc-under-test|reference)\.pdf$');

    AssertThat
        ->eachDocument()
        ->inFolder($folder)
        ->passedFilter($allPdfunitFiles)
        ->hasProperty("Title")->equalsTo("PDFUnit - Automated PDF Tests")
        ;
} "demo using a folder with a file filter";


diag $@->getMessage() if $@;
done_testing();


###############
# Some helpers:
###############

sub _createBodyRegion {
    my $leftX  =   0;
    my $upperY =  30;
    my $width  = 210;
    my $height = 235;

    return PageRegion->new($leftX, $upperY, $width, $height);
}

sub _createQRCodeRegion {
    my $leftX  =  30;
    my $upperY =  30;
    my $width  = 80;
    my $height = 100;

    return PageRegion->new($leftX, $upperY, $width, $height);
}

sub _createIBANRegion {
    my $ibanLeftX  =  80;  # in millimeter
    my $ibanUpperY = 175;
    my $ibanWidth  =  60;
    my $ibanHeight =   9;
    return PageRegion->new($ibanLeftX, $ibanUpperY, $ibanWidth, $ibanHeight);
}

