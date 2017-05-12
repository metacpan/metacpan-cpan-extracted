use strict;
use warnings;
use Test::More;
use Scalar::Util qw'reftype';
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::YARN::ResourceManager");
}

SKIP: {
    skip "No YARN_RESOURCE_MANAGER in environment", 1 if !$ENV{YARN_RESOURCE_MANAGER};

    my $rm;
    isa_ok(
        $rm = Net::Hadoop::YARN::ResourceManager->new(
            servers => [ split /,/, $ENV{YARN_RESOURCE_MANAGER} ]
        ),
        "Net::Hadoop::YARN::ResourceManager"
    );

    ok( $rm->info->{resourceManagerVersion}, "RM version info present" );
    ok( $rm->metrics->{totalNodes},          "at least 1 node in metrics" );
    is( reftype( $rm->scheduler->{rootQueue} ), "HASH", "scheduler root queue" );

    my $apps;
    is( reftype( $apps = $rm->apps( { limit => 10 } ) ), "ARRAY", "array of apps" );
    is( reftype( $apps = $rm->apps( { limit => 10, applicationType => "MAP" } ) ),
        "ARRAY", "array of maps" );

    is( reftype( $rm->appstatistics ), "ARRAY", "array of app stats" );
    ok( @{ $rm->appstatistics( { states => "RUNNING,ACCEPTED" } ) } == 2,
        "only RUNNING ans ACCEPTED app stats" );

    my ( $app_id, $app );
    like( $app_id = $apps->[0]->{id}, qr/^application/, "app ID found" );
    is( reftype( $app = $rm->apps($app_id) ), "HASH", "single app is a hash" );
    is( $app->{id}, $app_id, "app IDs match for apps(<id>) and apps->[0]{id}" );

    is( reftype( $rm->appattempts($app_id)->{appAttempt} ), "ARRAY", "array of app attempts" );

    my ( $node, $nodes );
    is( reftype( $nodes = $rm->nodes ), "ARRAY", "array of nodes" );
    my $node_id = $nodes->[0]{id};
    is( reftype( $node = $rm->nodes($node_id) ), "HASH", "single node is a hash" );
    is( $node->{id}, $node_id, "node IDs match for nodes(<id>) and nodes->[0]{id}" );

}

done_testing();
