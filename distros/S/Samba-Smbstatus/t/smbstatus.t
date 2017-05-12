#!env perl
use strict;
use warnings;
use utf8;

use Test::More;

use_ok ('Samba::Smbstatus');

my $status = Samba::Smbstatus->new;
$status->_build__all_data(smbstatus1());

my @locks = ();

foreach my $l (@{$status->locks}) {
    my $path = $l->{share} . '/' . $l->{name};
    push @locks, $path;
}

is_deeply([sort @locks], [
    '/home/ann/engravings/pasta',
    '/home/joe/sawing',
    '/home/sharon/Games/Barn Storm Cats/Logs/Sharon/2014-04-20.txt',
    ], 'Found locked files');

my %users = map { $_->{pid}, $_ } @{$status->users};
is_deeply($users{28660},
    {
        pid => 28660,
        username => 'joe',
        group => 'wrkgroup',
        machine => 'smell',
        ip => '192.168.0.53',
    },
    'joe user matches');

is_deeply(
    $status->services->[0],
    {
        service => 'picklefoot',
        pid => 28660,
        machine => 'smell',
        connected => 'Sun Apr 20 09:08:05 2014',
    },
    'picklefoot service matches'
);

done_testing;

sub smbstatus1 {
    return [ split(/\n/, <<'SMB1')];
NOTE: Service profiles is flagged unavailable.
NOTE: Service groups is flagged unavailable.

Samba version 3.6.7-48.28.1-3108-SUSE-SL12.2-x86_64
PID     Username      Group         Machine                        
-------------------------------------------------------------------
28660     joe           wrkgroup      smell        (192.168.0.53)
23679     sharon        wrkgroup      the-pickle   (192.168.0.40)

Service      pid     machine       Connected at
-------------------------------------------------------
picklefoot   28660   smell         Sun Apr 20 09:08:05 2014
sharon       23679   the-pickle    Sat Apr 19 17:45:34 2014
ann          28660   smell         Sun Apr 20 09:08:05 2014
joe          28660   smell         Sun Apr 20 09:08:05 2014
ann          23679   the-pickle    Sat Apr 19 09:55:23 2014
IPC$         22529   the-pickle    Sat Apr 26 15:26:57 2014

Locked files:
Pid          Uid        DenyMode   Access      R/W        Oplock           SharePath   Name   Time
--------------------------------------------------------------------------------------------------
23679        1001       DENY_NONE  0x2019f     RDWR       EXCLUSIVE+BATCH  /home/sharon   Games/Barn Storm Cats/Logs/Sharon/2014-04-20.txt   Sun Apr 20 13:57:15 2014
23679        1001       DENY_NONE  0x100081    RDONLY     NONE             /home/ann   engravings/pasta   Sat Apr 19 09:55:23 2014
28660        1000       DENY_NONE  0x100081    RDONLY     NONE             /home/joe   sawing   Sun Apr 20 09:08:07 2014
SMB1
}
