#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Spreadsheet::ParseXLSX;
use Spreadsheet::Template;

my $template = Spreadsheet::Template->new;
my $data = do { local $/; local @ARGV = ('t/data/merge.json'); <> };

{
    my $excel = $template->render(
        $data,
        {
            headers => [
                {
                    value1 => "Merge 1",
                    value2 => "Merge 2",
                    value3 => "Merge 3",
                    value4 => "Merge 4"
                },
            ],
            rows => [
                {
                    value1 => "1",
                    value2 => '0',
                    value3 => '0',
                    value4 => '0'
                },
                {
                    value1 => "2",
                    value2 => '0',
                    value3 => '0',
                    value4 => '0'
                }
            ],
        }
    );

    open my $fh, '<', \$excel;
    my $wb = Spreadsheet::ParseXLSX->new->parse($fh);
    is($wb->worksheet_count, 1);

    my $ws = $wb->worksheet(0);
    is($ws->get_name, 'Merge Report 1');

    # In the template, the 4 columns in row 1 are merged
    # with contents = "Merged Cells"
    for my $col (0..3) {
        if ($col == 0) {
            is($ws->get_cell(0, $col)->value, 'Merged Header');
        } else {
            is($ws->get_cell(0, $col)->value, '');
        }
    }
    is($ws->get_cell(1,0)->value, 1);
    is($ws->get_cell(2,0)->value, 2);
    my $value1 = $ws->get_cell(1,0)->value;
    my $value2 = $ws->get_cell(2,0)->value;
    my $sum = $value1 + $value2;
    is($ws->get_cell(3,0)->value, $sum);
}

done_testing;
