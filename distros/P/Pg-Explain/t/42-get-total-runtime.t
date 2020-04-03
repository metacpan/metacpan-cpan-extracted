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
        map  { s/\..*//; $_ }
        grep { /^\d+\.(?:plan|struct|replan)$/ } readdir $dir;

    closedir $dir;
}

plan 'tests' => 3 * scalar @tests;

for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $explain = Pg::Explain->new( 'source' => load_test_file( $test, 'plan' ) );
    isa_ok( $explain, 'Pg::Explain' );

    $explain->parse_source();
    isa_ok( $explain->top_node, 'Pg::Explain::Node' );

    my $expected_runtime = eval( load_test_file( $test, 'expect' ) );
    die $@ if $@;

    is( $explain->runtime, $expected_runtime, 'Runtime is sane.' );
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
