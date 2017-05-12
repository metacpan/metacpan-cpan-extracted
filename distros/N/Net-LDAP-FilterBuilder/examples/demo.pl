#!/usr/bin/perl

use Net::LDAP::FilterBuilder;

my $filter1 = Net::LDAP::FilterBuilder->new( sn => 'Jones' );
# now $filter1 eq '(sn=Jones)'
