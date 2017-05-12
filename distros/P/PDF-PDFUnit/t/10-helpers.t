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
# The methods in this file show how to use helper classes of PDFUnit-Java.
#
#############################################################################
use strict;
use warnings;
use utf8;
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
    my $expectedDate = DateHelper->getCalendar("17.04.2016", "dd.MM.yyyy");

    AssertThat
        ->document($pdfUnderTest)
        ->hasFormat(A4_PORTRAIT)
        ->hasCreationDate()
        ->equalsTo($expectedDate, AS_DATE)
        ;
} "demo using class DateHelper";


diag $@->getMessage() if $@;
done_testing();
