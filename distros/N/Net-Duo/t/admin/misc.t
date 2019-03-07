#!/usr/bin/perl
#
# Test suite for other Duo Admin API methods.
#
# Written by Russ Allbery <rra@cpan.org>
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

# Test retrieving administrator logs.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/administrator',
        response_file => 't/data/responses/log-admin.json',
    }
);
my @logs     = $duo->logs_administrator;
my $raw      = slurp('t/data/responses/log-admin.json');
my $expected = $json->decode($raw);
is_deeply([@logs], $expected, 'Administrator logs');

# The same with a minimum time.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/administrator',
        content       => { mintime => 1_403_053_795 },
        response_file => 't/data/responses/log-admin.json',
    }
);
@logs = $duo->logs_administrator(1_403_053_795);
is_deeply([@logs], $expected, 'Administrator logs with mintime');

# Test retrieving authentication logs.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/authentication',
        response_file => 't/data/responses/log-auth.json',
    }
);
@logs     = $duo->logs_authentication;
$raw      = slurp('t/data/responses/log-auth.json');
$expected = $json->decode($raw);
is_deeply([@logs], $expected, 'Authentication logs');

# The same with a minimum time.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/authentication',
        content       => { mintime => 1_403_053_795 },
        response_file => 't/data/responses/log-auth.json',
    }
);
@logs = $duo->logs_authentication(1_403_053_795);
is_deeply([@logs], $expected, 'Authentication logs with mintime');

# Test retrieving telephony logs.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/telephony',
        response_file => 't/data/responses/log-telephony.json',
    }
);
@logs     = $duo->logs_telephony;
$raw      = slurp('t/data/responses/log-telephony.json');
$expected = $json->decode($raw);
is_deeply([@logs], $expected, 'Telephony logs');

# The same with a minimum time.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/logs/telephony',
        content       => { mintime => 1_403_053_795 },
        response_file => 't/data/responses/log-telephony.json',
    }
);
@logs = $duo->logs_telephony(1_403_053_795);
is_deeply([@logs], $expected, 'Telephony logs with mintime');

# Finished.  Tell Test::More that.
done_testing();
