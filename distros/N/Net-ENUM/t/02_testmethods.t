#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use Net::ENUM;



# Phone number of http://www.denic.de/impressum.html
my $phone = '+49 69 27235-0';



# create Net::ENUM object
my $NetENUM = Net::ENUM->new( { udp_timeout => 15 } );
isa_ok( $NetENUM, 'Net::ENUM', 'create Net::ENUM object' );



# turn number into domain (number_to_domain)
# generate error 1
my $domain = $NetENUM->number_to_domain( '123 456-789' );
ok( ! defined $domain, "not a enum 1: '123 456-789'" );
diag( $NetENUM->{'enum_error'} );
# generate error 2
$domain = $NetENUM->number_to_domain( '+%/) !"=-`?§' );
ok( ! defined $domain, "not a enum 2: '+%/) !\"=-`?§'" );
diag( $NetENUM->{'enum_error'} );
# generate domain 1
$domain = $NetENUM->number_to_domain( $phone );
ok( $domain eq '0.5.3.2.7.2.9.6.9.4.e164.arpa', "turn number '$phone' into domain:" ) || diag( $NetENUM->{'enum_error'} );
diag( $domain );
# generate domain 2
$domain = $NetENUM->number_to_domain( '+49 nz asbdk-0' );
ok( $domain eq '0.5.3.2.7.2.9.6.9.4.e164.arpa', "turn vanity '+49 nz asbdk-0' into domain:" ) || diag( $NetENUM->{'enum_error'} );
diag( $domain );



# get nameservers (get_nameservers)
# generate error
my $nameserver = $NetENUM->get_nameservers( 'foo.bar' );
ok( ! defined $nameserver, "no nameserver for 'foo.bar'" );
diag( $NetENUM->{'enum_error'} );
# get nameserver
$nameserver = $NetENUM->get_nameservers( $domain );
isa_ok( $nameserver, 'ARRAY', "get nameservers of $domain" ) || diag( $NetENUM->{'enum_error'} );



# get Internet address (get_enum_address)
# get address string
my $address = $NetENUM->get_enum_address( $phone, undef, 'tel' );
ok( $address =~ /tel:/, 'get telefone address string' ) || diag( $NetENUM->{'enum_error'} );
diag( $address );
# get NAPTR array
my @address = $NetENUM->get_enum_address( $phone, 'order' );
ok( $address[0]->{'name'} eq $domain, 'get sip NAPTR array' ) || diag( $NetENUM->{'enum_error'} );
diag( "\$address[0]->{'name'} = $domain" );
