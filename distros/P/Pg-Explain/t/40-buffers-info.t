#!perl

use Test::More;
use Test::Deep;
use Data::Dumper;
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

plan 'tests' => 4 * scalar @tests;

for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $explain = Pg::Explain->new( 'source' => load_test_file( $test, 'plan' ) );
    isa_ok( $explain, 'Pg::Explain' );

    my $expected_struct = eval( load_test_file( $test, 'struct' ) );
    die $@ if $@;

    my $got_struct = $explain->get_struct();
    print STDERR Dumper( $got_struct ) if $ENV{ 'DEBUG_TESTS' };

    my $got_replan = $explain->as_text();
    my $reexplain  = Pg::Explain->new( 'source' => $got_replan );
    isa_ok( $reexplain, 'Pg::Explain' );

    my $restruct = $reexplain->get_struct();

    cmp_deeply( $got_struct, $expected_struct, 'Plan no. ' . $test . ' passed struct comparison.', );
    cmp_deeply( $got_struct, $restruct,        'Plan no. ' . $test . ' passed restruct comparison.', );
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
