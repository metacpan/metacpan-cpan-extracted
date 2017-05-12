#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN { 
  use_ok('RFID::Matrics::CRC');
  use_ok('RFID::Matrics::Tag');
  use_ok('RFID::Matrics::Reader');
  use_ok('RFID::Matrics::Reader::Serial');
  use_ok('RFID::Matrics::Reader::TCP');
  use_ok('RFID::Matrics::Reader::Test');
};


