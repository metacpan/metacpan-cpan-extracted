#!perl -T
# $RedRiver: 60-network-trangolink.t,v 1.2 2008/02/18 19:27:06 andrew Exp $

use Test::More tests => 8;
#use Data::Dumper;

BEGIN {
	use_ok( 'Net::Telnet::Trango' );
}

diag("60: trango-link tests");

SKIP: {
    my $skipped = 7;

    my $type = 'TLink';
    my ($host, $pass) = ('10.150.0.253', '');

    skip "password not set", $skipped if $pass eq '';

    my $t;
    ok($t = Net::Telnet::Trango->new(), "Instantiating object");

    ok($t->open($host), "Opening connection to $host");

    ok($t->is_connected, "connected");

    ok($t->login($pass), "Logging in");

    ok($t->logged_in, "logged in");

    # XXX Additional tests go here.

    my $sysinfo;
    ok($sysinfo = $t->sysinfo, "sysinfo");
    #print Dumper $sysinfo;

    ok($t->bye, "Goodbye");
}
