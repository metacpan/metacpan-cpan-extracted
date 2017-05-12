#!/usr/bin/perl

# (c) 2003 Luis E. Muñoz. This code is provided AS IS, with absolutely no
# warranty. It can be distributed under the same terms as Perl itself.

# This script tests the behavior of flock() in your installation.

use strict;
use warnings;
use IO::File;
use Fcntl qw(:flock);

our $lock_file = 'test_lck';

				# Get rid of our garbage
END {
    unlink $lock_file;
};

our %fh;
my $id = 'A';
my $pid;
my $buf = 'nothing';

$|++;

				# Spawn one helpful kid...

while (($pid = fork()) == -1)
{
    sleep 2;
}

unless ($pid)
{				# This is our child
    ++ $id;

    END {};

    my $fh = new IO::File "$lock_file", O_RDWR | O_CREAT
	or die "Failed to open $lock_file: $!\n";

    print "$id: about to lock...\n";

    unless (flock($fh, LOCK_EX | LOCK_NB))
    {
	die "$id: Failed to acquire lock: $!\n";
    }

    print "$id: done\n";

    print "$id: wrote\n";
    $fh->syswrite("$id\n", 3);
    print "$id: seeked\n";
    $fh->seek(0, 0);
    sleep 3;
    print "$id: read\n";
    $fh->sysread($buf, 3);
    chomp $buf;

    print "$id: got <$buf>\n";

    flock($fh, LOCK_UN);
    $fh->close;

    exit 0;
}

my $fh = new IO::File "$lock_file", O_RDWR | O_CREAT
    or die "Failed to open $lock_file: $!\n";

print "$id: about to lock...\n";

if (flock($fh, LOCK_EX | LOCK_NB))
{
    print "$id: done\n";

    print "$id: wrote\n";
    $fh->syswrite("$id\n", 3);
    print "$id: seeked\n";
    $fh->seek(0, 0);
    print "$id: read\n";
    $fh->sysread($buf, 3);
    sleep 2;
    chomp $buf;

    print "$id: got <$buf>\n";
    flock($fh, LOCK_UN);
}
else
{
    print "$id: Failed to acquire lock: $!\n";
}

$fh->close;

wait();				# Collect our child status

exit 0;

