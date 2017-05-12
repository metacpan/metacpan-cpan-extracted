#
# Show an example of access to an external DBI data source
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-20
#
# $Id: dbireport.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use PDF::ReportWriter;

my $rw = PDF::ReportWriter->new();

# Data comes from `datasource' definition
# in ./dbireport.xml report profile
# 
# Check the `account' csv file or the
# `account.sql' database dump

$rw->render_report('./dbireport.xml');
$rw->save();
