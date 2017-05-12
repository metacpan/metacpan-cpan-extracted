use strict;
use warnings;

use Test::More;
use File::Temp;
use Digest::MD5 qw(md5_hex);
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
    plan tests => 2;
}

my $hadoop = Net::Amazon::HadoopEC2->new(
    {
        aws_account_id        => $ENV{AWS_ACCOUNT_ID},
        aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    }
);

my $group_name = md5_hex($$, time);

{
    # depends on 't/02_launch_cluster.t'.
    my $cluster = $hadoop->launch_cluster(
        {
            name => $group_name,
            image_id => 'ami-b0fe1ad9', # hadoop-ec2 official image
            slaves => 1,
            key_name => $ENV{KEY_NAME},
            key_file => $ENV{PRIVATE_KEY_PATH},
            user_data => {
                FOO => 'bar',
            }
        }
    );
    isa_ok $cluster, 'Net::Amazon::HadoopEC2::Cluster';

    my $remote = $cluster->execute( { command => 'cat /tmp/user-data' } );
    ok grep {$_ eq 'FOO=bar'} split( /\n/, $remote->{stdout} );
    $cluster->terminate_cluster;
}
