#!/usr/bin/perl
##
## Net::XWhois
## Whois Client Interface Class.
##
## $Date: 2001/07/14 07:25:31 $
## $Revision: 1.3 $
## $State: Exp $
## $Author: vipul $
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
#
# modified August 2002 by Rob Woodard
# 
# Changes:
#
#  08/05/2002  rwoodard    Merged in changes from XWhois discussion forum on
#                          sourceforge.net; made additional changes as needed
#                          to implement reverse lookups of IP addresses
#  08/06/2002  rwoodard    Added comments for internal documentation.  Added
#                          parser defs for ARIN, set APNIC and RIPE to use RPSL.
#  08/07/2002  rwoodard    Added ARIN-specific following of multiple netblocks;
#                          this is done by setting the Bottom_netblock attrib
#  08/08/2002  rwoodard    Added Verbose attribute for displaying status info
#  08/26/2002  rwoodard    Revised ARIN parser to reflect updated responses
#

package Net::XWhois;

use Data::Dumper;
use IO::Socket;
use Carp;
use vars qw ( $VERSION $AUTOLOAD );

$VERSION     = '0.90';

my $CACHE    = "/tmp/whois";
my $EXPIRE   = 604800;
my $ERROR    = "return";
my $TIMEOUT  = 20;
my $RETRIES  = 3;

