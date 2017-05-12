use strict;
use warnings;

use Test::More;
use File::Temp;
use File::Basename;
use Net::Amazon::HadoopEC2;

BEGIN {
    # set by hadoop-ec2-env.sh
    for (qw( AWS_ACCOUNT_ID AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY KEY_NAME PRIVATE_KEY_PATH )) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test.";
            exit 0;
        }
    }
    # set manually
    for (qw( PERL_NET_AMAZON_HADOOPEC2_TEST_CLUSTER )) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test.";
            exit 0;
        }
    }
    plan tests => 8;
}

my $hadoop = Net::Amazon::HadoopEC2->new(
    {
        aws_account_id        => $ENV{AWS_ACCOUNT_ID},
        aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    }
);

my $group_name = $ENV{PERL_NET_AMAZON_HADOOPEC2_TEST_CLUSTER};

#preparation;
{
    # depends on 't/02_launch_cluster.t'.
    my $cluster = $hadoop->find_cluster(
        {
            name => $group_name,
            key_file => $ENV{PRIVATE_KEY_PATH},
        }
    ) || $hadoop->launch_cluster(
        {
            name => $group_name,
            image_id => 'ami-b0fe1ad9', # hadoop-ec2 official image
            slaves => 2,
            key_name => $ENV{KEY_NAME},
            key_file => $ENV{PRIVATE_KEY_PATH},
        }
    );
    isa_ok $cluster, 'Net::Amazon::HadoopEC2::Cluster';
}

{
    my $cluster = $hadoop->find_cluster(
        {
            name => $group_name,
            key_file => $ENV{PRIVATE_KEY_PATH},
        }
    );
    isa_ok $cluster, 'Net::Amazon::HadoopEC2::Cluster';

    my $existing = scalar @{$cluster->slave_instances};
    {
        my $res = $cluster->launch_slave(
            {
                slaves => 2,
            }
        );
        isa_ok $res, 'Net::Amazon::HadoopEC2::Cluster';
        is scalar @{$cluster->slave_instances}, $existing + 2;
    }
    {
        my $res = $cluster->terminate_slaves(
            {
                slaves => 2,
            }
        );
        isa_ok $res, 'ARRAY';
        is scalar @{$res}, 2;
        isa_ok $res->[0], 'Net::Amazon::EC2::TerminateInstancesResponse';
        is scalar @{$cluster->slave_instances}, $existing;
    }
}
