#
# ZipLookup.pm
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.com/zip4/
#
# BE SURE TO READ, UNDERSTAND, AND ABIDE BY THE TERMS OF USE FOR THE
# USPS WEB SITE. LINKS ARE PROVIDED IN THE TERMS OF USE SECTION IN THE
# DOCUMENTATION OF THIS PROGRAM, WHICH MAY BE FOUND AT THE END OF THIS
# SOURCE CODE FILE.
#
# Copyright (C) 1999-2012 Gregor N. Purdy, Sr. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
#
# [ $Id$ ]
#

package Scrape::USPS::ZipLookup;

use strict;
use warnings;
use encoding 'utf-8';

our $VERSION = '2.6';

use LWP::UserAgent; # To communicate with USPS and get HTML
use HTTP::Request::Common;
use HTML::TreeBuilder::XPath; # To parse HTML
use XML::XPathEngine; # To extract data

use Scrape::USPS::ZipLookup::Address;

my $start_url = 'https://tools.usps.com/go/ZipLookupAction!input.action?mode=0';


#
# new()
#

sub new
{
  my $class = shift;
  my $self = bless {
    VERBOSE    => 0,
  }, $class;

  return $self;
}


#
# verbose()
#

sub verbose
{
  my $self = shift;

  if (@_) {
    $self->{VERBOSE} = $_[0];
    return $_[0];
  } else {
    return $self->{VERBOSE};
  }
}


#
# dump()
#

sub dump
{
  my $self = shift;
  my ($response) = @_;

  my $request = $response->request;
  
  print "-" x 79, "\n";
  print "HTTP Request:\n";
  $request->dump;
  
  print "-" x 79, "\n";
  print "HTTP Response:\n";
  $response->dump;
}

#
# std_inner()
#
# The inner portion of the process, so it can be shared by
# std_addr() and std_addrs().
#

