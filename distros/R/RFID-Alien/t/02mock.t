#!/usr/bin/perl -w

use strict;

use Test::More tests => 41;
use RFID::Alien::Reader::Test;
use RFID::EPC::Tag;

our $obj = RFID::Alien::Reader::Test->new(node => 4,
					  debug => $ENV{ALIEN_DEBUG},
					  antenna => 1,
					 );
isa_ok($obj,'RFID::Alien::Reader::Test');
isa_ok($obj,'RFID::Alien::Reader');

do 't/readertest.pl'
    or die "Couldn't do t/readertest.pl: $@/$!\n";

1;
