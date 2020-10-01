use strict;
use Test::More tests => 5;
use File::Basename 'dirname';
use Spreadsheet::ReadSXC;
use Data::Dumper;

my $d = dirname($0);

my $workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/hidden-cols.ods");

my $expected = {
          'vhvhv' => [
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ],
                       [
                         'visible',
                         'hidden',
                         'visible',
                         'hidden',
                         'visible'
                       ]
                     ],
          'vhhhvh' => [
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'hidden',
                          'hidden',
                          'visible',
                          'hidden'
                        ]
                      ],
          'vhvhvh' => [
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ],
                        [
                          'visible',
                          'hidden',
                          'visible',
                          'hidden',
                          'visible',
                          'hidden'
                        ]
                      ]
        };

is_deeply $workbook_ref, $expected, "hidden-rows.ods gets parsed identically"
    or diag Dumper $workbook_ref;

$workbook_ref = Spreadsheet::ReadSXC::read_sxc("$d/hidden-cols.ods",
{   DropHiddenColumns      => 1,
});

$expected = {
          'vhvhv' => [
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ],
                       [
                         'visible',
                         ,
                         'visible',
                         ,
                         'visible'
                       ]
                     ],
          'vhhhvh' => [
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          ,
                          ,
                          ,
                          'visible',

                        ]
                      ],
          'vhvhvh' => [
                        [
                          'visible',
                          ,
                          'visible',
                          ,
                          'visible',

                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ],
                        [
                          'visible',
                          'visible',
                          'visible',
                        ]
                      ]
        };

is_deeply $workbook_ref, $expected, "hidden-cols.ods gets parsed identically with standardized values"
    or diag Dumper $workbook_ref;

for my $key (qw(vhvhvh vhvhv vhhhvh)) {
    is_deeply $workbook_ref->{$key}, $expected->{$key}, "hidden-cols.ods gets parsed identically with standardized values ($key)"
        or diag Dumper $workbook_ref->{$key};
};
