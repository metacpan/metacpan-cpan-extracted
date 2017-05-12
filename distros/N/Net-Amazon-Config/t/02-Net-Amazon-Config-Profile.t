# Copyright (c) 2010 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

plan tests => 13;

require_ok('Net::Amazon::Config::Profile');

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

my $profile = new_ok( 'Net::Amazon::Config::Profile', [%$data] );

is_deeply( $profile, $data, "default profile" );

$profile = new_ok( 'Net::Amazon::Config::Profile', [ [%$data] ] );

for my $n ( sort keys %$data ) {
    is( $profile->$n, $data->{$n}, "accessor for '$n'" );
}

