package Regru::API;

# ABSTRACT: Perl bindings for Reg.ru API v2

use strict;
use warnings;
use Moo;
use Carp ();
use Class::Load qw(try_load_class);
use namespace::autoclean;

our $VERSION = '0.051'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with 'Regru::API::Role::Client';

sub available_methods {[qw(
    nop
    reseller_nop
    get_user_id
    get_service_id
)]}

sub available_namespaces {[qw(
    user
    domain
    zone
    dnssec
    bill
    folder
    service
    hosting
    shop
)]}

sub _get_namespace_handler {
    my $self      = shift;
    my $namespace = shift;

    unless ( $self->{_handlers}->{$namespace} ) {
        my $ns = 'Regru::API::' . ( $namespace eq 'dnssec' ? uc($namespace) : ucfirst($namespace) );

        try_load_class $ns or Carp::croak 'Unable to load namespace: ' . $ns;

        my %params;

        foreach my $opt (qw(username password io_encoding lang debug)) {
            # predicate
            my $has = 'has_' . $opt;

            # pass option if it exists
            $params{$opt} = $self->$opt if $self->can($has) && $self->$has;
        }

        $self->{_handlers}->{$namespace} = $ns->new(@_, %params);
    }

    return $self->{_handlers}->{$namespace};
}

sub namespace_handlers {
    my $class = shift;

    my $meta = $class->meta;

    foreach my $namespace ( @{ $class->available_namespaces } ) {
        $namespace = lc $namespace;
        $namespace =~ s/\s/_/g;

        my $handler = sub {
            my ($self, @args) = @_;
            $self->_get_namespace_handler($namespace => @args);
        };

        $meta->add_method($namespace => $handler);
    }
}

__PACKAGE__->namespace_handlers;
__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API - Perl bindings for Reg.ru API v2

=head1 VERSION

version 0.051

=head1 SYNOPSIS

    my $client = Regru::API->new(
        username => 'test',
        password => 'test',
    );

    # trivial API request
    my $resp = $client->nop;

    if ($resp->is_success) {
        print $resp->get('user_id');
    }
    else {
        print "Error code: " . $resp->error_code . ", Error text: " . $resp->error_text;
    }

=head1 DESCRIPTION

Regru::API implements simplified access to the REG.API v2 provided by REG.RU LLC. This is a JSON-driven implementation.
Input/output request data will transforms from/to JSON transparently.

=head2 Rate limiting

Rate limiting in version 2 of the REG.API is considered on a per-user and per-ip basic. The REG.API methods have not
divided into groups by limit level. There is no difference between them. At the moment REG.API v2 allows to execute
C<1200> requests per-user and per-ip within C<1 hour> window. Both limits are acting at the same time.
If the limits has exceeded then REG.API sets the error code (depends on kind of) to C<IP_EXCEEDED_ALLOWED_CONNECTION_RATE> or
C<ACCOUNT_EXCEEDED_ALLOWED_CONNECTION_RATE> which might be checked via attribute L<error_code|Regru::API::Response/error_code>.

The following tips are there might helps to reduce the possibility of being rate limited:

=over

=item B<Caching>

Store all domain name or service related data locally and use the REG.API in cases you want to change some data in
the registry (e.g. contact data, DNS servers, etc).

=item B<Bulk requests>

Group similar items and execute a bulk API request. A bunch of methods supports sending request for the list of items at
the same time (e.g. multiple domain names). Check the details at
L<REG.API Service list identification parameters|https://www.reg.com/support/help/api2#common_service_list_identification_params>.

=item B<Journaling>

Keep the logs of interactions with REG.API (requests and responses). This will helps quickly resolve the issues
instead of sending additional requests to find out what's happened.

=back

=head2 Categories (namespaces)

