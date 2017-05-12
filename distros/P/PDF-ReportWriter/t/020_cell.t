#
# Test of PDF::ReportWriter functions about cells
# Cosimo Streppone 2006-03-16
#
# $Id: 020_cell.t 15 2006-03-27 16:50:11Z cosimo $

use strict;
use warnings;
use Test::More;

plan tests => 6;

use_ok('PDF::ReportWriter');

#
# Test of calculate_cell_height
#

my $cell = { font_size => 10, text => '' };
my $self = {};

is(
    PDF::ReportWriter::calculate_cell_height($self,$cell),
    10,
    'cell height of a single text row'
);

$cell = { font_size => 10, text_whitespace => 5 };

is(
    PDF::ReportWriter::calculate_cell_height($self,$cell),
    15,
    'cell height of a single text row + whitespace',
);

$cell = { font_size => 10, text_whitespace => 5, text => 'ABRACADABRA' };

is(
    PDF::ReportWriter::calculate_cell_height($self,$cell),
    15,
    'cell height of a single text row + whitespace',
);

$cell->{text} = "FIRST LINE\nSECOND LINE";

is(
    PDF::ReportWriter::calculate_cell_height($self,$cell),
    25,
    'cell height of 2 text rows + whitespace',
);

$cell->{text} = "FIRST LINE\nSECOND LINE\nTHIRD LINE";

is(
    PDF::ReportWriter::calculate_cell_height($self,$cell),
    35,
    'cell height of 3 text rows + whitespace',
);

