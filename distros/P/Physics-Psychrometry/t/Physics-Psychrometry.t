# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Physics-Psychrometry.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Physics::Psychrometry') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $db = 24.6; # C
my $rh = 0.68; # RH 0.0 to 1.0
my $p  = 102;  # kPa

my $e = Physics::Psychrometry::dbrh2e($db, $rh);
ok(closeto($e, 2.104209));

my $dp = Physics::Psychrometry::e2dp($e);
ok(closeto($dp, 18.324036));

my $wb = Physics::Psychrometry::dbdp2wb($db, $dp, $p);
ok(closeto($wb, 20.326262));

my $w = Physics::Psychrometry::e2w($e, $p);
ok(closeto($w, 0.013101));

my $h = Physics::Psychrometry::dbw2h($db, $w);
ok(closeto($h, 58.095979));

my $es = Physics::Psychrometry::t2es($db);
ok(closeto($es, 3.094426));

my $v = Physics::Psychrometry::dbw2v($db, $w, $p);
ok(closeto($v, 0.855627));

my $ws = Physics::Psychrometry::es2ws($es, $p);
ok(closeto($ws, 0.019460));

my $ds = Physics::Psychrometry::rhws2ds($rh, $ws);
ok(closeto($ds, 0.67325951));

my $da = Physics::Psychrometry::wv2da($w, $v);
ok(closeto($da, 1.184046));

my $q = Physics::Psychrometry::w2q($w);
ok(closeto($q, 0.012932));

my $x = Physics::Psychrometry::wv2X($w, $v);
ok(closeto($x, 0.015312));


sub closeto
{
    my ($actual, $expected, $tolerance) = @_;

    print "$actual, $expected\n";
    $tolerance = 0.0001 unless defined $tolerance;

    my $t = $expected * $tolerance;

    return $actual >= ($expected - $t) && $actual <= ($expected + $t);
}

