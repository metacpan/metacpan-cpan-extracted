#!/usr/bin/perl
#
# Test suite for integration handling in the Admin API.
#
# Written by Russ Allbery <rra@cpan.org>
# Copyright 2019 Russ Allbery <rra@cpan.org>
# Copyright 2014
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
# SPDX-License-Identifier: MIT

use 5.014;
use strict;
use warnings;

use lib 't/lib';

use JSON ();
use Net::Duo::Mock::Agent;
use Perl6::Slurp;
use Test::More;
use Test::RRA::Duo qw(is_admin_integration);

BEGIN {
    use_ok('Net::Duo::Admin');
}

# Create a JSON decoder.
my $json = JSON->new->utf8(1);

# Arguments for the Net::Duo constructor.
my %args = (key_file => 't/data/integrations/admin.json');

# Create the Net::Duo::Auth object with our testing integration configuration
# and a mock agent.
my $mock = Net::Duo::Mock::Agent->new(\%args);
$args{user_agent} = $mock;
my $duo = Net::Duo::Admin->new(\%args);
isa_ok($duo, 'Net::Duo::Admin');

# Try an integrations call, returning the test user data.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/integrations',
        content       => { limit => 500, offset => 0 },
        response_file => 't/data/responses/integrations-1.json',
        next_offset   => 1,
        total_objects => 2,
    }
);
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/integrations',
        content       => { limit => 500, offset => 1 },
        response_file => 't/data/responses/integrations-2.json',
        next_offset   => undef,
        total_objects => 2,
    }
);
note('Testing integrations endpoint');
my @integrations = $duo->integrations;

# Should be an array of two integrations.
is(scalar(@integrations), 2, 'integrations method returns two objects');

# Verify that the returned integration is correct.
my @expected;
for my $file ('integrations-1.json', 'integrations-2.json') {
    my $raw = slurp("t/data/responses/$file");
    push(@expected, $json->decode($raw)->[0]);
}
is_admin_integration($integrations[0], $expected[0]);
is_admin_integration($integrations[1], $expected[1]);

# Create a new integration.  Make sure we include some zero_or_one fields.
my $data = {
    name              => 'Test admin integration',
    type              => 'adminapi',
    adminapi_admins   => 0,
    adminapi_info     => 'true',
    adminapi_read_log => 1,
};

# Set up the mock for creating a new integration.  It will see the converted
# zero_or_one values.
my $post_data = { %{$data} };
$post_data->{adminapi_info} = 1;
$mock->expect(
    {
        method        => 'POST',
        uri           => '/admin/v1/integrations',
        content       => $post_data,
        response_file => 't/data/responses/integration.json',
    }
);

# Attempt the create call.
note('Testing integration create endpoint');
my $integration = Net::Duo::Admin::Integration->create($duo, $data);

# Verify that the returned group is correct.  (Just use the same return data.)
my $raw      = slurp('t/data/responses/integration.json');
my $expected = $json->decode($raw);
is_admin_integration($integration, $expected);

# Convert the full integration to JSON and compare that with the expected
# JSON.
is_deeply($json->decode($integration->json), $expected, 'Full JSON output');

# Retrieve an integration by key.
my $key = $integration->integration_key;
$mock->expect(
    {
        method        => 'GET',
        uri           => "/admin/v1/integrations/$key",
        response_file => 't/data/responses/integration.json',
    }
);
note('Testing integration retrieval by key');
$integration = Net::Duo::Admin::Integration->new($duo, $key);
is_admin_integration($integration, $expected);

# Delete that integration.
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/integrations/$key",
        response_data => q{},
    }
);
note('Testing integration delete endpoint');
$integration->delete;

# Finished.  Tell Test::More that.
done_testing();
