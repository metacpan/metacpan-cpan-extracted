#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use autodie;

use Pg::Explain;

plan 'tests' => 8;

my $explain = Pg::Explain->new(
    'source' => q{
 [
   {
     "Plan": {
       "Node Type": "Sort",
       "Parallel Aware": false,
       "Startup Cost": 33.44,
       "Total Cost": 34.41,
       "Plan Rows": 386,
       "Plan Width": 262,
       "Actual Startup Time": 0.714,
       "Actual Total Time": 0.774,
       "Actual Rows": 387,
       "Actual Loops": 1,
       "Sort Key": ["relkind", "relname DESC"],
       "Sort Method": "quicksort",
       "Sort Space Used": 131,
       "Sort Space Type": "Memory",
       "Shared Hit Blocks": 13,
       "Shared Read Blocks": 0,
       "Shared Dirtied Blocks": 0,
       "Shared Written Blocks": 0,
       "Local Hit Blocks": 0,
       "Local Read Blocks": 0,
       "Local Dirtied Blocks": 0,
       "Local Written Blocks": 0,
       "Temp Read Blocks": 0,
       "Temp Written Blocks": 0,
       "Plans": [
         {
           "Node Type": "Seq Scan",
           "Parent Relationship": "Outer",
           "Parallel Aware": false,
           "Relation Name": "pg_class",
           "Alias": "pg_class",
           "Startup Cost": 0.00,
           "Total Cost": 16.86,
           "Plan Rows": 386,
           "Plan Width": 262,
           "Actual Startup Time": 0.010,
           "Actual Total Time": 0.109,
           "Actual Rows": 387,
           "Actual Loops": 1,
           "Shared Hit Blocks": 13,
           "Shared Read Blocks": 0,
           "Shared Dirtied Blocks": 0,
           "Shared Written Blocks": 0,
           "Local Hit Blocks": 0,
           "Local Read Blocks": 0,
           "Local Dirtied Blocks": 0,
           "Local Written Blocks": 0,
           "Temp Read Blocks": 0,
           "Temp Written Blocks": 0
         }
       ]
     },
     "Planning Time": 0.167,
     "Triggers": [
     ],
     "Execution Time": 0.895
   }
 ]
(1 row)

    }
);
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                   'Sort',     'Properly extracted top node type' );
is( $explain->top_node->sub_nodes->[ 0 ]->type, 'Seq Scan', 'Properly extracted subnode-1' );

my $sort     = $explain->top_node;
my $seq_scan = $explain->top_node->sub_nodes->[ 0 ];

my $sort_extra_info = $sort->extra_info;
$sort_extra_info = join( "\n", @{ $sort_extra_info } ) if 'ARRAY' eq ref $sort_extra_info;

my $seq_scan_extra_info = $seq_scan->extra_info;
$seq_scan_extra_info = join( "\n", @{ $seq_scan_extra_info } ) if 'ARRAY' eq ref $seq_scan_extra_info;

ok( $sort_extra_info     =~ m{Sort Key: relkind, relname DESC},      'Got sort keyfor sort' );
ok( $sort_extra_info     =~ m{Sort Method: quicksort Memory: 131kB}, 'Got sort methodfor sort' );
ok( $sort_extra_info     =~ m{Buffers: shared hit=13},               'Got buffers infofor sort' );
ok( $seq_scan_extra_info =~ m{Buffers: shared hit=13},               'Got buffers info for seq scan' );

exit;
