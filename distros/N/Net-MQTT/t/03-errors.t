#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use warnings;
use strict;
use Test::More tests => 7;

use_ok('Net::MQTT::Constants');
use_ok('Net::MQTT::Message');

my $offset = 0;
is(test_error(sub { decode_byte('', \$offset) }),
   'decode_byte: insufficient data', 'decode_byte error');
is(test_error(sub { decode_short('1', \$offset) }),
   'decode_short: insufficient data', 'decode_short error');
is(test_error(sub { decode_string((pack 'H*', '00'), \$offset) }),
   'decode_short: insufficient data', 'decode_string error in short');
is(test_error(sub { decode_string((pack 'H*', '000201'), \$offset) }),
   'decode_string: insufficient data', 'decode_string error in string');

is(Net::MQTT::Message->new_from_bytes(pack "H*", "C080"), undef,
   'just return undef if we are decoding remaining length');

sub test_error {
  eval { shift->() };
  local $_ = $@;
  s/\s+at\s.*$//s;
  $_;
}