my %PARSERS  = (

#these are the parser definitions for each whois server.
#the AUTOLOAD subroutine creates an object method for each key defined within
#the server's hash of regexps; this applies the regexp to the response from
#the whois server to extract the data.  of course you can just write your own
#parsing subroutine as described in the docs.
#
#there ought to be some standardization of the fields being parsed.  for my 
#own personal purposes only RPSL and ARIN are standardized; there needs to be
#some work done on the other defs to get them to return at least these fields:
#
#  name        name of registrant entity (company or person)
#  netname     name assigned to registrant's network
#  inetnum     address range registered
#  abuse_email email addresses named 'abuse@yaddayadda'
#  gen_email   general correspondence email addresses
#
#yes some of these are redundant to what is already there; I saw no reason to
#delete non-standardized keys, they don't take that much space and might be
#needed for backwards compatibility. -rwoodard 08/2002
 
 RPSL => { #updated by rwoodard 08/06/2002
  name            => '(?:descr|owner):\s+([^\n]*)\n',
  netname         => 'netname:\s+([^\n]*)\n',
  inetnum         => 'inetnum:\s+([^\n]*)\n',
  abuse_email     => '\b(?:abuse|security)\@\S+',
  gen_email       => 'e-*mail:\s+(\S+\@\S+)',
  
  country         => 'country:\s+(\S+)',
  status          => 'status:\s+([^\n]*)\n',
  contact_admin   => '(?:admin|owner)-c:\s+([^\n]*)\n',
  contact_tech    => 'tech-c:\s+([^\n]*)\n',
  contact_emails  => 'email:\s+(\S+\@\S+)',
  contact_handles => 'nic-hdl(?:-\S*):\s+([^\n]*)\n',
  remarks         => 'remarks:\s+([^\n]*)\n',
  notify          => 'notify:\s+([^\n]*)\n',
  forwardwhois    => 'remarks:\s+[^\n]*(whois.\w+.\w+)',
 },

 ARIN => { #from Jon Gilbert 09/04/2000 updated/added to by rwoodard 08/07/2002
   
   name                 => '(?:OrgName|CustName):\s*(.*?)\n',
   
   netname              => 'etName:\s*(\S+)\n+',
   inetnum              => 'etRange:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} - \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
   abuse_email          => '(?:abuse|security)\@\S+',
   gen_email            => 'Coordinator:[\n\s]+.*?(\S+\@\S+)',

   netnum               => 'Netnumber:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
   hostname             => 'Hostname:\s*(\S+)[\n\s]*',
   maintainer           => 'Maintainer:\s*(\S+)',
   #record_update       => 'Record last updated on (\S+)\.\n+',
   record_update        => 'Updated:(\S+)\n+',
   database_update      => 'Database last updated on (.+)\.[\n\s]+The',
   registrant           => '^(.*?)\n\n',
   reverse_mapping      => 'Domain System inverse[\s\w]+:[\n\s]+(.*?)\n\n',
   coordinator          => 'Coordinator:[\n\s]+(.*?)\n\n',
   coordinator_handle   => 'Coordinator:[\n\s]+[^\(\)]+\((\S+?)\)',
   coordinator_email    => 'Coordinator:[\n\s]+.*?(\S+\@\S+)',
   address              => 'Address:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})',
   system               => 'System:\s+([^\n]*)\n',
   non_portable         => 'ADDRESSES WITHIN THIS BLOCK ARE NON-PORTABLE',
   #multiple            => 'To single out one record',
   multiple             => '\((NET\S+)\)',
   net_handle           => '(NET\S+)\)',
   country              => 'Country:\s*(\S+)\n+',
 },
 
 BRNIC => {
   name            => '(?:descr|owner):\s+([^\n]*)\n',
   netname        => 'netname:\s+([^\n]*)\n',
   inetnum        => 'inetnum:\s+([^\n]*)\n',
   abuse_email    => '\b(?:abuse|security)\@\S+',
   gen_email      => 'e-*mail:\s+(\S+\@\S+)',
  
   country        => 'BR', #yes this is ugly, tell BRNIC to start putting country fields in their responses
   status          => 'status:\s+([^\n]*)\n',
   contact_admin   => '(?:admin|owner)-c:\s+([^\n]*)\n',
   contact_tech    => 'tech-c:\s+([^\n]*)\n',
   contact_emails  => 'email:\s+(\S+\@\S+)',
   contact_handles => 'nic-hdl(?:-\S*):\s+([^\n]*)\n',
   remarks        => 'remarks:\s+([^\n]*)\n',
   notify         => 'notify:\s+([^\n]*)\n',
   forwardwhois   => 'remarks:\s+[^\n]*(whois.\w+.\w+)',
 },
 
 KRNIC => { #added by rwoodard 08/06/2002

 },

 TWNIC => { #added by rwoodard 08/06/2002
   name                 => '^([^\n]*)\n',
   netname              => 'etname:\s*(\S+)\n+',
   inetnum              => 'etblock:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} - \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
   abuse_email          => '(?:abuse|security)\@\S+',
   gen_email            => 'Coordinator:[\n\s]+.*?(\S+\@\S+)',

   netnum               => 'Netnumber:\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\n\s]*',
   hostname             => 'Hostname:\s*(\S+)[\n\s]*',
   maintainer           => 'Maintainer:\s*(\S+)',
   record_update        => 'Record last updated on (\S+)\.\n+',
   database_update      => 'Database last updated on (.+)\.[\n\s]+The',
   registrant           => '^(.*?)\n\n',
   reverse_mapping      => 'Domain System inverse[\s\w]+:[\n\s]+(.*?)\n\n',
   coordinator          => 'Coordinator:[\n\s]+(.*?)\n\n',
   coordinator_handle   => 'Coordinator:[\n\s]+[^\(\)]+\((\S+?)\)',
   coordinator_email    => 'Coordinator:[\n\s]+.*?(\S+\@\S+)',
   address              => 'Address:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})',
   system               => 'System:\s+([^\n]*)\n',
   non_portable         => 'ADDRESSES WITHIN THIS BLOCK ARE NON-PORTABLE',
   multiple             => 'To single out one record',
   net_handle           => '\((NETBLK\S+)\)',
   country              => '\n\s+(\S+)\n\n',
 },
 
 INTERNIC => {
  name            => '[\n\r\f]+\s*[Dd]omain [Nn]ame[:\.]*\s+(\S+)', 
  status          => 'omain Status[:\.]+\s+(.*?)\s*\n', 
  nameservers     => '[\n\r\f]+\s*([a-zA-Z0-9\-\.]+\.[a-zA-Z0-9\-]+\.[a-zA-Z\-]+)[:\s\n$]',
  registrant      => '(?:egistrant|rgani[sz]ation)[:\.]*\s*\n(.*?)\n\n',
  contact_admin   => '(?:dministrative Contact|dmin Contact).*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_tech    => '(?:echnical Contact|ech Contact).*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_zone    => 'one Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_billing => 'illing Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_emails  => '(\S+\@\S+)',
  contact_handles => '\(([^\W\d]+\d+)\)',
  domain_handles  => '\((\S*?-DOM)\)',
  org_handles     => '\((\S*?-ORG)\)',
  not_registered  => 'No match',
  forwardwhois    => 'Whois Server: (.*?)(?=\n)',
 },

 BULKREG => {
  name            => 'omain Name[:\.]*\s+(\S+)', 
  status          => 'omain Status[:\.]+\s+(.*?)\s*\n',
  nameservers     => '[\n\r\f]+\s*([a-zA-Z0-9\-\.]+\.[a-zA-Z0-9\-]+\.[a-zA-Z\-]+)[:\s\n$]',
  registrant      => '(.+)\([\w\-]+\-DOM\).*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_admin   => 'dmin[a-zA-Z]*? Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_tech    => 'ech[a-zA-Z]*? Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_zone    => 'one Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_billing => 'illing Contact.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_emails  => '(\S+\@\S+)',
  contact_handles => '\((\w+\d+\-BR)\)',
  domain_handles  => '\((\S*?-DOM)\)',
  org_handles     => '\((\S*?-ORG)\)',
  not_registered  => 'Not found\!',
  forwardwhois    => 'Whois Server: (.*?)(?=\n)',
  registrar       => 'egistrar\s*\w*[\.\:]* (.*?)\.?\n',
  reg_date        => 'reated on[\.\:]* (.*?)\.?\n',
  exp_date        => 'xpires on[\.\:]* (.*?)\.?\n',
 },

 INWW => {
  name            => 'omain Name\.+ (\S+)',
  status          => 'omain Status\.+ ([^\n]*)\n', 
  nameservers     => 'Name Server\.+ (\S+)',
  registrant      => 'Organisation \w{4,7}\.+ ([^\n]+?)\n',
  contact_admin   => 'Admin \w{3,7}\.+ ([^\n]*)\n',
  contact_tech    => 'Tech \w{3,7}\.+ ([^\n]*)\n',
  contact_zone    => 'Zone \w{3,7}\.+ ([^\n]*)\n',
  contact_billing => 'Billing \w{3,7}\.+ ([^\n]*)\n',
  contact_emails  => '(\S+\@\S+)',
  contact_handles => '\((\w+\d+)\)',
  domain_handles  => '\((\S*?-DOM)\)',
  org_handles     => '\((\S*?-ORG)\)',
  not_registered  => 'is not registered',
  forwardwhois    => 'Whois Server: (.*?)(?=\n)',
  registrar       => 'egistrar\s*\w*[\.\:]* (.*?)\.?\n',
  exp_date        => 'Expiry Date\.+ ([^\n]*)\n',
  reg_date        => 'Registration Date\.+ ([^\n]*)\n',
 }, 

 INTERNIC_CONTACT => {
  name            => '(.+?)\s+\(.*?\)(?:.*?\@)',
  address         => '\n(.*?)\n[^\n]*?\n\n\s+Re',
  email           => '\s+\(.*?\)\s+(\S+\@\S+)',
  phone           => '\n([^\n]*?)\(F[^\n]+\n\n\s+Re',
  fax             => '\(FAX\)\s+([^\n]+)\n\n\s+Re',
 },

 CANADA  => {
  name            => 'domain:\s+(\S+)\n',
  nameservers     => '-Netaddress:\s+(\S+)',
  contact_emails  => '-Mailbox:\s+(\S+\@\S+)',
 },

 RIPE => {
  name            => 'domain:\s+(\S+)\n',
  nameservers     => 'nserver:\s+(\S+)',
  contact_emails  => 'e-mail:\s+(\S+\@\S+)',
  registrant      => 'descr:\s+(.+?)\n',
 },

 RIPE_CH => {
  name            => 'Domain Name:[\s\n]+(\S+)\n',
  nameservers     => 'Name servers:[\s\n]+(\S+)[\s\n]+(\S+)',
 },

 NOMINET => { 
  name                => 'omain Name:\s+(\S+)',
  registrant          => 'egistered For:\s*(.*?)\n',
  ips_tag             => 'omain Registered By:\s*(.*?)\n',
  record_updated_date => 'Record last updated on\s*(.*?)\s+',
  record_updated_by   => 'Record last updated on\s*.*?\s+by\s+(.*?)\n',
  nameservers         => 'listed in order:[\s\n]+(\S+)\s.*?\n\s+(\S*?)\s.*?\n\s*\n',
  whois_updated       => 'database last updated at\s*(.*?)\n',
 },

 UKERNA  => {
  name                => 'omain Name:\s+(\S+)',
  registrant          => 'egistered For:\s*(.*?)\n',
  ips_tag             => 'omain Registered By:\s*(.*?)\n',
  record_updated_date => 'ecord updated on\s*(.*?)\s+',
  record_updated_by   => 'ecord updated on\s*.*?\s+by\s+(.*?)\n',
  nameservers         => 'elegated Name Servers:[\s\n]+(\S+)[\s\n]+(\S+).*?\n\s*\n',
  contact_emails      => 'Domain contact:\s*(.*?)\n',
 },

 CENTRALNIC => { 
  name                => 'omain Name:\s+(\S+)',
  registrant          => 'egistrant:\s*(.*?)\n',
  contact_admin       => 'lient Contact:\s*(.*?)\n\s*\n',
  contact_billing     => 'illing Contact:\s*(.*?)\n\s*\n',
  contact_tech        => 'echnical Contact:\s*(.*?)\n\s*\n',
  record_created_date => 'ecord created on\s*(.*?)\n',
  record_paid_date    => 'ecord paid up to\s*(.*?)\n',
  record_updated_date => 'ecord last updated on\s*(.*?)\n',
  nameservers         => 'in listed order:[\s\n]+(\S+)\s.*?\n\s+(\S*?)\s.*?\n\s*\n',
  contact_emails      => '(\S+\@\S+)',
 },

 DENIC => { 
  name            => 'domain:\s+(\S+)\n',
  registrants     => 'descr:\s+(.+?)\n',
  contact_admin   => 'admin-c:\s+(.*?)\s*\n',
  contact_tech    => 'tech-c:\s+(.*?)\s*\n',
  contact_zone    => 'zone-c:\s+(.*?)\s*\n',
  nameservers     => 'nserver:\s+(\S+)',
  status          => 'status:\s+(.*?)\s*\n',
  changed         => 'changed:\s+(.*?)\s*\n',
  source          => 'source:\s+(.*?)\s*\n',
  person          => 'person:\s+(.*?)\s*\n',
  address         => 'address:\s+(.+?)\n',
  phone           => 'phone:\s+(.+?)\n',
  fax_no          => 'fax-no:\s+(.+?)\n',
  contact_emails  => 'e-mail:\s+(.+?)\n',
},

 JAPAN => {
  name            => '\[Domain Name\]\s+(\S+)',
  nameservers     => 'Name Server\]\s+(\S+)',
  contact_emails  => '\[Reply Mail\]\s+(\S+\@\S+)',
 },

 TAIWAN => {
  name            => 'omain Name:\s+(\S+)',
  registrant      => '^(\S+) \(\S+?DOM)',
  contact_emails  => '(\S+\@\S+)',
  nameservers     => 'servers in listed order:[\s\n]+\%see\-also\s+\.(\S+?)\:',
 },

 KOREA  => {
  name            => 'Domain Name\s+:\s+(\S+)',
  nameservers     => 'Host Name\s+:\s+(\S+)',
  contact_emails  => 'E\-Mail\s+:\s*(\S+\@\S+)',
 },

 MEXICO => {
  name            => '[\n\r\f]+\s*[Nn]ombre del [Dd]ominio[:\.]*\s+(\S+)',
  status          => 'omain Status[:\.]+\s+(.*?)\s*\n',
  nameservers     => 'ameserver[^:]*:\s*([a-zA-Z0-9.\-])+',
  registrant      => '(?:egistrant|rgani[sz]acion)[:\.]*\s*\n(.*?)\n\n',
  contact_admin   => '(?:tacto [Aa]dministrativo|dmin Contact).*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_tech    => '(?:tacto [Tt]ecnico|ech Contact).*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_billing => 'to de Pago.*?\n(.*?)(?=\s*\n[^\n]+?:\s*\n|[\n\r\f]{2})',
  contact_emails  => '(\S+\@\S+)',
  contact_handles => '\(([^\W\d]+\d+)\)',
  not_registered  => 'No Encontrado',
  reg_date        => 'de creacion[\.\:]* (.*?)\.?\n',
  record_updated_date => 'a modificacion[\.\:]* (.*?)\.?\n',
 },

 ADAMS => {
  name    => '(\S+) is \S*\s*registered',
  not_registered  => 'is not registered',
 },



 GENERIC => {
  contact_emails  => '(\S+\@\S+)',
 },
 
);

