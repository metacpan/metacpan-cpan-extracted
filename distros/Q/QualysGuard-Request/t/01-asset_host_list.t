#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok( 'QualysGuard::Response::AssetHostList' );
}


my $xml = join('', <DATA>);
my $qr  = QualysGuard::Response::AssetHostList->new( $xml );
ok(1);

isa_ok($qr, 'XML::XPath');
isa_ok($qr, 'QualysGuard::Response');
isa_ok($qr, 'QualysGuard::Response::AssetHostList');

my $ip  = $qr->get_ip_address_list();

if ( $ip->[0] eq '192.168.1.10' &&
     $ip->[1] eq '192.168.1.20' &&
     $ip->[2] eq '192.168.3.5' )
{
    ok(1);
}




__DATA__
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE HOST_LIST SYSTEM "https://qualysguard.qualys.com/ip_list.dtd">
<HOST_LIST>
  <IP_LIST>
    <RANGE>
      <START><![CDATA[192.168.1.1]]></START>
      <END><![CDATA[192.168.1.255]]></END>
    </RANGE>
    <RANGE>
      <START><![CDATA[192.168.3.1]]></START>
      <END><![CDATA[192.168.3.255]]></END>
    </RANGE>
  </IP_LIST>
  <RESULTS>
    <HOST>
      <IP><![CDATA[192.168.1.10]]></IP>
      <TRACKING_METHOD>
        <VALUE><![CDATA[IP address]]></VALUE>
      </TRACKING_METHOD>
      <OPERATING_SYSTEM><![CDATA[Linux 2.4-2.6]]></OPERATING_SYSTEM>
      <OWNER>
        <FIRSTNAME><![CDATA[John]]></FIRSTNAME>
        <LASTNAME><![CDATA[Doe]]></LASTNAME>
        <USER_LOGIN><![CDATA[qualys_login]]></USER_LOGIN>
      </OWNER>
      <COMMENT>
        <VALUE><![CDATA[Example.com Mail Host]]></VALUE>
      </COMMENT>
    </HOST>
    <HOST>
      <IP><![CDATA[192.168.1.20]]></IP>
      <TRACKING_METHOD>
        <VALUE><![CDATA[IP address]]></VALUE>
      </TRACKING_METHOD>
      <DNS><![CDATA[server01.example.com]]></DNS>
      <OPERATING_SYSTEM><![CDATA[Linux 2.4-2.6 / Embedded Device]]></OPERATING_SYSTEM>
      <OWNER>
        <FIRSTNAME><![CDATA[John]]></FIRSTNAME>
        <LASTNAME><![CDATA[Doe]]></LASTNAME>
        <USER_LOGIN><![CDATA[qualys_login]]></USER_LOGIN>
      </OWNER>
      <COMMENT>
        <VALUE><![CDATA[Example.com FTP Server]]></VALUE>
      </COMMENT>
    </HOST>
    <HOST>
      <IP><![CDATA[192.168.3.5]]></IP>
      <TRACKING_METHOD>
        <VALUE><![CDATA[IP address]]></VALUE>
      </TRACKING_METHOD>
      <DNS><![CDATA[server02.example.com]]></DNS>
      <OPERATING_SYSTEM><![CDATA[Linux 2.4-2.6]]></OPERATING_SYSTEM>
      <OWNER>
        <FIRSTNAME><![CDATA[John]]></FIRSTNAME>
        <LASTNAME><![CDATA[Doe]]></LASTNAME>
        <USER_LOGIN><![CDATA[qualys_login]]></USER_LOGIN>
      </OWNER>
      <COMMENT>
        <VALUE><![CDATA[Example.com Web Server]]></VALUE>
      </COMMENT>
    </HOST>
  </RESULTS>
</HOST_LIST>
<!-- CONFIDENTIAL AND PROPRIETARY INFORMATION. Qualys provides the QualysGuard Service "As Is," without any warranty of any kind. Qualys makes no warranty that the information contained in this report is complete or error-free. Copyright 2008, Qualys, Inc. //--> 
