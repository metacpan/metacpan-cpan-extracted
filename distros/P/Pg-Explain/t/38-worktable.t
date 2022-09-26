#!perl

use Test::More;
use File::Basename;
use FindBin;
use Pg::Explain;

plan 'tests' => 12;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my $expect = {
    'worktable_name'  => 'foo',
    'worktable_alias' => 'foo_1'
};

for my $test ( qw( text json yaml xml ) ) {
    my $plan = Pg::Explain->new( 'source_file' => $data_dir . '/plan.' . $test );
    $plan->parse_source();
    my $ws = $plan->top_node->ctes->{ 'foo' }->sub_nodes->[ 1 ];
    ok( defined $ws,                                     "(${test}) WorkTable Scan exists" );
    ok( $plan->as_text =~ /WorkTable Scan on foo foo_1/, "(${test}) Text format of plan contains correct worktable info" );
    is_deeply( $ws->scan_on, $expect, "(${test}) Scan-on is correct." );
}

exit;