my %WHOIS_PARSER = (
    'whois.ripe.net'            => 'RPSL',
    'whois.nic.mil'             => 'INTERNIC',
    'whois.nic.ad.jp'           => 'JAPAN',
    'whois.domainz.net.nz'      => 'GENERIC',
    'whois.nic.gov'             => 'INTERNIC',
    'whois.nic.ch'              => 'RIPE_CH',
    'whois.twnic.net'           => 'TWNIC',
    'whois.internic.net'        => 'INTERNIC',
    'whois.aunic.net'           => 'RIPE',
    'whois.cdnnet.ca'           => 'CANADA',
    'whois.ja.net'              => 'UKERNA',
    'whois.nic.uk'              => 'NOMINET',
    'whois.krnic.net'           => 'KOREA',
    'whois.isi.edu'             => 'INTERNIC',
    'whois.norid.no'            => 'RPSL',
    'whois.centralnic.com'      => 'CENTRALNIC',
    'whois.denic.de'            => 'DENIC',
    'whois.InternetNamesWW.com' => 'INWW',
    'whois.bulkregister.com'    => 'BULKREG',
    'whois.arin.net'            => 'ARIN', #added 08/06/2002 by rwoodard
    'whois.apnic.net'           => 'RPSL', #added 08/06/2002 by rwoodard
    'whois.nic.fr'              => 'RPSL',
    'whois.lacnic.net'          => 'RPSL',
    'whois.nic.br'              => 'BRNIC',
    'whois.nic.mx'              => 'MEXICO',
    'whois.adamsnames.tc'       => 'ADAMS', 
);

