#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use File::Basename;
use autodie;
use FindBin;

use Pg::Explain;

plan 'tests' => 13;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my $explain = Pg::Explain->new( 'source' => load_test_file( '01', 'plan' ) );
isa_ok( $explain, 'Pg::Explain' );
$explain->parse_source();

is( $explain->top_node->type,                                                                         'Gather',             'Correct type for topnode' );
is( $explain->top_node->initplans->[ 0 ]->type,                                                       'Finalize Aggregate', 'Correct type for Finalize Aggregate' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->type,                                     'Gather',             'Correct type for nested Gather' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type,                   'Partial Aggregate',  'Correct type for Partial Aggregate' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->type, 'Parallel Seq Scan',  'Correct type for Parallel Seq Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->type,                                                       'Parallel Seq Scan',  'Correct type for Parallel Seq Scan' );

is( $explain->top_node->force_loops,                                                                         undef, 'Force loops for topnode' );
is( $explain->top_node->initplans->[ 0 ]->force_loops,                                                       undef, 'Correct force loops for Finalize Aggregate' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->force_loops,                                     undef, 'Correct forced_loops for nested Gather' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->force_loops,                   1,     'Correct force_loops for Partial Aggregate' );
is( $explain->top_node->initplans->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->sub_nodes->[ 0 ]->force_loops, 1,     'Correct force_loops for Parallel Seq Scan' );
is( $explain->top_node->sub_nodes->[ 0 ]->force_loops,                                                       1,     'Correct force_loops for top Parallel Seq Scan' );

exit;

sub sort_paths {
    return [
        map  { $_->[ 1 ] }
        sort { $a->[ 0 ] cmp $b->[ 0 ] }
        map  { [ join( ' :: ', @{ $_ } ), $_ ] } @{ $_[ 0 ] }
    ];
}

sub load_test_file {
    my $test_no = shift;
    my $type    = shift;

    my $filename = sprintf '%s/%s.%s', $data_dir, $test_no, $type;

    open my $fh, '<', $filename;
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    return $file_content;
}
