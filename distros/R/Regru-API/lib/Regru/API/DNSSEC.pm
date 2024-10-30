package Regru::API::DNSSEC;

# ABSTRACT: REG.API v2 DNSSEC management

use strict;
use warnings;
use Moo;
use namespace::autoclean;

our $VERSION = '0.053'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

with 'Regru::API::Role::Client';

has '+namespace' => (
    default => sub { 'dnssec' },
);

sub available_methods {[qw(
    nop
    get_status
    enable
    disable
    renew_ksk
    renew_zsk
    get_records
    add_keys
)]}

__PACKAGE__->namespace_methods;
__PACKAGE__->meta->make_immutable;

1; # End of Regru::API::DNSSEC

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::DNSSEC - REG.API v2 DNSSEC management

=head1 VERSION

version 0.053

=head1 DESCRIPTION

REG.API DNSSEC management methods

=head1 ATTRIBUTES

=head2 namespace

Always returns the name of category: C<dnssec>. For internal uses only.

=head1 REG.API METHODS

=head2 nop

For testing purposes to check the ability to manage DNSSEC of domains. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->nop(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of domain names which allows to manage DNSSEC
or error otherwise.

More info at L<DNSSEC management: nop|https://www.reg.com/support/help/api2#dnssec_nop>.

=head2 get_status

Gets DNSSEC status for domain(s). Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->get_status(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names (or
error otherwise) and subfield C<status> with one value of: enabled, disabled, updating.

More info at L<DNSSEC management: get_status|https://www.reg.com/support/help/api2#dnssec_get_status>.

=head2 enable

Enables DNSSEC for domain(s), that uses REG.RU nameservers. Later you can use L</get_status> to check that operation
finished successfully. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->enable(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNSSEC management: enable|https://www.reg.com/support/help/api2#dnssec_enable>.

=head2 disable

Disables DNSSEC for domain(s), that uses REG.RU nameservers. Later you can use L</get_status> to check that operation
finished successfully. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->disable(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNSSEC management: disable|https://www.reg.com/support/help/api2#dnssec_disable>.

=head2 renew_ksk

Regenerates and updates KSK key for domain(s), that uses REG.RU nameservers. Later you can use L</get_status> to check
that operation finished successfully. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->renew_ksk(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNSSEC management: renew_ksk|https://www.reg.com/support/help/api2#dnssec_renew_ksk>.

=head2 renew_zsk

Regenerates and updates ZSK key for domain(s), that uses REG.RU nameservers. Later you can use L</get_status> to check
that operation finished successfully. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->renew_zsk(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNSSEC management: renew_zsk|https://www.reg.com/support/help/api2#dnssec_renew_zsk>.

=head2 get_records

Gets list of DNSSEC records of a domain(s). These are DNSKEY and DS records for domains those use REG.RU nameservers.
For other domains it will return DNSSEC records from the parent zone. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->get_records(
        domains => [
            { dname => 'bluth-company.com' },
            { dname => 'sitwell-enterprises.com' },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names (or
error otherwise) and subfield records in described format.

More info at L<DNSSEC management: get_records|https://www.reg.com/support/help/api2#dnssec_get_records>.

=head2 add_keys

Adds information about KSK keys to the parent zone. Can be used only for domains which don't use REG.RU nameservers. C<records>
field should contain array of DNSKEY/DS records or API will try to get records from authoritative DNS server if field missed or emty.
Later you can use L</get_status>, L</get_records> to check that operation finished successfully. Scope: B<clients>. Typical usage:

    $resp = $client->dnssec->add_keys(
        domains => [
            { dname => 'bluth-company.com', records => [
                "bluth-company.com. 3600 IN DS 2371 13 2 4508a7798c38867c94091bbf91edaf9e6dbf56da0606c748d3d1d1b2382c1602"
            ] },
            { dname => 'sitwell-enterprises.com', records => [
                "sitwell-enterprises.com. IN DNSKEY 257 3 13 X2ehOZBEVxU6baEa58fQx/6Y+gckDeq85XGFW8o6jWFB19wtv6aqdc8ycpIrQaZ4bSLYM7ZyLPJtP6UOkzslDg=="
            ] },
        ],
    );

Answer will contains a field C<domains> with a list of results for each involved to this operation domain names or
error otherwise.

More info at L<DNSSEC management: add_keys|https://www.reg.com/support/help/api2#dnssec_add_keys>.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<Regru::API::Domain>

L<REG.API DNSSEC management|https://www.reg.com/support/help/api2#dnssec_functions>

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
