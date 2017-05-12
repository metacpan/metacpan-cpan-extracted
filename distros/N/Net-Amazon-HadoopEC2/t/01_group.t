use strict;
use warnings;
use Test::More;
use Digest::MD5 qw(md5_hex);

BEGIN {
    for (qw( AWS_ACCOUNT_ID AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY )) {
        unless ($ENV{$_}) {
            plan skip_all => "set $_ to run this test.";
            exit 0;
        }
    }
    plan tests => 15;
    use_ok 'Net::Amazon::HadoopEC2';
    use_ok 'Net::Amazon::HadoopEC2::Group';
}

my $hadoop = Net::Amazon::HadoopEC2->new(
    {
        aws_account_id => $ENV{AWS_ACCOUNT_ID},
        aws_access_key_id => $ENV{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
    }
);
isa_ok $hadoop, 'Net::Amazon::HadoopEC2';
isa_ok $hadoop->_ec2, 'Net::Amazon::EC2';
is $hadoop->_ec2->AWSAccessKeyId, $ENV{AWS_ACCESS_KEY_ID};
is $hadoop->_ec2->SecretAccessKey, $ENV{AWS_SECRET_ACCESS_KEY};

{
    my $res;
    my $group_name = md5_hex($$, time);
    my $group = Net::Amazon::HadoopEC2::Group->new(
        {
            _ec2 => $hadoop->_ec2,
            name => $group_name,
            aws_account_id => $ENV{AWS_ACCOUNT_ID},
        }
    );

    ok !$group->find;
    ok $group->ensure;
    $res = $hadoop->_ec2->describe_security_groups(GroupName => [$group_name, "$group_name-master"]);
    is scalar @{$res}, 2;
    ok $group->find;
    ok $group->remove;
    ok !$group->find;
    $res = $hadoop->_ec2->describe_security_groups(GroupName => [$group_name, "$group_name-master"]);
    isa_ok $res, 'Net::Amazon::EC2::Errors';
    is scalar @{$res->errors}, 1;
    is $res->errors->[0]->code, 'InvalidGroup.NotFound';
}
