#
# Copyright (c) 2019 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#
package OpenStack::Client::Auth;

use strict;
use warnings;

use OpenStack::Client ();

=encoding utf8

=head1 NAME

OpenStack::Client::Auth - OpenStack Keystone authentication and authorization

=head1 SYNOPSIS

    use OpenStack::Client::Auth ();

    my $auth = OpenStack::Client::Auth->new('http://openstack.foo.bar:5000/v2.0',
        'tenant'   => $ENV{'OS_TENANT_NAME'},
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'}
    );

    # or you can also use API v3
    $auth = OpenStack::Client::Auth->new(
        $ENV{OS_AUTH_URL},
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'},
        'version'  => 3,
        # provide a scope to get a catalog
        'scope' => {
            project => {
                name => $ENV{'OS_PROJECT_NAME'},
                domain => { id => 'default' },
            }
        }
    );

    my $glance = $auth->service('image',
        'region' => $ENV{'OS_REGION_NAME'}
    );

=head1 DESCRIPTION

C<OpenStack::Client::Auth> provides an interface for obtaining authorization
to access other OpenStack cloud services.

=head1 AUTHORIZING WITH KEYSTONE

=over

=item C<OpenStack::Client::Auth-E<gt>new(I<$endpoint>, I<%args>)>

Contact the OpenStack Keystone API at the address provided in I<$endpoint>, and
obtain an authorization token and set of endpoints for which the client is
allowed to access.  Credentials are specified in I<%args>; the following named
values are required:

=over

=item * B<tenant>

The OpenStack tenant (project) name

=item * B<username>

The OpenStack user name

=item * B<password>

The OpenStack password

=item * B<version>

The version of the Glance API to negotiate with.  Default is C<2.0>, but
C<3> is also accepted.

=item * B<scope>

When negotiating with an Identity v3 endpoint, the information provided here
is passed in the B<scope> property of the B<auth> portion of the request body
submitted to the endpoint.

=item * B<domain>

When negotiating with an Identity v3 endpoint, the name of the domain to
authenticate to.

=back

When successful, this method will return an object containing the following:

=over

=item * response

The full decoded JSON authorization response from Keystone

=item * services

A hash containing services the client has authorization to

=item * clients

An initially empty hash that would contain L<OpenStack::Client> objects obtained
for any requested OpenStack services

=back

=cut

sub new ($$%) {
    my ($class, $endpoint, %args) = @_;

    my %CLASSES = (
        '2.0' => 'OpenStack::Client::Auth::v2',
        '3'   => 'OpenStack::Client::Auth::v3'
    );

    unless (defined $endpoint) {
        die 'No OpenStack authentication endpoint provided';
    }

    $args{'version'} ||= '2.0';

    unless (defined $CLASSES{$args{'version'}}) {
        die "Unsupported Identity endpoint version $args{'version'}";
    }

    local $@;

    eval qq{
        use $CLASSES{$args{'version'}} ();
        1;
    } or die $@;

    return $CLASSES{$args{'version'}}->new($endpoint, %args);
}

=back

=head1 RETRIEVING RESPONSE

=over

=item C<$auth-E<gt>response()>

Return the full decoded response from the Keystone API.

=back

=head1 ACCESSING AUTHORIZATION DATA

=over

=item C<$auth-E<gt>access()>

Return the service access data stored in the current object.

=back

=head1 ACCESSING TOKEN DATA

=over

=item C<$auth-E<gt>token()>

Return the authorization token data stored in the current object.

=back

=head1 OBTAINING LIST OF SERVICES AUTHORIZED

=over

=item C<$auth-E<gt>services()>

Return a list of service types the OpenStack user is authorized to access.

=back

=head1 ACCESSING SERVICES AUTHORIZED

=over

=item C<$auth-E<gt>service(I<$type>, I<%opts>)>

Obtain a client to the OpenStack service I<$type>, where I<$type> is usually
one of:

=over

=item * B<compute>

=item * B<ec2>

=item * B<identity>

=item * B<image>

=item * B<network>

=item * B<volumev2>

=back

The following values may be specified in I<%opts> to help locate the most
appropriate endpoint for a given service:

=over

=item * B<uri>

When specified, use a specific URI to gain access to a named service endpoint.
This might be useful for non-production development or testing scenarios.

=item * B<id>

When specified, attempt to obtain a client for the very endpoint indicated by
that identifier.

=item * B<region>

When specified, attempt to obtain a client for the endpoint for that region.
When not specified, the a client for the first endpoint found for service
I<$type> is returned instead.

=item * B<endpoint>

When specified and set to one of 'public', 'internal' or 'admin', return a
client for the corresponding public, internal or admin endpoint.  The default
endpoint is the public endpoint.

=back

=back

=head1 AUTHOR

Written by Alexandra Hrefna Maheu <xan@cpanel.net>

=head1 COPYRIGHT

Copyright (c) 2019 cPanel, L.L.C.  Released under the terms of the MIT license.
See LICENSE for further details.

=cut

1;
