#!perl

use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;

plan 'tests' => 3;

use Pg::Explain;

my $plan = join '', <DATA>;

my $explain = Pg::Explain->new( 'source' => $plan );
isa_ok( $explain, 'Pg::Explain' );
$explain->parse_source();

isa_ok( $explain->top_node, 'Pg::Explain::Node' );

my $textual = $explain->as_text;
my ( $first_line ) = split( /\r?\n/, $textual );

is( $first_line, 'Result  (cost=0.00..0.10 rows=1 width=4) (actual time=0.003..0.003 rows=1 loops=1)', 'as_text generates proper cost string' );

exit;

__DATA__
             QUERY PLAN
─────────────────────────────────────
 [                                  ↵
   {                                ↵
     "Plan": {                      ↵
       "Node Type": "Result",       ↵
       "Parallel Aware": false,     ↵
       "Startup Cost": 0.00,        ↵
       "Total Cost": 0.10,          ↵
       "Plan Rows": 1,              ↵
       "Plan Width": 4,             ↵
       "Actual Startup Time": 0.003,↵
       "Actual Total Time": 0.003,  ↵
       "Actual Rows": 1,            ↵
       "Actual Loops": 1,           ↵
       "Shared Hit Blocks": 0,      ↵
       "Shared Read Blocks": 0,     ↵
       "Shared Dirtied Blocks": 0,  ↵
       "Shared Written Blocks": 0,  ↵
       "Local Hit Blocks": 0,       ↵
       "Local Read Blocks": 0,      ↵
       "Local Dirtied Blocks": 0,   ↵
       "Local Written Blocks": 0,   ↵
       "Temp Read Blocks": 0,       ↵
       "Temp Written Blocks": 0,    ↵
       "I/O Read Time": 0.000,      ↵
       "I/O Write Time": 0.000      ↵
     },                             ↵
     "Planning Time": 0.030,        ↵
     "Triggers": [                  ↵
     ],                             ↵
     "Execution Time": 0.024        ↵
   }                                ↵
 ]
(1 row)

Time: 1,324 ms
