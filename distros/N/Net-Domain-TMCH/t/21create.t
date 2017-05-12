#!/usr/bin/env perl
# Create an SMD structure
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';
use Test::More skip_all => 'creation is work in progress'; # tests => 14;
use XML::LibXML;

use Net::Domain::TMCH;
my $tmch = Net::Domain::TMCH->new
  ( tmv_certificate => 't/21cert/server.crt'
  );

# Have a look at the two templates in examples/ which show the expected
# data-structure.  Best to break the construction up into understandable
# components, as show below.  The fields here are mimicing the example SMD
# in t/20ok.smd

# Some static timestamps, for fixed output
my $prodate    = 1389770000;
my $begin      = 1389777913;
my $end        = $begin + 10_000;

my %issuer     =
  ( smd_org        => 'My own TMV'
  , smd_email      => 'notavailable@exmaple.com'
  , smd_url        => 'http://example.com'
  , smd_voice      => '+32.0000000'
  , issuerID       => '65535'          # attributes not ns-prefixed
  );

my (@holders, @contacts, @labels);

my %holder =
  ( name           => 'Frank White'
  , org            => 'Test Organization'
  , addr           =>
     +{ street => '101 West Arques Avenue'
      , city   => 'Sunnyvale'
      , sp     => 'CA'
      , pc     => '10023-3241'
      , cc     => 'US'
      }
  , voice          => '+1.3014556600'
  , fax            => '+1.3014556601'
  , email          => 'info@example.example'
  );

push @holders, \%holder;
push @labels, qw/test---validate test--validate test-and-validate/;


my (@trademark, @treaty, @court);
my %court      =
 +( id              => '0000001711373633628408-65535'
  , markName        => 'Test & Validate'
  , holder          => \@holders
  , contact         => \@contacts
  , label           => \@labels
  , goodsAndServices=> 'Musical instruments'
  , refNum          => 1234
  , proDate         => $prodate
  , cc              => 'US'
  , courtName       => 'Hove'
  );
push @court, \%court;

my %mark       =
  ( trademark       => \@trademark
  , treatyOrStatute => \@treaty
  , court           => \@court
  );

my %signedMark =
  ( id => 'my42'
  , smd_id         => '2348791986796-123243'
  , smd_issuerInfo => \%issuer
  , smd_notBefore  => $begin
  , smd_notAfter   => $end
  , mark           => \%mark
  );

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
my $xml = $tmch->createSignedMark
  ( $doc
  , \%signedMark
  );

warn $xml->toString(1);
