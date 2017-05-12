#!/usr/bin/perl
#
# Test suite for the generic Net::Duo call methods.
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

use 5.014;
use strict;
use warnings;

use HTTP::Response;
use JSON ();
use Net::Duo::Mock::Agent;
use Test::More;

BEGIN {
    use_ok('Net::Duo');
}

# Test initialization from a key file and a mock agent.
my %args = (key_file => 't/data/integrations/auth.json');
my $mock = Net::Duo::Mock::Agent->new(\%args);
$args{user_agent} = $mock;
my $duo = Net::Duo->new(\%args);
isa_ok($duo, 'Net::Duo');

# Make a generic call with no parameters.
my $response = HTTP::Response->new('404', 'Resource not found');
$mock->expect(
    {
        method   => 'GET',
        uri      => '/logo',
        response => $response,
    }
);
my $result = $duo->call('GET', '/logo');
is($result, $response, 'call return');

# Make a generic JSON call with some parameters.
$mock->expect(
    {
        method  => 'POST',
        uri     => '/foo/bar',
        content => {
            param => 'one',
            other => 'two',
        },
        response_data => {
            result => 'foo',
            extra  => 'bar',
        },
    }
);
my $args = {
    param => 'one',
    other => 'two',
};
$result = $duo->call_json('POST', '/foo/bar', $args);
is_deeply($result, { result => 'foo', extra => 'bar' }, 'call_json return');

# Finished.  Tell Test::More that.
done_testing();
