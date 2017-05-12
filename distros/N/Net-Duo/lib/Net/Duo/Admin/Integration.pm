# Representation of a single Duo integration for the Admin API.
#
# This class wraps the Duo representation of a single Duo integration, as
# returned by (for example) the Admin /integrations REST endpoint.

package Net::Duo::Admin::Integration 1.01;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo::Object);

# Data specification for converting JSON into our object representation.  See
# the Net::Duo::Object documentation for syntax information.
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fields {
    return {
        adminapi_admins               => ['simple', 'zero_or_one'],
        adminapi_info                 => ['simple', 'zero_or_one'],
        adminapi_integrations         => ['simple', 'zero_or_one'],
        adminapi_read_log             => ['simple', 'zero_or_one'],
        adminapi_read_resource        => ['simple', 'zero_or_one'],
        adminapi_settings             => ['simple', 'zero_or_one'],
        adminapi_write_resource       => ['simple', 'zero_or_one'],
        enroll_policy                 => 'simple',
        greeting                      => 'simple',
        groups_allowed                => 'array',
        integration_key               => 'simple',
        ip_whitelist                  => 'array',
        ip_whitelist_enroll_policy    => 'simple',
        name                          => 'simple',
        notes                         => 'simple',
        secret_key                    => 'simple',
        trusted_device_days           => 'simple',
        type                          => 'simple',
        username_normalization_policy => 'simple',
        visual_style                  => 'simple',
    };
}
## use critic

# Install our accessors.
Net::Duo::Admin::Integration->install_accessors;

# Override the new method to support creating an integration from an ID
# instead of decoded JSON data.
#
# $class      - Class of object to create
# $duo        - Net::Duo object to use to create the object
# $id_or_data - Integration ID or reference to data
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub new {
    my ($class, $duo, $id_or_data) = @_;
    if (!ref($id_or_data)) {
        my $uri = "/admin/v1/integrations/$id_or_data";
        $id_or_data = $duo->call_json('GET', $uri);
    }
    return $class->SUPER::new($duo, $id_or_data);
}

# Override the create method to add the appropriate URI.
#
# $class    - Class of object to create
# $duo      - Net::Duo object to use to create the object
# $data_ref - Data for new object as a reference to a hash
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub create {
    my ($class, $duo, $data_ref) = @_;
    return $class->SUPER::create($duo, '/admin/v1/integrations', $data_ref);
}

# Delete the integration from Duo.  After this call, the object should be
# treated as read-only since it can no longer be usefully updated.
#
# $self - The Net::Duo::Admin::Integration object to delete
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem deleting the object
## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my ($self) = @_;
    my $id = $self->{integration_key};
    $self->{_duo}->call_json('DELETE', "/admin/v1/integrations/$id");
    return;
}
## use critic

1;
__END__

=for stopwords
Allbery MERCHANTABILITY NONINFRINGEMENT CIDR CSV integrations sublicense

=head1 NAME

Net::Duo::Admin::Integration - Representation of a Duo integration

=head1 SYNOPSIS

    my $decoded_json = get_json();
    my $integration = Net::Duo::Admin::Integration->new($decoded_json);
    say $integration->secret_key;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

An integration is Duo's name for the metadata for a system or service that
is allowed to use one or more of the Duo APIs.  This object is the Perl
representation of a Duo integration as returned by the Duo Admin API,
usually via the integrations() method of Net::Duo::Admin or by retrieving
an integration by integration key.

=head1 CLASS METHODS

=over 4

=item create(DUO, DATA)

Creates a new integration in Duo and returns the resulting integration as
a new Net::Duo::Admin::Integration object.  DUO is the Net::Duo object
that should be used to perform the creation.  DATA is a reference to a
hash with one or more of the following keys (the C<name> and C<type> keys
are required):

=over 4

=item adminapi_admins

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API methods.  Optional and defaults to
false.

=item adminapis_info

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API account info methods.  Optional and
defaults to false.

=item adminapis_integrations

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API integration methods.  Optional and
defaults to false.

=item adminapis_read_log

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API log methods.  Optional and defaults
to false.

=item adminapis_read_resource

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API methods that retrieve objects such
as users, phones, and hardware tokens.  Setting this key does not grant
permission to change those objects or create new ones.  Optional and
defaults to false.

=item adminapis_settings

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API settings methods.  These control
global settings for the entire Duo account.  Optional and defaults to
false.

=item adminapis_write_resource

Only valid for integrations of type C<adminapi>.  Set to a true value to
grant permission to use all Admin API methods that create or modify
objects such as as users, phones, and hardware tokens.  Optional and
defaults to false.

=item enroll_policy

What to do after an enrolled user passes primary authentication.  See the
L</enroll_policy()> method below for the possible values.  Optional and
defaults to C<enroll>.

=item greeting

Voice greeting read before the authentication instructions to users who
authenticate with a phone callback.  Optional.

=item groups_allowed

A comma-separated list of group IDs that are allowed to authenticate with
the integration.  Optional.  By default, all groups are allowed.

=item ip_whitelist

CSV string of trusted IPs or IP ranges.  Both CIDR-style ranges and ranges
specified by two IP addresses separated by a dash (C<->) are supported.
Authentications from these IP addresses will not require a second factor.

This can only be set for certain integrations.  For the range of valid
values and circumstances in which this can be used, see the Duo Admin API
documentation.  Optional.

=item ip_whitelist_enroll_policy

