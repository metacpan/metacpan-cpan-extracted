#!perl

use Test::More;
use Test::Deep;
use Test::Exception;
use File::Basename;
use autodie;
use FindBin;

my $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

use Pg::Explain;
use Pg::Explain::Analyzer;

my @tests = @ARGV;
if ( 0 == scalar @tests ) {
    opendir( my $dir, $data_dir );

    my %uniq = ();
    @tests = sort { $a <=> $b }
        grep { !$uniq{ $_ }++ }
        map  { s/\..*//; $_ }
        grep { /^\d+\.plan$/ } readdir $dir;

    closedir $dir;
}

plan 'tests' => 8 + 4 * scalar @tests;

# Check if creation of objects works, and fails when needed.
my $ex, $an;
lives_ok( sub { $ex = Pg::Explain->new( 'source' => 'Result  (cost=0.00..0.01 rows=1 width=4)' ) }, 'Pg::Explain created' );
isa_ok( $ex, 'Pg::Explain' );
dies_ok( sub { $an = Pg::Explain::Analyzer->new(); },       'Expecting to die #1' );
dies_ok( sub { $an = Pg::Explain::Analyzer->new( 1, 2 ); }, 'Expecting to die #2' );
dies_ok( sub { $an = Pg::Explain::Analyzer->new( 1 ); },    'Expecting to die #3' );
lives_ok( sub { $an = Pg::Explain::Analyzer->new( $ex ); }, 'Should live' );
isa_ok( $an, 'Pg::Explain::Analyzer' );
throws_ok( sub { Pg::Explain::Analyzer->new( $an ); }, qr{not Pg::Explain}, 'Expecting to die #4' );

# Run the tests
for my $test ( @tests ) {

    print STDERR 'Working on test ' . $test . "\n" if $ENV{ 'DEBUG_TESTS' };

    my $explain = Pg::Explain->new( 'source' => load_test_file( $test, 'plan' ) );
    isa_ok( $explain, 'Pg::Explain' );

    my $analyzer = Pg::Explain::Analyzer->new( $explain );
    isa_ok( $analyzer, 'Pg::Explain::Analyzer' );

    my $expected_types = [ sort @{ eval( load_test_file( $test, 'types' ) ) } ];
    die $@ if $@;

    my $got_types = [ sort @{ $analyzer->all_node_types } ];

    cmp_deeply( $got_types, $expected_types, 'Types list extracted OK.' );

    my $expected_paths = sort_paths( eval( load_test_file( $test, 'paths' ) ) );
    die $@ if $@;

    my $got_paths = sort_paths( $analyzer->all_node_paths );

    cmp_deeply( $got_paths, $expected_paths, 'Paths list extracted OK.' );
}

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
