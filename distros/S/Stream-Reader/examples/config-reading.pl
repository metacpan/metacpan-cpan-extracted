#!/usr/bin/perl -w

use strict;
use Stream::Reader;

# This is very simple examle of reading configuration file config.txt

my $handler;
open( $handler, '<', 'config.txt' ) or die $!;

my $stream = Stream::Reader->new( $handler );
my $string;
while( $stream->readto( "\r\n", { Out => \$string } )) {
  # Do something with $string
}

close($handler) or die $!;
