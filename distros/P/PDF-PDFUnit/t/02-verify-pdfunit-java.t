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
# The method verifies that all required libraries and files are found on the 
# classpath. Additionally it logs some system properties and writes 
# all to System.out.
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
my $vipFile       = "$resources_dir/pdfunit.vip";


########
# Tests:
########

#
# The method verifies that all required libraries and files are found on the 
# Java classpath. Additionally it logs some system properties and writes 
# everything into both an XML file and an HTML formatted file.
#
lives_ok {
    AssertThat->installationIsClean($vipFile);
} "checking the configuration of PDFUnit-Java";


diag $@->getMessage() if $@;
done_testing();
