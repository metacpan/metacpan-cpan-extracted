#!/usr/bin/env perl 

use strict;
use warnings;

use Test::More tests => 29;

use_ok 'Net::Whois::Raw';
use_ok 'Net::Whois::Raw::Common';

ok( Net::Whois::Raw::Common::domain_level( 'reg.ru' )     == 2, 'domain_level' );
ok( Net::Whois::Raw::Common::domain_level(' www.reg.ru' ) == 3, 'domain_level' );

my ($name, $tld) = Net::Whois::Raw::Common::split_domain( 'reg.ru' );
ok( $name eq 'reg' && $tld eq 'ru', 'split_domain' );

($name, $tld) = Net::Whois::Raw::Common::split_domain( 'REG.RU' );
ok( $name eq 'REG' && $tld eq 'RU', 'split_domain');

($name, $tld) = Net::Whois::Raw::Common::split_domain( 'auto.msk.ru' );
ok( $name eq 'auto' && $tld eq 'msk.ru', 'split_domain' );

ok(  Net::Whois::Raw::Common::is_ipaddr( '122.234.214.214' ), 'is_ipaddr' );
ok( !Net::Whois::Raw::Common::is_ipaddr( 'a22.b34.214.214' ), 'is_ipaddr' );

ok(  Net::Whois::Raw::Common::is_ip6addr( '2002::2eb6:195b' ), 'is_ip6addr' );
ok( !Net::Whois::Raw::Common::is_ip6addr( '2002::2eb6:195g' ), 'is_ip6addr' );
ok(  Net::Whois::Raw::Common::is_ip6addr( '::ffff:c000:0280' ), 'is_ip6addr (ipv4)' );

ok( Net::Whois::Raw::Common::get_dom_tld( '125.214.84.1' )   eq 'IP',     'get_dom_tld' );
ok( Net::Whois::Raw::Common::get_dom_tld( 'REGRU-REG-RIPN' ) eq 'NOTLD',  'get_dom_tld' );
ok( Net::Whois::Raw::Common::get_dom_tld( 'yandex.ru' )      eq 'ru',     'get_dom_tld' );
ok( Net::Whois::Raw::Common::get_dom_tld( 'auto.msk.ru' )    eq 'msk.ru', 'get_dom_tld' );

ok( Net::Whois::Raw::Common::get_real_whois_query( 'sourceforge.net', 'whois.crsnic.net' )
    eq 'domain sourceforge.net', 'get_real_whois_query'
);
ok( Net::Whois::Raw::Common::get_real_whois_query( 'mobile.de', 'whois.denic.de' )
    eq '-T dn,ace -C ISO-8859-1 mobile.de', 'get_real_whois_query'
);
ok( Net::Whois::Raw::Common::get_real_whois_query( 'nic.name',  'whois.nic.name' )
    eq 'domain=nic.name', 'get_real_whois_query'
);
ok( Net::Whois::Raw::Common::get_real_whois_query( 'reg.ru',    'whois.ripn.net' )
    eq 'reg.ru', 'get_real_whois_query'
);

is( Net::Whois::Raw::Common::get_server( 'reg.ru' ), 'whois.ripn.net', 'get_server' );
is( Net::Whois::Raw::Common::get_server( 'nic.vn' ), 'www_whois',      'get_server' );
is( Net::Whois::Raw::Common::get_server( undef, undef, 'spb.ru' ), 'whois.flexireg.net', 'get_server' );


for ('ReferralServer: rwhois://rwhois.theplanet.com:4321') {
    my ($res) = Net::Whois::Raw::_referral_server();
    is $res, 'rwhois.theplanet.com:4321', "_referral_server should work for rwhois:// and port";
}

for ('ReferralServer: whois://some-host.com') {
    ok $_ =~ /ReferralServer: whois:\/\/([-.\w]+)/, "this test example match regexp used in previous versions of module";
    my ($res) = Net::Whois::Raw::_referral_server();
    is $res, 'some-host.com', "_referral_server should work for whois:// without port";
}

is Net::Whois::Raw::Common::_strip_trailer_lines( q{
blah-blah-blah

>>> Last update of WHOIS database: 2014-02-24T04:01:25-0800 <<<

The Data in MarkMonitor.com's WHOIS database is provided by MarkMonitor.com for
    } ),
    "\nblah-blah-blah\n", '_strip_trailer_lines';

is Net::Whois::Raw::Common::_strip_trailer_lines( q{
Record created on 24-Sep-1998
Database last updated on 12-Sep-2013

The Data in the Safenames Registrar WHOIS database is provided by Safenames for
information purposes only, and to assist persons in obtaining information about
or related to a domain name registration record.  Safenames does not guarantee
its accuracy.  Additionally, the data may not reflect updates to billing
contact information.} ),
    "\nRecord created on 24-Sep-1998\n", '_strip_trailer_lines';


is Net::Whois::Raw::Common::_strip_trailer_lines( q{
Domain Last Updated Date:                    Sat Jun 04 15:25:01 GMT 2011

>>>> Whois database was last updated on: Mon Feb 24 12:49:50 GMT 2014 <<<<

NeuStar, Inc., the Registry Operator for .BIZ, has collected this information} ),
    "\nDomain Last Updated Date:                    Sat Jun 04 15:25:01 GMT 2011\n",
    '_strip_trailer_lines';
