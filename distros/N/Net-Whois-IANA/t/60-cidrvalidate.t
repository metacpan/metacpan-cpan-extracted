#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Net::CIDR;
use Net::Whois::IANA;

my $iana = Net::Whois::IANA->new;

ok $iana;

$iana->whois_query( -ip => '191.96.58.222', -debug => 0 );

my $cidr = $iana->cidr;

if ($cidr) {    # some smokers are flapping... this is kind of a big todo...

    is ref $cidr, 'ARRAY', "cidr is an array ref" or diag "CIDR: ", explain $cidr;

    note explain $cidr;

    if ( defined $cidr->[0] ) {    # query can fail on some smokers...

        is $cidr->[0], '191.96.58/24', 'cidr';

        # view on travis smoker this can be either 191.96.58/24 or 191.96.58-191.96.58...
        ### need to investigate

        #is $iana->inetnum, '191.96.58-191.96.58', 'range';
        ok Net::CIDR::cidrvalidate( $cidr->[0] );
    }

}

done_testing;
