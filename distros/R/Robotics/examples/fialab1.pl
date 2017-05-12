#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use lib '../lib';
use Robotics;

print "Testing Robotics $Robotics::VERSION, Perl $], $^X\n";
my $obj = Robotics->new();
print "Hardware: ". $obj->printDevices();
my $gemini;
my $tecan;
if ($gemini = $obj->findDevice(product => "Gemini")) { 
    print "Found local Gemini $gemini\n";
    my $genesis = $obj->findDevice(product => "Genesis");
    $tecan = Robotics::Tecan->new(
        connection => $gemini);
}
else {
    print "No Gemini found\n";
    if (0) { 
        $tecan = Robotics::Tecan->new(
            connection => 'network,Robotics::Tecan::Genesis,genesis0',
            token => 'M1',
            serveraddr => 'heavybio.dyndns.org:8088',
            password => $ENV{'ROBOTICSPASSWORD'});
    }
}
my $fialab;
my $sia;
if ($fialab = $obj->findDevice(product => "Microsia")) { 
    print "Found local FIALab syringe+valve device $fialab\n";
    $sv = Robotics::Fialab->new(
        connection => $fialab);
}
else {
    print "No FIALab device found; opening network connection\n";
    if (0) { 
        $sia = Robotics::Fialab->new(
            connection => 'network,Robotics::Fialab::Microsia,sia0,option=sv',
            token => 'M1',
            serveraddr => 'heavybio.dyndns.org:8089',
            password => $ENV{'ROBOTICSPASSWORD'});
    }
}


print "Managing hardware\n";
my $manager = Robotics->new(
        device => $sv,
        alias => "syringe-valve1");

print "Attaching to hardware\n";
if ($tecan) { 
    print $tecan->attach();
    print $tecan->status();
    print $tecan->status();
    print $tecan->initialize();
    print $tecan->status();
}

warn "
#
# WARNING!  HARDWARE WILL RUN!
# 
";

print "HARDWARE WILL ACTIVATE!!  Is this okay?  (must type 'yes') [no]:";
$_ = <STDIN>;
if (!($_ =~ m/yes/i)) { 
    exit -4;
}
if ($tecan) { 
    $tecan->command("ROMA_PARK", grippos => "0"); print "\t".$tecan->Read()."\n\n";
    $tecan->command("ROMA_PARK", grippos => "1"); print "\t".$tecan->Read()."\n\n";
    $tecan->command("ROMA_PARK", grippos => "2"); print "\t".$tecan->Read()."\n\n";
    $tecan->park();
    $tecan->dispense();
    $tecan->detach();
}
if ($sv) { 
    $sv->attach();

    my $response;

    print "-- Valve operation\n";
    $response = $sv->literal("NP_SET", address => "valve", numport => "10");
    print "$response\n";
    $response = $sv->literal("GET_POS");
    print "$response\n";
    $response = $sv->literal("MOVE_CCW", pos => "9");
    print "$response\n";
    $response = $sv->literal("MOVE_CCW", pos => "1");
    print "$response\n";

    print "-- Peristaltic operation\n";
    $response = $sv->literal("SET_SPEED", address => "peristaltic", speed => "99");
    print "$response\n";

    print "-- Syringe operation\n";
    $response = $sv->literal("GET_STATUS", address => "syringe");
    print "$response\n";
    $response = $sv->literal("SET_SPEED", speed => 4200);
    print "$response\n";

    print "-- Valve operation\n";
    $response = $sv->literal("MOVE_DIRECT", address => "valve", pos => "2");
    print "$response\n";
    $response = $sv->literal("MOVE_DIRECT", pos => "7");
    print "$response\n";

    $sv->detach();
}

1;