What to do after a new user from a trusted IP completes primary
authentication.  See the L</ip_whitelist_enroll_policy()> method below for
the possible values.  Optional and defaults to C<enforce>.

=item name

The name of the integration.  Required.

=item notes

Any further description of the integration.  Optional.

=item trusted_device_days

Number of days to allow a user to trust the device they are logging in
with.  This can only be set for certain integrations and must be between 0
and 60.  (0 disables this feature.)  For the circumstances in which this
can be used, see the Duo Admin API documentation.  Optional.

=item type

The type of the integration.  For a list of valid values, see the Duo
Admin API documentation.  Required.

=item username_normalization_policy

Controls whether or not usernames should be altered before trying to match
them to a user account.  See the L</username_normalization_policy()> method
below for the possible values.  Optional and defaults to C<simple>.

=item visual_style

Look and feel of web content generated by the integration.  This can only
be set for certain integrations.  For a list of valid values and
circumstances in which this can be used, see the Duo Admin API
documentation.  Optional.

=back

=item new(DUO, DATA)

Creates a new Net::Duo::Admin::Integration object from a full data set.
DUO is the Net::Duo object that should be used for any further actions on
this object.  DATA should be the data structure returned by the Duo REST
API for a single user, after JSON decoding.  This constructor is primarily
used internally by other Net::Duo::Admin methods.

=item new(DUO, KEY)

Creates a new Net::Duo::Admin::Integration object from the integration
key.  DUO is the Net::Duo object that is used to retrieve the integration
from Duo and will be used for any subsequent operations.  The KEY should
be the integration key of the integration.  This constructor is
distinguished from the previous constructor by checking whether KEY is a
reference.

=back

=head1 INSTANCE ACTION METHODS

=over 4

=item delete()

Delete this integration from Duo.  After successful completion of this
call, the Net::Duo::Admin::Integration object should be considered
read-only, since no further changes to the object can be meaningfully sent
to Duo.

=item json()

Convert the data stored in the object to JSON and return the results.  The
resulting JSON should match the JSON that one would get back from the Duo
web service when retrieving the same object (plus any changes made locally
to the object via set_*() methods).  This is primarily intended for
debugging dumps or for passing Duo objects to other systems via further
JSON APIs.

=back

=head1 INSTANCE DATA METHODS

=over 4

=item adminapi_admins()

Whether this admin integration may use all Admin API methods.

=item adminapis_info()

Whether this admin integration may use all Admin API account info methods.

=item adminapis_integrations()

Whether this admin integration may use all Admin API integration methods.

=item adminapis_read_log()

Whether this admin integration may use all Admin API log methods.

=item adminapis_read_resource()

Whether this admin integration may use all Admin API methods that retrieve
objects such as users, phones, and hardware tokens.

=item adminapis_settings()

Whether this admin integration may use all Admin API settings methods.

=item adminapis_write_resource()

Whether this admin integration may use all Admin API methods that create
or modify objects such as as users, phones, and hardware tokens.

=item enroll_policy()

What to do after an enrolled user passes primary authentication.  The
value will be one of C<enroll>, to prompt the user to enroll, C<allow>, to
allow the user to sign in without presenting an additional factor, and
C<deny>, to deny authentication for this user.

=item greeting()

Voice greeting read before the authentication instructions to users who
authenticate with a phone callback.

=item groups_allowed()

A reference to an array of group IDs that are allowed to authenticate with
the integration.

=item ip_whitelist()

List of trusted IPs or IP ranges.  Ranges may be in the form of CIDR
network blocks or ranges specified by two IP addresses separated by a dash
(C<->) are supported.  Authentications from these IP addresses will not
require a second factor.  Example values:

    192.0.2.8
    198.51.100.0-198.51.100.20
    203.0.113.0/24

This is only supported with certain integration types.

=item ip_whitelist_enroll_policy()

What to do after a new user from a trusted IP completes primary
authentication.  The value will be either C<enforce>, meaning that the
user will be subject to the normal enrollment policy as returned by
enroll_policy(), or C<allow>, which means that the user will be
successfully authenticated without being required to enroll, skipping any
enrollment policy.

=item integration_key()

The identifier of this integration.  For C<adminapi>, C<accountsapi>,
C<rest>, and C<verify> integrations, this is the key used as the
C<integration_key> value when constructing a Net::Duo object.

=item name()

The name of the integration.

=item notes()

Any further description of the integration.

=item secret_key()

Secret used when configuring systems to use this integration.  For
C<adminapi>, C<accountsapi>, C<rest>, and C<verify> integrations, this is
the key used as the C<secret_key> value when constructing a Net::Duo
object.  This is equivalent to a password and should be treated with the
same care.

=item trusted_device_days()

Number of days to allow a user to trust the device they are logging in
with, or C<0> if this is disabled.  This setting only has an effect for
certain integrations.

=item type()

The type of the integration.  For a list of possible values, see the Duo
Admin API documentation.

=item username_normalization_policy()

Controls whether or not usernames should be altered before trying to match
them to a user account.  The value will be either C<none>, indicating no
normalization, or C<simple>, in which C<DOMAIN\username> and
C<username@example.com> will be converted to C<username> before
authentication is attempted.

=item visual_style()

Look and feel of web content generated by the integration.  This only has
an effect for some integrations.  For a list of valid values, see the Duo
Admin API documentation.

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

L<Net::Duo::Admin>

L<Duo Admin API for integrations|https://www.duosecurity.com/docs/adminapi#integrations>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<http://www.eyrie.org/~eagle/software/net-duo/>.

=cut
