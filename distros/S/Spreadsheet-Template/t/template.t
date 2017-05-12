#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Spreadsheet::ParseXLSX;
use Spreadsheet::Template;

my $template = Spreadsheet::Template->new;
my $data = do { local $/; local @ARGV = ('t/data/template.json'); <> };
{
    my $excel = $template->render(
        $data,
        {
            rows => [
                {
                    description => "Row 1",
                    number      => 26,
                    date        => '2013-03-21T00:00:00',
                    money       => 3.50,
                },
                {
                    description => "Row 2",
                    number      => 83,
                    date        => '2013-06-25T00:00:00',
                    money       => 84.28,
                },
            ],
        }
    );

    open my $fh, '<', \$excel;
    my $wb = Spreadsheet::ParseXLSX->new->parse($fh);
    is($wb->worksheet_count, 1);

    my $ws = $wb->worksheet(0);
    is($ws->get_name, 'Report 1');
    is_deeply([$ws->row_range], [0, 3]);
    is_deeply([$ws->col_range], [0, 3]);

    my @values = (
        ["Descriptions", "Numbers", "Dates",  "Money"  ],
        ["Row 1",        "26",      "21-Mar", "\$3.50" ],
        ["Row 2",        "83",      "25-Jun", "\$84.28"],
        ["Totals:",      "109",     "",       "\$87.78"],
    );
    for my $row (0..3) {
        for my $col (0..3) {
            is($ws->get_cell($row, $col)->value, $values[$row][$col]);
        }
    }
}

{
    my $excel = $template->render(
        $data,
        {
            rows => [
                {
                    description => "Another Row",
                    number      => 42,
                    date        => '2012-12-25T00:00:00',
                    money       => 1.22,
                },
                {
                    description => "Yet Another Row",
                    number      => 0,
                    date        => '2011-03-09T00:00:00',
                    money       => 1001.01,
                },
            ],
        }
    );

    open my $fh, '<', \$excel;
    my $wb = Spreadsheet::ParseXLSX->new->parse($fh);
    is($wb->worksheet_count, 1);

    my $ws = $wb->worksheet(0);
    is($ws->get_name, 'Report 1');
    is_deeply([$ws->row_range], [0, 3]);
    is_deeply([$ws->col_range], [0, 3]);

    my @values = (
        ["Descriptions",    "Numbers", "Dates",  "Money"     ],
        ["Another Row",     "42",      "25-Dec", "\$1.22"    ],
        ["Yet Another Row", "0",       "9-Mar",  "\$1,001.01"],
        ["Totals:",         "42",      "",       "\$1,002.23"],
    );
    for my $row (0..3) {
        for my $col (0..3) {
            is($ws->get_cell($row, $col)->value, $values[$row][$col]);
        }
    }
}

done_testing;
