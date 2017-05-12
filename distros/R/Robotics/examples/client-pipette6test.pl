#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use lib '../lib';
use Robotics;

print "Testing Robotics $Robotics::VERSION, Perl $], $^X\n";
my $obj = Robotics->new();
print "Hardware: ". $obj->printDevices();
my $gemini;
my $hw;
if ($gemini = $obj->findDevice(product => "Gemini")) { 
    print "Found local Gemini $gemini\n";
    my $genesis = $obj->findDevice(product => "Genesis");
    $hw = Robotics::Tecan->new(
        connection => $gemini);
}
else {
    print "No Gemini found, opening network client\n";
    $hw = Robotics::Tecan->new(
        connection => 'network,Robotics::Tecan::Genesis,genesis0',
        token => 'M1',
        serveraddr => 'heavybio.dyndns.org:8088',
        password => $ENV{'TECANPASSWORD'});
}

if (!$hw) { 
    die "fail to connect\n";
}
print "Managing hardware\n";
my $manager = Robotics->new(
        device => $hw,
        alias => "worker1");

print "Attaching to hardware\n";
print $hw->attach();
print $hw->status();
print $hw->initialize();
print $hw->status();

warn "
#
# WARNING!  ARMS WILL MOVE!
# 
";

#print "ROBOT ARMS WILL MOVE!!  Is this okay?  (must type 'yes') [no]:";
#$_ = <STDIN>;
#if (!($_ =~ m/yes/i)) { 
#    exit -4;
#}

$hw->configure("client-traymove1test.yaml");

print "\n\n\n\n";
my $result;
$hw->command("ROMA_PARK", grippos => "0"); print "\t".$hw->Read()."\n\n";
$hw->command("ROMA_PARK", grippos => "1"); print "\t".$hw->Read()."\n\n";
$hw->command("ROMA_PARK", grippos => "2"); print "\t".$hw->Read()."\n\n";
$hw->park();

$wellmax = $ARGV[0] || 96;
for $well (1 .. $wellmax) { 
    $result = $hw->aspirate(
            on => "JCplateholder", 
            at => "JCgreinerVbottom96", 
            position => "1,2,1",
            wellnum => $well, volume => "100u"); 
    print "Aspirate: $result\n";

    $result = $hw->dispense(
            on => "JCplateholder", 
            at => "JCgreinerVbottom96", 
            position => "1,2,1",
            wellnum => $well, volume => "100u"); 
    print "Dispense: $result\n";
}

$hw->park("liha0");
$hw->detach();

1;

