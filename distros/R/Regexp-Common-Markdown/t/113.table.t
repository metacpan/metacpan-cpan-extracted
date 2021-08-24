#!/usr/local/bin/perl

use Test::More qw( no_plan );

BEGIN { use_ok( 'Regexp::Common::Markdown' ) || BAIL_OUT( "Unable to load Regexp::Common::Markdown" ); }

use lib './lib';
use Regexp::Common qw( Markdown );
require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );

## https://regex101.com/r/01XCqB/13
my $tests = 
[
    {
        table => "|               |            Grouping            ||\n+---------------+---------------------------------+\n| First Header  |  Second Header  |  Third Header |\n+---------------+-----------------+---------------+\n| Content       |           *Long Cell*          ||\n: continued     :                                ::\n: content       :                                ::\n| Content       |    **Cell**     |          Cell |\n: continued     :                 :               :\n: content       :                 :               :\n| New section   |      More       |          Data |\n| And more      |             And more           ||\n [Prototype table]\n",
        table_caption => " [Prototype table]\n",
        table_header => "|               |            Grouping            ||\n+---------------+---------------------------------+\n| First Header  |  Second Header  |  Third Header |\n+---------------+-----------------+---------------+\n",
        table_header1 => "|               |            Grouping            ||\n",
        table_header2 => "| First Header  |  Second Header  |  Third Header |\n+---------------+-----------------+---------------+\n",
        table_header_sep => "+---------------+---------------------------------+\n",
        table_headers => "|               |            Grouping            ||\n+---------------+---------------------------------+\n| First Header  |  Second Header  |  Third Header |\n+---------------+-----------------+---------------+\n",
        table_row => "| And more      |             And more           ||\n",
        table_rows => "| Content       |           *Long Cell*          ||\n: continued     :                                ::\n: content       :                                ::\n| Content       |    **Cell**     |          Cell |\n: continued     :                 :               :\n: content       :                 :               :\n| New section   |      More       |          Data |\n| And more      |             And more           ||\n",
        name => "With caption",
        test => <<EOT,
|               |            Grouping            ||
+---------------+---------------------------------+
| First Header  |  Second Header  |  Third Header |
+---------------+-----------------+---------------+
| Content       |           *Long Cell*          ||
: continued     :                                ::
: content       :                                ::
| Content       |    **Cell**     |          Cell |
: continued     :                 :               :
: content       :                 :               :
| New section   |      More       |          Data |
| And more      |             And more           ||
 [Prototype table]

EOT
    },
    {
        table => "Header 1  | Header 2\n--------- | ---------\nCell 1    | Cell 2\nCell 3    | Cell 4\n",
        table_header => "Header 1  | Header 2\n--------- | ---------\n",
        table_header1 => "Header 1  | Header 2\n",
        table_header_sep => "--------- | ---------\n",
        table_headers => "Header 1  | Header 2\n--------- | ---------\n",
        table_row => "Cell 3    | Cell 4\n",
        table_rows => "Cell 1    | Cell 2\nCell 3    | Cell 4\n",
        name => q{Simple tables},
        test => <<EOT,
Header 1  | Header 2
--------- | ---------
Cell 1    | Cell 2
Cell 3    | Cell 4
EOT
    },
    {
        table => "| Header 1  | Header 2\n| --------- | ---------\n| Cell 1    | Cell 2\n| Cell 3    | Cell 4\n",
        table_header => "| Header 1  | Header 2\n| --------- | ---------\n",
        table_header1 => "| Header 1  | Header 2\n",
        table_header_sep => "| --------- | ---------\n",
        table_headers => "| Header 1  | Header 2\n| --------- | ---------\n",
        table_row => "| Cell 3    | Cell 4\n",
        table_rows => "| Cell 1    | Cell 2\n| Cell 3    | Cell 4\n",
        name => q{With leading pipes},
        test => <<EOT,
| Header 1  | Header 2
| --------- | ---------
| Cell 1    | Cell 2
| Cell 3    | Cell 4
EOT
    },
    {
        table => "Header 1  | Header 2  |\n--------- | --------- |\nCell 1    | Cell 2    |\nCell 3    | Cell 4    |\n",
        table_header => "Header 1  | Header 2  |\n--------- | --------- |\n",
        table_header1 => "Header 1  | Header 2  |\n",
        table_header_sep => "--------- | --------- |\n",
        table_headers => "Header 1  | Header 2  |\n--------- | --------- |\n",
        table_row => "Cell 3    | Cell 4    |\n",
        table_rows => "Cell 1    | Cell 2    |\nCell 3    | Cell 4    |\n",
        name => q{With tailing pipes},
        test => <<EOT,
Header 1  | Header 2  |
--------- | --------- |
Cell 1    | Cell 2    |
Cell 3    | Cell 4    |
EOT
    },
    {
        table => "| Header 1  | Header 2  |\n| --------- | --------- |\n| Cell 1    | Cell 2    |\n| Cell 3    | Cell 4    |\n",
        table_header => "| Header 1  | Header 2  |\n| --------- | --------- |\n",
        table_header1 => "| Header 1  | Header 2  |\n",
        table_header_sep => "| --------- | --------- |\n",
        table_headers => "| Header 1  | Header 2  |\n| --------- | --------- |\n",
        table_row => "| Cell 3    | Cell 4    |\n",
        table_rows => "| Cell 1    | Cell 2    |\n| Cell 3    | Cell 4    |\n",
        name => q{With leading and tailing pipes},
        test => <<EOT,
| Header 1  | Header 2  |
| --------- | --------- |
| Cell 1    | Cell 2    |
| Cell 3    | Cell 4    |
EOT
    },
    {
        table => "| Header\n| -------\n| Cell\n",
        table_header => "| Header\n| -------\n",
        table_header1 => "| Header\n",
        table_header_sep => "| -------\n",
        table_headers => "| Header\n| -------\n",
        table_row => "| Cell\n",
        table_rows => "| Cell\n",
        name => q{One-column one-row table},
        test => <<EOT,
| Header
| -------
| Cell
EOT
    },
    {
        table => "Header  |\n------- |\nCell    |\n",
        table_header => "Header  |\n------- |\n",
        table_header1 => "Header  |\n",
        table_header_sep => "------- |\n",
        table_headers => "Header  |\n------- |\n",
        table_row => "Cell    |\n",
        table_rows => "Cell    |\n",
        name => q{With tailing pipes},
        test => <<EOT,
Header  |
------- |
Cell    |
EOT
    },
    {
        table => "| Header  |\n| ------- |\n| Cell    |\n",
        table_header => "| Header  |\n| ------- |\n",
        table_header1 => "| Header  |\n",
        table_header_sep => "| ------- |\n",
        table_headers => "| Header  |\n| ------- |\n",
        table_row => "| Cell    |\n",
        table_rows => "| Cell    |\n",
        name => q{With leading and tailing pipes},
        test => <<EOT,
| Header  |
| ------- |
| Cell    |
EOT
    },
    ## t9
    {
        table => "| Default   | Right     |  Center   |     Left  |\n| --------- |:--------- |:---------:| ---------:|\n| Long Cell | Long Cell | Long Cell | Long Cell |\n| Cell      | Cell      |   Cell    |     Cell  |\n",
        table_header => "| Default   | Right     |  Center   |     Left  |\n| --------- |:--------- |:---------:| ---------:|\n",
        table_header1 => "| Default   | Right     |  Center   |     Left  |\n",
        table_header_sep => "| --------- |:--------- |:---------:| ---------:|\n",
        table_headers => "| Default   | Right     |  Center   |     Left  |\n| --------- |:--------- |:---------:| ---------:|\n",
        table_row => "| Cell      | Cell      |   Cell    |     Cell  |\n",
        table_rows => "| Long Cell | Long Cell | Long Cell | Long Cell |\n| Cell      | Cell      |   Cell    |     Cell  |\n",
        name => q{Table alignement},
        test => <<EOT,


| Default   | Right     |  Center   |     Left  |
| --------- |:--------- |:---------:| ---------:|
| Long Cell | Long Cell | Long Cell | Long Cell |
| Cell      | Cell      |   Cell    |     Cell  |

EOT
    },
    {
        table => "| Header 1  | Header 2  |\n| --------- | --------- |\n| A         | B         |\n| C         |           |\n",
        table_header => "| Header 1  | Header 2  |\n| --------- | --------- |\n",
        table_header1 => "| Header 1  | Header 2  |\n",
        table_header_sep => "| --------- | --------- |\n",
        table_headers => "| Header 1  | Header 2  |\n| --------- | --------- |\n",
        table_row => "| C         |           |\n",
        table_rows => "| A         | B         |\n| C         |           |\n",
        name => q{Empty cells},
        test => <<EOT,
| Header 1  | Header 2  |
| --------- | --------- |
| A         | B         |
| C         |           |
EOT
    },
    {
        table => "Header 1  | Header 2\n--------- | ---------\nA         | B\n          | D\n",
        table_header => "Header 1  | Header 2\n--------- | ---------\n",
        table_header1 => "Header 1  | Header 2\n",
        table_header_sep => "--------- | ---------\n",
        table_headers => "Header 1  | Header 2\n--------- | ---------\n",
        table_row => "          | D\n",
        table_rows => "A         | B\n          | D\n",
        name => q{Empty cells},
        test => <<EOT,
Header 1  | Header 2
--------- | ---------
A         | B
          | D
EOT
    },
    {
        table => "| Header 1  | Header 2  |\n| --------- \n| Cell      | Cell      | Extra cell? |\n| Cell      | Cell      | Extra cell? |\n",
        table_header => "| Header 1  | Header 2  |\n| --------- \n",
        table_header1 => "| Header 1  | Header 2  |\n",
        table_header_sep => "| --------- \n",
        table_headers => "| Header 1  | Header 2  |\n| --------- \n",
        table_row => "| Cell      | Cell      | Extra cell? |\n",
        table_rows => "| Cell      | Cell      | Extra cell? |\n| Cell      | Cell      | Extra cell? |\n",
        name => q{Too many pipes in rows},
        test => <<EOT,
| Header 1  | Header 2  |
| --------- 
| Cell      | Cell      | Extra cell? |
| Cell      | Cell      | Extra cell? |

EOT
    },
    {
        table => "+------+-------------+--------------------------------------------+--------+\n| id   | name        | description                                | price  |\n+------+-------------+--------------------------------------------+--------+\n|    1 | gizmo       | Takes care of the doohickies               |   1.99 | \n|    2 | doodad      | Collects *gizmos*                          |  23.80 | \n|   10 | dojigger    | Handles:\n| * gizmos\n| * doodads\n| * thingamobobs | 102.98 | \n| 1024 | thingamabob | Self-explanatory, no?                      |   0.99 | \n+------+-------------+--------------------------------------------+--------+\n",
        table_bottom_sep => "+------+-------------+--------------------------------------------+--------+\n",
        table_header => "+------+-------------+--------------------------------------------+--------+\n| id   | name        | description                                | price  |\n+------+-------------+--------------------------------------------+--------+\n",
        table_header1 => "| id   | name        | description                                | price  |\n",
        table_header_sep => "+------+-------------+--------------------------------------------+--------+\n",
        table_header_sep_top => "+------+-------------+--------------------------------------------+--------+\n",
        table_headers => "+------+-------------+--------------------------------------------+--------+\n| id   | name        | description                                | price  |\n+------+-------------+--------------------------------------------+--------+\n",
        table_row => "| 1024 | thingamabob | Self-explanatory, no?                      |   0.99 | \n",
        table_rows => "|    1 | gizmo       | Takes care of the doohickies               |   1.99 | \n|    2 | doodad      | Collects *gizmos*                          |  23.80 | \n|   10 | dojigger    | Handles:\n| * gizmos\n| * doodads\n| * thingamobobs | 102.98 | \n| 1024 | thingamabob | Self-explanatory, no?                      |   0.99 | \n",
        name => q{Header with uper line},
        test => <<EOT,
+------+-------------+--------------------------------------------+--------+
| id   | name        | description                                | price  |
+------+-------------+--------------------------------------------+--------+
|    1 | gizmo       | Takes care of the doohickies               |   1.99 | 
|    2 | doodad      | Collects *gizmos*                          |  23.80 | 
|   10 | dojigger    | Handles:
| * gizmos
| * doodads
| * thingamobobs | 102.98 | 
| 1024 | thingamabob | Self-explanatory, no?                      |   0.99 | 
+------+-------------+--------------------------------------------+--------+
EOT
    },
];

run_tests( $tests,
{
    debug => 1,
    re => $RE{Markdown}{ExtTable},
    type => 'Table',
});
