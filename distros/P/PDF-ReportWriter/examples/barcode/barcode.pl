#
# A simple barcode report
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-15
#
# $Id: barcode.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use PDF::ReportWriter;

my $rw = PDF::ReportWriter->new();
$rw->render_report('./barcode.xml');
$rw->save();
