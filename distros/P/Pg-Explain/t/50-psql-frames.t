#!perl

use Test::More;
use Test::Exception;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

my %tests = ();

if ( 0 == scalar @ARGV ) {
    opendir( my $dir, $data_dir );

    for my $file ( readdir $dir ) {
        next unless $file =~ s/\.plan$//;
        $tests{ $file } = sprintf '%s/%s.plan', $data_dir, $file;
    }
    closedir $dir;
}
else {
    for my $test ( @ARGV ) {
        $tests{ $test } = sprintf '%s/%s.plan', $data_dir, $test;
    }
}

plan 'tests' => 22 * scalar keys %tests;

for my $test ( sort { $a cmp $b } keys %tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $expect_format = uc( $test );
    $expect_format =~ s/-.*//;

    my $explains = {
        'file' => Pg::Explain->new( 'source_file' => $tests{ $test } ),
        'text' => Pg::Explain->new( 'source'      => load_test_file( $tests{ $test } ) ),
    };

    for my $type ( qw( file text ) ) {
        my $explain = $explains->{ $type };
        isa_ok( $explain, 'Pg::Explain', "(${test}:${type}) Object creation" );
        lives_ok( sub { $explain->parse_source(); }, "(${test}:${type}) Parsing lives" );
        my $top_node = $explain->top_node;
        my $looks_ok = isa_ok( $top_node, 'Pg::Explain::Node', "(${test}:${type}) Top node is a node" );

        SKIP: {
            skip "(${test}:${type}) parsing failed", 8 unless $looks_ok;

            is( $explain->source_format, $expect_format, "(${test}:${type}) Correct format detected" );

            my $first_kid  = $top_node->sub_nodes->[ 0 ];
            my $second_kid = $top_node->sub_nodes->[ 1 ];

            isa_ok( $first_kid,  'Pg::Explain::Node', "(${test}:${type}) First kid is a node" );
            isa_ok( $second_kid, 'Pg::Explain::Node', "(${test}:${type}) Second kid is a node" );

            is( $top_node->type,   'Nested Loop', "(${test}:${type}) Top node is Nested Loop" );
            is( $first_kid->type,  'Seq Scan',    "(${test}:${type}) First kid is Seq Scan" );
            is( $second_kid->type, 'Seq Scan',    "(${test}:${type}) Second kid is Seq Scan" );

            cmp_deeply( $first_kid->scan_on,  { 'table_alias' => 'u', 'table_name' => 'users' },  "(${test}:${type}) Correct scan info for first kid" );
            cmp_deeply( $second_kid->scan_on, { 'table_alias' => 'p', 'table_name' => 'part_0' }, "(${test}:${type}) Correct scan info for second kid" );
        }
    }
}

exit;

sub load_test_file {
    my $path = shift;
    open my $fh, '<', $path;
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    return $file_content;
}

