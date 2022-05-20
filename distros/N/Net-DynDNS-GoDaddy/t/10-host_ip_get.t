use warnings;
use strict;

use Mock::Sub;
use Net::DynDNS::GoDaddy;
use Test::More;

my $saved_ip = '10.10.10.10';

# croak
{
    is eval {
        host_ip_get();
        1;
    }, undef, "host_ip_get() croaks if hostname param missing";
    like $@, qr/hostname and domain/, "...and error message is sane";

    is eval {
        host_ip_get('hostname');
        1;
    }, undef, "host_ip_get() croaks if domain name param missing";
    like $@, qr/hostname and domain/, "...and error message is sane";
}

# production (dev only test)
my ($h, $d) = ('dyndns', 'hellbent.app');

if ($ENV{STEVEB_DEV_TESTING}) {
    my $ip = host_ip_get($h, $d);
    is $ip, $saved_ip, "Got the correct IP ok";
}
else {
    warn "STEVEB_DEV_TESTING env var not set, not running live tests";
}

# mocked success
{
    my $m = Mock::Sub->new;
    my $r_sub = $m->mock('HTTP::Tiny::request');

    my $content = '[{ "data": "10.10.10.10" }]';
    $r_sub->return_value({status => 200, content => $content});

    my $ip = host_ip_get($h, $d);
    is $ip, $saved_ip, "Got the correct IP ok (mocked)";
    is $r_sub->called_count, 1, "Mocked sub called ok";
}

done_testing();