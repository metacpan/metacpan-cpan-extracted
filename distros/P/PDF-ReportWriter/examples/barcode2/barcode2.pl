# Example of creation of a PDF document with a
# custom format. In this example, a simple
# barcode label.
#
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-23
#
# $Id: barcode2.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use PDF::ReportWriter;
#use Devel::TraceCalls { Package => 'PDF::ReportWriter' };

my $rw = PDF::ReportWriter->new();
$rw->render_report('./barcode2.xml');
$rw->save();

