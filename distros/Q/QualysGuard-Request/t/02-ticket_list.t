#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok( 'QualysGuard::Response::TicketList' );
}


my $xml = join('', <DATA>);
my $qr  = QualysGuard::Response::TicketList->new( $xml );
ok(1);

isa_ok($qr, 'XML::XPath');
isa_ok($qr, 'QualysGuard::Response');
isa_ok($qr, 'QualysGuard::Response::TicketList');


is($qr->is_truncated(),              1, 'is_truncated');
is($qr->get_last_ticket_number(), 1234, 'get_last_ticket_number');




__DATA__
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE REMEDIATION_TICKETS SYSTEM "https://qualysguard.qualys.com/ticket_list_output.dtd">
<REMEDIATION_TICKETS>
  <HEADER>
    <USER_LOGIN>qualys_login</USER_LOGIN>
    <COMPANY><![CDATA[example.com]]></COMPANY>
    <DATETIME>2008-07-29T17:01:46Z</DATETIME>
    <WHERE>
      <ASSET_GROUPS><![CDATA[asset_group_one,asset_group_two]]></ASSET_GROUPS>
      <STATES>OPEN</STATES>
    </WHERE>
  </HEADER>
  <TICKET_LIST>
    <TICKET>
      <NUMBER>1234</NUMBER>
      <CREATION_DATETIME>2008-02-13T22:22:29Z</CREATION_DATETIME>
      <DUE_DATETIME>2008-06-12T22:22:29Z</DUE_DATETIME>
      <CURRENT_STATE>OPEN</CURRENT_STATE>
      <INVALID>0</INVALID>
      <ASSIGNEE>
        <NAME><![CDATA[John Doe]]></NAME>
        <EMAIL><![CDATA[john.doe@example.com]]></EMAIL>
        <LOGIN>qualys_login</LOGIN>
      </ASSIGNEE>
      <DETECTION>
        <IP>192.168.1.50</IP>
        <DNSNAME><![CDATA[hostname.example.com]]></DNSNAME>
        <NBHNAME><![CDATA[hostname]]></NBHNAME>
        <SERVICE>SMB / NETBIOS</SERVICE>
      </DETECTION>
      <STATS>
        <FIRST_FOUND_DATETIME>2008-02-13T22:22:29Z</FIRST_FOUND_DATETIME>
        <LAST_FOUND_DATETIME>2008-07-03T03:23:54Z</LAST_FOUND_DATETIME>
        <LAST_SCAN_DATETIME>2008-07-03T03:23:54Z</LAST_SCAN_DATETIME>
        <TIMES_FOUND>9</TIMES_FOUND>
        <TIMES_NOT_FOUND></TIMES_NOT_FOUND>
        <LAST_OPEN_DATETIME>2008-02-13T22:22:29Z</LAST_OPEN_DATETIME>
      </STATS>
      <HISTORY_LIST>
        <HISTORY>
          <DATETIME>2008-02-13T22:22:29Z</DATETIME>
          <ACTOR>qualys_login</ACTOR>
          <STATE>
            <NEW>OPEN</NEW>
          </STATE>
          <ADDED_ASSIGNEE>
            <NAME><![CDATA[John Doe]]></NAME>
            <EMAIL><![CDATA[john.doe@example.com]]></EMAIL>
            <LOGIN>qualys_login</LOGIN>
          </ADDED_ASSIGNEE>
          <SCAN>
            <REF>scan/5555555555.55555</REF>
            <DATETIME>2008-02-13T21:29:28Z</DATETIME>
          </SCAN>
          <RULE><![CDATA[Default Policy]]></RULE>
        </HISTORY>
      </HISTORY_LIST>
      <VULNINFO>
        <TITLE><![CDATA[NetBIOS Name Accessible]]></TITLE>
        <TYPE>VULN</TYPE>
        <QID>70000</QID>
        <SEVERITY>2</SEVERITY>
        <STANDARD_SEVERITY>2</STANDARD_SEVERITY>
        <CVE_ID_LIST>
          <CVE_ID><![CDATA[CVE-1999-0621]]></CVE_ID>
        </CVE_ID_LIST>
      </VULNINFO>
    </TICKET>
  </TICKET_LIST>
  <TRUNCATION last="1234">Truncated after 1000 records</TRUNCATION>
</REMEDIATION_TICKETS>
<!-- CONFIDENTIAL AND PROPRIETARY INFORMATION. Qualys provides the QualysGuard Service "As Is," without any warranty of any kind. Qualys makes no warranty that the information contained in this report is complete or error-free. Copyright 2008, Qualys, Inc. //--> 
