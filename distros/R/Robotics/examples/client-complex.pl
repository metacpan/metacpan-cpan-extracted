#!perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use lib '../lib';
use Robotics;
use Robotics::Tecan;

print "Testing Robotics $Robotics::VERSION, Perl $], $^X\n";

my $hw = Robotics::Tecan->new(
    'server' => 'heavybio.dyndns.org:8088',
    'password' => $ENV{'TECANPASSWORD'});

if (!$hw) { 
    die "fail to connect\n";
}

$hw->attach();
$_ = $hw->status();
exit if !/IDLE/i;


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

$hw->status();
#$hw->initialize();
$_ = $hw->status();
exit if !/IDLE/i;

$hw->park("roma0");
$hw->move("roma0", "nonesuch");
$hw->grip("roma0", "o", 120);
$hw->move("roma0", "jc-traypickup", "e", 2);
$hw->grip("roma0", "c", 112);
$hw->move("roma0", "jc-traypickup", "s");
$hw->park("roma0");
$hw->move("roma0", "jc-traypickup", "e", 2);
$hw->grip("roma0", "o", 120);
$hw->move("roma0", "jc-traypickup", "s", 2);
$hw->park("roma0");

$hw->park("liha");
$hw->tip_query();
$hw->tip_get("1", 0, 0);


$hw->detach();

1;
__END__

