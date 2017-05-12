use strict;
use warnings;

use Test::More 0.88;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

plan tests => 3;

local $ENV{NET_AMAZON_CONFIG_DIR} = 't/data';

require_ok('Net::Amazon::Config');

my $config = new_ok('Net::Amazon::Config');

my $data = {
    profile_name      => 'johndoe',
    access_key_id     => 'XXXXXXXXXXXXXXXXXXXX',
    secret_access_key => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    certificate_file  => 'my-cert.pem',
    private_key_file  => 'my-key.pem',
    ec2_keypair_name  => 'my-ec2-keypair',
    ec2_keypair_file  => 'ec2-private-key.pem',
    aws_account_id    => '0123-4567-8901',
    canonical_user_id => '64-character-string',
};

my $profile = $config->get_profile;

is_deeply( $profile, $data, "default profile" );

