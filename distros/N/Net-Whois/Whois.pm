# -*- mode:CPerl -*-
# N.B. revision control headers below reflect only recent work
# $Header
# $Id: Whois.pm,v 1.6 1999/12/01 14:00:51 dhudes Exp dhudes $
# $Log: Whois.pm,v $
#
# Revision 1.6  1999/08/31 11:57:12  dhudes
# Don't require 5.005, only 5.004 and don't do it in a BEGIN
# per CPAN tester pudge@pobox.comm
#
# Revision 1.5  1999/08/29 15:09:26  dhudes
# Fixes for new Network Solutions response when domain unregistered:
# 1. break out of the loop that scans through the leading boilerplate
# when the string "No match" is found as well as when "REGISTRANT" is found.
# 2. If no match, set the MATCH to 0 (if there is a match, MATCH is set to 1)
# and (very important) test this value before looking for the record fields
# If match is 0, skip to the end and bless the structure. Caller tests by invoking the method 'ok' 1 match 0 no match
#
# Revision 1.401  1999/08/13 22:11:39  dhudes
# Revised POD to reflect dual-maintainers
#
# Revision 1.4  1999/08/09 00:05:44  dhudes
# local /$ rather than undef /$
# Thanks to Chris Nandor for pointing this out
#
# Revision 1.3  1999/08/08 22:53:54  dhudes
# change \r and \n in network connection to \x0d\x0a for portability
#
# Revision 1.2  1999/07/25 03:01:04  dhudes
# 1. Fix to address changes by Network Solutions in response to WHOIS requests
# (strip out leading disclaimer)
# 2. fix record created and record created internal tags
# 3. Reformat POD portion
#
# Revision 1.1  1999/07/20 03:54:11  dhudes
# Initial revision
#

package Net::Whois;
require 5.004;
use strict;
use Carp;

=head1 NAME

Net::Whois - Get and parse "whois" domain data from InterNIC

=head1 SYNOPSIS

Note that all fields except "name" and "tag" may be undef
because "whois" information is erratically filled in.

use Net::Whois;
use Carp;

 my $w = new Net::Whois::Domain $dom
 or die "Can't connect to Whois server\n;

 unless ($w->ok) { croak "No match for $dom";}

 print "Domain: ", $w->domain, "\n";
 print "Name: ", $w->name, "\n";
 print "Tag: ", $w->tag, "\n";
 print "Address:\n", map { "    $_\n" } $w->address;
 print "Country: ", $w->country, "\n";
 print "Name Servers:\n", map { "    $$_[0] ($$_[1])\n" }
 @{$w->servers};
 my ($c, $t);
 if ($c = $w->contacts) {
   print "Contacts:\n";
   for $t (sort keys %$c) {
     print "    $t:\n";
     print map { "\t$_\n" } @{$$c{$t}};
   }
 }
 print "Record created:", $w->record_created ;
 print "Record updated:", $w->record_updated ;

=head1 DESCRIPTION

Net::Whois::Domain new() attempts to retrieve and parse the given
domain's "whois" information from the InterNIC (whois.internic.net).
If the server could not be contacted, is too busy, or otherwise does not process
the query then the constructor does not return a reference and your object is undefined.
If the constructor returns a reference, that reference can be used to access the various
attributes of the domains' whois entry assuming that there was a match.
The member function ok returns 1 if a match 0 if no match.

Note that the Locale::Country module (part of the Locale-Codes
distribution) is used to recognize spelled-out country names; if that
module is not present, only two-letter country abbreviations will be
recognized.

The server consulted is "whois.internic.net". You can only
get .org, .edu, .net, .com domains from Internic. Other whois servers
for other Top-Level-Domains (TLD) return information in a different syntax
and are not supported at this time. Also, only queries for domains are
valid. Querying for a network will fail utterly since those are not
kept in the whois.internic.net server (a future enhancement will
add a network lookup function). Querying for NIC handles won't work
since they have a different return syntax than a domain. Domains other
than those listed won't work they're not in the server. A future enhancment
planned will send the query to the appropriate server based on its TLD.


=head1 AUTHOR

Originally written by Chip Salzenberg (chip@pobox.com) 
in April of 1997 for Idle Communications, Inc. 
In September of 1998 Dana Hudes (dhudes@hudes.org) found this
but it was broken and he needed it so he fixed it.
In August, 1999 Dana and Chip agreed to become co-maintainers of the module.
Dana released a new version of Net::Whois to CPAN and resumed active
development. 

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. If you make modifications,
the author would like to know so that they can be incorporated into
future releases.

=cut

use IO::Socket;
use IO::File;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);


$VERSION = '1.9';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = ();

