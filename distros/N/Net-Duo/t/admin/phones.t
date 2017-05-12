#!/usr/bin/perl
#
# Test suite for phone handling in the Admin API.
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
use Test::RRA::Duo qw(is_admin_phone);

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

# Create a new phone.
my $data = {
    number => '+15555550100',
    name   => 'Random test phone',
};
$mock->expect(
    {
        method        => 'POST',
        uri           => '/admin/v1/phones',
        content       => $data,
        response_file => 't/data/responses/phone-create.json',
    }
);
note('Testing phone create endpoint');
my $phone = Net::Duo::Admin::Phone->create($duo, $data);

# Verify that the returned phone is correct.  (Just use the same return data.)
my $raw      = slurp('t/data/responses/phone-create.json');
my $expected = $json->decode($raw);
is_admin_phone($phone, $expected);

# Convert the full phone to JSON and compare that with the expected JSON.
is_deeply($json->decode($phone->json), $expected, 'Full JSON output');

# Test a phone update.  First, we'll do an update with every field that's
# possible to change.  When we commit, all the fields should revert since we
# refresh from the server's view.
$data = {
    extension => '71351',
    name      => 'Updated phone name',
    number    => '+15555551910',
    platform  => 'Generic Smartphone',
    postdelay => '1',
    predelay  => '5',
    type      => 'mobile',
};
my $id = $expected->{phone_id};
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/phones/$id",
        content       => $data,
        response_file => 't/data/responses/phone-create.json',
    }
);
note('Testing phone modification with all data');
for my $field (sort keys %{$data}) {
    my $method = "set_$field";
    $phone->$method($data->{$field});
    is($phone->$field, $data->{$field}, "set_$field changes data");
}
$phone->commit;
is_admin_phone($phone, $expected);

# Now test a phone update with only one change.
$data = { name => 'Updated phone name' };
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/phones/$id",
        content       => $data,
        response_file => 't/data/responses/phone-create.json',
    }
);
note('Testing phone modification with one field');
$phone->set_name('Updated phone name');
$phone->commit;
is_admin_phone($phone, $expected);

# Retrieve a phone by ID.
$mock->expect(
    {
        method        => 'GET',
        uri           => "/admin/v1/phones/$id",
        response_file => 't/data/responses/phone-create.json',
    }
);
note('Testing phone retrieval by ID');
$phone = Net::Duo::Admin::Phone->new($duo, $id);
is_admin_phone($phone, $expected);

# Send SMS passcodes to the phone.
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/phones/$id/send_sms_passcodes",
        response_data => q{},
    }
);
note('Testing sending SMS passcodes');
$phone->send_sms_passcodes;

# Create an activation code for the phone.
$data = {
    activation_url     => 'https://example.com/iphone/7d3J4RLs',
    activation_barcode => 'https://example.com/frame/qr?value=duo%3A%2F%2Fat',
    valid_secs         => 3600,
};
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/phones/$id/activation_url",
        content       => { valid_secs => 3600 },
        response_data => $data,
    }
);
note('Testing activation URL without install URL');
my $activation = $phone->activation_url({ valid_secs => 3600 });
is_deeply($activation, $data, 'Phone activation data');

# Try the same but also requesting an installation_url.
$data->{installation_url} = 'https://example.com/installduo';
$mock->expect(
    {
        method        => 'POST',
        uri           => "/admin/v1/phones/$id/activation_url",
        content       => { install => 1, valid_secs => 3600 },
        response_data => $data,
    }
);
note('Testing activation URL with install URL');
$activation = $phone->activation_url({ install => 1, valid_secs => 3600 });
is_deeply($activation, $data, 'Phone activation data');

# Delete that phone.
$mock->expect(
    {
        method        => 'DELETE',
        uri           => "/admin/v1/phones/$id",
        response_data => q{},
    }
);
note('Testing phone delete endpoint');
$phone->delete;

# Finished.  Tell Test::More that.
done_testing();
