#!perl

use Test::More;
use Test::Deep;
use autodie;

use Pg::Explain;

my @plans = (
    q{
                                                                       QUERY PLAN                                                                        
---------------------------------------------------------------------------------------------------------------------------------------------------------
 HashSetOp Intersect All  (cost=0.27..177.83 rows=341 width=8) (actual time=10.922..10.922 rows=0 loops=1)
   ->  Append  (cost=0.27..169.74 rows=3234 width=8) (actual time=6.408..9.847 rows=3234 loops=1)
         ->  Subquery Scan on "*SELECT* 1"  (cost=0.27..28.21 rows=341 width=8) (actual time=6.407..6.608 rows=341 loops=1)
               ->  Index Only Scan using pg_class_oid_index on pg_class  (cost=0.27..21.39 rows=341 width=4) (actual time=6.404..6.514 rows=341 loops=1)
                     Heap Fetches: 0
         ->  Subquery Scan on "*SELECT* 2"  (cost=0.28..141.54 rows=2893 width=8) (actual time=0.285..2.556 rows=2893 loops=1)
               ->  Index Only Scan using pg_proc_oid_index on pg_proc  (cost=0.28..83.68 rows=2893 width=4) (actual time=0.284..1.766 rows=2893 loops=1)
                     Heap Fetches: 0
 Planning time: 0.237 ms
 Execution time: 11.060 ms
(10 rows)
},
    q{
                      QUERY PLAN                       
-------------------------------------------------------
 [                                                    +
   {                                                  +
     "Plan": {                                        +
       "Node Type": "SetOp",                          +
       "Strategy": "Hashed",                          +
       "Parallel Aware": false,                       +
       "Command": "Intersect All",                    +
       "Startup Cost": 0.27,                          +
       "Total Cost": 177.83,                          +
       "Plan Rows": 341,                              +
       "Plan Width": 8,                               +
       "Actual Startup Time": 3.731,                  +
       "Actual Total Time": 3.731,                    +
       "Actual Rows": 0,                              +
       "Actual Loops": 1,                             +
       "Plans": [                                     +
         {                                            +
           "Node Type": "Append",                     +
           "Parent Relationship": "Outer",            +
           "Parallel Aware": false,                   +
           "Startup Cost": 0.27,                      +
           "Total Cost": 169.74,                      +
           "Plan Rows": 3234,                         +
           "Plan Width": 8,                           +
           "Actual Startup Time": 0.053,              +
           "Actual Total Time": 2.705,                +
           "Actual Rows": 3234,                       +
           "Actual Loops": 1,                         +
           "Plans": [                                 +
             {                                        +
               "Node Type": "Subquery Scan",          +
               "Parent Relationship": "Member",       +
               "Parallel Aware": false,               +
               "Alias": "*SELECT* 1",                 +
               "Startup Cost": 0.27,                  +
               "Total Cost": 28.21,                   +
               "Plan Rows": 341,                      +
               "Plan Width": 8,                       +
               "Actual Startup Time": 0.052,          +
               "Actual Total Time": 0.245,            +
               "Actual Rows": 341,                    +
               "Actual Loops": 1,                     +
               "Plans": [                             +
                 {                                    +
                   "Node Type": "Index Only Scan",    +
                   "Parent Relationship": "Subquery", +
                   "Parallel Aware": false,           +
                   "Scan Direction": "Forward",       +
                   "Index Name": "pg_class_oid_index",+
                   "Relation Name": "pg_class",       +
                   "Alias": "pg_class",               +
                   "Startup Cost": 0.27,              +
                   "Total Cost": 21.39,               +
                   "Plan Rows": 341,                  +
                   "Plan Width": 4,                   +
                   "Actual Startup Time": 0.050,      +
                   "Actual Total Time": 0.153,        +
                   "Actual Rows": 341,                +
                   "Actual Loops": 1,                 +
                   "Heap Fetches": 0                  +
                 }                                    +
               ]                                      +
             },                                       +
             {                                        +
               "Node Type": "Subquery Scan",          +
               "Parent Relationship": "Member",       +
               "Parallel Aware": false,               +
               "Alias": "*SELECT* 2",                 +
               "Startup Cost": 0.28,                  +
               "Total Cost": 141.54,                  +
               "Plan Rows": 2893,                     +
               "Plan Width": 8,                       +
               "Actual Startup Time": 0.048,          +
               "Actual Total Time": 1.847,            +
               "Actual Rows": 2893,                   +
               "Actual Loops": 1,                     +
               "Plans": [                             +
                 {                                    +
                   "Node Type": "Index Only Scan",    +
                   "Parent Relationship": "Subquery", +
                   "Parallel Aware": false,           +
                   "Scan Direction": "Forward",       +
                   "Index Name": "pg_proc_oid_index", +
                   "Relation Name": "pg_proc",        +
                   "Alias": "pg_proc",                +
                   "Startup Cost": 0.28,              +
                   "Total Cost": 83.68,               +
                   "Plan Rows": 2893,                 +
                   "Plan Width": 4,                   +
                   "Actual Startup Time": 0.047,      +
                   "Actual Total Time": 1.041,        +
                   "Actual Rows": 2893,               +
                   "Actual Loops": 1,                 +
                   "Heap Fetches": 0                  +
                 }                                    +
               ]                                      +
             }                                        +
           ]                                          +
         }                                            +
       ]                                              +
     },                                               +
     "Planning Time": 0.235,                          +
     "Triggers": [                                    +
     ],                                               +
     "Execution Time": 3.874                          +
   }                                                  +
 ]
(1 row)
}
);

plan 'tests' => 16;

my $explain = Pg::Explain->new( 'source' => $plans[ 0 ] );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                                             'HashSetOp Intersect All' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                                           'Append' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type,                         'Subquery Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 1 ]->type,                         'Subquery Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->scan_on->{ 'subquery_name' }, '*SELECT* 1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 1 ]->scan_on->{ 'subquery_name' }, '*SELECT* 2' );

$explain = Pg::Explain->new( 'source' => $plans[ 1 ] );
isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

is( $explain->top_node->type,                                                             'SetOp' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                                           'Append' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type,                         'Subquery Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 1 ]->type,                         'Subquery Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->scan_on->{ 'subquery_name' }, '*SELECT* 1' );
is( $explain->top_node->sub_nodes->[ 0 ]->sub_nodes->[ 1 ]->scan_on->{ 'subquery_name' }, '*SELECT* 2' );

exit;
