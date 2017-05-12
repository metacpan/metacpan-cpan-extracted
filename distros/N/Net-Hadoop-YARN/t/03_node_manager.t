use strict;
use warnings;
use Test::More;
use Scalar::Util qw'reftype';
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::YARN::NodeManager");
}

SKIP: {
    skip "No YARN_RESOURCE_MANAGER in environment", 1 if !$ENV{YARN_RESOURCE_MANAGER};

    use Net::Hadoop::YARN::ResourceManager;
    my $rm
        = Net::Hadoop::YARN::ResourceManager->new( servers => [ split /,/, $ENV{YARN_RESOURCE_MANAGER} ] );
    my $nodes = $rm->nodes;

    # get the first running node that we find
    my ($node) = grep { $_->{state} eq "RUNNING" } @$nodes;

    my $nm;
    isa_ok( $nm
            = Net::Hadoop::YARN::NodeManager->new( servers => [ $node->{nodeHTTPAddress} ] ),
        "Net::Hadoop::YARN::NodeManager" );

    ok( $nm->info->{nodeManagerVersion}, "NM version info present" );

    my ( $app_id, $app, $apps );

    is( reftype( $apps = $nm->apps ), "ARRAY", "list of applications" );

    like( $app_id = $apps->[0]{id}, qr/^application/, "app ID found" );
    is( reftype( $app = $nm->app($app_id) ), "HASH", "single app is a hash" );
    is( $app->{id}, $app_id, "app IDs match for apps(<id>) and apps->[0]{id}" );

    my ( $container_id, $container, $containers );

    is( reftype( $containers = $nm->containers ), "ARRAY", "list of containers" );

    like( $container_id = $containers->[0]{id}, qr/^container/, "container ID found" );
    is( reftype( $container = $nm->container($container_id) ),
        "HASH", "single container is a hash" );
    is( $container->{id}, $container_id,
        "container IDs match for containers(<id>) and containers->[0]{id}" );

}

done_testing();
