use strict;
use Test::More tests => 5;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;
use Data::Dumper;

my $d = dirname($0);

my $workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/hidden-rows.ods");

my $expected = {
          'vhvh' => [
                      [
                        'visible',
                        'visible'
                      ],
                      [
                        'hidden',
                        'hidden'
                      ],
                      [
                        'visible',
                        'visible'
                      ],
                      [
                        'hidden',
                        'hidden'
                      ]
                    ],
          'vhvhv' => [
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'hidden',
                         'hidden'
                       ],
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'hidden',
                         'hidden'
                       ],
                       [
                         'visible',
                         'visible'
                       ]
                     ],
          'vhhhv' => [
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'hidden',
                         'hidden'
                       ],
                       [
                         'hidden',
                         'hidden'
                       ],
                       [
                         'hidden',
                         'hidden'
                       ],
                       [
                         'visible',
                         'visible'
                       ]
                     ]
        };

is_deeply $workbook_ref, $expected, "hidden-rows.ods gets parsed identically"
    or diag Dumper $workbook_ref;

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/hidden-rows.ods",
{   DropHiddenRows      => 1,
});

$expected = {
          'vhvh' => [
                      [
                        'visible',
                        'visible'
                      ],
                      [
                        'visible',
                        'visible'
                      ],
                    ],
          'vhvhv' => [
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'visible',
                         'visible'
                       ]
                     ],
          'vhhhv' => [
                       [
                         'visible',
                         'visible'
                       ],
                       [
                         'visible',
                         'visible'
                       ]
                     ]
        };

is_deeply $workbook_ref, $expected, "hidden-rows.ods gets parsed identically with standardized values"
    or diag Dumper $workbook_ref;

for my $key (qw(vhhhv vhvh vhvhv)) {
    is_deeply $workbook_ref->{$key}, $expected->{$key}, "hidden-rows.ods gets parsed identically with standardized values ($key)"
        or diag Dumper $workbook_ref->{$key};
};
