use strict;
use warnings;

use Test::More tests => 6;

use File::Find::Rule;
use File::Path qw( mkpath );
use File::Spec;
use List::Util qw( max );
use SmokeRunner::Multi::TestSet;

use lib 't/lib';
use SmokeRunner::Multi::Test;


test_setup();

my $root_dir = root_dir();
my $set_dir  = set_dir();
my $t_dir    = test_dir();

subtest new => sub {
    mkpath( $set_dir, 0, 0755 )
        or die "Cannot mkpath $set_dir: $!";

    eval { SmokeRunner::Multi::TestSet->new( set_dir => $set_dir ) };
    like( $@, qr/\Qmust have a 't' subdirectory/,
          'TestSet constructor requires a dir with a subdir named t' );

    mkpath( $t_dir, 0, 0755 )
        or die "Cannot mkpath $t_dir: $!";

    my $set = eval { SmokeRunner::Multi::TestSet->new( set_dir => $set_dir ) };
    is( $@, '',
        'TestSet constructor succeeds with valid dir' );
    is( $set->name(), 'set1', 'name() returns set1' );
    is( $set->set_dir(), $set_dir,
        'set_dir() method returns expected path' );
    is( $set->test_dir(), $t_dir,
        'test_dir() method returns expected path' );
    isa_ok( $set, 'SmokeRunner::Multi::TestSet' );
};

subtest TEST_FILES => sub {
    my $set = SmokeRunner::Multi::TestSet->new( set_dir => $set_dir );

    my @tests = $set->test_files();
    is( scalar @tests, 0, 'no test files found' );

    my @expected_tests;
    for my $num ( 1..5 )
    {
        my $file = File::Spec->catfile( $t_dir, "$num.t" );
        open my $fh, '>', $file
            or die "Cannot write to $file: $!";
        close $fh;

        push @expected_tests, $file;
    }

    # We want a file not ending in .t to ensure that only .t files are
    # returned by the test_files() method.
    my $file = File::Spec->catfile( $t_dir, 'not-a-test.not' );
    open my $fh, '>', $file
        or die "Cannot write to $file: $!";
    close $fh;

    @tests = $set->test_files();
    is( scalar @tests, 5, 'five test files found' );
    is_deeply( \@tests, \@expected_tests,
               'test files found in set are 1.t - 5.t, in sorted order' );
};

subtest ATTRIBUTES => sub {
    my $set = SmokeRunner::Multi::TestSet->new( set_dir => $set_dir );

    my $last_mod_time = max map { ( stat $_ )[9] } $set->test_files();
    is( $set->last_mod_time(), $last_mod_time,
        'last mod time is the mod time of the most recently modified test file' );
    is( $set->last_run_time(), 0, 'last_run_time() is 0' );
    ok( ! $set->is_prioritized(), 'set is not prioritized' );

    ok( $set->is_out_of_date(), 'set is out of date' );
    cmp_ok( $set->seconds_out_of_date(), '>', 0,
            'seconds out of date is > 0' );

    my $time = time;
    $set->update_last_run_time($time);
    is( $set->last_run_time(), $time,
        'last_run_time() is time passed to update_last_run_time()' );

    ok( ! $set->is_out_of_date(), 'set is not out of date' );
    cmp_ok( $set->seconds_out_of_date(), '<=', 0,
            'seconds out of date is <= 0' );

    $set->prioritize();
    ok( $set->is_prioritized(), 'set is prioritized after calling prioritize()' );

    $set->unprioritize();
    ok( ! $set->is_prioritized(), 'set is not prioritized after calling unprioritize()' );
};

subtest ALL => sub {
    my $new_set_dir = File::Spec->catdir( $root_dir, 'set2' );
    mkpath( $new_set_dir, 0, 0755 )
        or die "Cannot mkpath $new_set_dir: $!";

    my @sets = SmokeRunner::Multi::TestSet->All();
    is( scalar @sets, 1, 'only one set is returned from All()' );
    is( $sets[0]->name(), 'set1',
        'only set1 is returned by All()' ); 

    my $new_t_dir = File::Spec->catdir( $new_set_dir, 't' );
    mkpath( $new_t_dir, 0, 0755 )
        or die "Cannot mkpath $new_t_dir: $!";

    @sets = SmokeRunner::Multi::TestSet->All();
    is( scalar @sets, 2, 'two sets are returned from All()' );
    is_deeply( [ sort map { $_->name() } @sets ],
               [ 'set1', 'set2' ],
               'the two sets returned are the two sets we expect' );
};

subtest REMOVE => sub {
    my $new_set_dir = File::Spec->catdir( $root_dir, 'set2' );
    my $set = SmokeRunner::Multi::TestSet->new( set_dir => $new_set_dir );

    $set->remove();

    ok( ! -d $new_set_dir, 'remove() delete the set dir' );

    my $dbh = SmokeRunner::Multi::DBI::handle();
    my $count = $dbh->selectrow_array( 'SELECT COUNT(*) FROM TestSet WHERE name = ?', {}, 'set2' );

    is( $count, 0, 'set data was deleted from database' );
};

subtest ALL_SORTING => sub {
    $_->remove() for SmokeRunner::Multi::TestSet->All();

    write_four_sets();

    is_deeply( [ map { $_->name() } SmokeRunner::Multi::TestSet->All() ],
               [ qw( set1 set4 set3 set2 ) ],
               'sets are sorted by out of date-ness',
             );

    my $set3 = SmokeRunner::Multi::TestSet->new(
        set_dir => File::Spec->catdir( root_dir(), 'set3' ) );
    $set3->prioritize();

    is_deeply( [ map { $_->name() } SmokeRunner::Multi::TestSet->All() ],
               [ qw( set3 set1 set4 set2 ) ],
               'prioritized sets are sorted first',
             );

    my $set2 = SmokeRunner::Multi::TestSet->new(
        set_dir => File::Spec->catdir( root_dir(), 'set2' ) );
    $set2->prioritize();

    is_deeply( [ map { $_->name() } SmokeRunner::Multi::TestSet->All() ],
               [ qw( set3 set2 set1 set4 ) ],
               'prioritized sets are sorted first, and secondary sort if by out of date-ness',
             );
};