my %DOMAIN_ASSOC = (

    'al'  => 'whois.ripe.net',      'am'  => 'whois.ripe.net',       
    'at'  => 'whois.ripe.net',      'au'  => 'whois.aunic.net',      
    'az'  => 'whois.ripe.net',       
    'ba'  => 'whois.ripe.net',      'be'  => 'whois.ripe.net',       
    'bg'  => 'whois.ripe.net',      'by'  => 'whois.ripe.net',
    'ca'  => 'whois.cdnnet.ca',     'ch'  => 'whois.nic.ch',          
    'com' => 'whois.internic.net',
    'cy'  => 'whois.ripe.net',      'cz'  => 'whois.ripe.net',
    'de'  => 'whois.denic.de',      'dk'  => 'whois.dk-hostmaster.dk',
    'dz'  => 'whois.ripe.net', 
    'edu' => 'whois.internic.net',  'ee'  => 'whois.ripe.net',
    'eg'  => 'whois.ripe.net',      'es'  => 'whois.ripe.net',
    'fi'  => 'whois.ripe.net',      'fo'  => 'whois.ripe.net',
    'fr'  => 'whois.nic.fr',
    'gb'  => 'whois.ripe.net',      'ge'  => 'whois.ripe.net',
    'gov' => 'whois.nic.gov',       'gr'  => 'whois.ripe.net',
    'hr'  => 'whois.ripe.net',      'hu'  => 'whois.ripe.net',
    'ie'  => 'whois.ripe.net',      'il'  => 'whois.ripe.net',
    'is'  => 'whois.ripe.net',      'it'  => 'whois.ripe.net',
    'jp'  => 'whois.nic.ad.jp',
    'kr'  => 'whois.krnic.net',
    'li'  => 'whois.ripe.net',      'lt'  => 'whois.ripe.net',
    'lu'  => 'whois.ripe.net',      'lv'  => 'whois.ripe.net',
    'ma'  => 'whois.ripe.net',      'md'  => 'whois.ripe.net',
    'mil' => 'whois.nic.mil',       'mk'  => 'whois.ripe.net',
    'mt'  => 'whois.ripe.net',      'mx'  => 'whois.nic.mx',
    'net' => 'whois.internic.net',  'nl'  => 'whois.ripe.net',
    'no'  => 'whois.norid.no',      'nz'  => 'whois.domainz.net.nz',
    'org' => 'whois.internic.net',
    'pl'  => 'whois.ripe.net',      'pt'  => 'whois.ripe.net',
    'ro'  => 'whois.ripe.net',      'ru'  => 'whois.ripe.net',
    'se'  => 'whois.ripe.net',      'sg'  => 'whois.nic.net.sg',
    'si'  => 'whois.ripe.net',      'sk'  => 'whois.ripe.net',
    'sm'  => 'whois.ripe.net',      'su'  => 'whois.ripe.net',
    'tn'  => 'whois.ripe.net',      'tr'  => 'whois.ripe.net',
    'tw'  => 'whois.twnic.net',
    'ua'  => 'whois.ripe.net',      

    'uk'     => 'whois.nic.uk',     
    'gov.uk' => 'whois.ja.net',
    'ac.uk'  => 'whois.ja.net', 
    'eu.com' => 'whois.centralnic.com',
    'uk.com' => 'whois.centralnic.com',
    'uk.net' => 'whois.centralnic.com',
    'gb.com' => 'whois.centralnic.com',
    'gb.net' => 'whois.centralnic.com',

    'us'  => 'whois.isi.edu',
    'va'  => 'whois.ripe.net',
    'yu'  => 'whois.ripe.net',
 
);

