# Representation of a single Duo phone for the Admin API.
#
# This class wraps the Duo representation of a single Duo phone, as returned
# by (for example) the Admin /phones REST endpoint.

package Net::Duo::Admin::Phone 1.01;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo::Object);

use Net::Duo::Admin::User;

# Data specification for converting JSON into our object representation.  See
# the Net::Duo::Object documentation for syntax information.
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fields {
    return {
        activated          => 'simple',
        capabilities       => 'array',
        extension          => ['simple', 'set'],
        name               => ['simple', 'set'],
        number             => ['simple', 'set'],
        phone_id           => 'simple',
        platform           => ['simple', 'set'],
        postdelay          => ['simple', 'set'],
        predelay           => ['simple', 'set'],
        sms_passcodes_sent => 'simple',
        type               => ['simple', 'set'],
        users              => 'Net::Duo::Admin::User',
    };
}
## use critic

# Install our accessors.
Net::Duo::Admin::Phone->install_accessors;

# Override the new method to support creating a phone from an ID instead
# of decoded JSON data.
#
# $class      - Class of object to create
# $duo        - Net::Duo object to use to create the object
# $id_or_data - Phone ID or reference to data
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub new {
    my ($class, $duo, $id_or_data) = @_;
    if (!ref($id_or_data)) {
        $id_or_data = $duo->call_json('GET', "/admin/v1/phones/$id_or_data");
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
    return $class->SUPER::create($duo, '/admin/v1/phones', $data_ref);
}

# Request an activation URL and barcode for a phone.
#
# $self     - The Net::Duo::Admin::Phone object to request activation URLs for
# $args_ref - Arguments for the request (optional)
#   install    - Set to a true value to request an install URL as well
#   valid_secs - Time the URL will be valid in seconds
#
# Returns: A reference to a hash with the following possible keys
#            activation_url     - Activation URL for this phone
#            activation_barcode - Activation URL for QR code for this phone
#            installation_url   - Install URL if one was requested
#            valid_secs         - How long URLs will be valid
#  Throws: Net::Duo::Exception on any problem getting activation URLs
sub activation_url {
    my ($self, $args_ref) = @_;
    my %args = %{$args_ref};

    # Canonicalize the install argument.
    if (defined($args_ref) && defined($args_ref->{install})) {
        $args{install} = $args{install} ? 1 : 0;
    }

    # Make the JSON call and return the results.
    my $uri = "/admin/v1/phones/$self->{phone_id}/activation_url";
    return $self->{_duo}->call_json('POST', $uri, \%args);
}

# Commit any changed data and refresh the object from Duo.
#
# $self - The Net::Duo::Admin::Phone object to commit changes for
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem updating the object
sub commit {
    my ($self) = @_;
    return $self->SUPER::commit("/admin/v1/phones/$self->{phone_id}");
}

# Delete the phone from Duo.  After this call, the object should be treated as
# read-only since it can no longer be usefully updated.
#
# $self - The Net::Duo::Admin::Phone object to delete
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem deleting the object
## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my ($self) = @_;
    $self->{_duo}->call_json('DELETE', "/admin/v1/phones/$self->{phone_id}");
    return;
}
## use critic

# Send a new batch of SMS passcodes to a phone.
#
# $self - The Net::Duo::Admin::Phone object to which to send SMS passcodes
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem sending passcodes
sub send_sms_passcodes {
    my ($self) = @_;
    my $uri = "/admin/v1/phones/$self->{phone_id}/send_sms_passcodes";
    $self->{_duo}->call_json('POST', $uri);
    return;
}

1;
__END__

=for stopwords
Allbery MERCHANTABILITY NONINFRINGEMENT SMS passcodes sublicense postdelay
predelay

=head1 NAME

Net::Duo::Admin::Phone - Representation of a Duo phone

=head1 SYNOPSIS

    my $decoded_json = get_json();
    my $phone = Net::Duo::Admin::Phone->new($decoded_json);
    say $phone->number;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

A Net::Duo::Admin::Phone object is a Perl representation of a Duo phone as
returned by the Duo Admin API, usually via the phones() method or nested
in a user returned by the users() method.  It contains various information
about a phone.

=head1 CLASS METHODS

=over 4

=item create(DUO, DATA)

Creates a new phone in Duo and returns the resulting phone as a new
Net::Duo::Admin::Phone object.  DUO is the Net::Duo object that should be
used to perform the creation.  DATA is a reference to a hash with the
following keys:

=over 4

=item extension

The extension.  Optional.

=item name

The name of the phone.  Optional.

=item number

The phone number.  Optional.

=item platform

The platform of phone for Duo Mobile, or C<unknown> for a generic phone
type.  For the list of valid values, see the Duo Admin API documentation.
Optional.

=item postdelay

The time (in seconds) to wait after the extension is dialed and before the
speaking the prompt.  Optional.