sub std_inner
{
  my $self = shift;

  #
  # Turn the input into an Address instance:
  #

  my $addr = Scrape::USPS::ZipLookup::Address->new(@_);

  if ($self->verbose) {
    print ' ', '_' x 77, ' ',  "\n";
    print '/', ' ' x 77, '\\', "\n";
    $addr->dump("Input");
    print "\n";
  }

  my $response = undef;
  
  #
  # Submit the form to the USPS web server:
  #
  # Unless we are in verbose mode, we make the WWW::Mechanize user agent be
  # quiet. At the time this was written [2003-01-28], it generates a warning
  # about the "address" form field being read-only if its not in quiet mode.
  #
  # We set the form's Selection field to "1" to indicate that we are doing
  # regular zip code lookup.
  #

  my $ua = LWP::UserAgent->new(cookie_jar => { }); # We need a cookie jar for USPS to let is through
  $response = $ua->get($start_url);
    
  if ($self->verbose) {
    $self->dump($response);
  }

  my $query_url = 'https://tools.usps.com/go/ZipLookupResultsAction!input.action';
  my $temp = POST $query_url, [
    resultMode  => '0',
    companyName => '',
    address1    => $addr->delivery_address // '',
    address2    => '',
    city        => $addr->city // '',
    state       => $addr->state // '',
    urbanCode   => '',
    postalCode  => $addr->zip_code // '',
    zip         => ''
  ];
    
  $response = $ua->request($temp);
  
  if ($self->verbose) {
    $self->dump($response);
  }

  my $content = $response->decoded_content;

  #
  # Time to Parse:
  #

  my @matches;

  my $tree = HTML::TreeBuilder::XPath->new();
  $tree->parse($content);
  my @html_matches = $tree->findnodes('//div[@class="data"]');

  my $xp = XML::XPathEngine->new();

  for my $node (@html_matches) {
#    $node->dump();

    my $firm = undef;
    my $address = undef;
    my $city = undef;
    my $state = undef;
    my $zip4 = undef;
    my $zip = undef;

    my $found;

    $found = $xp->find('p[@class="std-address"]/span[@class="address1 range"]', $node);
    for my $x ($found->get_nodelist) {
      $address = $x->as_trimmed_text();

#      my $firm_node = $xp->find('preceding-sibling::text()', $x);
#      for my $y ($firm_node->get_nodelist) {
#        $firm .= $y->as_trimmed_text();
#      }

      last;
    }

    $found = $xp->find('p[@class="std-address"]/span[@class="city range"]', $node);
    for my $x ($found->get_nodelist) {
      $city = $x->as_trimmed_text();
      last;
    }

    $found = $xp->find('p[@class="std-address"]/span[@class="state range"]', $node);
    for my $x ($found->get_nodelist) {
      $state = $x->as_trimmed_text();
      last;
    }

    $found = $xp->find('p[@class="std-address"]/span[@class="zip4"]', $node);
    for my $x ($found->get_nodelist) {
      $zip4 = $x->as_trimmed_text();
      last;
    }

    $found = $xp->find('p[@class="std-address"]/span[@class="zip"]', $node);
    for my $x ($found->get_nodelist) {
      $zip = $x->as_trimmed_text() . (defined($zip4) ? ('-' . $zip4) : '');
      last;
    }

    my %details;

    my $dts = $xp->find('div/dl[@class="details"]/dt', $node);
    for my $dt ($dts->get_nodelist) {
      my $key = $dt->as_trimmed_text();

      my $dds = $xp->find('following-sibling::dd[1]', $dt);

      for my $dd ($dds->get_nodelist) {
        my $value = $dd->as_trimmed_text();
        $details{$key} = $value;
      }
    }

    my $carrier_route = $details{'Carrier Route'};
    my $county = $details{'County'};
    my $delivery_point = $details{'Delivery Point Code'};
    my $check_digit = $details{'Check Digit'};

    my $commercial_mail_receiving_agency = $details{'Commercial Mail Receiving Agency'};

    my $lac_indicator = $details{"LAC\x{2122}"};
    my $elot_sequence = $details{"eLOT\x{2122}"};
    my $elot_indicator = $details{'eLOT Ascending/Descending Indicator'};
    my $record_type = $details{'Record Type Code'};
    my $pmb_designator = $details{'PMB Designator'};
    my $pmb_number = $details{'PMB Number'};
    my $default_address = $details{'Default Flag'};
    my $early_warning = $details{'EWS Flag'};
    my $valid = $details{'DPV Confirmation Indicator'};

    if ($self->verbose) {
      print("-" x 70, "\n");

      print "Firm:                              $firm\n"                             if defined $firm;

      print "Address:                           $address\n";
      print "City:                              $city\n";
      print "State:                             $state\n";
      print "Zip:                               $zip\n";

      print "Carrier Route:                     $carrier_route\n"                    if defined $carrier_route;
      print "County:                            $county\n"                           if defined $county;
      print "Delivery Point:                    $delivery_point\n"                   if defined $delivery_point;
      print "Check Digit:                       $check_digit\n"                      if defined $check_digit;
      print "Commercial Mail Receiving Agency:  $commercial_mail_receiving_agency\n" if defined $commercial_mail_receiving_agency;
      print "LAC Indicator:                     $lac_indicator\n"                    if defined $lac_indicator;
      print "eLOT Sequence:                     $elot_sequence\n"                    if defined $elot_sequence;
      print "eLOT Indicator:                    $elot_indicator\n"                   if defined $elot_indicator;
      print "Record Type:                       $record_type\n"                      if defined $record_type;
      print "PMB Designator:                    $pmb_designator\n"                   if defined $pmb_designator;
      print "PMB Number:                        $pmb_number\n"                       if defined $pmb_number;
      print "Default Address:                   $default_address\n"                  if defined $default_address;
      print "Early Warning:                     $early_warning\n"                    if defined $early_warning;
      print "Valid:                             $valid\n"                            if defined $valid;

      print "\n";
    }

    my $match = Scrape::USPS::ZipLookup::Address->new($address, $city, $state, $zip);

    $match->firm($firm);

    $match->carrier_route($carrier_route);
    $match->county($county);
    $match->delivery_point($delivery_point);
    $match->check_digit($check_digit);
    $match->commercial_mail_receiving_agency($commercial_mail_receiving_agency);
    $match->lac_indicator($lac_indicator);
    $match->elot_sequence($elot_sequence);
    $match->elot_indicator($elot_indicator);
    $match->record_type($record_type);
    $match->pmb_designator($pmb_designator);
    $match->pmb_number($pmb_number);
    $match->default_address($default_address);
    $match->early_warning($early_warning);
    $match->valid($valid);

    push @matches, $match;
  }

  print('\\', '_' x 77, '/', "\n") if $self->verbose;

  return @matches;
}


#
# std_addr()
#

sub std_addr
{
  my $self = shift;

  return $self->std_inner(@_);
}


#
# std_addrs()
#

sub std_addrs
{
  my $self = shift;

  my @result;

  foreach my $addr (@_) {
    my @addr = $self->std_inner(@$addr);

    push @result, [ @addr ];
  }

  return @result;
}


#
# trim()
#
# A purely internal utility subroutine.
#

sub trim
{
  my $string = shift;
  $string =~ s/\x{a0}/ /sg;   # Remove this odd character.
  $string =~ s/^\s+//s;       # Trim leading whitespace.
  $string =~ s/\s+$//s;       # Trim trailing whitespace.
  $string =~ s/\s+/ /sg;      # Coalesce interior whitespace.
  return $string;
}


