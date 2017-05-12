
use strict;
use warnings;

use Test::More;
use NRD::Packet;
use NRD::Serialize;

my $packet = NRD::Packet->new();
my $temp_file = "/tmp/nsca2_test.tmp";
my $message = 'message';
open TEMP, ">", $temp_file or die $!;

my $data = [
        ["hostname", "0", "Plugin output"],
        ["long_output", 0, 'x' x 10240 ],
        ["hostname-with-other-bits", "1", "More data to be read"],
        ["hostname.here", "2", "Check that ; are okay to receive"],
        ["host", "service", 0, "A good result here"],
        ["host54", "service with spaces", 1, "Warning! My flies are undone!"],
        ["host-robin", "service with a :)", 2, "Critical? Alert! Alert!"],
        ["host-batman", "another service", 3, "Unknown - the only way to travel"],
        ["long_output", "service1", 0, 'x' x 10240 ], #10K of plugin output
        ];
plan tests => scalar(@$data);

my $ser = NRD::Serialize->instance_of('plain', { });
foreach my $d (@$data){
    print TEMP $packet->pack($ser->freeze($d));
}
close TEMP;

open TEMP2, "<", $temp_file or die "$!";

foreach my $d (@$data){
  is_deeply($d, $ser->unfreeze($packet->unpack(*TEMP2)), 'recovered packet is the same as the packed one');
}

close TEMP2;
#unlink $temp_file or die $!;