my %ARGS = (
    'whois.nic.ad.jp'            => { 'S' => '/e' },
    'whois.internic.net'         => { 'P' => '=' },
    'whois.networksolutions.com' => { 'P' => '=' },
);

sub register_parser {

    my ( $self, %args ) = @_;

    $self->{ _PARSERS }->{ $args{ Name } } = {} unless $args{ Retain }; #set Retain to keep parser entries already present
    for ( keys %{ $args{ Parser } } ) {
        $self->{ _PARSERS }->{ $args{ Name } }->{$_} = $args{ Parser }->{$_};
    }

    return 1;

}

sub register_association {

    my ( $self, %args ) = @_;
    foreach my $server ( keys %args ) {
        # Update our table for looking up the whois server => parser
        $self->{ _WHOIS_PARSER }->{ $server } = $args{ $server }->[0];  # Save name of whois server and associated parser
        # Update our table of domains and their associated server
        #$self->{ _DOMAIN_ASSOC }->{ $_ } = $server for ( @{$args{ $server }}->[1]);
        $self->{ _DOMAIN_ASSOC }->{ $_ } = $server for ( @{$args{ $server }->[1]}); #from Paul Fuchs
    };

    return 1;

}

sub register_cache {

    my ( $self, $cache ) = @_;
    return ${ $self->{ _CACHE } } = $cache  if $cache;

}

sub server {
     my $self = shift;
     return $self->{ Server };

}

sub guess_server_details {

    my ( $self, $domain ) = @_;
    $domain = lc $domain;

    my $ip=$domain=~/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/; #processing an IP?
    my ( $server, $parser );
    my ( $Dserver, $Dparser ) = 
         $ip ? ( 'whois.arin.net', { %{ $self->{ _PARSERS }->{ ARIN } } }) :
               ( 'whois.internic.net', { %{ $self->{ _PARSERS }->{ INTERNIC } } } ) ;
        
    #figure out what our server and parser should be
    if ($ip) {
       $server= $self->{ Server } ? $self->{ Server } : 'whois.arin.net' ;
    }
    else {
       $domain =~ s/.*\.(\w+\.\w+)$/$1/; #peels off the last two elements
       $server = $self->{ _DOMAIN_ASSOC }->{ $domain };

       unless ($server) { 
          $domain =~ s/.*\.(\w+)$/$1/; #peels off the last element
          $server = $self->{ _DOMAIN_ASSOC }->{ $domain };
       }
    }
    $parser = $self->{ _PARSERS }->{ $self->{ _WHOIS_PARSER }->{ $server } } if ($server);
    #print "domain $domain server $server parser $parser\n";    
    return $server ? [$server, $parser] : [$Dserver, $Dparser];
};

sub new {
    my ( $class, %args ) = @_;

    my $self = {};
    $self->{ _PARSERS } = \%PARSERS;
    $self->{ _DOMAIN_ASSOC } = \%DOMAIN_ASSOC;
    $self->{ _WHOIS_PARSER } = \%WHOIS_PARSER;
    $self->{ _CACHE }   = $args{Cache}   || \$CACHE;
    $self->{ _EXPIRE }  = $args{Expire}  || \$EXPIRE;
    $self->{ _ARGS }    = \%ARGS;

    bless $self, $class;

    $self->personality ( %args );
    $self->lookup () if $self->{ Domain };
    return $self;

}

sub personality {
    my ( $self, %args ) = @_;

    #set all attributes that were passed in
    for ( keys %args ) {chomp $args{ $_} if defined($args{ $_}); $self->{ $_ }=$args{ $_ } }    
    $self->{ Parser } = $self->{ _PARSERS }->{ $args{ Format } }
                        if $args{ Format }; #lets you pick an alternate parser set

    #if we don't have a whois server to use, guess based on the Domain (or IP)
    unless ( $self->{ Server } ) {
        my $res = $self->guess_server_details ( $self->{ Domain } );
        ( $self->{ Server }, undef ) = @$res;
    }

    #if there is already a Parser defined for this server, use it
    if ( $self->{ _PARSERS }->{ $self->{ Server }}) {
        $self->{ Parser } = $self->{ _PARSERS }->{ $self->{ Server }};
    }

    #if we still don't have a Parser to use, guess based on the Domain (or IP)
    unless ( $self->{ Parser } ) {
        my $res = $self->guess_server_details ( $self->{ Domain } );
        ( undef, $self->{ Parser } ) = @$res;
    }

    #set these if they aren't already set
    $self->{ Timeout } = $TIMEOUT unless $self->{ Timeout };
    $self->{ Error }   = $ERROR unless $self->{ Error };
    $self->{ Retries } = $RETRIES unless $self->{ Retries };
}

