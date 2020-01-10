#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use Data::Dumper;
use File::Basename;
use autodie;
use FindBin;

use Pg::Explain;

plan 'tests' => 30;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

for my $format ( qw( json yaml xml ) ) {
    my $explain = Pg::Explain->new( 'source' => load_test_file( $format, 'plan' ) );
    isa_ok( $explain, 'Pg::Explain' );

    $explain->parse_source();
    isa_ok( $explain->top_node, 'Pg::Explain::Node' );

    my $gather    = $explain->top_node->sub_nodes->[ 0 ];
    my $aggregate = $gather->sub_nodes->[ 0 ];
    my $seq_scan  = $aggregate->sub_nodes->[ 0 ];

    is( $explain->top_node->type, 'Aggregate', "Correct type for topnode, for $format" );
    is( $gather->type,            'Gather',    "Correct type for Gather, for $format" );
    is( $aggregate->type,         'Aggregate', "Correct type for Aggregate, for $format" );
    is( $seq_scan->type,          'Seq Scan',  "Correct type for Seq Scan, for $format" );

    is( $explain->top_node->workers, 1, "Correct workers for topnode, for $format" );
    is( $gather->workers,            1, "Correct workers for Gather, for $format" );
    is( $aggregate->workers,         3, "Correct workers for Aggregate, for $format" );
    is( $seq_scan->workers,          3, "Correct workers for Seq Scan, for $format" );
}

exit;

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
