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
print $hw->status();
print $hw->initialize();
print $hw->status();


warn "
#
# WARNING!  ARMS WILL MOVE!
# 
";

print "ROBOT ARMS WILL MOVE!!  Is this okay?  (must type 'yes') [no]:";
$_ = <STDIN>;
if (!($_ =~ m/yes/i)) { 
    exit -4;
}

print "Enter tecan commands!\n\n";
while ($_ = <STDIN>) {
    s/[\n\r\t]*//g;
    if (!$_) { last; }
    $hw->Write(split(';'));
    print "\t".$hw->Read()."\n\n";
}

$hw->detach();

1;
