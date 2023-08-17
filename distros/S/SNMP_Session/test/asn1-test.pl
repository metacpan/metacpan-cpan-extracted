#!/usr/local/bin/perl -w
######################################################################
### Name:	  asn1-test.pl
### Date Created: Sat Feb  1 18:45:38 1997
### Author:	  Simon Leinen  <simon@switch.ch>
### RCS $Id: asn1-test.pl,v 1.3 1997-08-15 23:55:48 simon Exp $
######################################################################

require 5.002;
use strict;
use ASN_1;

my ($result, $index);

($result, $index) = &ASN_1::BER::decode_length ("\x81\x02", 0);
die unless $result == (1 << 7) + 2;
die unless $index == 2;
($result, $index) = &ASN_1::BER::decode ("\x01\x01\x01", 0);
die unless ref($result) eq 'ASN_1::Boolean';
die unless $result->value eq 1;
die unless $index == 3;
($result, $index) = &ASN_1::BER::decode ("\x01\x01\x00", 0);
die unless ref($result) eq 'ASN_1::Boolean';
die unless $result->value eq 0;
die unless $index == 3;
($result, $index) = &ASN_1::BER::decode ("\x10\x03\x01\x01\x00", 0);
die "$result" unless ref($result) eq 'ASN_1::Sequence';
die unless length $result->members == 1;
die unless ref(($result->members)[0]) eq 'ASN_1::Boolean';
die unless ($result->members)[0]->value eq 0;
die unless $index == 5;
1;
