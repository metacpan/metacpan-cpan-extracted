use strict;
use blib;
use Test::More;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY_ID} || ! $ENV{SECRET_ACCESS_KEY} ) {
        plan skip_all => "Set AWS_ACCESS_KEY_ID and SECRET_ACCESS_KEY environment variables to run these tests";
    }
    else {
        plan tests => 1;
        use_ok( 'Net::Amazon::EC2' );
    }
};

my $ec2 = Net::Amazon::EC2->new(
	AWSAccessKeyId  => $ENV{AWS_ACCESS_KEY_ID}, 
	SecretAccessKey => $ENV{SECRET_ACCESS_KEY},
);
