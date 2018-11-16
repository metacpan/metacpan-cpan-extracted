# Run via 'make test' or 'perl 67-Data-BoxFormat-read-embedded_vertbars.t'

use strict;
use warnings;
use 5.10.0; # me want say

# use Data::Dumper;
use Data::Dumper::Concise;

use Test::More;
BEGIN {
  use FindBin qw( $Bin );
  use lib ("$Bin/../lib/");
  use_ok('Table::BoxFormat');
};

# INSERT INTO funked_up (name, score, wisdom) VALUES
#   ('alfred', 58, 'Slavish imitation | gobs hobbies at mini-minds'),
#   ('betty',  32, 'Let us retire to the bar: |'),
#   ('cain',   13, 'simon ┼: angelic dust'),
#   ('dawn',   16, '|cracked|'),
#   ('eeegah', 88, '-----------'),
#   ('finfangfoom', 62, 'claw|back|now'),
#   ('gort',   66, '|'),
#   ('helen',  14, '');



my $DAT = "$Bin/dat";
   #  /home/doom/End/Cave/SkullPlot/Wall/Data-Boxes/t/dat

{
  my $test_name = "Testing read method with embedded vertbars in a middle column";


# Just simple ascii vertical bars, and not in first or last column

# select id, name, wisdom, score from funked_up where name = 'alfred' OR name = 'betty' OR name = 'dawn' OR name = 'gort';
#  id |  name  |                     wisdom                     | score
# ----+--------+------------------------------------------------+-------
#   1 | alfred | Slavish imitation | gobs hobbies at mini-minds |    58
#   2 | betty  | Let us retire to the bar: |                    |    32
#   4 | dawn   | |cracked|                                      |    16
#   7 | gort   | |                                              |    66

  my $expected =
    [
     [ 'id', 'name',   'wisdom'                                        , 'score', ],
     [  '1', 'alfred', 'Slavish imitation | gobs hobbies at mini-minds', '58',    ],
     [  '2', 'betty',  'Let us retire to the bar: |'                   , '32',    ],
     [  '4', 'dawn',   '|cracked|'                                     , '16',    ],
     [  '7', 'gort',   '|'                                             , '66',    ],
    ];

  my $format = 'psql';

  my $input_file = "$DAT/funked_up-2-ascii_vertbars_middle-psql.dbox";
  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  is_deeply( $data, $expected, "$test_name on $format format" );
  # say "===";
}


{
  my $test_name = "Testing read method with vertbars in last column";

# Just simple ascii vertical bars:
# select id, name, score, wisdom from funked_up where name = 'alfred' OR name = 'betty' OR name = 'dawn' OR name = 'gort'
#  id |  name  | score |                     wisdom
# ----+--------+-------+------------------------------------------------
#   2 | betty  |    32 | Let us retire to the bar: |
#   1 | alfred |    58 | Slavish imitation | gobs hobbies at mini-minds
#   4 | dawn   |    16 | |cracked|
#   7 | gort   |    66 | |

  my $expected = [
          [ 'id', 'name',        'score', 'wisdom'                                         ],
          [  '2', 'betty',       '32',    'Let us retire to the bar: |'                    ],
          [  '1', 'alfred',      '58',    'Slavish imitation | gobs hobbies at mini-minds' ],
          [  '4', 'dawn',        '16',    '|cracked|'                                      ],
          [  '7', 'gort',        '66',    '|'                                              ],
        ];

  my $format = 'psql';

  my $input_file = "$DAT/funked_up-1-ascii_vertbars-psql.dbox";
  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  # say "---\n", Dumper( $data ) , "---";
  is_deeply( $data, $expected, "$test_name on $format format" );
  # say "===";
}

done_testing();
exit;

# TODO add tests of mysql and postgres unicode formats


{
  my $test_name = "Testing read method";

  my $expected = [
          [ 'id', 'name',        'score', 'wisdom'                                         ],
          [  '1', 'alfred',      '58',    'Slavish imitation | gobs hobbies at mini-minds' ],
          [  '2', 'betty',       '32',    'Let us retire to the bar: |'                     ],
          [  '3', 'cain',        '13',    'simon : angelic dust'                           ],
          [  '4', 'dawn',        '16',    '|cracked'                                       ],
          [  '5', 'eeegah',      '88',    '-----------'                                    ],
          [  '6', 'finfangfoom', '62',    'claw|back|now'                                  ],
          [  '7', 'gort',        '66',    ''                                               ],
          [  '8', 'helen',       '14',    undef                                            ]
        ];


  ###
  my $format = 'psql_unicode';

  my $input_file = "$DAT/expensoids-psql_unicode.dbox";

  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  is_deeply( $data, $expected, "$test_name on $format format" );

  ###
  $format = 'mysql';

  $input_file = "$DAT/expensoids-mysql.dbox";

  $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  $data = $bxs->read_dbox; # array of arrays, header in first row

  is_deeply( $data, $expected, "$test_name on $format format" );

}



done_testing();
