# Helper functions for testing Net::Duo.
#
# This module provides a useful set of additional functions to help write
# test programs for the Net::Duo distribution.  It exports functions in the
# same style as Test::More to compare various Net::Duo objects against
# reference data.
#
# All functions exported by this module report multiple separate test results,
# and the number of reported tests is not predictable in advance.  Users of
# this module should not set a test plan and should instead use done_testing()
# at the end of the test program.
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

package Test::RRA::Duo 1.00;

use 5.014;
use strict;
use warnings;

use Exporter qw(import);
use Net::Duo::Admin::Group;
use Net::Duo::Admin::Phone;
use Net::Duo::Admin::Token;
use Net::Duo::Admin::User;
use Test::More;

# Data keys that can use simple verification.
my @GROUP_KEYS = qw(desc name);
my @TOKEN_KEYS = qw(serial token_id type);
my @USER_KEYS  = qw(user_id username realname email status last_login notes);
my @PHONE_KEYS = qw(
  phone_id number extension name postdelay predelay type platform
  activated sms_passcodes_sent
);
my @INTEGRATION_KEYS = qw(
  adminapi_admins adminapi_info adminapi_integrations adminapi_read_log
  adminapi_read_resource adminapi_settings adminapi_write_resource
  enroll_policy greeting integration_key ip_whitelist_enroll_policy name
  notes secret_key trusted_device_days type username_normalization_policy
  visual_style
);

# Declare variables that should be set in BEGIN for robustness.
our @EXPORT_OK;

# Set everything export-related in a BEGIN block for robustness against
# circular module loading.
BEGIN {
    @EXPORT_OK = qw(
      is_admin_group is_admin_integration is_admin_phone is_admin_token
      is_admin_user
    );
}

# Internal helper function to check a nested array of objects.  Takes a
# reference to an array of objects (possibly empty), a reference to an array
# of data structures representing expected values (possibly undef), the
# function to call to compare them, and the prefix for each reporting message.
# Test results are reported via Test::More.
#
# $args_ref - Reference to hash of arguments with the following keys:
#   seen     - Reference to array of objects to check
#   expected - Reference to array of expected data (may be undef)
#   compare  - Function to compare seen and expected
#   prefix   - The prefix of the comment on test results
#
# Returns: undef
sub _check_array {
    my ($args_ref) = @_;
    my @seen = @{ $args_ref->{seen} };
    my @expected    = $args_ref->{expected} ? @{ $args_ref->{expected} } : ();
    my $compare_ref = $args_ref->{compare};
    my $prefix      = $args_ref->{prefix};

    # Check the count of objects.
    is(scalar(@seen), scalar(@expected), "...$prefix count");

    # Compare the actual objects.
    for my $i (0 .. $#seen) {
        $compare_ref->($seen[$i], $expected[$i], "$prefix $i");
    }
    return;
}

# Given a Net::Duo::Admin::Group object and the data structure representation
# of the JSON for that user, check that all the data fields match.  Test
# results are reported via Test::More.
#
# $seen     - The Net::Duo::Admin::Group object
# $expected - The data structure representing that group
# $prefix   - The prefix for the comment on test results
#
# Returns: undef
sub is_admin_group {
    my ($seen, $expected, $prefix) = @_;

    # Check object type.
    isa_ok($seen, 'Net::Duo::Admin::Group', $prefix);

    # Check the underlying data.
    $prefix = defined($prefix) ? "$prefix " : q{};
    for my $key (@GROUP_KEYS) {
        is($seen->$key, $expected->{$key}, "...$prefix$key");
    }
    return;
}

# Given a Net::Duo::Admin::Integration object and the data structure
# representation of the JSON for that user, check that all the data fields
# match.  Test results are reported via Test::More.
#
# $seen     - The Net::Duo::Admin::Integration object
# $expected - The data structure representing that group
# $prefix   - The prefix for the comment on test results
#
# Returns: undef
sub is_admin_integration {
    my ($seen, $expected, $prefix) = @_;

    # Check object type.
    isa_ok($seen, 'Net::Duo::Admin::Integration', $prefix);

    # Check the underlying data.
    $prefix = defined($prefix) ? "$prefix " : q{};
    for my $key (@INTEGRATION_KEYS) {
        is($seen->$key, $expected->{$key}, "...$prefix$key");
    }

    # Check the groups_allowed and ip_whitelist fields, which are arrays.
    my $want = $expected->{groups_allowed} // [];
    is_deeply([$seen->groups_allowed], $want, "...${prefix}groups_allowed");
    $want = $expected->{ip_whitelist} // [];
    is_deeply([$seen->ip_whitelist], $want, "...${prefix}ip_whitelist");
    return;
}

