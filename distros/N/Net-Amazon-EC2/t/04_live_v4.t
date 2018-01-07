use strict;
use blib;
use Test::More;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY_ID} || ! $ENV{SECRET_ACCESS_KEY} ) {
        plan skip_all => "Set AWS_ACCESS_KEY_ID and SECRET_ACCESS_KEY environment variables to run these _LIVE_ tests (NOTE: they will incur one instance hour of costs from EC2)";
    }
    else {
        plan tests => 5;
        use_ok( 'Net::Amazon::EC2' );
    }
};

my $ec2 = eval {
    Net::Amazon::EC2->new(
	AWSAccessKeyId    => $ENV{AWS_ACCESS_KEY_ID},
	SecretAccessKey   => $ENV{SECRET_ACCESS_KEY},
        region            => 'eu-central-1',
	ssl               => 1,
        #debug             => 1,
        signature_version => 4,
	return_errors     => 1,
    );
};

isa_ok($ec2, 'Net::Amazon::EC2');

my $availability_zones = $ec2->describe_availability_zones();
my $seen_availability_zone = 0;
foreach my $availability_zone (@{$availability_zones}) {
	if ($availability_zone->zone_name eq 'eu-central-1a') {
		$seen_availability_zone = 1;
	}
}
ok($seen_availability_zone == 1, "Describing availability zones");

my $regions = $ec2->describe_regions();
my $seen_region = 0;
foreach my $region (@{$regions}) {
	if ($region->region_name eq 'us-east-1') {
		$seen_region = 1;
	}
}
ok($seen_region == 1, "Describing regions");

my $reserved_instance_offerings = $ec2->describe_reserved_instances_offerings();
my $seen_offering = 0;
foreach my $offering (@{$reserved_instance_offerings}) {
	if ($offering->product_description eq 'Linux/UNIX') {
		$seen_offering = 1;
	}
}
ok($seen_offering == 1, "Describing Reserved Instances Offerings");
