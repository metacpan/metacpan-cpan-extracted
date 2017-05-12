#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

BEGIN { 
  use_ok('RFID::Alien::Reader');
  use_ok('RFID::Alien::Reader::Serial');
  use_ok('RFID::Alien::Reader::TCP');
  use_ok('RFID::Alien::Reader::Test');
};
