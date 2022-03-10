#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Net::CIDR;
use Net::Whois::IANA;

use Test::MockModule;

# note: we are mocking some internal to freeze the ripe reply
my $mocked_iana = Test::MockModule->new('Net::Whois::IANA');

$mocked_iana->redefine(
    source_connect => sub {
        my ( $self, $source_name ) = @_;

        note "mocked source_connect for ", $source_name;
        my $sock = $mocked_iana->original('source_connect')->( $self, $source_name );

        $self->{query_sub} = sub {
            return %{ _ripe_query() } if $source_name eq 'ripe';
            return ();
        };

        return $sock;
    }
);

my $iana = Net::Whois::IANA->new;

ok $iana;

$iana->whois_query( -ip => '191.96.58.222', -debug => 0 );

my $cidr = $iana->cidr;

if ($cidr) {    # some smokers are flapping... this is kind of a big todo...

    is ref $cidr, 'ARRAY', "cidr is an array ref" or diag "CIDR: ", explain $cidr;

    note explain $cidr;

    if ( defined $cidr->[0] ) {    # query can fail on some smokers...

        like $cidr->[0], qr{^\Q191.96.0.0/16\E}, 'cidr';

        # view on travis smoker this can be either 191.96.58/24 or 191.96.58-191.96.58...
        ### need to investigate

        #is $iana->inetnum, '191.96.58-191.96.58', 'range';
        ok Net::CIDR::cidrvalidate( $cidr->[0] );
    }

}

done_testing;
exit;

sub _ripe_query {
    return {
        'abuse-c'  => 'IPXO834',
        'admin-c'  => 'CYB777',
        'cidr'     => ['191.96.0.0/16'],
        'country'  => 'AE',
        'created'  => '2022-03-02T14:23:29Z',
        'fullinfo' => '% This is the RIPE Database query service.
    % The objects are in RPSL format.
    %
    % The RIPE Database is subject to Terms and Conditions.
    % See http://www.ripe.net/db/support/db-terms-conditions.pdf

    % Note: this output has been filtered.
    %       To receive output for a database update, use the "-B" flag.

    % Information related to \'191.96.0.0 - 191.96.255.255\'

    % Abuse contact for \'191.96.0.0 - 191.96.255.255\' is \'abuse@ipxo.com\'

    inetnum:        191.96.0.0 - 191.96.255.255
    netname:        AE-CYBERASSETS-20131024
    country:        AE
    org:            ORG-CAF4-RIPE
    admin-c:        CYB777
    tech-c:         CYB777
    abuse-c:        IPXO834
    mnt-lower:      IPXO-MNT
    mnt-domains:    IPXO-MNT
    mnt-routes:     IPXO-MNT
    status:         ALLOCATED PA
    mnt-by:         CYBER-A-MNT
    mnt-by:         RIPE-NCC-HM-MNT
    created:        2022-03-02T14:23:29Z
    last-modified:  2022-03-02T14:29:23Z
    source:         RIPE

    % This query was served by the RIPE Database Query Service version 1.102.2 (ANGUS)


    ',
        'inetnum'       => '191.96.0.0 - 191.96.255.255',
        'last-modified' => '2022-03-02T14:29:23Z',
        'mnt-by'        => 'CYBER-A-MNT RIPE-NCC-HM-MNT',
        'mnt-domains'   => 'IPXO-MNT',
        'mnt-lower'     => 'IPXO-MNT',
        'mnt-routes'    => 'IPXO-MNT',
        'netname'       => 'AE-CYBERASSETS-20131024',
        'org'           => 'ORG-CAF4-RIPE',
        'permission'    => 'allowed',
        'source'        => 'RIPE',
        'status'        => 'ALLOCATED PA',
        'tech-c'        => 'CYB777'
    };
}