my $server_name = 'whois.internic.net';
my $server_addr;
my %TLDs = ( COM => 'whois.networksolutions.com', NET => 'whois.networksolutions.com', EDU => 'whois.networksolutions.com', ORG => 'whois.networksolutions.com', ARPA =>'whois.arin.net', MIL =>'whois.nic.mil');
my %US_State = (
  AL => 'ALABAMA',
  AK => 'ALASKA',
  AZ => 'ARIZONA',
  AR => 'ARKANSAS',
  CA => 'CALIFORNIA',
  CO => 'COLORADO',
  CT => 'CONNECTICUT',
  DE => 'DELAWARE',
  DC => 'DISTRICT OF COLUMBIA',
  FL => 'FLORIDA',
  GA => 'GEORGIA',
  GU => 'GUAM',
  HI => 'HAWAII',
  ID => 'IDAHO',
  IL => 'ILLINOIS',
  IN => 'INDIANA',
  IA => 'IOWA',
  KS => 'KANSAS',
  KY => 'KENTUCKY',
  LA => 'LOUISIANA',
  ME => 'MAINE',
  MH => 'MARSHALL ISLANDS',
  MD => 'MARYLAND',
  MA => 'MASSACHUSETTS',
  MI => 'MICHIGAN',
  MN => 'MINNESOTA',
  MS => 'MISSISSIPPI',
  MO => 'MISSOURI',
  MT => 'MONTANA',
  'NE' => 'NEBRASKA',
  NV => 'NEVADA',
  NH => 'NEW HAMPSHIRE',
  NJ => 'NEW JERSEY',
  NM => 'NEW MEXICO',
  NY => 'NEW YORK',
  NC => 'NORTH CAROLINA',
  ND => 'NORTH DAKOTA',
  MP => 'NORTHERN MARIANA ISLANDS',
  OH => 'OHIO',
  OK => 'OKLAHOMA',
  OR => 'OREGON',
  PA => 'PENNSYLVANIA',
  PR => 'PUERTO RICO',
  RI => 'RHODE ISLAND',
  SC => 'SOUTH CAROLINA',
  SD => 'SOUTH DAKOTA',
  TN => 'TENNESSEE',
  TX => 'TEXAS',
  UT => 'UTAH',
  VT => 'VERMONT',
  VI => 'VIRGIN ISLANDS',
  VA => 'VIRGINIA',
  WA => 'WASHINGTON',
  WV => 'WEST VIRGINIA',
  WI => 'WISCONSIN',
  WY => 'WYOMING',
);

@US_State{values %US_State} = keys %US_State;


sub _connect {
  unless ($server_addr) {
    my $a = gethostbyname $server_name;
    $server_addr = inet_ntoa($a) if $a;
  }
  $server_addr or croak 'Net::Whois:: no server';
  
  my $sock = IO::Socket::INET->new(PeerAddr => $server_addr,
    PeerPort => 'whois',
  Proto => 'tcp')
  or croak "Net::Whois: Can't connect to $server_name: $@";
  $sock->autoflush;
  $sock;
}

#----------------------------------------------------------------
# Net::Whois::Domain
#----------------------------------------------------------------

package Net::Whois::Domain;
use Carp;

BEGIN {
  if (eval { require Locale::Country }) {
    Locale::Country->import(qw(code2country country2code));
    }else {
    *code2country = sub { ($_[0] =~ /^[^\W\d_]{2}$/i) && $_[0] };
    *country2code = sub { undef };
  }
}

