#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
#
# 2009-09-03 jcline@ieee.org  Initial version
#  Take sample tray, move to shaker, lock in shaker, remove tray
#  from shaker, return sample tray, park
#

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

$hw->attach("o");
$_ = $hw->status();
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
    exit -3 if !/IDLE/i;
    $hw->status();

    $hw->park("liha");
    $hw->park("roma0");
    checkerr7 $hw->move("roma0", "nonesuch-expect-error7");
    checkok $hw->grip("roma0", 'o', 120);
    checkok $hw->move("roma0", "sampletray-hover");
    checkok $hw->move("roma0", "sampletray-place");
    checkok $hw->grip("roma0");
    checkok $hw->move("roma0", "sampletray-hover");

    checkok $hw->move("roma0", "shaker-hover");
    checkok $hw->move("roma0", "shaker-put");
    checkok $hw->grip("roma0", 'o', 120);

    my @path = (
        "shakerlock-hover", 
        "shakerlock-1",
        "shakerlock-2",
        "shakerlock-3",
        "shakerlock-4",
        "shakerlock-5",
        "shakerlock-hover"
        );
    checkok $hw->move_path("roma0", @path);

    checkok $hw->move("roma0", "shaker-take");
    checkok $hw->grip("roma0");
    checkok $hw->move("roma0", "shaker-hover");

    checkok $hw->move("roma0", "sampletray-hover");
    checkok $hw->move("roma0", "sampletray-place");
    checkok $hw->grip("roma0", 'o', 120);
    checkok $hw->move("roma0", "sampletray-hover");
    checkok $hw->park("roma0");

    checkok $hw->park("liha");

    $hw->detach();

    1;
}

__END__

