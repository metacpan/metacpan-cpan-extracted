#!perl

use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

use Pg::Explain;

my @tests = @ARGV;
if ( 0 == scalar @tests ) {
    opendir( my $dir, $data_dir );

    my %uniq = ();
    @tests = sort { $a <=> $b }
        grep { !$uniq{ $_ }++ }
        grep { !/\.txt$/ }
        grep { /^\d+\.[a-z]+$/ } readdir $dir;

    closedir $dir;
}

plan 'tests' => 4 * scalar @tests;

for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $text_file = $test;
    $text_file =~ s/\..*$/.txt/;
    my $text_explain = Pg::Explain->new( 'source' => load_file( $text_file ) );
    $text_explain->parse_source;

    my $expected_type = $text_explain->top_node->type;

    my $explain = Pg::Explain->new( 'source' => load_file( $test ) );
    $explain->parse_source();
    is( $explain->top_node->type, $expected_type, "Correct top node type for plan $test" );
    cmp_deeply( $text_explain->top_node->extra_info, $explain->top_node->extra_info, "Plan $test has correct extra_info" );

    my $reparsed = Pg::Explain->new( 'source' => $explain->as_text );
    $reparsed->parse_source();
    is( $reparsed->top_node->type, $expected_type, "Correct top node type for reparse of plan $test" );
    cmp_deeply( $text_explain->top_node->extra_info, $reparsed->top_node->extra_info, "Reparsed plan $test has correct extra_info" );
}

exit;

sub load_file {
    my $filename = shift;
    my $filepath = $data_dir . '/' . $filename;

    open my $fh, '<', $filepath;
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    return $file_content;
}
