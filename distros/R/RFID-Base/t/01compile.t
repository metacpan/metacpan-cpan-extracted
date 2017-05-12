#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

BEGIN { 
  use_ok('RFID::Tag');
  use_ok('RFID::Reader');
  use_ok('RFID::Reader::TCP');
  use_ok('RFID::Reader::Serial');
  use_ok('RFID::Reader::TestBase');
};
