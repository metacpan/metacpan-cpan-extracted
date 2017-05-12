#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 20;
use Regexp::Common qw(VATIN);

ok 'DE123456789' =~ /^$RE{VATIN}{DE}$/;
ok 'DE123456789' =~ /^$RE{VATIN}{any}$/;
ok 'DE12345678' !~ /^$RE{VATIN}{DE}$/;
ok 'DE1234567890' !~ /^$RE{VATIN}{any}$/;

ok 'GBGD123' =~ $RE{VATIN}{GB};      # United Kingdom
ok 'GBGD1234' =~ $RE{VATIN}{GB};     # pattern needs line anchors:
ok 'GBGD123' =~ /^$RE{VATIN}{GB}$/;  # <--
ok 'GBGD1234' !~ /^$RE{VATIN}{GB}$/; # <--

ok 'GB123456789' =~ /^$RE{VATIN}{IM}$/;    # Isle of Man (use 'GB' as prefix)
ok 'GBGD1234' !~ /^$RE{VATIN}{IT}$/;       # Italy
ok 'NL999999999B99' =~ /^$RE{VATIN}{NL}$/; # Netherlands
ok 'ESA9999999B' =~ /^$RE{VATIN}{ES}$/;    # Spain

ok 'EL123456789' =~ /^$RE{VATIN}{EL}$/;    # Greece!
ok 'EL123456789' =~ /^$RE{VATIN}{GR}$/;    # Greece with ISO-3166 code
ok 'GR123456789' !~ /^$RE{VATIN}{GR}$/;    # VATIN prefix still requires 'EL'

ok 'HR12345678901' =~ /^$RE{VATIN}{HR}$/;  # Croatia

ok 'IE1234567X' =~ /^$RE{VATIN}{IE}$/;  # Ireland
ok 'IE1234567WI' =~ /^$RE{VATIN}{IE}$/; # Ireland
ok 'IE1X34567Y'  =~ /^$RE{VATIN}{IE}$/; # Ireland
ok 'IE1234567AB' =~ /^$RE{VATIN}{IE}$/; # Ireland
