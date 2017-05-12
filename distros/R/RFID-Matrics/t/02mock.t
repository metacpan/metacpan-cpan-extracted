#!/usr/bin/perl -w

use strict;

use Test::More tests => 22;
use RFID::Matrics::Reader::Test;
use RFID::Matrics::Reader qw(:ant);
use RFID::Matrics::Tag qw(tagcmp);

our $obj = RFID::Matrics::Reader::Test->new(Node => 4,
					    Antenna => 1,
					    Debug => $ENV{MATRICS_DEBUG},
					   );
isa_ok($obj,'RFID::Matrics::Reader::Test');
isa_ok($obj,'RFID::Matrics::Reader');
    
do 't/readertest.pl'
    or die "Couldn't do t/readertest.pl: $@/$!\n";

1;
