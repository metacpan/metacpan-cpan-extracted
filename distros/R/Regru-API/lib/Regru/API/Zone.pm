package Regru::API::Zone;

# ABSTRACT: REG.API v2 DNS resource records management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.052'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'zone' },
);

sub available_methods {[qw(
    nop
    add_alias
    add_aaaa
    add_caa
    add_cname
    add_mx
    add_ns
    add_txt
    add_srv
    add_spf
    get_resource_records
    update_records
    update_soa
    tune_forwarding
    clear_forwarding
    tune_parking
    clear_parking
    remove_record
    clear
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::Zone

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Zone - REG.API v2 DNS resource records management

=head1 VERSION

version 0.052

=head1 DESCRIPTION

REG.API DNS management methods such as create/remove resource records, enable/disable parking and forwarding features.

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<zone>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes to check the ability to manage DNS resource records. This feature is available for domain names
that hosted by REG.RU DNS servers only. Scope: B<clients>. Typical usage:

    $resp = $client->zone->nop(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of domain names which allows to manage resource records
or error otherwise.

More info at L<DNS management: nop|https://www.reg.com/support/help/api2#zone_nop>.

=head2 add_alias

Creates an A (IPv4 address) resource record for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_alias(
        subdomain   => 'gob',
        ipaddr      => '172.26.14.51',
        domains     => [
            { dname => 'bluth-company.com' },
        ],
    );

B<NOTE> Also allowed to pass subdomain as C<@> (at) - resource record will point to domain itself or
C<*> (asterisk) - catch-all resource record.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_alias|https://www.reg.com/support/help/api2#zone_add_alias>.

=head2 add_aaaa

Creates an AAAA (IPv6 address) resource record for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_aaaa(
        subdomain   => 'coffee',
        ipaddr      => '2001:0db8:11a3:09d7:1f34:8a2e:07a0:765d',
        domains     => [
            { dname => 'gobias-industries.net' },
        ],
    );

This one also supports a special names for subdomains. See note for L</add_alias>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_aaaa|https://www.reg.com/support/help/api2#zone_add_aaaa>.

=head2 add_caa

Creates a CAA (SSL certificate issue rule) resource record for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_caa(
        subdomain       => 'home',
        flags           => 128,
        tag             => 'issue',
        value           => 'commodo.com; id=321'
        domain_name     => 'gobias.co.uk',
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_caa|https://www.reg.com/support/help/api2#zone_add_caa>.

=head2 add_cname

Creates a CNAME (canonical name) resource record for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_cname(
        subdomain       => 'products',
        canonical_name  => 'coffee.gobias-industries.net',
        domain_name     => 'gobias.co.uk',
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_cname|https://www.reg.com/support/help/api2#zone_add_cname>.

=head2 add_mx

Creates a MX (mail exchange) resource record for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_mx(
        subdomain   => '@',
        priority    => 5,
        mail_server => 'mail.hot-cops.xxx',         # mail server host should have an A/AAAA record(s)
        domains     => [
            { dname => 'blue-man-group.org' },
            { dname => 'gobias-industri.es' },
            { dname => 'sudden-valley.travel' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_mx|https://www.reg.com/support/help/api2#zone_add_mx>.

=head2 add_ns

Creates a NS (name server) resource record which will delegate a subdomain onto the other name server. Scope: B<clients>.
Typical usage:

    $resp = $client->zone->add_ns(
        subdomain       => 'annyong',
        dns_server      => 'ns1.milford-school.ac.us',
        domain_name     => 'bluth-family.ru',
        record_number   => 1,   # just for relative arrangement of the NS records
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_ns|https://www.reg.com/support/help/api2#zone_add_ns>.

=head2 add_txt

Creates a TXT (text) resource record up to 512 characters in length. Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_txt(
        subdomain   => '@',
        domain_name => 'bluth-company.com',
        text        => 'v=spf1 include:_spf.google.com ~all',
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_txt|https://www.reg.com/support/help/api2#zone_add_txt>.

=head2 add_srv

Creates a SRV (service locator) resource record. Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_srv(
        domain_name => 'gobias-industri.es',
        service     => '_sip._tcp',
        priority    => 0,
        weight      => 5,
        port        => 5060,
        target      => 'phone.gobias.co.uk',        # target host should have an A/AAAA record(s)
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_srv|https://www.reg.com/support/help/api2#zone_add_srv>.

=head2 add_spf

Creates a SPF (sender policy framework) resource record up to 512 characters in length.
Scope: B<clients>. Typical usage:

    $resp = $client->zone->add_spf(
        subdomain   => '@',
        domain_name => 'stand-poor.net',
        text        => 'v=spf1 include:_spf.google.com ~all',
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: add_spf|https://www.reg.com/support/help/api2#zone_add_spf>.

=head2 get_resource_records

Retrieves all resource records for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->get_resource_records(
        domains => [
            { dname => 'gangie.tv' },
            { dname => 'wrench.tv' },
        ],
    );

Answer will contains a field C<domains> with a list of domains. For each domain will be shown a resource records set (as a
list), settings of the SOA resource record. If any error will occur this also will be reported.

More info at L<DNS management: get_resource_records|https://www.reg.com/support/help/api2#zone_get_resource_records>.

=head2 update_records

Takes a set of actions and manipulates the resource records in batch mode. Scope: B<partners>. Typical usage:

    $update = [
        { action => 'add_alias',     subdomain => '@',   ipaddr => '127.0.0.1' },
        { action => 'add_alias',     subdomain => 'www', ipaddr => '127.0.0.1' },
        { action => 'add_mx',        subdomain => '@',   priority => 5,  mail_server => 'mx.bluth-company.net' },
        { action => 'add_mx',        subdomain => '@',   priority => 10, mail_server => 'mx.bluth-family.com' },
        { action => 'remove_record', subdomain => 'maeby',  record_type => 'TXT' },
        { action => 'remove_record', subdomain => 'buster', record_type => 'A', content => '10.13.0.5' },
        { action => 'add_txt',       subdomain => 'maeby',  text => 'Marry Me!' },
    ];
    $resp = $client->zone->update_records(
        domain_name => 'bluth.com',
        action_list => $update,
    );

    # or more complex
    $update1 = [ # actions for 'gobias.com'
        { action => '..', ... },
        ...
    ];
    $update2 = [ # actions for 'gobias.net'
        { action => '..', ... },
        ...
    ];
    $resp = $client->zone->update_records(
        domains => [
            { dname => 'gobias.com', action_list => $update1 },
            { dname => 'gobias.net', action_list => $update2 },
        ],
    );

Action should one of allowed methods related to resource records: L</add_alias>, L</add_aaaa>, L</add_caa>, L</add_cname>, L</add_mx>,
L</add_ns>, L</add_txt>, L</add_srv> or L</remove_record>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names and actions or
error otherwise.

More info at L<DNS management: update_records|https://www.reg.com/support/help/api2#zone_update_records>.

=head2 update_soa

Changes a cache settings for the SOA (start of authority) resource record. Scope: B<clients>. Typical usage:

    $resp = $client->zone->update_soa(
        ttl         => '2h', # for the entire zone
        minimum_ttl => '1h', # for the NXDOMAIN answers
        domains     => [
            { dname => 'gobias.com' },
            { dname => 'gobias.net' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: update_soa|https://www.reg.com/support/help/api2#zone_update_soa>.

=head2 tune_forwarding

Enables a web forwarding feature for domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->tune_forwarding(
        domain_name => 'barrygood.biz',
    );

Prior to use this method ensure that desired domain name(s) has attached and configured correctly a C<srv_webfwd> service.
This can be done by using methods L<Regru::API::Domain/create> or L<Regru::API::Domain/update>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: tune_forwarding|https://www.reg.com/support/help/api2#zone_tune_forwarding>.

=head2 clear_forwarding

Disables a web forwarding feature for domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->clear_forwarding(
        domain_name => 'barrygood.biz',
    );

Prior to use this method ensure that desired domain name(s) has attached and configured correctly a C<srv_webfwd> service.
This can be done by using methods L<Regru::API::Domain/create> or L<Regru::API::Domain/update>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: clear_forwarding|https://www.reg.com/support/help/api2#zone_clear_forwarding>.

=head2 tune_parking

Enables a web parking feature for domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->tune_parking(
        domains => [
            { dname => 'barrygood.biz' },
        ],
    );

Prior to use this method ensure that desired domain name(s) has attached and configured correctly a C<srv_parking> service.
This can be done by using methods L<Regru::API::Domain/create> or L<Regru::API::Domain/update>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: tune_parking|https://www.reg.com/support/help/api2#zone_tune_parking>.

=head2 clear_parking

Disables a web parking feature for domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->clear_parking(
        domains => [
            { dname => 'barrygood.biz' },
        ],
    );

Prior to use this method ensure that desired domain name(s) has attached and configured correctly a C<srv_parking> service.
This can be done by using methods L<Regru::API::Domain/create> or L<Regru::API::Domain/update>.

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: clear_parking|https://www.reg.com/support/help/api2#zone_clear_parking>.

=head2 remove_record

Removes any resource record from domain name(s). Scope: B<clients>. Typical usage:

    $resp = $client->zone->remove_record(
        domains => [
            { dname => 'cia.com' },
        ],
        subdomain   => 'tobias',
        record_type => 'TXT',
        content     => 'Mr. F!',
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: remove_record|https://www.reg.com/support/help/api2#zone_remove_record>.

=head2 clear

B<Watch out! Handy way to get lost everything!>

Deletes ALL resource records. Scope: B<clients>. Typical usage:

    $resp = $client->zone->clear(
        domains => [
            { dname => 'scandalmakers.com' },
            { dname => 'weathers.net' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNS management: clear|https://www.reg.com/support/help/api2#zone_clear>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<Regru::API::Domain>

L<REG.API DNS management|https://www.reg.com/support/help/api2#zone_functions>

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