# Given a Net::Duo::Admin::Phone object and the data structure representation
# of the JSON for that user, check that all the data fields match.  Test
# results are reported via Test::More.
#
# $seen     - The Net::Duo::Admin::Phone object
# $expected - The data structure representing that group
# $prefix   - The prefix for the comment on test results
#
# Returns: undef
sub is_admin_phone {
    my ($seen, $expected, $prefix) = @_;

    # Check object type.
    isa_ok($seen, 'Net::Duo::Admin::Phone', $prefix);

    # Check the underlying simple data.
    $prefix = defined($prefix) ? "$prefix " : q{};
    for my $key (@PHONE_KEYS) {
        is($seen->$key, $expected->{$key}, "...$prefix$key");
    }

    # Check the capabilities, which is an array.
    my $want = $expected->{capabilities} // [];
    is_deeply([$seen->capabilities], $want, "...${prefix}capabilities");
    return;
}

# Given a Net::Duo::Admin::Token object and the data structure representation
# of the JSON for that user, check that all the data fields match.  Test
# results are reported via Test::More.
#
# $seen     - The Net::Duo::Admin::Token object
# $expected - The data structure representing that group
# $prefix   - The prefix for the comment on test results
#
# Returns: undef
sub is_admin_token {
    my ($seen, $expected, $prefix) = @_;

    # Check object type.
    isa_ok($seen, 'Net::Duo::Admin::Token', $prefix);

    # Check the underlying simple data.
    $prefix = defined($prefix) ? "$prefix " : q{};
    for my $key (@TOKEN_KEYS) {
        is($seen->$key, $expected->{$key}, "...$prefix$key");
    }
    return;
}

# Given a Net::Duo::Admin::User object and the data structure representation
# of the JSON for that user, check that all the data fields match.  Test
# results are reported via Test::More.
#
# $seen     - The Net::Duo::Admin::User object
# $expected - The data structure representing that user
# $prefix   - The prefix for the comment on test results
#
# Returns: undef
sub is_admin_user {
    my ($seen, $expected, $prefix) = @_;

    # Check the object type.
    isa_ok($seen, 'Net::Duo::Admin::User', $prefix);

    # Check the top-level, simple data.  We can't just use is_deeply on the
    # top-level object because we've converted some of the underlying hashes
    # to other objects, so we walk specific keys and confirm they match.
    $prefix = defined($prefix) ? "$prefix " : q{};
    for my $key (@USER_KEYS) {
        is($seen->$key, $expected->{$key}, "...$prefix$key");
    }

    # Check the nested arrays of objects.
    _check_array(
        {
            seen     => [$seen->groups],
            expected => $expected->{groups},
            compare  => \&is_admin_group,
            prefix   => $prefix . 'group',
        }
    );
    _check_array(
        {
            seen     => [$seen->phones],
            expected => $expected->{phones},
            compare  => \&is_admin_phone,
            prefix   => $prefix . 'phone',
        }
    );
    _check_array(
        {
            seen     => [$seen->tokens],
            expected => $expected->{tokens},
            compare  => \&is_admin_token,
            prefix   => $prefix . 'token',
        }
    );
    return;
}

1;
__END__

=for stopwords
Allbery

=head1 NAME

Test::RRA::Duo - Support functions for Net::Duo tests

=head1 SYNOPSIS

    use Test::RRA::Duo qw(is_admin_user);

    my $seen     = some_duo_call();
    my $expected = get_expected();
    is_admin_user($seen, $expected, 'Result of some_duo_call');

=head1 DESCRIPTION

Test::RRA::Duo provides some additional functions useful for testing
the Net::Duo module distribution.

All functions exported by this module report results in the style of
Test::More.  They all report multiple separate test results, and the
number of reported tests is not predictable in advance.  Users of this
module should not set a test plan and should instead use done_testing() at
the end of the test program.

=head1 FUNCTIONS

All functions take an object (SEEN), a reference to a hash of expected
data (EXPECTED), and a prefix for the messages for test results (PREFIX).

=over 4

=item is_admin_group(SEEN, EXPECTED, PREFIX)

Check a Net::Duo::Admin::Group object.

=item is_admin_integration(SEEN, EXPECTED, PREFIX)

Check a Net::Duo::Admin::Integration object.

=item is_admin_phone(SEEN, EXPECTED, PREFIX)

Check a Net::Duo::Admin::Phone object.

=item is_admin_token(SEEN, EXPECTED, PREFIX)

Check a Net::Duo::Admin::Token object.

=item is_admin_user(SEEN, EXPECTED, PREFIX)

Check a Net::Duo::Admin::User object.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Test::More>

=cut