sub new {
  my $class = @_ ? shift : 'Net::Whois';
  @_ == 1 or croak "usage: new $class DOMAIN";
  my ($domain) = @_;
  my $text;
  my $retval;
#  my $FH = new IO::File ">> whois.log" or croak "Could not open log";
  my ($sock, $target_server);
  my @fieldlist; # each element is one part of FQDN e.g. www.smartcard.com would be 3 entries 0-3 [0]=www [1]=smartcard [3]=com
  my $tld;
  my %info;

  @fieldlist = split /\./, $domain;
  eval { # convert to one-entry/one-exit . replace individual out-of-path returns with die. eval will catch them.
    $tld = $fieldlist[$#fieldlist];
    $tld =~ tr /a-z/A-Z/; #uppercase key
    $target_server = $TLDs {$tld};
    $server_name = $target_server if defined $target_server;
    $sock = Net::Whois::_connect();
#    print	$sock "dom $domain\x0d\x0a";
    print       $sock "$domain\x0d\x0a";
    {
        local $/; $text = <$sock>;
    }
    undef	$sock;
    $text || die "No data returned from server";
    
    if ($text =~ /single out one record/) {
      return unless $text =~ /\((.+?)\)[ \t]+\Q$domain\E\x0d?\x0a/i;
      my	$newdomain = $1;
      $sock = Net::Whois::_connect();
      print $sock "dom $newdomain\x0d\x0a";
      {
        local $/; $text = <$sock>;
      }
      undef $sock;
      $text || die "No data from server";
    }
# 7/21/99 Network Solutions now put a bunch of garbage text before the beginning of the actual record
# so we have to spin past it. ARIN records start with registrant name on the 2nd line. Both identify the whois server
# on the first line.
    $text =~ s/^ +//gm;
# if (defined			      $FH) {
#   print			      $FH $text;
# }

    my @text = split / *\x0d?\x0a/, $text;
    for (@text) {s/^ +//}
    my (@t, $t, $c);
    my $flag = 1;
    $t= shift @text;
    until (!defined $t || $t =~ /Registrant/ || $t =~ /No match/)
      {
	$t = shift @text;
    }
    $t =~ s/^\s//;		#trim whitespace
    if ($t eq '') {
      $t = shift @text;
    }
#if domain exists next line up is "Registrant" which we don't want, we want the name and tag of registrant
    $_ = $t;
    if (/Registrant/) {
      $t = shift @text;
      $info{'MATCH'} = 1;
      } elsif (/No match/) {
      $info{'MATCH'} = 0;
    }
    if ($info{'MATCH'} ) { 
    @info{'NAME', 'TAG'} = (	      $t =~ /^(.*)\s+\((\S+)\)$/)
    or die "Registrant Name not found in returned information";
    
    @t = ();
    push @t, shift @text while	      $text[0];
    $t = $t[$#t];
    if (! defined			      $t) {
# do nothing
      } elsif (			      $t =~ /^(?:usa|u\.\s*s\.\s*a\.)$/i) {
      pop @t;
      $t = 'US';
      } elsif (code2country(	      $t)) {
      pop @t;
      $t = uc $t;
      } elsif (			      $c = country2code($t)) {
      pop @t;
      $t = uc $c;
      } elsif (			      $t =~ /,\s*([^,]+?)(?:\s+\d{5}(?:-\d{4})?)?$/) {
      $t = $US_State{uc $1} ? 'US' : undef;
      } else {
      undef			      $t;
    }
    $info{ADDRESS} = [@t];
    $info{COUNTRY} = $t;
    
    while (@text) {
      $t = shift @text;
      next if $t=~ /^$/; #discard blank line
      if ( $t =~ s/^domain name:\s+(\S+)$//i) {
	  $info{DOMAIN}  = $1;
	  $info{DOMAIN} =~ tr/A-Z/a-z/ ;
      } elsif ( $t =~ /contact.*:$/i) {
	  my @ctypes = (	      $t =~ /\b(\S+) contact/ig);
	  my @c;
	  while ( $text[0] ) {
	      last if $text[0] =~ /contact.*:$/i;
	      push @c, shift @text;
	  }
	  @{ $info{CONTACTS} } {map {uc} @ctypes} = (\@c) x @ctypes;
      } elsif (			      $t =~ /^Record created on (\S+)\.$/) {
	  $info{RECORD_CREATED} = $1;
      } elsif (			      $t =~ /^Record last updated on (\S+)\.$/) {
	  $info{RECORD_UPDATED} = $1;
      } elsif (			      $t =~ /^Domain servers/i) {
	  my @s;
	  shift @text unless  $text[0];
	  while ( $t = shift @text) {
	      #translate  to lower case to match useage in DNS
	      $t  =~ tr/A-Z/a-z/;
	      push @s, [split /\s+/,  $t];
	  }
	  $info{SERVERS} = \@s;
      }
    }
	}
  };
  
  if ($@) {
    carp $@;
    undef $retval;
    }
  else {
    $retval = bless [\%info], $class;
  }
  return $retval;
}

sub		    domain {
  my				      $self = shift;
  $self->[0]->{DOMAIN};
}

sub		    name {
  my				      $self = shift;
  $self->[0]->{NAME};
}

sub		    tag {
  my				      $self = shift;
  $self->[0]->{TAG};
}

sub		    address {
  my				      $self = shift;
  my				      $addr = $self->[0]->{ADDRESS};
  wantarray ? @		      $addr : join "\n", @$addr;
}

sub		    country {
  my				      $self = shift;
  $self->[0]->{COUNTRY};
}

sub		    contacts {
  my				      $self = shift;
  $self->[0]->{CONTACTS};
}

sub		    servers {
  my				      $self = shift;
  $self->[0]->{SERVERS};
}

sub		    record_created {
  my				      $self = shift;
  $self->[0]->{RECORD_CREATED};
}

sub		    record_updated {
  my				      $self = shift;
  $self->[0]->{RECORD_UPDATED};
}

sub ok {
  my $self = shift;
  $self->[0]->{MATCH};
}
;









