# Perl interface for the Duo Admin API.
#
# This Perl module collection provides a Perl interface to the Admin API
# integration for the Duo multifactor authentication service
# (https://www.duo.com/).  It differs from the Perl API sample code in that it
# wraps all the returned data structures in objects with method calls,
# abstracts some of the API details, and throws rich exceptions rather than
# requiring the caller deal with JSON data structures directly.
#
# SPDX-License-Identifier: MIT

package Net::Duo::Admin 1.02;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo);

use Net::Duo::Admin::Integration;
use Net::Duo::Admin::User;

##############################################################################
# Admin API methods
##############################################################################

# Retrieve all integrations associated with a Duo account.
#
# $self - The Net::Duo::Admin object
#
# Returns: List of Net::Duo::Admin::Integration objects
#  Throws: Net::Duo::Exception on failure
sub integrations {
    my ($self) = @_;

    # Make the Duo call and get the decoded result.
    my $result = $self->call_json_paged('GET', '/admin/v1/integrations');

    # Convert the returned integrations into Net::Duo::Admin::Integration
    # objects.
    my @integrations;
    for my $integration (@{$result}) {
        my $object = Net::Duo::Admin::Integration->new($self, $integration);
        push(@integrations, $object);
    }
    return @integrations;
}

# Retrieve logs of administrative actions.  At most 1000 entries are returned,
# so the caller may need to call this repeatedly with different mintime
# parameters to retrieve all of the logs.
#
# $self    - The Net::Duo::Admin object
# $mintime - Only return records with a timestamp after this (optional)
#
# Returns: A list of log entries, each of which is a hash reference with keys:
#            timestamp   - Time of event in seconds since epoch
#            username    - Admin username or API for changes via API
#            action      - The action taken
#            object      - The object on which the action was performed
#            description - The details of what was changed
#  Throws: Net::Duo::Exception on failure
sub logs_administrator {
    my ($self, $mintime) = @_;

    # Make the Duo call and get the decoded result.
    my $args   = defined($mintime) ? { mintime => $mintime } : {};
    my $uri    = '/admin/v1/logs/administrator';
    my $result = $self->call_json('GET', $uri, $args);

    # Return the result as a list.
    return @{$result};
}

# Retrieve authentication logs.  At most 1000 entries are returned, so the
# caller may need to call this repeatedly with different mintime parameters to
# retrieve all of the logs.
#
# $self    - The Net::Duo::Admin object
# $mintime - Only return records with a timestamp after this (optional)
#
# Returns: A list of log entries, each of which is a hash reference with keys:
#            timestamp   - Time of event in seconds since epoch
#            username    - The authenticating username
#            factor      - The authentication factor
#            result      - The result of the authentication
#            ip          - IP address from which the request originated
#            integration - Integration name attempting the authentication
#  Throws: Net::Duo::Exception on failure
sub logs_authentication {
    my ($self, $mintime) = @_;

    # Make the Duo call and get the decoded result.
    my $args   = defined($mintime) ? { mintime => $mintime } : {};
    my $uri    = '/admin/v1/logs/authentication';
    my $result = $self->call_json('GET', $uri, $args);

    # Return the result as a list.
    return @{$result};
}

# Retrieve telephony logs.  At most 1000 entries are returned, so the caller
# may need to call this repeatedly with different mintime parameters to
# retrieve all of the logs.
#
# $self    - The Net::Duo::Admin object
# $mintime - Only return records with a timestamp after this (optional)
#
# Returns: A list of log entries, each of which is a hash reference with keys:
#            timestamp - Time of event in seconds since epoch
#            context   - How this telephony event was initiated
#            type      - The event type
#            phone     - The phone number for this event
#            credits   - How many telephony credits this event cost
#  Throws: Net::Duo::Exception on failure
sub logs_telephony {
    my ($self, $mintime) = @_;

    # Make the Duo call and get the decoded result.
    my $args   = defined($mintime) ? { mintime => $mintime } : {};
    my $uri    = '/admin/v1/logs/telephony';
    my $result = $self->call_json('GET', $uri, $args);

    # Return the result as a list.
    return @{$result};
}

# Retrieve a single user by username.  An empty reply indicates that no user
# by that username exists.
#
# $self     - The Net::Duo::Admin object
# $username - Username whose record to retrieve
#
# Returns: A single Net::Duo::User object or undef
#  Throws: Net::Duo::Exception on failure
sub user {
    my ($self, $username) = @_;

    # Make the Duo call and get the decoded result.
    my $args   = { username => $username };
    my $result = $self->call_json('GET', '/admin/v1/users', $args);

    # Convert the returned user into a Net::Duo::Admin::User object.
    if (@{$result}) {
        return Net::Duo::Admin::User->new($self, $result->[0]);
    } else {
        return;
    }
}

# Retrieve all users associated with a Duo account.
#
# $self     - The Net::Duo::Admin object
# $username - Retrieve the record for only this user (optional)
#
# Returns: List of Net::Duo::User objects if no parameter is given
#          A single Net::Duo::User object if $username is given and found
#          undef if $username is given and not found
#  Throws: Net::Duo::Exception on failure
sub users {
    my ($self, $username) = @_;

    # Make the Duo call and get the decoded result.
    my $args   = $username ? { username => $username } : undef;
    my $result = $self->call_json_paged('GET', '/admin/v1/users', $args);

    # Convert the returned users into Net::Duo::Admin::User objects.
    my @users;
    for my $user (@{$result}) {
        push(@users, Net::Duo::Admin::User->new($self, $user));
    }
    return @users;
}

