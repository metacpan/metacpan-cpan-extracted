#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use lib '../lib';
use Robotics;
use Robotics::Tecan;

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

$hw->attach();
$_ = $hw->status();
print;
exit -2 if !/IDLE/i;

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

&Main;
exit 0;

sub checkok {
    my $s = @_[0];
    my $want = "0";
    if (!grep(/$want/, $s)) { 
        die "Robot err $s, wanted $want\n";
    }
    else {
        warn "Got: $s\n";
    }
}
sub checkerr7 {
    my $s = @_[0];
    my $want = "7";
    if (!grep(/$want/, $s)) { 
        die "Robot err $s, wanted $want\n";
    }
    else {
        warn "Got: $s\n";
    }

}

sub Main {

    $hw->status();
    $_ = $hw->initialize();
    #exit -3 if !/IDLE/i;
    $_ = $hw->status();
    exit -3 if !/IDLE/i;

    $hw->park("roma0");
    checkerr7 $hw->move(motor => "roma0", to => "nonesuch-expect-error7");
    checkok $hw->grip("roma0", 'o', 120);
    checkok $hw->move(motor => "roma0", to => "jc-traypickup", dir => 'e', site => 1);
    checkok $hw->grip("roma0");
    checkok $hw->move(motor => "roma0", to => "jc-traypickup", dir => 's', site => 1);
    checkok $hw->park("roma0");

    checkok $hw->park("liha");



    $hw->detach();

    1;
}

__END__

