#!/usr/bin/perl
#
# Test suite for token handling in the Admin API.
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
use Test::RRA::Duo qw(is_admin_token);

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

# Create a new token.
my $data = {
    type    => 'h8',
    serial  => '0',
    secret  => 'BAbja87NB8AmzlgalGAm09abNqpGZVva985al1zF',
    counter => 2,
};
$mock->expect(
    {
        method        => 'POST',
        uri           => '/admin/v1/tokens',
        content       => $data,
        response_file => 't/data/responses/token-create.json',
    }
);
note('Testing token create endpoint');
my $token = Net::Duo::Admin::Token->create($duo, $data);

# Verify that the returned token is correct.  (Just use the same return data.)
my $raw      = slurp('t/data/responses/token-create.json');
my $expected = $json->decode($raw);
is_admin_token($token, $expected);

# Convert the full token to JSON and compare that with the expected JSON.
is_deeply($json->decode($token->json), $expected, 'Full JSON output');

# Delete that token.
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/tokens/$expected->{token_id}",
        response_data => q{},
    }
);
note('Testing token delete endpoint');
$token->delete;

# Finished.  Tell Test::More that.
done_testing();
