#!/usr/bin/perl
#
# Test suite for Net::Duo::Exception.
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

use HTTP::Response;
use JSON ();

use Test::More tests => 53;

BEGIN {
    use_ok('Net::Duo::Exception');
}

# Start with the simplest error message.
my $e = Net::Duo::Exception->internal('some error');
isa_ok($e, 'Net::Duo::Exception', 'internal()');
is($e->code,      50000,                '...code');
is($e->message,   'some error',         '...message');
is($e->content,   undef,                '...content');
is($e->detail,    undef,                '...detail');
is($e->to_string, 'some error [50000]', '...string form');

# Check cmp.
my $string = "$e";
is($e cmp $string, 0,  'cmp equal');
is($string cmp $e, 0,  'cmp equal reversed');
is($e cmp 'test',  -1, 'cmp unequal');
is('test' cmp $e,  1,  'cmp unequal reversed');

# Get a text form of an exception with line information appended.
## no critic (ErrorHandling::RequireCarping)
eval { die 'some error' };
## use critic

# Exception propagation.  Same as internal, but strips trailing line info.
$e = Net::Duo::Exception->propagate($@);
isa_ok($e, 'Net::Duo::Exception', 'propagate()');
is($e->code,      50000,                '...code');
is($e->message,   'some error',         '...message');
is($e->content,   undef,                '...content');
is($e->detail,    undef,                '...detail');
is($e->to_string, 'some error [50000]', '...string form');

# Protocol errors are the same except they take some content to stuff in the
# exception object.  This isn't included in the string form, but can be
# retrieved with the accessor.
$e = Net::Duo::Exception->protocol('another error', "random\nnewline\ndata");
isa_ok($e, 'Net::Duo::Exception', 'protocol()');
is($e->code,      50000,                   '...code');
is($e->message,   'another error',         '...message');
is($e->content,   "random\nnewline\ndata", '...content');
is($e->detail,    undef,                   '...detail');
is($e->to_string, 'another error [50000]', '...string form');

# HTTP errors extract the details from an HTTP::Response object.
my $response = HTTP::Response->new('404', 'Resource not found');
$response->content("random\nnewline\ndata");
$e = Net::Duo::Exception->http($response);
isa_ok($e, 'Net::Duo::Exception', 'http()');
is($e->code,      40400,                        '...code');
is($e->message,   'Resource not found',         '...message');
is($e->content,   "random\nnewline\ndata",      '...content');
is($e->detail,    undef,                        '...detail');
is($e->to_string, 'Resource not found [40400]', '...string form');

# API errors have the most complex logic, since we expect to have certain keys
# in API errors and convert to different types of exceptions without them.
# Start with an empty JSON object to exercise the missing stat value path.
$e = Net::Duo::Exception->api({}, q{});
isa_ok($e, 'Net::Duo::Exception', 'api() without stat');
is($e->code,    50000,                              '...code');
is($e->message, 'missing stat value in JSON reply', '...message');
is($e->content, q{},                                '...content');
is($e->detail,  undef,                              '...detail');
is($e->to_string, 'missing stat value in JSON reply [50000]',
    '...string form');

# Now with an invalid stat value.
$e = Net::Duo::Exception->api({ stat => 'FOO' }, '{"stat":"FOO"}');
isa_ok($e, 'Net::Duo::Exception', 'api() with invalid stat');
is($e->code,      50000,                              '...code');
is($e->message,   'invalid stat value',               '...message');
is($e->content,   '{"stat":"FOO"}',                   '...content');
is($e->detail,    'FOO',                              '...detail');
is($e->to_string, 'invalid stat value (FOO) [50000]', '...string form');

# With various missing fields.
$e = Net::Duo::Exception->api({ stat => 'FAIL' }, '{"stat":"FAIL"}');
isa_ok($e, 'Net::Duo::Exception', 'api() with missing fields');
is($e->code,      50000,                           '...code');
is($e->message,   'missing error message',         '...message');
is($e->content,   '{"stat":"FAIL"}',               '...content');
is($e->detail,    undef,                           '...detail');
is($e->to_string, 'missing error message [50000]', '...string form');

# A full, useful API error.  Example from the Auth API documentation.
my $object = {
    stat           => 'FAIL',
    code           => 40002,
    message        => 'Invalid request parameters',
    message_detail => 'username',
};
my $content = JSON->new->encode($object);
$e = Net::Duo::Exception->api($object, $content);
isa_ok($e, 'Net::Duo::Exception', 'api()');
is($e->code,    40002,                        '...code');
is($e->message, 'Invalid request parameters', '...message');
is($e->content, $content,                     '...content');
is($e->detail,  'username',                   '...detail');
is(
    $e->to_string,
    'Invalid request parameters (username) [40002]',
    '...string form'
);
