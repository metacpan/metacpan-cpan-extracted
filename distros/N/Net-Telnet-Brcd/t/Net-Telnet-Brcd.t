#!/usr/local/bin/perl
# %W%
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Telnet-Brcd.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use constant DEBUG => $ENV{DEBUG};
use Data::Dumper;
BEGIN { 
   use_ok('Net::Telnet');
   use_ok('Net::Telnet::Brcd');
};
use Net::Telnet::Brcd;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

unless ($ENV{BRCD_USER} && $ENV{BRCD_SWITCH} && $ENV{BRCD_PASS}) {
   plan skip_all => "BRCD_USER, BRCD_SWITCH and BRCD_PASS not set.";
   exit(0);
}

plan tests => 9;

no warnings;

my $brcd = new Net::Telnet::Brcd;
ok($brcd ne undef, "Init brocade");

my $rc   = $brcd->connect();
ok($rc ne undef, "Connect");

my %fabrics = $brcd->fabricShow(-bydomain => 1);
ok(%fabrics ne undef, "fabricShow");
DEBUG && warn "fabricShow, bydomain: ",Dumper(\%fabrics);

my %alias_port = $brcd->aliShow(-byport => 1);
ok(%alias_port ne undef, "aliShow");
DEBUG && warn "aliShow, byport: ", Dumper(\%alias_port);
if (DEBUG) {
   while (my ($port_id, $alias) = each(%alias_port)) {
       my ($domain, $port_number) = $brcd->portAlias($port_id);
       my $fabric = $fabrics{$domain}->{FABRIC};

       warn "$fabric, $port_number\n";
   }
}

my %ports = $brcd->switchShow();
ok(%ports ne undef, "switchShow");
DEBUG && warn "switchShow: ",Dumper(\%ports);
if (DEBUG) {
    foreach my $port (sort {$a <=> $b} keys %ports) {
        my $p_name = $brcd->portShow($port);
        warn $port, ": $p_name = ", Dumper($ports{$port}), "\n";
    }
}
my @rc;
@rc = $brcd->ali(
   -create => 1,
   -name   => "test_net_brcd",
   -members => "30:00:00:00:c9:30:fa:30",
);
my %args;
if (DEBUG) {
    %args = (-verbose => 1);
}
@rc = $brcd->cmd("cfgTransShow");
ok(scalar(@rc) > 0, "aliCreate");
$brcd->cfgSave(%args);
ok(1,"cfgSave with actions");

my @rc = $brcd->ali(
   -delete => 1,
   -name   => "test_net_brcd",
);
@rc = $brcd->cmd("cfgtransshow");
ok(scalar(@rc) > 0, "aliDelete");
$brcd->cfgSave(%args);
$brcd->cfgSave(%args);
ok(1,"cfgSave without actions");
