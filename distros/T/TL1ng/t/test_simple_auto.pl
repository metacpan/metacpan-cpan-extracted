#!/usr/bin/perl -w

use TL1ng;
use Data::Dumper;

$| = 1;  # Autoflush STDOUT

my $tl1 = TL1ng->new({
    timeout => 10,
    hostname => '127.0.0.1',
    port => 12345,
    source => 'Telnet',
    type => 'Base',
    connect => 1,
    });

print "TL1 Connection opened\n" if $tl1->source()->connected();

my $cmd = "ACT-USER:DUMMYTID:DUMMYUSER:" . $tl1->rand_ctag() . "::DUMMYPASS;";
print "Sending command: $cmd\n";
$tl1->send_cmd($cmd);

print "Last sent CTAG: " . $tl1->last_ctag() . "\n\n";


while($tl1->source()->connected()) {
    while(my $msg = $tl1->get_next()){
        print Dumper $msg;
    }
}



