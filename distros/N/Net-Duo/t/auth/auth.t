#!/usr/bin/perl
#
# Test suite for the Auth API auth functions.
#
# Written by Jon Robertson <jonrober@stanford.edu>
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

use Net::Duo::Mock::Agent;
use Test::More;

BEGIN {
    use_ok('Net::Duo::Auth');
}

# Arguments for the Net::Duo constructor.
my %args = (key_file => 't/data/integrations/auth.json');

# Create the Net::Duo::Auth object with our testing integration configuration
# and a mock agent.
my $mock = Net::Duo::Mock::Agent->new(\%args);
$args{user_agent} = $mock;
my $duo = Net::Duo::Auth->new(\%args);
isa_ok($duo, 'Net::Duo::Auth');

# Set expected data for a successful validation call.
note('Testing token validation');
$mock->expect(
    {
        method  => 'POST',
        uri     => '/auth/v2/auth',
        content => {
            username => 'user',
            passcode => '0123456',
            factor   => 'passcode',
        },
        response_data => {
            result     => 'allow',
            status     => 'allow',
            status_msg => 'Success. Logging you in...',
        },
    }
);
my $args = {
    username => 'user',
    factor   => 'passcode',
    passcode => '0123456',
};
is(scalar($duo->auth($args)), 1, 'Auth returns scalar success');

# Do a Duo Push authentication with some extra data.
$mock->expect(
    {
        method  => 'POST',
        uri     => '/auth/v2/auth',
        content => {
            username => 'user',
            factor   => 'push',
            device   => 'auto',
            pushinfo => 'from=login%20portal&domain=example.com',
        },
        response_data => {
            result     => 'allow',
            status     => 'allow',
            status_msg => 'Success. Logging you in...',
        },
    }
);
$args = {
    username => 'user',
    factor   => 'push',
    device   => 'auto',
    pushinfo => [from => 'login portal', domain => 'example.com'],
};
my ($success, $data) = $duo->auth($args);
is($success, 1, 'Auth returns list success');
my $expected = {
    status     => 'allow',
    status_msg => 'Success. Logging you in...',
};
is_deeply($data, $expected, '...with correct extra information');

# Test an asynchronous authentication.
note('Testing asynchronous authentication');
$mock->expect(
    {
        method  => 'POST',
        uri     => '/auth/v2/auth',
        content => {
            username => 'user',
            device   => 'auto',
            factor   => 'auto',
            async    => 1,
        },
        response_data => { txid => 'id' },
    }
);
my $async = $duo->auth_async({ username => 'user', factor => 'auto' });
isa_ok($async, 'Net::Duo::Auth::Async', 'return from auth_async');
is($async->id, 'id', '...with correct transaction ID');

# Out of band auth_status.
note('Testing authentication status');
$mock->expect(
    {
        method        => 'GET',
        uri           => '/auth/v2/auth_status',
        content       => { txid => 'id' },
        response_data => {
            result     => 'allow',
            status     => 'allow',
            status_msg => 'Success. Logging you in...',
        },
    }
);
is($async->status, 'allow', 'Async status correct in scalar context');
$mock->expect(
    {
        method        => 'GET',
        uri           => '/auth/v2/auth_status',
        content       => { txid => 'id' },
        response_data => {
            result     => 'allow',
            status     => 'allow',
            status_msg => 'Success. Logging you in...',
        },
    }
);
my $status;
($status, $data) = $async->status;
is($status, 'allow', 'Async status correct in array context');
$expected = {
    status     => 'allow',
    status_msg => 'Success. Logging you in...',
};
is_deeply($data, $expected, 'Async data correct in array context');

# Recreate the Net::Duo::Auth::Async object from the transaction ID.
my $id = $async->id;
$async = Net::Duo::Auth::Async->new($duo, $id);
isa_ok($async, 'Net::Duo::Auth::Async', 'return from new');
is($async->id, 'id', '...with correct transaction ID');

# Finished.  Tell Test::More that.
done_testing();