#
# Proper module termination:
#

1;

__END__

#
# Documentation:
#

=pod

=head1 NAME

Scrape::USPS::ZipLookup - Standardize U.S. postal addresses.

=head1 SYNOPSIS
  
  #!/usr/bin/perl
  
  use Scrape::USPS::ZipLookup::Address;
  use Scrape::USPS::ZipLookup;
  
  my $addr = Scrape::USPS::ZipLookup::Address->new(
    'Focus Research, Inc.',                # Firm
    '',                                    # Urbanization
    '8080 Beckett Center Drive Suite 203', # Delivery Address
    'West Chester',                        # City
    'OH',                                  # State
    '45069-5001'                           # ZIP Code
  );
  
  my $zlu = Scrape::USPS::ZipLookup->new();
  
  my @matches = $zlu->std_addr($addr);
  
  if (@matches) {
    printf "\n%d matches:\n", scalar(@matches);
    foreach my $match (@matches) {
      print "-" x 39, "\n";
      print $match->to_string;
      print "\n";
    }
    print "-" x 39, "\n";
  }
  else {
    print "No matches!\n";
  }
  
  exit 0;


=head1 DESCRIPTION

The United States Postal Service (USPS) has on its web site an HTML form at
C<http://www.usps.com/zip4/>
for standardizing an address. Given a firm, urbanization, street address,
city, state, and zip, it will put the address into standard form (provided
the address is in their database) and display a page with the resulting
address.

This Perl module provides a programmatic interface to this service, so you
can write a program to process your entire personal address book without
having to manually type them all in to the form.

Because the USPS could change or remove this functionality at any time,
be prepared for the possibility that this code may fail to function. In
fact, as of this version, there is no error checking in place, so if they
do change things, this code will most likely fail in a noisy way. If you
discover that the service has changed, please email the author your findings.

If an error occurs in trying to standardize the address, then no array
will be returned. Otherwise, a four-element array will be returned.

To see debugging output, call C<< $zlu->verbose(1) >>.


=head1 FIELDS

This page at the U.S. Postal Service web site contains definitions of some
of the fields: C<http://zip4.usps.com/zip4/pu_mailing_industry_def.htm>


=head1 TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE PAGE
(AT C<http://www.usps.com/homearea/docs/termsofuse.htm> AT THE TIME THIS TEXT
WAS WRITTEN). IN PARTICULAR, NOTE THAT THEY DO NOT PERMIT THE USE OF THEIR WEB
SITE'S FUNCTIONALITY FOR COMMERCIAL PURPOSES. DO NOT USE THIS CODE IN A WAY
THAT VIOLATES THE TERMS OF USE.

As the user of this code, you are responsible for complying with the most
recent version of the Terms of Use, whether at the URL provided above or
elsewhere if the U.S. Postal Service moves it or updates it. As a convenience,
here is a copy of the most relevant paragraph of the Terms of Use as of
2006-07-04:

  Material on this site is the copyrighted property of the United States
  Postal Service¨ (Postal Serviceª). All rights reserved. The information
  and images presented here may not under any circumstances be reproduced
  or used without prior written permission. Users may view and download
  material from this site only for the following purposes: (a) for personal,
  non-commercial home use; (b) where the materials clearly state that these
  materials may be copied and reproduced according to the terms stated in
  those particular pages; or (c) with the express written permission of the
  Postal Service. In all other cases, you will need written permission from
  the Postal Service to reproduce, republish, upload, post, transmit,
  distribute or publicly display material from this Web site. Users agree not
  to use the site for sale, trade or other commercial purposes. Users may not
  use language that is threatening, abusive, vulgar, discourteous or criminal.
  Users also may not post or transmit information or materials that would
  violate rights of any third party or which contains a virus or other harmful
  component. The Postal Service reserves the right to remove or edit any
  messages or material submitted by users. 

The author believes that the example usage given above does not violate
these terms, but sole responsibility for conforming to the terms of use
belongs to the user of this code, not the author.


=head1 BUG REPORTS

When contacting the author with bug reports, please provide a test address that
exhibits the problem, and make sure it is OK to add that address to the test
suite.

Be sure to let me know if you don't want me to mention your name or email
address when I document the changes and contributions to the release. Typically
I put this information in the CHANGES file.


=head1 AUTHOR

Gregor N. Purdy, Sr. C<gnp@acm.org>.


=head1 COPYRIGHT

Copyright (C) 1999-2012 Gregor N. Purdy, Sr. All rights reserved.

This program is free software. It is subject to the same license as Perl.

=cut


#
# End of file.
#
