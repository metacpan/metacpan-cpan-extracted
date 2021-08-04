#!perl

use strict;
use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

# two node types, 4 explain formats, single test for each combination.
plan 'tests' => 2 * 4;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my %node_types = (
    'is'  => 'Index Scan Backward',
    'ios' => 'Index Only Scan Backward',
);

for my $type ( sort keys %node_types ) {

    my $expected_type = $node_types{ $type };

    for my $format ( qw( text json yaml xml ) ) {
        my $test    = "${format}.${type}.plan";
        my $explain = Pg::Explain->new( 'source' => load_file( $test ) );
        my $scan    = $explain->top_node->sub_nodes->[ 0 ];
        is( $scan->type, $expected_type, "${format} Sub node type" );
    }
}

exit;

sub load_file {
    my $filename = shift;
    open my $fh, '<', sprintf( "%s/%s", $data_dir, $filename );
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    $file_content =~ s/\s*\z//;

    return $file_content;
}

