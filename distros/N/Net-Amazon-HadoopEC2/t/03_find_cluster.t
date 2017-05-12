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
    plan tests => 6;
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
    {
        my $file_push = File::Temp->new;
        print $file_push 'hoge';
        close $file_push;
        ok $cluster->push_files(
            {
                files => [$file_push->filename],
                destination => '/mnt',
            }
        );
        my $remote = $cluster->execute( { command => 'ls /mnt' } );
        ok grep {$_ eq basename($file_push->filename)} split( /\n/, $remote->{stdout} );
        my $file_get = File::Temp->new;
        close $file_get;
        $cluster->get_files(
            {
                files => [ File::Spec->catfile('/mnt', basename($file_push->filename)) ],
                destination => $file_get->filename,
            }
        );
        open my $fh, '<', $file_get->filename;
        my $content = do {local $/; <$fh>};
        close $fh;
        is $content, 'hoge';
    }

    {
        diag "sleep 30 seconds....";
        sleep 30;
        my $command = join ' ', qw(
            /usr/local/hadoop-0.18.0/bin/hadoop
            jar
            /usr/local/hadoop-0.18.0/hadoop-0.18.0-examples.jar
            pi 10 100
        );
        my $result = $cluster->execute( { command => $command, } );
        my ($pi) = grep { /^Estimated value of PI is/} split( /\n/, $result->{stdout} );
        ok $pi, $pi;
    }
}
