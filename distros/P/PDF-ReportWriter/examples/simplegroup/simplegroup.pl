#
# Show an example of simple grouping
# The program is always the same!
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-14
#
# $Id: simplegroup.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use PDF::ReportWriter;

my $rw = PDF::ReportWriter->new();
my @data = (
    [ 2002, 'Income',                1000.000 ],
    [ 2002, 'Expenses',               -900.000 ],
    [ 2002, 'Taxes',                  -300.000 ],
    [ 2003, 'Income',                 2000.000 ],
    [ 2003, 'Expenses',              -1200.000 ],
    [ 2003, 'Taxes',                  -400.000 ],
    [ 2004, 'Income',                 4000.000 ],
    [ 2004, 'Expenses',              -1800.000 ],
    [ 2004, 'Taxes',                 -1000.000 ],
    [ 2005, 'Income',                10000.000 ],
    [ 2005, 'Expenses',              -3000.000 ],
    [ 2005, 'Taxes',                 -2300.000 ],
    [ 2006, 'Income (projection)',   90000.000 ],
    [ 2006, 'Expenses (projection)', -9900.000 ],
    [ 2006, 'Taxes (projection)',   -15000.000 ],
);

$rw->render_report('./simplegroup.xml', \@data);
$rw->save();
