package Regru::API::Service;

# ABSTRACT: REG.API v2 service management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.052'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'service' },
);

sub available_methods {[qw(
    nop
    get_prices
    get_servtype_details
    create
    delete
    get_info
    get_list
    get_folders
    get_details
    get_dedicated_server_list
    update
    renew
    get_bills
    set_autorenew_flag
    suspend
    resume
    get_depreciated_period
    upgrade
    partcontrol_grant
    partcontrol_revoke
    resend_mail
    refill
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Service

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Service - REG.API v2 service management

=head1 VERSION

version 0.052

=head1 DESCRIPTION

REG.API service management methods such as create/remove/suspend/resume services, get information, grant/revoke access to
a service to other users, retrieve list of invoices on service and many others.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<service>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<clients>. Typical usage:

    $resp = $client->service->nop(
        dname   => 'kavorka.lv',
    );

Answer will contains a field C<services> with a list of results for each involved to this operation services (domain names,
hosting plans, certificates, etc) or error otherwise.

More info at L<Service management: nop|https://www.reg.com/support/help/api2#service_nop>.

=head2 get_prices

Gets a service registration/renewal pricing. Scope: B<everyone>. Typical usage:

    $resp = $client->service->get_prices(
        currency => 'USD',      # default in RUR. also valid UAH and EUR
    );

Answer will contains a field C<prices> with a list of all available services, their names, types, billing term and price.

More info at L<Service management: get_prices|https://www.reg.com/support/help/api2#service_get_prices>.

=head2 get_servtype_details

Gets detailed information about service. Scope: B<clients>. Typical usage:

    $resp = $client->service->get_servtype_details(
        servtype    => 'srv_vps,srv_hosting_plesk',
    );

    $details = $resp->answer;

Answer will contains a list of all available plans and parameters for requested types of services, their names,
types, billing term and prices for registration and renewal.

More info at L<Service management: get_servtype_details|https://www.reg.com/support/help/api2#service_get_servtype_details>.

=head2 create

Orders a new service. Scope: B<clients>. Typical usage:

    $resp = $client->service->create(
        # common options
        domain_name => 'kramerica.com',
        forder_name => 'kramerica-industries',      # put newly created service to folder
        period      => 3,                           # for 3 months

        # service related options
        servtype    => 'srv_hosting_plesk',
        subtype     => 'Host-2-0311',               # service plan
        contype     => 'hosting_org',               # organization or hosting_pp for person
        email       => 'info@kramerica.com',
        country     => 'US',
        code        => '',                          # empty for non RU-redidents only
        org_r       => 'Limited Liability Company "Kramerica Industries"',
    );

    # or
    $csreq = <<CSR;
    -----BEGIN CERTIFICATE REQUEST-----
    ...
    TwGJ9/LuG771Ehq41X/IunqqZ9+lAObxqJ9XAwNAielSPdVhx4NrPjaIGdFhdPeL
    ...
    w9n2/G9Q8gcSGg2HG09fLyvjcFMC0cnASS26EAbfOmrcFhCp2cXddmeIlpc=
    -----END CERTIFICATE REQUEST-----
    CSR

    $resp = $client->service->create(
        # common options
        domain_name         => 'kramerica.com',
        forder_name         => 'kramerica-industries',      # put newly created service to folder
        period              => 2,                           # SSL sectificate for 2 years

        # service related options
        servtype            => 'srv_ssl_sertificate',
        subtype             => 'sslwebserver',              # Thawte SSL Web Server
        server_type         => 'apachessl',                 # server software
        csr_string          => $csreq,                      # certificate request as string
        approver_email      => 'webmaster@kramerica.com',   # email for confirmation

        # organization
        org_org_name        => 'Kramerica Industries',
        org_address         => '129 West 81st Street, apt. 5B',
        org_city            => 'New York',
        org_state           => 'NY',
        org_postal_code     => '10024',
        org_country         => 'US',
        org_phone           => '+1.212.5553455',

        # administrative contact
        admin_first_name    => 'Cosmo',
        admin_last_name     => 'Kramer',
        admin_title         => 'Mr.',
        # rest of required admin_* fields
        ...

        # billing contact
        billing_*           => ...,

        # technical contact
        tech_*              => ...,
    );

Successful answer will contains a newly created service and invoice indentifiers, description of order and total
amount of charges or error otherwise.

More info at L<Service management: create|https://www.reg.com/support/help/api2#service_create>.

=head2 delete

Refuses from using active service. Scope: B<clients>. Typical usage:

    $resp = $client->service->delete(
        domain_name => 'buck-naked.xxx',
        servtype    => 'srv_vps',
    );

Returns a success response or error if any.

More info at L<Service management: delete|https://www.reg.com/support/help/api2#service_delete>.

=head2 get_info

Obtains a detailed information about service(s) by domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->service->get_info(
        show_folders    => 1, # include folders
        domains         => [
            { dname => 'monks.com' },
            { dname => 'reggies.com' },
        ],
    );

Answer will contains a field C<services> with a list of services, their subtypes, states, dates of creation and
dates of expiration. Also a list of folders accociated with services might be included.

More info at L<Service management: get_info|https://www.reg.com/support/help/api2#service_get_info>.

=head2 get_list

Obtains an information about active service(s) by type. Scope: B<clients>. Typical usage:

    $resp = $client->service->get_list(
        servtype => 'srv_webfwd',
    );

In case of C<servtype> is not defined the full list of active services will be returned.

Answer will contains a field C<services> with a list of services, their subtypes, states, dates of creation and
dates of expiration.

More info at L<Service management: get_list|https://www.reg.com/support/help/api2#service_get_list>.

=head2 get_folders

Returns a list of folders associated with a service. Scope: B<clients>. Typical usage:

    $resp = $client->service->get_folders(
        service_id => 1744688,
    );

    # or
    $resp = $client->service->get_folders(
        domain_name => 'bob.sacamano.name',
    );

Answer will contains a field C<folders> with a list of folder associated with service or empty list if no those folders.

More info at L<Service management: get_folders|https://www.reg.com/support/help/api2#service_get_folders>.

=head2 get_details

Gets a detailed information about the services including contact data for domains, account settings for hosting services, etc.
Scope: B<clients>. Typical usage:

    $resp = $client->service->get_details(
        services => [
            { dname => 'bubble-boy.net' },
            { service_id => 5177993 },
        ],
    );

Answer will contains a field C<services> with a list of detailed information for each services or error otherwise.

More info at L<Service management: get_details|https://www.reg.com/support/help/api2#service_get_details>.

=head2 get_dedicated_server_list

Gets a dedicated servers' list avaliable for order. Scope: B<clients>. Typical usage:

    $resp = $client->service->get_dedicated_server_list;

Answer will contains a field C<server_list> with a list of dedicated configurations available for order.

More info at L<Service management: get_dedicated_server_list|https://www.reg.com/support/help/api2#service_get_dedicated_server_list>.

=head2 update

Updates service configuration. Scope: B<clients>. Typical usage:

    $resp = $client->service->update(
        domain_name => 'jambalaya.net',
        servtype    => 'srv_webfwd',    # web forwarding
        subtask     => 'addfwd',        # add rule
        fwd_type    => 'frames',        # framing content

        # http://jambalaya.net/this -> http://mulligatawny.com/that
        fwdfrom     => '/this',
        fwdto       => 'http://mulligatawny.com/that',
    );

This one is similar to method L</create>. Answer will contains a field C<descr> with a description of the order
or error otherwise.

More info at L<Service management: update|https://www.reg.com/support/help/api2#service_update>.

=head2 renew

Renewals the service(s) (domain name, hosting, SSL certificate, etc). Scope: B<clients>. Typical usage:

    $resp = $client->service->renew(
        service_id  => 2674890,
        period      => 2,   # service's billing term
    );

    # or
    $resp = $client->service->renew(
        period  => 3,   # 3 years (for domain names)
        domains => [
            { dname => 'schmoopie.com' },
            { dname => 'schmoopie.net' },
        ],
    );

Answer will contains a set of fields like renewal period, invoice identifier, currency and amount of charges,.. for each of
services or error otherwise.

More info at L<Service management: renew|https://www.reg.com/support/help/api2#service_renew>.

=head2 get_bills

Gets a list of invoices associated with service(s). Scope: B<partners>. Typical usage:

    $resp = $client->service->get_bills(
        domains => [
            { dname => 'giddyup.com' },
        ],
    );

Answer will contains a field C<services> with a list of services, their types, id and list of invoices (field C<bills>)
or error otherwise.

More info at L<Service management: get_bills|https://www.reg.com/support/help/api2#service_get_bills>.

=head2 set_autorenew_flag

Manages automatic service renewals. Scope: B<clients>. Typical usage:

    $resp = $client->service->set_autorenew_flag(
        service_id  => 86478,
        flag_value  => 1,       # 1/0 - enable/disable autorenew feature
    );

Returns just a successful/error response.

More info at L<Service management: set_autorenew_flag|https://www.reg.com/support/help/api2#service_set_autorenew_flag>.

=head2 suspend

Suspends service usage. Scope: B<clients>. Typical usage:

    $resp = $client->service->suspend(
        domain_name => 'festivus.org',
    );

For domain names means a suspending delegation of the. Returns just a successful/error response.

More info at L<Service management: suspend|https://www.reg.com/support/help/api2#service_suspend>.

=head2 resume

Resumes service usage. Scope: B<clients>. Typical usage:

    $resp = $client->service->resume(
        domain_name => 'festivus.org',
    );

For domain names means a resuming delegation of the. Returns just a successful/error response.

More info at L<Service management: resume|https://www.reg.com/support/help/api2#service_resume>.

=head2 get_depreciated_period

Gets the number of billing terms till the service expiration date. Scope: B<clients>. Typical usage:

    $resp = $client->service->get_depreciated_period(
        domain_name => 'kavorka.net',
        servtype    => 'srv_hosting_ispmgr',
    );

Answer will contains a field C<depreciated_period> with a number of terms or error otherwise.

More info at L<Service management: get_depreciated_period|https://www.reg.com/support/help/api2#service_get_depreciated_period>.

=head2 upgrade

Upgrades service plans for services such as virtual hosting (C<srv_hosting_ispmgr>), VPS servers (C<srv_vps>) and additional
disk space (C<srv_disk_space>). Scope: B<clients>. Typical usage:

    $resp = $client->service->upgrade(
        domain_name => 'beef-a-reeno.com',
        servtype    => 'srv_vps',
        subtype     => 'VPS-4-1011',
        period      => 3,
    );

Answer will contains a withdrawal amount and a new service identifier or error otherwise.

More info at L<Service management: upgrade |https://www.reg.com/support/help/api2#service_upgrade>.

=head2 partcontrol_grant

Grants service management to other user. Scope: B<clients>. Typical usage:

    $resp = $client->service->partcontrol_grant(
        domain_name => 'mulva.org',
        newlogin    => 'Dolores',
    );

Answer will contains a field user login (C<newlogin>)to whom the right were granted and the service identifier C<service_id>
or error otherwise.

More info at L<Service management: partcontrol_grant|https://www.reg.com/support/help/api2#service_partcontrol_grant>.

=head2 partcontrol_revoke

Revokes service management from other user. Scope: B<clients>. Typical usage:

    $resp = $client->service->partcontrol_revoke(
        service_id => 2865903,
    );

Answer will contains a service identifier C<service_id> or error otherwise.

More info at L<Service management: partcontrol_revoke|https://www.reg.com/support/help/api2#service_partcontrol_revoke>.

=head2 resend_mail

Resends an email to user. Applicable only for hosting services and SSL certificates. Scope: B<clients>. Typical usage:

    $resp = $client->service->resend_mail(
        domain_name => 'jujyfruits.net',
        servtype    => 'srv_ssl_certificate',
        mailtype    => 'approver_email',        # or 'certificate_email'
    );

Answer will contains a domain name and service identifier or error otherwise.

More info at L<Service management: resend_mail|https://www.reg.com/support/help/api2#service_resend_mail>.

=head2 refill

For Jelastic service only. Tranfers specified amount from the user account to the Jelastic account,
associated with the specified service_id. Scope: B<clients>. Typical usage:

    $resp = $client->service->refill(
        service_id => 13726302,
        amount     => 2,
        currency   => 'USD'
    );

Answer will contain information about created invoice, such as invoice currency, charged sum, bill number.
More info at L<Service management: refill|https://www.reg.com/support/help/api2#service_refill>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Service management|https://www.reg.com/support/help/api2#service_functions>

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
