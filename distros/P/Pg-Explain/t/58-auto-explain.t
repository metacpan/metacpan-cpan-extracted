#!perl

use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

# 4 formats, 2 types, 5 tests each
plan 'tests' => 4 * 2 * 5;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

for my $format ( qw( text json yaml xml ) ) {
    for my $type ( qw( simple analyze ) ) {

        my $test = "$format-$type.plan";

        my $explain = Pg::Explain->new( 'source' => load_file( $test ) );

        isa_ok( $explain, 'Pg::Explain', "(${test}) Object creation" );
        lives_ok( sub { $explain->parse_source(); }, "(${test}) Parsing lives" );

        ok( defined $explain->top_node, "${test} top_node defined" );
        is( $explain->top_node->type, 'Result', "${test} top_node type correct" );

        if ( $type eq 'analyze' ) {
            ok( $explain->top_node->is_analyzed, "${test} top_node is analyzed" );
        }
        else {
            ok( !$explain->top_node->is_analyzed, "${test} top_node is not analyzed" );
        }
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