sub lookup {
    my ( $self, %args ) = @_;
    
    $self->personality ( %args );

    my $cache = $args{ Cache } || ${ $self->{ _CACHE } };
    $self->{ Domain }=~s/^www\.//; #trim leading www. if present; internic doesn't like it
    print "looking up ", $self->{ Domain }, " on ", $self->{ Server }, "\n" if ($self->{ Verbose });
    
    #see if we already have a response in the cache, unless told not to
    unless ( $self->{ Nocache } ) {
      READCACHE: {
        if ( -d $cache ) {
            last READCACHE unless -e "$cache/$domain";
            my $current = time ();
            open D, "$cache/$domain" || last READCACHE;
            my @stat = stat ( D );
            if ( $current - $stat[ 9 ] > ${ $self->{ _EXPIRE } } ) {
                close D;
                last READCACHE;
            }
            undef $/; $self->{ Response } = <D>;
            return 1;
        }
      }
    }

    #connect to whois server
    my $server = $self->{ Server };
    my $suffix = $self->{ _ARGS }->{ $server }->{S} || '';
    my $prefix = $self->{ _ARGS }->{ $server }->{P} || '';
    my $sock = $self->_connect ( $self->{ Server } );
    return undef unless $sock;
    
    #request whois info, then disconnect
    print $sock $prefix , $self->{ Domain }, "$suffix\r\n";
    #print $sock $prefix , $domain, "$suffix\r\n";
    { local $/; undef $/; $self->{  Response  } = <$sock>; }
    close($sock); undef $sock;

    #did we get forwarded?
    my $fw = eval { ($self->forwardwhois)[0] };
    my @fwa = ();
    
    #if ($fw =~ m/\n/) {
    unless (defined($fw) && $fw=~/whois/) { #if forwardwhois is a server, use it; otherwise...
       #ARIN forwarding kludge 08/06/2002 rwoodard
       if ( $self->{ Server } eq "whois.arin.net" ) {
          $fw="whois.apnic.net" if ( $self->{ Response }=~/Asia Pacific Network Information (?:Center|Centre)/misg );
          $fw="whois.ripe.net" if ( $self->{ Response }=~/European Regional Internet Registry|RIPE Network Coordination Centre/misg );
          
          $fw="whois.lacnic.net" if ( $self->{ Response }=~/Latin American and Caribbean IP address Regional Registry/misg );
       }
       
       #APNIC forwarding kludge 08/06/2002 rwoodard
       elsif ($self->{ Server } eq 'whois.apnic.net') {
          $fw="whois.krnic.net" if ($self->{ Response }=~/Allocated to KRNIC/misg );
          $fw="whois.twnic.net" if ($self->{ Response }=~/Allocated to TWNIC/misg );
       }
       else { #original code
          @fwa = $self->{ Response } =~ m/\s+$self->{ Domain }\n.*?\n*?\s*?.*?Whois Server: (.*?)(?=\n)/isg;
          $fw = shift @fwa;
          return undef unless (defined($fw) && length($fw) > 0); # pattern not found
       }
        
       return undef if (defined($fw) && $self->{ Server } eq $fw); #avoid infinite loop
    }
    if ( defined($fw) && $fw ne "" ) {
        $self->personality( Format => $self->{_WHOIS_PARSER}->{$fw});
        return undef if ($self->{ Server } eq $fw); #avoid infinite loop
        $self->{ Server } = $fw; $self->{ Response } = "";
        #$self->lookup();
        print "   forwarded to server $fw\n" if ($self->{ Verbose });
        $self->lookup( Server => "$fw" ); #from Paul Fuchs
    }

    #are there multiple netblocks? If so, do we pursue them? (ARIN only for now)
    if ( $self->{Server} eq 'whois.arin.net' && $self->multiple && $self->{ Bottom_netblock } && $self->net_handle ) {
       my @netblocks=($self->net_handle);
       my $cnt=$#netblocks;
       #print "mult blocks, looking up ", $netblocks[$cnt], " on ", $self->{ Server }, "\n";
       $self->{ Response } = "";
       $self->lookup( Domain => $netblocks[$cnt], Server => $self->{ Server });
    }
    
    #cache the response
    if ( (-d $cache) && (!($self->{Nocache})) ) {
        open D, "> $cache/$domain" || return;
        print D $self->{ Response };
        close D;
    }
    #print "done with lookup\n";
}

