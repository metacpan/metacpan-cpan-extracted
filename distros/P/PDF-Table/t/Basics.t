#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';    # Needed for 'make test' from project dir
use TestData;
use PDFAPI2Mock;    # provide dummy PDF::API2. obviously a real PDF::API2 or
                    # PDF::Builder installation will be needed in order to run

BEGIN {
    use_ok('PDF::Table');
}
require_ok('PDF::Table');

my ( $pdf, $page, $tab, @data, %opts );

$pdf  = PDF::API2->new();
$page = $pdf->page();
$tab  = PDF::Table->new($pdf,$page);

@data = ( [ 'foo', 'bar', 'baz' ], );
$tab->table( $pdf, $page, \@data, %TestData::required, );

#Check default font size
ok( $pdf->match( [ [qw(font 1 12)], [qw(font 1 12)], [qw(font 1 12)] ] ),
    'default font_size' )
  || note explain $pdf;

#Check default text placement
ok(
    $pdf->match(
        [ [qw(translate 12 686)],  [qw(text foo)] ],
        [ [qw(translate 112 686)], [qw(text bar)] ],
        [ [qw(translate 212 686)], [qw(text baz)] ],
    ),
    'default text placement in one row'
) or note explain $pdf;

#Check default splitting of long words
@data = ( ['123456789012345678901234567890123456789012345678901234567890'], );
%opts = (
    %TestData::required,
    w => 400,    #override w so table() will not use text_block()
);
$tab->table( $pdf, $page, \@data, %opts );
ok(
    $pdf->match(
        [
            [
                'text',
                '12345678901234567890 12345678901234567890 12345678901234567890'
            ]
        ],
    ),
    'default break long words on every 20th character'
) or note explain $pdf;

#
# Test header alignment if unspecified (should default to column alignment
# if unspecified)
# 
$pdf  = PDF::API2->new();
$page = $pdf->page();
$tab  = PDF::Table->new($pdf,$page);

@data = ( [ 'head1', 'head2', 'head3'], [ 'foo', 'bar', 'baz' ], );

# Match column properties to default header properties
my $col_props = [
    { font_color => '#000066', font_size => 14, background_color => '#FFFFAA', justify => 'left' },
    { font_color => '#000066', font_size => 14, background_color => '#FFFFAA', justify => 'center' },
    { font_color => '#000066', font_size => 14, background_color => '#FFFFAA', justify => 'right' },
];
%opts = (
    %TestData::required,
    column_props => $col_props,
);
$tab->table( $pdf, $page, \@data, %opts );
my @pdf_no_header_props = $pdf->getall;

my $pdf2  = PDF::API2->new();
my $page2 = $pdf2->page();
my $tab2  = PDF::Table->new($pdf2,$page2);

@data = ( [ 'head1', 'head2', 'head3'], [ 'foo', 'bar', 'baz' ], );
%opts = (
    %TestData::required,
    header_props => {
       repeat => 1,
    },
    column_props => $col_props,
);
$tab2->table( $pdf2, $page2, \@data, %opts );
ok(
    $pdf2->match( \@pdf_no_header_props ),
    'Header alignment matches column alignment if unspecified'
) or note explain $pdf2;

$pdf  = PDF::API2->new();
$page = $pdf->page();
@data = ( [0..2], [3..5], [6..8] );
my $cell_data;
%opts = (
    %TestData::required,
    cell_render_hook => sub {
      my ($page, $first_row, $row, $col, $x, $y, $w, $h) = @_;
      $cell_data .= "($row, $col), "; 
    }
);
$tab = PDF::Table->new( $pdf, $page );
$tab->table( $pdf2, $page2, \@data, %opts );
ok(
    $cell_data eq '(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2), ',
    'The cell_render_hook() subroutine output is valid'
) or diag explain \$pdf;

1;
