#!/usr/bin/env perl

use strict;
use warnings;

use Google::ProtocolBuffers;
my $name = $ARGV[0] or die "no file given\n";

Google::ProtocolBuffers->parsefile(
    $name, 
    { generate_code => ucfirst($name) . '.pm'}
);

exit 0;
