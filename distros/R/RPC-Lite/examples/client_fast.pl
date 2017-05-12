#!/usr/bin/perl
use strict;

use RPC::Lite::Client;

use Data::Dumper;

my $client = RPC::Lite::Client->new(
                                     {
                                       Transport  => 'TCP:Host=localhost,Port=10000',
                                     }
                                   );    

my $fastResult;

$fastResult = $client->Request( 'FastMethod' );
print "FastMethod 1:\n  $fastResult\n\n";

$fastResult = $client->Request( 'FastMethod' );
print "FastMethod 2:\n  $fastResult\n\n";

$fastResult = $client->Request( 'FastMethod' );
print "FastMethod 3:\n  $fastResult\n\n";

print "sleeping 10 seconds\n";
sleep(10);

$fastResult = $client->Request( 'FastMethod' );
print "FastMethod 4:\n  $fastResult\n\n";
