use strict;
use warnings;
use Test::More;
use Ref::Util qw( is_hashref );
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps");
}

SKIP: {
    skip "No YARN_RESOURCE_MANAGER in environment", 1 if !$ENV{YARN_RESOURCE_MANAGER};

    my $uapp;
    isa_ok(
        $uapp = Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps->new,
        'Net::Hadoop::YARN::ResourceManager::Scheduler::UserApps',
    );

    my $test_user = $ENV{YARN_TEST_USER} || 'mapred';
    my $fake_user = 'this_is_a_test_request';

    my $user_apps = $uapp->collect( $test_user );

    my $fake_apps = $uapp->collect( $fake_user );

    ok( is_hashref $fake_apps, "$fake_user apps is a hash" );

    foreach my $tuple (
        [ $test_user => $user_apps ],
        [ $fake_user => $fake_apps ],
    ) {
        my($user, $apps) = @{ $tuple };
        ok( is_hashref $apps, "`$user` apps is a hash" );
        foreach my $key ( qw( total_apps grouped_apps resources user ) ) {
            ok(
               exists $apps->{ $key },
               "`$key` exists in the returned data set",
            );
        }
        ok( $user eq $apps->{user}, "The data set has the same username `$user`" );
    }

    # There can be more extensive tests with the mapred user but it needs to
    # involve submitting jobs and checking their state back on the YARN cluster
    # which is really out of scope for this distro for now.
    #
}

done_testing();