sub AUTOLOAD {

    my $self = shift;

    return undef unless $self->{ Response }; #we didn't get a response, nothing to return
    my $key = $AUTOLOAD; 
    $key =~ s/.*://;

    #croak "Method $key not defined" unless exists ${$self->{ Parser }}{$key};
    return undef unless exists ${$self->{ Parser }}{$key}; #don't croak(), just don't do anything
    
    my @matches = ();

    if ( ref(${$self->{ Parser } }{ $key }) !~ /^CODE/  ) { #not an array or hash, i.e. a regexp
       #get everything in the response that matches the regexp; each match is an element in the array
       @matches = $self->{ Response } =~ /${ $self->{ Parser } }{ $key }/sg;
       #print "matches for $key: @matches\n";
    } 
    else { #assumes you have defined your own subroutine with register_parser, pass the whole response to it
       @matches = &{ $self->{ Parser }{$key}}($self->response);
    }

    my @tmp = split /\n/, join "\n", @matches;
    for (@tmp) { s/^\s+//; s/\s+$//; chomp }; #trim leading/trailing whitespace and newline
    #print "tmp: @tmp\n";
    #depending on calling context, return an array or a newline-delimited string
    return wantarray ? @tmp :  join "\n", @tmp ;

}

sub response {

    my $self = shift;
    return $self->{ Response };

}

sub _connect {

    my $self = shift;
    my $machine = shift;
    my $error = $self->{Error};
    my $maxtries = $self->{Retries};
    my $sock;
    my $retries=0;
    
    until ($sock || $retries == $maxtries) {
       #print "   connecting to $machine\n";
       $sock = new IO::Socket::INET PeerAddr => $machine,
                                    PeerPort => 'whois',
                                    Proto    => 'tcp',
                                    Timeout  => $self->{Timeout};
      # or &$error( "[$@]" );
       $retries++ unless ($sock);
       print "try $retries failed\n" if ( $self->{ Verbose } && !$sock);
    }
    &$error( "[$@]" ) unless ($sock);
    
    $sock->autoflush if $sock;
    return $sock;
}

sub ignore {}

sub DESTROY {} #from Gregory Karpinsky

'True Value.';


=head1 NAME

Net::XWhois - Whois Client Interface for Perl5.

=head1 SYNOPSIS

 use Net::XWhois;

 $whois = new Net::XWhois Domain => "vipul.net" ;
 $whois = new Net::XWhois Domain => "bit.ch",
                          Server => "domreg.nic.ch",
                          Retain => 1,
                          Parser => {
                             nameservers => 'nserver:\s+(\S+)',
                          };

=head1 DESCRIPTION

The Net::XWhois class provides a generic client framework for doing Whois
queries and parsing server response.

The class maintains an array of top level domains and whois servers
associated with them. This allows the class to transparently serve
requests for different tlds, selecting servers appropriate for the tld.
The server details are, therefore, hidden from the user and "vipul.net"
(from InterNIC), gov.ru (from RIPE) and "bit.ch" (from domreg.nic.ch) are
queried in the same manner. This behaviour can be overridden by specifying
different bindings at object construction or by registering associations
with the class. See L<"register_associations()"> and L<"new()">.

One of the more important goals of this module is to enable the design of
consistent and predictable interfaces to incompatible whois response
formats. The Whois RFC (954) does not define a template for presenting
server data; consequently there is a large variation in layout styles as
well as content served across servers.

(There is, however, a new standard called RPSL (RFC2622) used by RIPE
(http://www.ripe.net), the European main whois server.)

To overcome this, Net::XWhois maintains another set of tables - parsing
rulesets - for a few, popular response formats. (See L<"%PARSERS">). These
parsing tables contain section names (labels) together with regular
expressions that I<match> the corresponding section text. The section text
is accessed "via" labels which are available as data instance methods at
runtime. By following a consistent nomenclature for labels, semantically
related information encoded in different formats can be accessed with the
same methods.

=head1 CONSTRUCTOR

=over 4

=item new ()

Creates a Net::XWhois object. Takes an optional argument, a hash, that
specifies the domain name to be queried. Calls lookup() if a name is
provided. The argument hash can also specify a whois server, a parsing
rule-set or a parsing rule-set format. (See L<"personality()">). Omitting
the argument will create an "empty" object that can be used for accessing
class data.

=item personality ()

Alters an object's personality.  Takes a hash with following arguments.
(Note: These arguments can also be passed to the constructor).

=over 8

=item B<Domain>

Domain name to be queried.

=item B<Server>

Server to query.

=item B<Parser>

Parsing Rule-set.  See L<"%PARSERS">.

 Parser => {
   name            => 'domain:\s+(\S+)\n',
   nameservers     => 'nserver:\s+(\S+)',
   contact_emails  => 'e-mail:\s+(\S+\@\S+)',
 };


=item B<Format>

A pre-defined parser format like INTERNIC, INTERNIC_FORMAT, RIPE,
RIPE_CH, JAPAN etc.

 Format => 'INTERNIC_CONTACT',

=item B<Nocache>

Force XWhois to ignore the cached records.

=item B<Error>

Determines how a network connection error is handled. By default Net::XWhois
will croak() if it can't connect to the whois server. The Error attribute
specifies a function call name that will be invoked when a network
connection error occurs. Possible values are croak, carp, confess (imported
from Carp.pm) and ignore (a blank function provided by Net::XWhois). You
can, of course, write your own function to do error handling, in which case
you'd have to provide a fully qualified function name. Example:
main::logerr.

=item B<Timeout>

Timeout value for establishing a network connection with the server. The
default value is 60 seconds.

=back

=back

=head1 CLASS DATA & ACCESS METHODS

=over 4

=item %PARSERS

An associative array that contains parsing rule-sets for various response
formats.  Keys of this array are format names and values are hash refs that
contain section labels and corresponding parser code.  The parser code can
either be a regex or a reference to a subroutine.  In the case of a
subroutine, the whois 'response' information is available to the sub in
$_[0].  Parsers can be added and extended with the register_parser() method.
Also see L<Data Instance Methods>.

  my %PARSERS  = (
   INTERNIC => {
    contact_tech    => 'Technical Contact.*?\n(.*?)(?=\...
    contact_zone    => 'Zone Contact.*?\n(.*?)(?=\s*\n[...
    contact_billing => 'Billing Contact.*?\n(.*?)(?=\s*...
    contact_emails  => \&example_email_parser
  },
  { etc. ... },
 );

 sub example_email_parser {

     # Note that the default internal implemenation for
     # the INTERNIC parser is not a user-supplied code
     # block.  This is just an instructive example.

     my @matches = $_[0] =~ /(\S+\@\S+)/sg;
     return @matches;
 }

See XWhois.pm for the complete definition of %PARSERS.

=item %WHOIS_PARSER

%WHOIS_PARSER is a table that associates each whois server with their output format.

    my %WHOIS_PARSER = (
    'whois.ripe.net'       => 'RPSL',
    'whois.nic.mil'        => 'INTERNIC',
    'whois.nic.ad.jp'      => 'JAPAN',
    'whois.domainz.net.nz' => 'GENERIC',
    'whois.nic.gov'        => 'INTERNIC',
    'whois.nic.ch'         => 'RIPE_CH',
    'whois.twnic.net'      => 'TAIWAN',
    'whois.internic.net'   => 'INTERNIC',
    'whois.nic.net.sg'     => 'RIPE',
    'whois.aunic.net'      => 'RIPE',
    'whois.cdnnet.ca'      => 'CANADA',
    'whois.nic.uk'         => 'INTERNIC',
    'whois.krnic.net'      => 'KOREA',
    'whois.isi.edu'        => 'INTERNIC',
    'whois.norid.no'       => 'RPSL',
        ( etc.....)

Please note that there is a plethora of output formats, allthough there
are RFCs on this issue, like for instance RFC2622, there are numerous
different formats being used!

=item %DOMAIN_ASSOC

%DOMAIN_ASSOC is a table that associates top level domain names with their
respective whois servers. You'd need to modity this table if you wish to
extend the module's functionality to handle a new set of domain names. Or
alter existing information. I<register_association()> provides an
interface to this array. See XWhois.pm for the complete definition.

    my %DOMAIN_ASSOC = (
    'al' => 'whois.ripe.net',
    'am' => 'whois.ripe.net',
    'at' => 'whois.ripe.net',
    'au' => 'whois.aunic.net',
    'az' => 'whois.ripe.net',
    'ba' => 'whois.ripe.net',
    'be' => 'whois.ripe.net',


=item register_parser()

Extend, modify and override entries in %PARSERS. Accepts a hash with three
keys - Name, Retain and Parser. If the format definition for the specified
format exists and the Retain key holds a true value, the keys from the
specified Parser are added to the existing definition. A new definition is
created when Retain is false/not specified.

 my $w = new Net::Whois;
 $w->register_parser (
    Name   => "INTERNIC",
    Retain => 1,
    Parser => {
        creation_time => 'created on (\S*?)\.\n',
        some_randome_entity => \&random_entity_subroutine
    };

Instructions on how to create a workable random_entity_subroutine are
availabe in the I<%PARSERS> description, above.

=item register_association()

Override and add entries to %ASSOC. Accepts a hash that contains
representation specs for a whois server. The keys of this hash are server
machine names and values are list-refs to the associated response formats
and the top-level domains handled by the servers. See Net/XWhois.pm for
more details.

 my $w = new Net::XWhois;
 $w->register_association (
     'whois.aunic.net' => [ RIPE, [ qw/au/ ] ]
 );

=item register_cache()

By default, Net::XWhois caches all whois responses and commits them, as
separate files, to /tmp/whois.  register_cache () gets and sets the cache
directory. Setting to "undef" will disable caching.

 $w->register_cache ( "/some/place/else" );
 $w->register_cache ( undef );

=back

=head1 OBJECT METHODS

=over 4

=item B<Data Instance Methods>

Access to the whois response data is provided via AUTOLOADED methods
specified in the Parser. The methods return scalar or list data depending
on the context.


Internic Parser provides the following methods:

=over 8

=item B<name()>

Domain name.

=item B<status()>

Domain Status when provided.  When the domain is on hold, this
method will return "On Hold" string.

=item B<nameservers()>

Nameservers along with their IPs.

=item B<registrant>

Registrant's name and address.

=item B<contact_admin()>

Administrative Contact.

=item B<contact_tech()>

Technical Contact.

=item B<contact_zone()>

Zone Contact.

=item B<contact_billing()>

Billing Contact.

=item B<contact_emails()>

List of email addresses of contacts.

=item B<contact_handles()>

List of contact handles in the response.  Contact and Domain handles
are valid query data that can be used instead of contact and domain
names.

=item B<domain_handles()>

List of domain handles in the response.   Can be used for sorting
out reponses that contain multiple domain names.

=back

=item B<lookup()>

Does a whois lookup on the specified domain.  Takes the same arguments as
new().

 my $w = new Net::XWhois;
 $w->lookup ( Domain => "perl.com" );
 print $w->response ();

=back

=head1 EXAMPLES

Look at example programs that come with this package. "whois" is a
replacement for the standard RIPE/InterNIC whois client. "creation"
overrides the Parser value at object init and gets the Creation Time of an
InterNIC domain. "creation2" does the same thing by extending the Class
Parser. "contacts" queries and prints information about domain's
Tech/Billing/Admin contacts.

contribs/ containts parsers for serveral whois servers, which have not been
patched into the module.

=head1 AUTHOR

Vipul Ved Prakash <mail@vipul.net>

=head1 THANKS

Curt Powell <curt.powell@sierraridge.com>, Matt Spiers
<matt@pavilion.net>, Richard Dice <rdice@pobox.com>, Robert Chalmers
<robert@chalmers.com.au>, Steinar Overbeck Cook <steinar@balder.no>, Steve
Weathers <steve@domainit.com>, Robert Puettmann <rpuettmann@ipm.net>,
Martin H . Sluka" <martin@sluka.de>, Rob Woodard <rwoodard15@attbi.com>,
Jon Gilbert, Erik Aronesty for patches, bug-reports and many cogent
suggestions.

=head1 MAILING LIST

Net::XWhois development has moved to the sourceforge mailing list,
xwhois-devel@lists.sourceforge.net. Please send all Net::XWhois related
communication directly to the list address. The subscription interface is
at: http://lists.sourceforge.net/mailman/listinfo/xwhois-devel

=head1 SEE ALSO

 RFC 954  <http://www.faqs.org/rfcs/rfc954.html>
 RFC 2622 <http://www.faqs.org/rfcs/rfc2622.html>

=head1 COPYRIGHT

Copyright (c) 1998-2001 Vipul Ved Prakash. All rights reserved. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