REG.API methods are divided into categories (namespaces). When you wish to make an API request to some REG.API method,
that belongs to some namespace (category) you should get a namespace handler (defined as trivial client's method):

    # suppose we already have a client
    $client->user->nop;

    # or like this
    $zone = $client->zone;
    $zone->register_ns(...);

At the moment there are the following namespaces:

=over

=item B<root>

General purpose methods such as L</nop>, L</reseller_nop> etc which are described below. Actually is a virtual namespace
defined by client. No needs to get namespace handler. The methods of this C<namespace> are available as client's methods
directly.

    $client->nop;
    $client->reseller_nop;

See L</"REG.API METHODS">.

=item B<user>

User account management methods.

    # suppose we already have a client
    $client->user->nop;

See L<Regru::API::User> for details and
L<REG.API Account management functions|https://www.reg.com/support/help/api2#user_functions>.

=item B<domain>

Domain names management methods.

    # suppose we already have a client
    $client->domain->get_nss(
        domain_name => 'gallifrey.ru',
    );

See L<Regru::API::Domain> for details and
L<REG.API Domain management functions|https://www.reg.com/support/help/api2#domain_functions>.

=item B<zone>

DNS resource records management methods.

    # suppose we already have a client
    $client->zone->clear(
        domain_name => 'pyrovilia.net',
    );

See L<Regru::API::Zone> for details and
L<REG.API DNS management functions|https://www.reg.com/support/help/api2#zone_functions>.

=item B<dnssec>

DNSSEC management methods.

    # suppose we already have a client
    $client->dnssec->enable(
        domain_name => 'tvilgo.com',
    );

See L<Regru::API::DNSSEC> for details and
L<REG.API DNSSEC management functions|https://www.reg.com/support/help/api2#dnssec_functions>.

=item B<service>

Service management methods.

    # suppose we already have a client
    $client->service->delete(
        domain_name => 'sontar.com',
        servtype    => 'srv_hosting_plesk',
    );

See L<Regru::API::Service> for details and
L<REG.API Service management functions|https://www.reg.com/support/help/api2#service_functions>.

=item B<folder>

User folders management methods.

    # suppose we already have a client
    $client->folder->create(
        folder_name => 'UNIT',
    );

See L<Regru::API::Folder> for details and
L<REG.API Folder management functions|https://www.reg.com/support/help/api2#folder_functions>.

=item B<bill>

Invoice management methods.

    # suppose we already have a client
    $client->bill->get_not_payed(
        limit => 10,
    );

See L<Regru::API::Bill> for details and
L<REG.API Invoice management functions|https://www.reg.com/support/help/api2#bill_functions>.

=item B<hosting>

Hosting management methods.

    # suppose we already have a client
    $client->hosting->set_jelastic_refill_url(
        url => 'http://mysite.com?service_id=<service_id>&email=<email>'
    );

See L<Regru::API::Hosting> for details and
L<REG.API Hosting management functions|https://www.reg.com/support/help/api2#hosting_functions>.

=item B<shop>

Domain shop management methods.

    # suppose we already have a client
    $client->shop->get_info();

See L<Regru::API::Shop> for details and
L<REG.API Domain shop management functions|https://www.reg.com/support/help/api2#shop_functions>.

=back

=head2 Methods accessibility

All REG.API methods can be divided into categories of accessibility. On manual pages of this distibution accessibility
marked by C<scope> tag. At the moment the following categories of accessibility present:

=over

=item B<everyone>

All methods tagged by this one are accessible to all users. Those methods does not require authentication before call.

=item B<clients>

This tag indicates the methods which accessible only for users registered on L<reg.com|https://www.reg.com> website.
Strongly required an authenticated API request.

=item B<partners>

Group of methods which accessible only for partners (resellers) of the REG.RU LLC. Actually, partners (resellers)
able to execute all methods of the REG.API without any restrictions.

=back

=head2 Request parameters

Each API request should contains a set of parameters. There are the following parameters:

=over

=item B<authentication parameters>

These parameters are mandatory for the each method that requires authentication. This group of parameters includes
C<username> and C<password>. Both parameters should be passed to the L<constructor|/new> and their will be added
to API request.

=item B<management parameters>

This group include parameters defines input/output formats, encodings and language prefecence. Some parameters are fixed to
certains values, some might be set via passing values to the L<constructor|/new>: see C<io_encoding> and C<lang> options.

=item B<service identification parameters>

The group of parameters with aims to point to the particular service or group of services such as domain names,
folders, etc. Should be passed to an API request together with C<method specific parameters>.

More info at
L<REG.API Service identification parameters|https://www.reg.com/support/help/api2#common_service_identification_params>

=item B<method specific parameters>

Parameters applicable to a particular API method. Very wide group. Strongly recommended to consult with REG.API documentation
for each method before perform an API request to it. The distribution's manual pages includes links to documentation
for each API method call. The main source for the method specific parameters available at
L<REG.API General description of functions|https://www.reg.com/support/help/api2#common_functions_description>.

=back

=head2 Response parameters

Response parameters of the API request automatically handles by L<Regru::API::Response> module. There is no reasons to
do some addtional work on them. Each response may contains the following set of fileds:

=over

=item B<result>

The result of API request. Either C<success> or C<error>. Can be accessed via attribute
L<is_success|Regru::API::Response/is_success> in boolean context.

=item B<answer>

The answer of API method call. May appear only when result of API request was successful. Can be accessed via attribute
L<answer|Regru::API::Response/answer>. Default value is C<{}> (empty HashRef). Gets assigned a default value if
result of API request was finished with error.

=item B<error_code>

The error code of API method call. May appear only when result of API request finished with error. Can be accessed via
attribute L<error_code|Regru::API::Response/error_code>.
See details at L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>.

=item B<error_text>

The short description of error. The language depends on option lang L</new> passed to constructor. May appear only when result
of API request finished with error. Can be accessed via attribute L<error_text|Regru::API::Response/error_text>.
See details at L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>.

=item B<error_params>

Additional parameters included to the error. May appear only when result of API request finished with error. Can be accessed
via attribute L<error_params|Regru::API::Response/error_params>.

=back

=head2 Access to REG.API in test mode

REG.RU LLC provides an access to REG.API in test mode. For this, might be used a test account with C<username> and C<password>
equals to B<test>.

    my $client = Regru::API->new(username => 'test', password => 'test');
    # we're in test mode now
    $client->domain->get_prices;

In the test mode REG.API engine (at server-side) handles API request: ensures necessary checks of input parameters,
produces response but actually does not perform any real actions/changes.

Also, for debugging purposes REG.API provides a special set of methods allows to ensure the remote system for availability
without workload at minimal response time. Each namespace has method called B<nop> for that.

=head1 METHODS

=head2 new

Creates a client instance to interract with REG.API.

    my $client = Regru::API->new(
        username => 'Rassilon',
        password => 'You die with me, Doctor!'
    );

    my $resp = $client->user->get_balance;

    print $resp->get('prepay') if $resp->is_success;

    # another cool code...

Available options:

=over

=item B<username>

Account name of the user to access to L<reg.com|https://www.reg.com> website. Required. Should be passed at instance
create time. Although it might be changed at runtime.

    my $client = Regru::API->new(username => 'Cyberman', password => 'Exterminate!');
    ...
    # at runtime
    $client->username('Dalek');

=item B<password>

Account password of the user to access to L<reg.com|https://www.reg.com> website or an alternative password for API
defined at L<Reseller settings|https://www.reg.com/reseller/details> page. Required. Should be passed at instance create time.
Although it might be changed at runtime.

    my $client = Regru::API->new(username => 'Master', password => 'Doctor');
    ...
    # at runtime
    $client->password('The-Master.');

=item B<io_encoding>

Defines encoding that will be used for data exchange between the Service and the Client. At the moment REG.API v2
supports the following encodings: C<utf8>, C<cp1251>, C<koi8-r>, C<koi8-u>, C<cp866>. Optional. Default value is B<utf8>.

    my $client = Regru::API->new(..., io_encoding => 'cp1251');
    ...
    # or at runtime
    $client->io_encoding('cp1251');

    my $resp = $client->user->create(
        user_login      => 'othertest',
        user_password   => '111',
        user_email      => 'test@test.ru',
        user_first_name => $cp1251_encoded_name
    );

=item B<lang>

Defines the language which will be used in error messages. At the moment REG.API v2 supports the following languages:
C<en> (English), C<ru> (Russian) and C<th> (Thai). Optional. Default value is B<en>.

    my $client = Regru::API->new(..., lang => 'ru');
    ...
    # or at runtime
    $client->lang('ru');

    $client->username('bogus-user');
    print $client->nop->error_text; # -> "Ошибка аутентификации по паролю"

=item B<debug>

A few messages will be printed to STDERR. Default value is B<0> (suppressed debug activity).

    my $client = Regru::API->new(..., debug => 1);
    ...
    # or at runtime
    $client->debug(1);

=back

=head2 user

Returns a handler to access to REG.API user account management methods. See L<Regru::API::User>.

=head2 domain

Returns a handler to access to REG.API domain name management methods. See L<Regru::API::Domain>.

=head2 zone

Returns a handler to access to REG.API DNS resource records management methods. See L<Regru::API::Zone>.

=head2 dnssec

Returns a handler to access to REG.API DNSSEC management methods. See L<Regru::API::DNSSEC>.

=head2 service

Returns a handler to access to REG.API service management methods. See L<Regru::API::Service>.

=head2 folder

Returns a handler to access to REG.API folder management methods. See L<Regru::API::Folder>.

=head2 bill

Returns a handler to access to REG.API invoice management methods. See L<Regru::API::Bill>.

=head2 hosting

Returns a handler to access to REG.API hosting management methods. See L<Regru::API::Hosting>.

=head2 shop

Returns a handler to access to REG.API domain shop management methods. See L<Regru::API::Shop>.

=head2 namespace_handlers

Creates shortcuts to REG.API categories (namespaces). Used internally.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<everyone>. Typical usage:

    $resp = $client->nop;

Answer will contains an user_id and login fields.

More info at L<Common functions: nop|https://www.reg.com/support/help/api2#common_nop>.

=head2 reseller_nop

Similar to previous one but only for partners. Scope: B<partners>. Typical usage:

    $resp = $client->reseller_nop;

Answer will contains an user_id and login fields.

More info at L<Common functions: nop|https://www.reg.com/support/help/api2#common_reseller_nop>.

=head2 get_user_id

Get the identifier of the current user. Scope: B<clients>. Typical usage:

    $resp = $client->get_user_id;

Answer will contains an user_id field.

More info at L<Common functions: nop|https://www.reg.com/support/help/api2#common_get_user_id>.

=head2 get_service_id

Get service or domain name identifier by its name. Scope: B<clients>. Typical usage:

    $resp = $client->get_service_id(
        domain_name => 'teselecta.ru',
    );

Answer will contains a service_id field or error code if requested domain name/service not found.

More info at L<Common functions: nop|https://www.reg.com/support/help/api2#common_get_service_id>.

=head1 SEE ALSO

L<Regru::API::Bill>

L<Regru::API::Domain>

L<Regru::API::Folder>

L<Regru::API::Service>

L<Regru::API::User>

L<Regru::API::Zone>

L<Regru::API::Hosting>

L<Regru::API::Shop>

L<Regru::API::Response>

L<REG.API Common functions|https://www.reg.com/support/help/api2#common_functions>

L<REG.API Common error codes|https://www.reg.com/support/help/api2#common_errors>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
