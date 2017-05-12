#!/usr/bin/perl
#
# Test suite for user handling in the Admin API.
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

use lib 't/lib';

use JSON ();
use Net::Duo::Mock::Agent;
use Perl6::Slurp;
use Test::More;
use Test::RRA::Duo qw(is_admin_user);

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

# Try a users call, returning the test user data.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/users',
        response_file => 't/data/responses/users.json',
    }
);
note('Testing users endpoint with no search');
my @users = $duo->users;

# Should be an array of a single user.
is(scalar(@users), 1, 'users method returns a single user');

# Verify that the returned user is correct.
my $raw      = slurp('t/data/responses/users.json');
my $expected = $json->decode($raw)->[0];
is_admin_user($users[0], $expected);

# Now, try a user call with a specified username.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/users',
        content       => { username => 'jdoe' },
        response_file => 't/data/responses/user.json',
    }
);
note('Testing users endpoint with search for jdoe');
my $user = $duo->user('jdoe');

# Verify that the returned user is correct.
$raw      = slurp('t/data/responses/user.json');
$expected = $json->decode($raw)->[0];
is_admin_user($user, $expected);

# Convert the full user to JSON and compare that with the expected JSON.
is_deeply($json->decode($user->json), $expected, 'Full JSON output');

# Remove the first phone from that user.
my $user_id  = $user->user_id;
my $phone    = ($user->phones)[0];
my $phone_id = $phone->phone_id;
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/users/$user_id/phones/$phone_id",
        response_data => q{},
    }
);
note('Testing disassociating a phone with a user');
$user->remove_phone($phone);

# Add the phone back.
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/users/$user_id/phones",
        content       => { phone_id => $phone_id },
        response_data => q{},
    }
);
note('Testing associating a phone with a user');
$user->add_phone($phone);

# Remove the first token from that user.
my $token    = ($user->tokens)[0];
my $token_id = $token->token_id;
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/users/$user_id/tokens/$token_id",
        response_data => q{},
    }
);
note('Testing disassociating a token with a user');
$user->remove_token($token);

# Add the token back.
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/users/$user_id/tokens",
        content       => { token_id => $token_id },
        response_data => q{},
    }
);
note('Testing associating a token with a user');
$user->add_token($token);

# Create a new user.
my $data = {
    username => 'jdoe',
    realname => 'Jane Doe',
    email    => 'jdoe@example.com',
    status   => 'active',
    notes    => 'Some user note',
};
$mock->expect(
    {
        method        => 'POST',
        uri           => '/admin/v1/users',
        content       => $data,
        response_file => 't/data/responses/user-create.json',
    }
);
note('Testing user create endpoint');
$user = Net::Duo::Admin::User->create($duo, $data);

# Verify that the returned user is correct.  (Just use the same return data.)
$raw      = slurp('t/data/responses/user-create.json');
$expected = $json->decode($raw);
is_admin_user($user, $expected);

# Test a user update.  First, we'll do an update with every field that's
# possible to change.  When we commit, all the fields should revert since we
# refresh from the server's view.
$data = {
    email    => 'jane@example.net',
    notes    => 'Some other user note',
    realname => 'Jane Hamilton',
    status   => 'bypass',
    username => 'jane',
};
my $id = $expected->{user_id};
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/users/$id",
        content       => $data,
        response_file => 't/data/responses/user-create.json',
    }
);
note('Testing user modification with all data');
for my $field (sort keys %{$data}) {
    my $method = "set_$field";
    $user->$method($data->{$field});
    is($user->$field, $data->{$field}, "set_$field changes data");
}
$user->commit;
is_admin_user($user, $expected);

# Now test a user update with only one change.
$data = { realname => 'Peter Jacobs' };
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/users/$id",
        content       => $data,
        response_file => 't/data/responses/user-create.json',
    }
);
note('Testing user modification with one field');
$user->set_realname('Peter Jacobs');
$user->commit;
is_admin_user($user, $expected);

# Request bypass codes for a user.
$mock->expect(
    {
        method  => 'POST',
        uri     => "/admin/v1/users/$id/bypass_codes",
        content => { count => 2, valid_secs => 3600 },
        response_data => ['567891', '857231'],
    }
);
note('Testing bypass code generation');
my $codes = $user->bypass_codes({ count => 2, valid_secs => 3600 });
is_deeply($codes, ['567891', '857231'], 'bypass_codes return');

# The same, but pass in a list of codes to set.
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/users/$id/bypass_codes",
        content       => { codes => '123891,589134,490152' },
        response_data => ['123891', '589134', '490152'],
    }
);
note('Testing bypass code setting');
$codes = $user->bypass_codes({ codes => ['123891', '589134', '490152'] });
is_deeply($codes, ['123891', '589134', '490152'], 'bypass_codes return');

# Delete that user.
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/users/$expected->{user_id}",
        response_data => q{},
    }
);
note('Testing user delete endpoint');
$user->delete;

# Finished.  Tell Test::More that.
done_testing();