1;
__END__

=for stopwords
Allbery Auth MERCHANTABILITY NONINFRINGEMENT sublicense MINTIME
integrations ip

=head1 NAME

Net::Duo::Admin - Perl interface for the Duo Admin API

=head1 SYNOPSIS

    my $duo = Net::Duo::Admin->new({ key_file => '/path/to/keys.json' });
    my @users = $duo->users;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules HTTP::Request and HTTP::Response (part
of HTTP::Message), JSON, LWP (also known as libwww-perl), Perl6::Slurp,
Sub::Install, and URI::Escape (part of URI), all of which are available
from CPAN.

=head1 DESCRIPTION

Net::Duo::Admin is an implementation of the Duo Admin REST API for Perl.
Method calls correspond to endpoints in the REST API.  Its goal is to
provide a native, natural interface for all Duo operations in the API from
inside Perl, while abstracting away as many details of the API as can be
reasonably handled automatically.

Currently, only a tiny number of available methods are implemented.

For calls that return complex data structures, the return from the call
will generally be an object in the Net::Duo::Admin namespace.  These
objects all have methods matching the name of the field in the Duo API
documentation that returns that field value.  Where it makes sense, there
will also be a method with the same name but with C<set_> prepended that
changes that value.  No changes are made to the Duo record itself until
the commit() method is called on the object, which will make the
underlying Duo API call to update the data.

Some objects have associated lists of other objects.  For example, a user
has a list of phones and a list of tokens.  Wherever this pattern occurs,
new objects can be added to that list with a method starting with C<add_>
and removed with a method starting with C<remove_>.  These changes are
pushed to Duo immediately and do not wait for the next commit().

On failure, all methods throw a Net::Duo::Exception object.  This can be
interpolated into a string for a simple error message, or inspected with
method calls for more details.  This is also true of all methods in all
objects in the Net::Duo namespace.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new Net::Duo::Admin object, which is used for all subsequent
calls.  This constructor is inherited from Net::Duo.  See L<Net::Duo> for
documentation of the possible arguments.

=back

=head1 INSTANCE METHODS

=over 4

=item integrations()

Retrieves all the integrations currently present in this Duo account and
returns them as a list of Net::Duo::Admin::Integration objects.  Be aware
that this list may be quite long if the Duo account supports many
integrations, and the entire list is read into memory.

=item logs_administrator([MINTIME])

Returns a list of administrative actions.  Each member of this list will
be a reference to a hash with the following keys:

=over 4

=item timestamp

The time of the event in seconds since UNIX epoch.

=item username

The username of the administrator, or C<API> if the action was performed
via the Admin API.

=item action

The administrator action.  See the Duo Admin API documentation for a full
list of valid values.

=item object

An identifier for the object that was acted on.  What fields are used as
an identifier will vary by type of object.

=item description

The details of what was changed.

=back

At most 1,000 log entries will be returned.  If MINTIME is provided, only
records with a time stamp after MINTIME will be returned.  All records can
therefore be retrieved by calling this method repeatedly, first with no
MINTIME and then with MINTIME matching the timestamp of the last returned
record from the previous call.

=item logs_authentication([MINTIME])

Returns a list of authentication attempts.  Each member of the list will
be a reference to a hash with the following keys:

=over 4

=item timestamp

The time of the event in seconds since UNIX epoch.

=item username

The authenticating user's username.

=item factor

The authentication factor, chosen from C<phone call>, C<passcode>,
C<bypass code>, C<sms passcode>, C<sms refresh>, or C<duo push>.

=item result

The result of the authentication, chosen from C<success>, C<failure>,
C<error>, or C<fraud>.

=item ip

The IP address from which the authentication attempt originated.

=item integration

The name of the integration from which the authentication attempt
originated.

=back

At most 1,000 authentication log entries will be returned.  If MINTIME is
provided, only records with a time stamp after MINTIME will be returned.
All records can therefore be retrieved by calling this method repeatedly,
first with no MINTIME and then with MINTIME matching the timestamp of the
last returned record from the previous call.

=item logs_telephony([MINTIME])

Returns a list of telephony events.  Each member of this list will be a
reference to a hash with the following keys:

=over 4

=item timestamp

The time of the event in seconds since UNIX epoch.

=item context

How this telephony event was initiated.  This will be one of
C<administrator login>, C<authentication>, C<enrollment>, or C<verify>.

=item type

The event type.  One of C<sms> or C<phone>.

=item phone

The phone number that initiated this event.

=item credits

How many telephony credits this event cost.

=back

At most 1,000 log entries will be returned.  If MINTIME is provided, only
records with a time stamp after MINTIME will be returned.  All records can
therefore be retrieved by calling this method repeatedly, first with no
MINTIME and then with MINTIME matching the timestamp of the last returned
record from the previous call.

=item user(USERNAME)

Retrieves a single user by username and returns it as a
Net::Duo::Admin::User object if found.  If no user with that username
exists, returns undef, and does not throw an exception.

=item users()

Retrieves all the users currently present in this Duo account and returns
them as a list of Net::Duo::Admin::User objects.  Be aware that this list
may be quite long and consume a lot of resources for accounts with many
users.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Copyright 2019 Russ Allbery <rra@cpan.org>

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

L<Duo Auth API|https://www.duo.com/docs/authapi>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/net-duo/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
