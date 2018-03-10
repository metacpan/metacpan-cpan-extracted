#!/usr/bin/env perl

use warnings;
use strict;
use Monitoring::Config;

# read objects
my $conf = Monitoring::Config->new({ obj_dir => $ARGV[0] })->init();

for my $id (@{$conf->{'objects'}->{'bytype'}->{'host'}}) {
    my $host = $conf->get_object_by_id($id);
    $host->{'conf'}->{'contacts'} = ['admin'];
    $host->{'file'}->{'changed'} = 1;
}

for my $id (@{$conf->{'objects'}->{'bytype'}->{'service'}}) {
    my $svc = $conf->get_object_by_id($id);
    $svc->{'conf'}->{'contacts'} = ['webadmin'] if grep(/http/mx, @{$svc->{'conf'}->{'servicegroups'}});
    $svc->{'file'}->{'changed'} = 1;
}

# save back
$conf->commit();
