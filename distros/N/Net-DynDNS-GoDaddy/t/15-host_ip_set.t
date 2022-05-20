use warnings;
use strict;

use Mock::Sub;
use Net::DynDNS::GoDaddy;
use Test::More;

my $saved_ip = '10.10.10.10';
my $new_ip   = '192.168.0.10';

# croak
{
    is eval {
        host_ip_set();
        1;
    }, undef, "host_ip_set() croaks if hostname param missing";
    like $@, qr/hostname, domain/, "...and error message is sane";

    is eval {
        host_ip_set('hostname');
        1;
    }, undef, "host_ip_set() croaks if domain name param missing";
    like $@, qr/hostname, domain/, "...and error message is sane";

    is eval {
        host_ip_set('hostname', 'domain');
        1;
    }, undef, "host_ip_set() croaks if IP param missing";
    like $@, qr/hostname, domain/, "...and error message is sane";

    is eval {
        host_ip_set('hostname', 'domain', 'aasdf');
        1;
    }, undef, "host_ip_set() croaks if IP param is invalid";
    like $@, qr/invalid IP/, "...and error message is sane";
}

# production (dev only test)
my ($h, $d) = ('dyndns', 'hellbent.app');

if ($ENV{STEVEB_DEV_TESTING}) {
    my $success = host_ip_set($h, $d, $new_ip);
    is $success, 1, "host_ip_set() returned success on new IP ok";

    my $ip = host_ip_get($h, $d);
    is $ip, $new_ip, "Got the new IP ok";

    $success = host_ip_set($h, $d, $saved_ip);
    is $success, 1, "host_ip_set() returned success on saved IP ok";

    $ip = host_ip_get($h, $d);
    is $ip, $saved_ip, "Got the saved IP ok";
}
else {
    warn "STEVEB_DEV_TESTING env var not set, not running live tests";
}

# mocked success
{
    my $m = Mock::Sub->new;
    my $r_sub = $m->mock('HTTP::Tiny::request');

    $r_sub->return_value({status => 200, success => 1});

    my $success = host_ip_set($h, $d, $saved_ip);

    is $success, 1, "host_ip_set() mocked returns ok";
    is $r_sub->called_count, 1, "Mocked sub called ok";
}

done_testing();