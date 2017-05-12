use strict;
use warnings;

use Test::More;
use Test::Exception;
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
    plan tests => 2;
}

{
    my $hadoop = Net::Amazon::HadoopEC2->new(
        {
            aws_account_id        => 'dummy',
            aws_access_key_id     => 'dummy',
            aws_secret_access_key => 'dummy',
        }
    );
    dies_ok { $hadoop->launch_cluster(
            {
                name => $ENV{PERL_NET_AMAZON_HADOOPEC2_TEST_CLUSTER},
                image_id => 'ami-b0fe1ad9', # hadoop-ec2 official image
                slaves => 1,
                key_name => $ENV{KEY_NAME},
                key_file => $ENV{PRIVATE_KEY_PATH},
            }
        ) } 
    'invalid AWS Access Key Id';
}
{
    my $hadoop = Net::Amazon::HadoopEC2->new(
        {
            aws_account_id        => $ENV{AWS_ACCESS_KEY_ID},
            aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
            aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
        }
    );
    dies_ok {$hadoop->launch_cluster(
            {
                name => $ENV{PERL_NET_AMAZON_HADOOPEC2_TEST_CLUSTER},
                image_id => 'ami-dummy',
                slaves => 1,
                key_name => $ENV{KEY_NAME},
                key_file => $ENV{PRIVATE_KEY_PATH},
            }
        )}
    'invalid image_id';
}
