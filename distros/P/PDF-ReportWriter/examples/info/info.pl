#
# The First Basic Report
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-14
#
# $Id: info.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use warnings;
use PDF::ReportWriter;

my $rw = PDF::ReportWriter->new();
$rw->render_report('./info.xml');
$rw->save();

