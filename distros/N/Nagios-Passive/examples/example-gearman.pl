#!/usr/bin/env perl

# Check all local ext[234] Filesystems

use Nagios::Passive;
use Nagios::Passive::Gearman;
use Gearman::Client;
use 5.010;
use strict;

# assuming that you have 200 filesystems mounted, and you want
# to monitor the usage of them. Instead of calling 200 times df for each
# filesystem, you call it only once for all filesystems.

my $gearman = Gearman::Client->new;
$gearman->job_servers(['127.0.0.1:4730']);

# linux specific ...
my $cmd = [qw/df -kPT/]; # example output at end of this file
open(my $df, "-|") || exec({ $cmd->[0] } @$cmd);
scalar <$df>; # skip header line
while(defined(my $line = <$df>)) {
    my($mountpoint, $type, $blocks, $used, $available) = split ' ', $line;
    next if $type !~ /\Aext[234]\Z/; # skip everything except ext[234];
    my $np = Nagios::Passive->create(
        gearman => $gearman,
        key => '1vPVrBAA7adUK7cExIVu3jt6RkAwp9g6',
        # you need a service "disk $mountpoint" on localhost configured into nagios
        service_description => "disk $mountpoint",
        host_name           => 'localhost',
        check_name          => "DISKUSAGE",
    );

    # usage >= 91% => warn
    # usage >= 97% => critical
    $np->set_thresholds(warning => ':91', critical => ':97');

    my $usage = sprintf '%.2f', ($used/($used+$available))*100;
    # calculate the value that gets checked against thresholds
    $np->set_status($usage);

    # provide some human readable output
    $np->output(
        sprintf("disk usage: %.2f%% -- %dK used, %dK available",
            $usage, $used, $available)
    );

    # Add performance data
    $np->add_perf(
        label => 'used',
        value => $used,
        uom => 'kB',
    );
    $np->add_perf(
        label => 'available',
        value => $available,
        uom => 'kB',
    );
    $np->add_perf(
        label => 'usage',
        value => $usage,
        uom => '%',
        threshold => $np->threshold,
    );

    print STDERR $np->to_string,"\n" if($ENV{DEBUG});

    # write it into nagios' command pipe
    $np->submit;
}
close($df);

__END__
Filesystem    Type 1024-blocks      Used Available Capacity Mounted on
/dev/mapper/VolGroup-lv_root ext4  13973860   2193576  11070448      17% /
tmpfs        tmpfs      251364         0    251364       0% /dev/shm
/dev/sda1     ext4      495844     69370    400874      15% /boot
tmpfs        tmpfs      251364      2168    249196       1% /opt/omd/sites/mon1/tmp
