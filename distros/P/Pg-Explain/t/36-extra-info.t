#!perl

use Test::More;
use Test::Deep;
use autodie;

use Pg::Explain;

plan 'tests' => 14;

my $plan_file = 't/36-extra-info/plan';
my $explain   = Pg::Explain->new( 'source_file' => $plan_file );

isa_ok( $explain,           'Pg::Explain' );
isa_ok( $explain->top_node, 'Pg::Explain::Node' );

ok( defined $explain->planning_time,                                                          'planning time defined' );
ok( $explain->planning_time == 0.057,                                                         'planning time as expected' );
ok( defined $explain->execution_time,                                                         'execution time defined' );
ok( $explain->execution_time == 68937.619,                                                    'execution time as expected' );
ok( defined $explain->trigger_times,                                                          'trigger times defined' );
ok( 5 == scalar @{ $explain->trigger_times },                                                 'correct count of triggers' );
ok( 'for constraint fk_df_usage_2_df_scenario' eq $explain->trigger_times->[ 0 ]->{ 'name' }, 'correct name of first trigger' );
ok( 51330.296 == $explain->trigger_times->[ 0 ]->{ 'time' },                                  'correct time of first trigger' );
ok( 1 == $explain->trigger_times->[ 0 ]->{ 'calls' },                                         'correct calls of first trigger' );

my $textual = $explain->as_text();

my $reparsed = Pg::Explain->new( 'source' => $textual );
isa_ok( $reparsed,           'Pg::Explain' );
isa_ok( $reparsed->top_node, 'Pg::Explain::Node' );

my $expected = $explain->get_struct();
my $got      = $reparsed->get_struct();

cmp_deeply( $got, $expected, 'Structured match' );

exit;
