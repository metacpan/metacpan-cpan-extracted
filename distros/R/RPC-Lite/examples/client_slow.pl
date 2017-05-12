#!/usr/bin/perl
use strict;

use RPC::Lite::Client;

use Data::Dumper;

my $client = RPC::Lite::Client->new(
                                     {
                                       Transport  => 'TCP:Host=localhost,Port=10000',
                                     }
                                   );    

my $slowResult = $client->Request( 'SlowMethod' );
print "SlowMethod:\n  $slowResult\n\n";