=item predelay

The time (in seconds) to wait after the number picks up and before dialing
the extension.  Optional.

=item type

The type of the phone.  See the L</type()> method below for the possible
values.  Optional.

=back

=item new(DUO, DATA)

Creates a new Net::Duo::Admin::Phone object from a full data set.  DUO is
the Net::Duo object that should be used for any further actions on this
object.  DATA should be the data structure returned by the Duo REST API
for a single user, after JSON decoding.

=item new(DUO, ID)

Creates a new Net::Duo::Admin::Phone by ID.  DUO is the Net::Duo object
that is used to retrieve the phone from Duo and will be used for any
subsequent operations.  The ID should be the Duo identifier of the phone.
This constructor is distinguished from the previous constructor by
checking whether ID is a reference.

=back

=head1 INSTANCE ACTION METHODS

=over 4

=item activation_url([ARGS])

Request activation URLs (and optionally an install URL) for this phone.
ARGS is an optional reference to a hash whose keys should be chosen from
the following:

=over 4

=item install

If set to a true value, request an installation URL for this phone as well
as the activation URLs.  This is a URL that, when opened, will prompt the
user to install Duo Mobile.  The default is to not request an installation
URL.

=item valid_secs

The number of seconds these activation URLs should be valid for.  The
default is 86,400 (one day).

=back

The return value of this method will be a reference to a hash containing
the following keys:

=over 4

=item activation_url

Opening this URL with the Duo Mobile app will complete activation.

=item activation_barcode

URL of an image that can be scanned with Duo Mobile to complete
activation.  Activating with this image or with the activation URL will
produce the same result.

=item installation_url

Opening this URL on the phone will prompt the user to install Duo Mobile.
This will only be present if the install argument is set to a true value.

=item valid_secs

The number of seconds that the activation code is valid for.  Normally
this will be the same as the valid_secs argument in the request if it was
present, unless Duo rejected the requested validity interval.

=back

=item commit()

Commit all changes made via the set_*() methods to Duo.  Until this method
is called, any changes made via set_*() are only internal to the object
and not reflected in Duo.

After commit(), the internal representation of the object will be
refreshed to match the new data returned by the Duo API for that object.
Therefore, other fields of the object may change after commit() if some
other user has changed other, unrelated fields in the object.

It's best to think of this method as a synchronize operation: changed data
is written back, overwriting what's in Duo, and unchanged data may be
overwritten by whatever is currently in Duo, if it is different.

=item delete()

Delete this phone from Duo.  After successful completion of this call, the
Net::Duo::Admin::Phone object should be considered read-only, since no
further changes to the object can be meaningfully sent to Duo.

=item json()

Convert the data stored in the object to JSON and return the results.  The
resulting JSON should match the JSON that one would get back from the Duo
web service when retrieving the same object (plus any changes made locally
to the object via set_*() methods).  This is primarily intended for
debugging dumps or for passing Duo objects to other systems via further
JSON APIs.

=item send_sms_passcodes()

Generate a new batch of SMS passcodes and send them to the phone in a
single SMS message.  The number of passcodes sent is a global setting on
the Duo account.

=back

=head1 INSTANCE DATA METHODS

Some fields have set_*() methods.  Those methods replace the value of the
field in its entirety with the new value passed in.  This change is only
made locally in the object until commit() is called.

=over 4

=item activated()

Whether the phone has been activated for Duo Mobile.

=item capabilities()

A list of phone capabilities, chosen from the following values:

=over 4

=item C<push>

The device is activated for Duo Push.

=item C<phone>

The device can receive phone calls.

=item C<sms>

The device can receive batches of SMS passcodes.

=back

=item extension()

=item set_extension(EXTENSION)

The extension for this phone, if any.

=item name()

=item set_name(NAME)

The name of this phone.

=item number()

=item set_number(NUMBER)

The number for this phone, without any extension.

=item phone_id()

The unique ID of this phone as generated by Duo on phone creation.

=item platform()

=item set_platform(PLATFORM)

The platform of phone for Duo Mobile, or C<unknown> for a generic phone
type.  For the list of valid values, see the Duo Admin API documentation.

=item postdelay()

=item set_postdelay(POSTDELAY)

The time (in seconds) to wait after the extension is dialed and before the
speaking the prompt.

=item predelay()

=item set_predelay(PREDELAY)

The time (in seconds) to wait after the number picks up and before dialing
the extension.

=item sms_passcodes_sent()

Whether SMS passcodes have been sent to this phone.

=item type()

=item set_type(TYPE)

The type of phone, chosen from C<unknown>, C<mobile>, or C<landline>.

=item users()

The users associated with this phone as a list of Net::Duo::Admin::User
objects.

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

L<Duo Admin API for phones|https://www.duosecurity.com/docs/adminapi#phones>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<http://www.eyrie.org/~eagle/software/net-duo/>.

=cut
