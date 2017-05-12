#! /usr/bin/perl

use strict;
use warnings;

use Fcntl qw/:flock/;
use File::Temp qw/tempfile/;
use Test::More tests => 5;

use_ok('Parallel::Prefork');

my $reaped = 0;
my $pm;
eval {
    $pm = Parallel::Prefork->new({
        max_workers   => 10,
        fork_delay    => 0,
        on_child_reap => sub {
            $reaped++;
        }
    });
};
ok($pm);

my ($fh, $filename) = tempfile;
syswrite $fh, '0', 1;
close $fh;

my $ppid = $$;

my $c;

until ($pm->signal_received) {
    $pm->start and next;
    open $fh, '+<', $filename
        or die "failed to open temporary file: $filename: ";
    flock $fh, LOCK_EX;
    sysread $fh, $c, 10;
    $c++;
    seek $fh, 0, 0;
    syswrite $fh, $c, length($c);
    flock $fh, LOCK_UN;
    local $SIG{TERM} = sub {
        flock $fh, LOCK_EX;
        seek $fh, 0, 0;
        sysread $fh, $c, 10;
        $c++;
        seek $fh, 0, 0;
        syswrite $fh, $c, length($c);
        flock $fh, LOCK_UN;
        exit 0;
    };
    if ($c == $pm->max_workers) {
        kill 'TERM', $ppid;
    }
    sleep 100;
    $pm->finish;
}
ok(1);
$pm->wait_all_children;

open $fh, '<', $filename
    or die "failed to open temporary file: $filename: ";
sysread $fh, $c, 10;
close $fh;
is($c, $pm->max_workers * 2);
is($reaped, $pm->max_workers, "properly called on_child_reap callback");

unlink $filename;
