#!/usr/bin/perl -w

##############################################################################
#
# An example of writing an Excel file to a Perl scalar using Spreadsheet::
# WriteExcelXML and the new features of perl 5.8.
#
# For an examples of how to write to a scalar in versions prior to perl 5.8
# see the filehandle.pl program and IO:Scalar.
#
# reverse('©'), September 2004, John McNamara, jmcnamara@cpan.org
#

use strict;
use Spreadsheet::WriteExcelXML;

require 5.008;


# Use perl 5.8's feature of using a scalar as a filehandle.
my   $fh;
my   $str = "";
open $fh, '>', \$str or die "Failed to open filehandle: $!";;


# Or replace the previous three lines with this:
# open my $fh, '>', \my $str or die "Failed to open filehandle: $!";


# Spreadsheet::WriteExce accepts filehandle as well as file names.
my $workbook  = Spreadsheet::WriteExcelXML->new($fh);
my $worksheet = $workbook->add_worksheet();

$worksheet->write(0, 0,  "Hi Excel!");

$workbook->close();


# The Excel file in now in $str.
print $str;


__END__

