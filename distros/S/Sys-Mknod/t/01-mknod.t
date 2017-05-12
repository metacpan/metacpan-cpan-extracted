#   -*- perl -*-

use Test::More tests => 11;
use Fcntl qw(S_IFCHR S_IFIFO S_IFBLK);
use strict;
use warnings;

use_ok("Sys::Mknod");

# on my system, the macro for makedev was broken.
my $val;
eval { $val = Sys::Mknod::make_dev(1,2) };
is ($@, "", "make_dev(1,2)");
ok($val, "make_dev returns a value ($val)");

umask 0;

SKIP: {
    eval { mknod ("/tmp/special", "char", 1, 2, 0600) };
    skip "Failed to make test device nodes; are you root? (error: $@)", 8
	if $@;

my (@stat) = stat "/tmp/special";
is($stat[2] & &S_IFCHR, &S_IFCHR, "Made a character device");
is($stat[6], Sys::Mknod::make_dev(1,2), "Device has correct dev num");
is($stat[2] & 07777, 0600, "Node has correct permissions");
unlink "/tmp/special" or die $!;

eval { mknod ("/tmp/special", "block", 1, 2, 0611) };
die $@ if $@;

@stat = stat "/tmp/special";
is($stat[2] & &S_IFBLK, &S_IFBLK, "Made a block device");
is($stat[6], Sys::Mknod::make_dev(1,2), "Device has correct dev num");
is($stat[2] & 07777, 0611, "Node has correct permissions");
unlink "/tmp/special" or die $!;

eval { mkfifo ("/tmp/fifo") };
@stat = stat "/tmp/fifo";
is($stat[2] & &S_IFIFO, &S_IFIFO, "Made a named pipe");
is($stat[2] & 07777, 0666, "permissions correct");
unlink "/tmp/fifo" or die $!;

}
1;
