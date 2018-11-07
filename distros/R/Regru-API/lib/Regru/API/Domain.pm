package Regru::API::Domain;

# ABSTRACT: REG.API v2 domain names management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.049'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'domain' },
);

sub available_methods {[qw(
    nop
    get_prices
    get_suggest
    get_premium
    get_deleted
    check
    create
    transfer
    get_rereg_data
    set_rereg_bids
    get_user_rereg_bids
    get_docs_upload_uri
    update_contacts
    update_private_person_flag
    register_ns
    delete_ns
    get_nss
    update_nss
    delegate
    undelegate
    transfer_to_another_account
    look_at_entering_list
    accept_or_refuse_entering_list
    cancel_transfer
    request_to_transfer
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Domain

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Domain - REG.API v2 domain names management

=head1 VERSION

version 0.049

=head1 DESCRIPTION

REG.API domain names management methods such as applying registration, initiating transfer to REG.RU, update administrative
contacts, placing bids on freeing domain names, retrive/update DNS servers for domain and many others.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<domain>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes. Scope: B<everyone>. Typical usage:

    $resp = $client->domain->nop(
        dname => 'sonic-screwdriver.com',
    );

Returns success response.

More info at L<Domain management: nop|https://www.reg.com/support/help/api2#domain_nop>.

=head2 get_prices

Get prices for domain registration/renewal in all available zones. Scope: B<everyone>. Typical usage:

    $resp = $client->domain->get_prices;

    # or
    $resp = $client->domain->get_prices(
        currency => 'USD',
    );

Additional options might be passed to this method. Returns a list available zones and cost of domain registration/renewal
onto the minimal required term.

More info at L<Domain management: get_prices|https://www.reg.com/support/help/api2#domain_get_prices>.

=head2 get_suggest

Gets the domain names suggestions for given word or two (as additional parameter). Scope: B<partners>. Typical usage:

    $resp = $client->domain->get_suggest(
        word => 'teselecta',
        tlds => 'ru',
        tlds => 'com',
    );

Returns a list of alternatives and its availability in given zones. Result set is limited to I<100> items.

More info at L<Domain management: get_suggest|https://www.reg.com/support/help/api2#domain_get_suggest>.

=head2 get_premium

Gets a list of the premium domains available for registration. Scope: B<partners>. Typical usage:

    $resp = $client->domain->get_premium(
        tld     => 'ru',     # default zone
        tld     => 'orgcyr', # IDN @ .ORG
        limit   => 10,
    );

Answer contains a list each element of it contains premium domain name and its price.

More info at L<Domain management: get_premium|https://www.reg.com/support/help/api2#domain_get_premium>.

=head2 get_deleted

Gets a list of freeing domain names in zones C<.ru>, C<.su> and C<.рф>. This one similar to the
L<Deleted Domains|https://www.reg.com/domain/new/freeing_domains> page. Scope: B<partners>. Typical usage:

    $resp = $client->domain->get_deleted(
        tlds            => 'ru',            # look up .ru
        tlds            => 'su',            # look up .su
        deleted_from    => '2013-10-01',
        deleted_to      => '2013-11-01',
        min_pr          => 2,               # Google PR
        min_cy          => 1,               # Yandex CY
    );

Answer will contains a field C<domains> with a list of domain names that satisfied by request criteria. Also each element
will includes domain status, first registration date, freeing date and values of ranks (Google PR and Yandex CY).
Maximum returned elements in list equals to 50000.

More info at L<Domain management: get_deleted|https://www.reg.com/support/help/api2#domain_get_deleted>.

=head2 check

Use this method to check availability of a domain name for registration. Scope: B<partners>. Typical usage:

    $resp = $client->domain->check(
        domain_name => 'trenzalore.net',
    );

    # or
    $resp = $client->domain->check(
        domains => [
            { dname => 'apalapucia.com' },
            { dname => 'gallifrey.ru' },
        ],
    );

Response answer contains C<domains> field with list of hashes providing information about domain names and their
availability or error code.

More info at L<Domain management: check|https://www.reg.com/support/help/api2#domain_check>.

=head2 create

Apply for domain name registration. Scope: B<clients>. Typical usage:

    $resp = $client->domain->create(
        domain_name => 'messaline.ru',
        contacts => {
            # set of contact fields goes here (depends on zone)
            ...
        },
        nss => {
            ns0     => 'ns1.messaline.ru',
            ns0ip   => '172.16.10.1',       # The glue record for the name server at the same domain
            ns1     => 'ns2.messaline.com',
        },
    );

Successful response will contains a list of domains and billing information.

More info at L<Domain management: create|https://www.reg.com/support/help/api2#domain_create>.

=head2 transfer

Apply for a transfer of a domain name from foreign registrar. Scope: B<clients>. Typical usage:

    $resp = $client->domain->transfer(
        authinfo    => 'f8gL-rGi/*8_VB',
        domain_name => 'midnight.net',
    );

This method has request fields similar to L<#create> method call. For the most part of the international zones such as
C<.com>, C<.net>, C<.org> should be provided transfer key by specifying parameter authinfo.

More info at L<Domain management: transfer|https://www.reg.com/support/help/api2#domain_transfer>.

=head2 get_rereg_data

Gets a list of freeing domain names and their details. Scope: B<partners>. Typical usage:

    $resp = $client->domain->get_rereg_data(
        min_pr      => 2,
        max_chars   => 5,
        sort        => 'price',
    );

Returns a domain names list for the given parameters.

More info at L<Domain management: get_rereg_data|https://www.reg.com/support/help/api2#domain_get_rereg_data>.

=head2 set_rereg_bids

Places a bid or bids for the freeing domain names. Scope: B<clients>. Typical usage:

    $resp = $client->domain->set_rereg_bids(
        contacts => {
            # similar to apply domain name registration
            ...
        },
        nss => {
            # this one too
            ...
        },
        domains => [
            { dname => 'pyrovilia.su', price => 400 },
            { dname => 'saturnyne.ru', price => 225 },
        ],
    );

Answer will be contains a list of domain names and their bid status. Additionally a payment status for the placed
bids will be returned.

More info at L<Domain management: set_rereg_bids|https://www.reg.com/support/help/api2#domain_set_rereg_bids>.

=head2 get_user_rereg_bids

Gets the bids placed on. Scope: B<clients>. Typical usage:

    $resp = $client->domain->get_user_rereg_bids;

Returns a list of a domain names for which user has placed bids on.

More info at L<Domain management: get_user_rereg_bids|https://www.reg.com/support/help/api2#domain_get_user_rereg_bids>.

=head2 get_docs_upload_uri

Gets a link for uploading registrant identification documents (only for B<.RU>, B<.SU> and B<.РФ> zones).
Scope: B<clients>. Typical usage:

    $resp = $client->domain->get_docs_upload_uri(
        dname => 'test.ru',
    );

Answer will be contains an url that should be used to upload documents.

More info at L<Domain management: get_docs_upload_uri|https://www.reg.com/support/help/api2#domain_get_docs_upload_uri>.

=head2 update_contacts

Make changes of the domain name contact data. Scope: B<clients>. Typical usage:

    $resp = $client->domain->update_contacts(
        domains => [
            { dname => 'griffoth.com' },
            { dname => 'jahoo.net' },
        ],
        contacts => {
            # XXX keys of the contacts data may differ from zone to zone

            # Domain name Owner contact data (o_*)
            o_company       => 'Private person',
            o_first_name    => 'Madame',
            o_last_name     => 'Kovarian',
            o_email         => 'patch-lady@kovarian.com',
            ...
            o_country_code  => 'US',
            ...

            # Domain name Administrative contact data (a_*)
            ...

            # Domain name Technical contact data (t_*)
            ...

            # Domain name Billing contact data (b_*)
            ...

            # Additional data
            private_person_flag => 1,
        },
    );

Answer will contains a domains field with list of domain names each item consist of dname, service_id and/or error_code
parameters.

More info at L<Domain management: update_contacts|https://www.reg.com/support/help/api2#domain_update_contacts>.

=head2 update_private_person_flag

Change settings of the Private Person and Total Private Person flags (show/hide contact data in WHOIS answers).
Scope: B<clients>. Typical usage:

    $resp = $client->domain->update_private_person_flag(
        domains => [
            { dname => 'griffoth.com' },
            { dname => 'jahoo.net' },
        ],
        private_person_flag => 1, # or 0, to expose contacts data
    );

Answer will contains a domains field with list of domain names and operation status.

More info at L<Domain management: update_private_person_flag|https://www.reg.com/support/help/api2#domain_update_private_person_flag>.

=head2 register_ns

Domain name server registration in the NSI registry ((for internatonal domains only). Scope: B<clients>. Typical usage:

    $resp = $client->domain->register_ns(
        domain_name => 'griffoth.com',
        ns0         => 'ns1.griffoth.com',
        ns0ip       => '172.20.21.1',
    );

Answer will contains a C<resp> field with a detailed response from the NSI registry, typically a hash. Available
in sussessful resposnses only.

More info at L<Domain management: register_ns|https://www.reg.com/support/help/api2#domain_register_ns>.

=head2 delete_ns

Deletion of a domain name server from the NSI registry (for international domains only). Scope: B<clients>. Typical usage:

    $resp = $client->domain->delete_ns(
        domain_name => 'griffoth.com',
        ns0         => 'ns1.griffoth.com',
        ns0ip       => '172.20.21.1',
    );

Answer will contains a C<resp> field with a detailed response from the NSI registry, typically a hash. Available
in sussessful resposnses only.

More info at L<Domain management: delete_ns|https://www.reg.com/support/help/api2#domain_delete_ns>.

=head2 get_nss

Retrive a domane name servers for domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->domain->get_nss(
        domain_name => 'griffoth.com',
    );

    # or
    $resp = $client->domain->get_nss(
        domains => [
            { dname => 'griffoth.com' },
            { dname => 'jahoo.net' },
        ],
    );

Answer will contains a list of domain names and nameservers (and ip addresses if any) and/or error codes.

More info at L<Domain management: get_nss|https://www.reg.com/support/help/api2#domain_get_nss>.

=head2 update_nss

Change DNS servers of the domain name. Also this function enables/disables domain name delegation (for partners only).
Scope: B<clients>/B<partners>. Typical usage:

    $resp = $client->domain->update_nss(
        domains => [
            { dname => 'koorharn.ru' },
            { dname => 'stormcage.ru' },
        ],
        nss => {
            ns0 => 'ns1.barcelona.net',
            ns1 => 'ns2.barcelona.org',
            ns3 => 'ns3.barcelona.com',
        },
    );

Answer will contains a list of domain names with the parameters dname, service_id and/or a service identification error_code.

More info at L<Domain management: update_nss|https://www.reg.com/support/help/api2#domain_update_nss>.

=head2 delegate

Turn on a domain name delegation flag. Scope: B<partners>. Typical usage:

    $resp = $client->domain->delegate(
        domains => [
            { dname => 'koorharn.ru' },
            { dname => 'stormcage.ru' },
        ],
    );

Answer will contains a list of domain names with the parameters dname, service_id and/or a service identification error_code.

More info at L<Domain management: delegate|https://www.reg.com/support/help/api2#domain_delegate>.

=head2 undelegate

Turn off a domain name delegation flag. Scope: B<partners>. Typical usage:

    $resp = $client->domain->undelegate(
        domains => [
            { dname => 'koorharn.ru' },
            { dname => 'stormcage.ru' },
        ],
    );

Answer will contains a list of domain names with the parameters dname, service_id and/or a service identification error_code.

More info at L<Domain management: undelegate|https://www.reg.com/support/help/api2#domain_undelegate>.

=head2 transfer_to_another_account

Transfer a domain name to another account within REG.RU. Scope: B<partners>. Typical usage:

    $resp = $client->domain->transfer_to_another_account(
        domain_name   => 'stormcage.ru',
        new_user_name => 'river-song',
    );

Answer will contains a list of domain names transferred to another account. In case of success, the field
C<result> there will be the B<request_is_sent> value for each domain name in the C<result> field, otherwise an
error code will be returned.

More info at L<Domain management: transfer_to_another_account|https://www.reg.com/support/help/api2#domain_transfer_to_another_account>.

=head2 look_at_entering_list

Show the list of domain names transferred to current account. Scope: B<partners>. Typical usage:

    $resp = $client->domain->look_at_entering_list;

Answer will contains a list of messages about domain names transfer. Each message contains an ID and the name of
the transferred domain. Upon each transfer domain names are assigned to new user ID.

More info at L<Domain management: look_at_entering_list|https://www.reg.com/support/help/api2#domain_look_at_entering_list>.

=head2 accept_or_refuse_entering_list

Accept or decline domain names transferred to current account. Scope: B<partners>. Typical usage:

    $resp = $client->domain->accept_or_refuse_entering_list(
        dname       => 'stormcage.ru',
        id          => 895901,
        action_type => 'accept', # accept/refuse; yes/no; 1/0
    );

Answer will contains a list of domain names with result for each domain name.

More info at L<Domain management: accept_or_refuse_entering_list|https://www.reg.com/support/help/api2#domain_accept_or_refuse_entering_list>.

=head2 cancel_transfer

Shut down transfers of the domain names. Scope: B<partners>. Typical usage:

    $resp = $client->domain->cancel_transfer(
        domains => [
            { dname => 'koorharn.ru' },
            { dname => 'stormcage.ru' },
        ],
    );

Answer will contains a list of domain names with result for each domain name.

More info at L<Domain management: cancel_transfer|https://www.reg.com/support/help/api2#domain_cancel_transfer>.

=head2 request_to_transfer

Send request to transfer a domain name to foreign registrar. Scope: B<partners>. Typical usage:

    $resp = $client->domain->cancel_transfer(
        domain_name => 'felspoon.com',
    );

Answer will contains a list of domain names with result for each domain name.

More info at L<Domain management: request_to_transfer|https://www.reg.com/support/help/api2#domain_request_to_transfer>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<REG.API Domain management|https://www.reg.com/support/help/api2#domain_functions>

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
