use Test::More tests => 7;
use strict;
use warnings;

use lib 't/lib';    # Needed for 'make test' from project dir
use TestData;
use PDFAPI2Mock;

BEGIN {
    use_ok('PDF::Table');
}
require_ok('PDF::Table');

my ( $pdf, $page, $tab, @data, %opts );

$pdf  = PDF::API2->new();
$page = $pdf->page();
$tab  = PDF::Table->new($pdf,$page);

@data = ( [ 'r1c1', 'r1c2', 'r1c3' ], ['r2c1',undef,'r2c3'] );
$tab->table( $pdf, $page, \@data, %TestData::required,
    column_props => [
            { background_color => 'red' },
      ],
    cell_props => [
        [],
        [{colspan=>2}]
    ]
 );

#Check first row text placement
ok(
    $pdf->match(
        [ [qw(translate 10 688)],  [qw(text r1c1)] ],
        [ [qw(translate 110 688)], [qw(text r1c2)] ],
        [ [qw(translate 210 688)], [qw(text r1c3)] ],
    ),
    'text placement in first row'
) or note explain $pdf;

ok(
    $pdf->match(
        [ [qw(translate 10 676)],  [qw(text r2c1)] ],
    ),
    'text placement r2c1'
) or note explain $pdf;

ok(
    $pdf->match(
        [ [qw(translate 210 676)],  [qw(text r2c3)] ],
    ),
    'text placement r2c3'
) or note explain $pdf;

ok(
    $pdf->match(
        [ [qw(rect 10 688 100 12)],  [qw(fillcolor red)] ],
    ),
    'r1c1 background box'
) or note explain $pdf;

ok(
    $pdf->match(
        [ [qw(rect 10 676 200 12)],  [qw(fillcolor red)] ],
    ),
    'r2c1 colspan background box'
) or note explain $pdf;

