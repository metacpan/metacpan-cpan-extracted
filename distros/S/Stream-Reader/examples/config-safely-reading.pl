#!/usr/bin/perl -w

use strict;
use Stream::Reader;

# For example we have possible very big or malformed
# configuration file config.txt, and we want to parse this file
# maximaly safely. This code making that:

my $handler;
open( $handler, '<', 'config.txt' ) or die $!;

my $stream = Stream::Reader->new( $handler, { Limit => 1024*1024 } ); # 1Mb maximum
my $string;
for( 1 .. 1e3 ) { # limit in 1000 iterations
  last unless $stream->readto( "\r\n",
    {
      Out   => \$string,
      Limit => 10*1024 # limit in 10Kb for every string
    }
  );
  # Do something with $string
}

close($handler) or die $!;

# Ps: this is only example and have not actions on errors
