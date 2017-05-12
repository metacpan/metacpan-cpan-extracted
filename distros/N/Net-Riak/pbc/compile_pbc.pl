#!/bin/env perl
use 5.01;
use strict;
use warnings;
use Google::ProtocolBuffers;

my $pbc_definition = "pbc/riakclient.proto";
my $output_file = "lib/Net/Riak/Transport/Message.pm";

say "Compiling Protocol Buffers definition..";

Google::ProtocolBuffers->parsefile(
    $pbc_definition, {
        generate_code => $output_file,
        create_accessors => 1
    }
);

say "done.";

exit;
