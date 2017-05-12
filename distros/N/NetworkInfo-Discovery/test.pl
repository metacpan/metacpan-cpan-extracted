use Test;
#use warnings;
use strict;

use lib qw( ./lib/ );

BEGIN { plan tests => 1 };

use NetworkInfo::Discovery::Register;
use NetworkInfo::Discovery::Sniff;
use NetworkInfo::Discovery::Traceroute;
use NetworkInfo::Discovery::Scan;

ok(1);

my $r = new NetworkInfo::Discovery::Register(autosave=>1, file=>"/tmp/$0.register");
ok(2);

# these should fail
ok(not $r->add_subnet({ip=> '1.1.1.1' }));
ok(not $r->add_subnet({ip=> '2.2.2/5' }));
ok(not $r->add_interface({mask=>'255.255.0.0',dns=>'fail.testhost.com'}) );

# these should work
ok($r->add_subnet({ip=> '3.3.3.3', mask=>'8'})   == 1);
ok($r->add_subnet({ip=> '5.5.5.3', mask => '24'}) == 2);
ok($r->add_subnet({ip=> '128.6.222.28', mask=>'255.255.0.0'}) == 3);
ok($r->has_subnet({ip=>'128.6.222.28', mask=>'16'}) == 3 );

ok($r->add_interface({mac=>'22:50:DA:1A:0C:DD', ip=>'1.1.1.1', mask=>22,dns=>'huh.testhost.com'}) );
ok($r->add_interface({mac=>'22:50:DA:1A:0C:DD', ip=>'1.1.1.1', mask=>22,dns=>'huh.testhost.com'}) );

ok( $r->add_interface({mac=>'00:50:DA:1A:0C:BC',ip=>'128.6.222.28',mask=>'255.255.0.0',dns=>'testhost.com'}) );

ok( $r->add_interface({mac=>'00:50:CA:1A:0C:AA',ip=>'172.16.1.1',mask=>'255.255.255.0',dns=>'yoyo.testhost.com'}) );
ok( $r->add_interface({mac=>'00:50:CA:1A:0C:AA',dns=>'moved.testhost.com'}) );
ok( $r->add_interface({mac=>'00:50:CA:1A:0C:AA', ip=>'172.16.2.1',mask=> 24}) );

ok( $r->add_interface({mac=>'11:50:DA:1A:0C:BB',ip=>'128.6.222.28',mask=>'255.255.0.0',dns=>'testhost.com'}) );
ok( $r->add_interface({ip=>'208.185.38.238'}) );
ok( $r->add_interface({ip=>'192.168.165.37', mask=>'255.255.192.0'}) );
ok( $r->add_interface({ip=>'192.168.164.136', mask=>'255.255.192.0'}) );

ok( $r->has_interface({ip=>'1.1.1.1', mask=>'22'}) );
ok( $r->has_interface({mac=>'11:50:DA:1A:0C:BB'}) );

ok( $r->delete_interface({mac=>'22:50:DA:1A:0C:DD'}) );
ok( $r->delete_interface({ip=>'192.168.164.136'}) );

#ok( $r->add_gateway('22:50:DA:1A:0C:DD') );
ok( $r->add_gateway({ip=>'10.20.1.1'}) );
ok( $r->add_gateway({ip=>'10.90.160.1'}) );
ok( $r->has_gateway({ip=>'10.20.1.1'}) );
#ok( $r->delete_interface({ip=>'10.90.160.1'}) );
ok( $r->has_gateway({ip=>'10.90.160.1'}) );

$r->dump_us;
$r->verify_structure;;
exit;

my $scan = new NetworkInfo::Discovery::Scan;
$scan->hosts(["10.20.1.130", "10.20.1.1", "10.20.1.95"]);

my @hosts = $scan->do_it;

$scan->add_interface($_) foreach (@hosts) ;
$r->dump_us;
$r->verify_structure;;

my $t = new NetworkInfo::Discovery::Traceroute;
$t->max_ttl(5);
$t->host("yahoo.com");
$t->do_it();

@hosts = $t->get_interfaces();
my @gateways = $t->get_gateways();

$r->add_interface($_) for (@hosts);
$r->add_gateway($_) for (@gateways);

$r->dump_us;
$r->verify_structure;;


my $s = new NetworkInfo::Discovery::Sniff;
$s->maxcapture(60);
@hosts = $s->do_it;

foreach (@hosts) {
    $r->add_interface($_);
}
$r->dump_us;
$r->verify_structure;;

