use strict;
use warnings;
use Test::More;
use Digest::MD5 qw(md5_hex);
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
    plan tests => 5;
}

my $hadoop = Net::Amazon::HadoopEC2->new(
    {
        aws_account_id => $ENV{AWS_ACCOUNT_ID},
        aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    }
);

my $group_name = $ENV{PERL_NET_AMAZON_HADOOPEC2_TEST_CLUSTER};

SKIP: {
    my $cluster = $hadoop->find_cluster(
        {
            name => $group_name,
            key_file => $ENV{PRIVATE_KEY_PATH},
        }
    );
    skip 'cluster not running' => 5 unless $cluster;

    {
        my $res = $cluster->terminate_cluster;
        isa_ok $res, 'ARRAY';
        is scalar @{$res}, 3;
        isa_ok $res->[0], 'Net::Amazon::EC2::TerminateInstancesResponse';
        is $cluster->master_instance, undef;
        is_deeply $cluster->slave_instances, [];
    }
}
