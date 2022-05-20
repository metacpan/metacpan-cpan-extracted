use warnings;
use strict;

use Hook::Output::Tiny;
use Mock::Sub;
use Net::DynDNS::GoDaddy;
use Test::More;

my ($h, $d) = ('test', 'example.com');
my $hook = Hook::Output::Tiny->new;

{
    my $m = Mock::Sub->new;
    my $r_sub = $m->mock('HTTP::Tiny::request');

    my $content = 'Unauthorized';
    $r_sub->return_value({status => 403, content => $content});

    $hook->hook;
    my $ip = host_ip_get($h, $d);
    $hook->unhook;

    my @err = $hook->stderr;

    is $r_sub->called_count, 1, "Mocked sub called ok";

    like
        $err[0],
        qr/Failed to connect.*Unauthorized/,
        "On non-200 status, warning is displayed correctly"
}

done_testing();