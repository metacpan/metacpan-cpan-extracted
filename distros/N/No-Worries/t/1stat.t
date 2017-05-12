#!perl

use strict;
use warnings;
use Test::More tests => 32;
use File::Temp qw(tempdir);
use No::Worries::Dir qw(dir_ensure);
use No::Worries::File qw(file_write);

use No::Worries::Stat qw(*);

our($dir, $path, @stat);

$dir = tempdir(CLEANUP => 1);

# type tests

if (defined(&S_IFREG)) {
    is(stat_type(S_IFREG),  "plain file", "stat_type(plain file)");
} else {
    pass("S_IFREG is not defined");
}
if (defined(&S_IFDIR)) {
    is(stat_type(S_IFDIR),  "directory", "stat_type(directory)");
} else {
    pass("S_IFDIR is not defined");
}
if (defined(&S_IFIFO)) {
    is(stat_type(S_IFIFO),  "pipe", "stat_type(pipe)");
} else {
    pass("S_IFIFO is not defined");
}
if (defined(&S_IFSOCK)) {
    is(stat_type(S_IFSOCK), "socket", "stat_type(socket)");
} else {
    pass("S_IFSOCK is not defined");
}
if (defined(&S_IFBLK)) {
    is(stat_type(S_IFBLK),  "block device", "stat_type(block device)");
} else {
    pass("S_IFBLK is not defined");
}
if (defined(&S_IFCHR)) {
    is(stat_type(S_IFCHR),  "character device", "stat_type(character device)");
} else {
    pass("S_IFCHR is not defined");
}
if (defined(&S_IFLNK)) {
    is(stat_type(S_IFLNK),  "symlink", "stat_type(symlink)");
} else {
    pass("S_IFLNK is not defined");
}
if (defined(&S_IFDOOR)) {
    is(stat_type(S_IFDOOR), "door", "stat_type(door)");
} else {
    pass("S_IFDOOR is not defined");
}
if (defined(&S_IFPORT)) {
    is(stat_type(S_IFPORT), "event port", "stat_type(event port)");
} else {
    pass("S_IFPORT is not defined");
}
if (defined(&S_IFNWK)) {
    is(stat_type(S_IFNWK),  "network file", "stat_type(network file)");
} else {
    pass("S_IFNWK is not defined");
}
if (defined(&S_IFWHT)) {
    is(stat_type(S_IFWHT),  "whiteout", "stat_type(whiteout)");
} else {
    pass("S_IFWHT is not defined");
}

# constants consistency tests

is(S_IRWXU, S_IRUSR | S_IWUSR | S_IXUSR, "S_IRWXU");
is(S_IRWXG, S_IRGRP | S_IWGRP | S_IXGRP, "S_IRWXU");
is(S_IRWXO, S_IROTH | S_IWOTH | S_IXOTH, "S_IRWXU");

# directory tests

$path = "$dir/directory";
dir_ensure($path);
@stat = stat($path);
ok(scalar(@stat), "stat(directory)");
is(stat_type($stat[ST_MODE]), "directory", "type(directory)");
ok(S_ISDIR($stat[ST_MODE]), "S_ISDIR(directory)");
ok(!S_ISREG($stat[ST_MODE]), "!S_ISREG(directory)");

# file tests

$path = "$dir/file";
file_write($path, data => "abc");
@stat = stat($path);
ok(scalar(@stat), "stat(file)");
is(stat_type($stat[ST_MODE]), "plain file", "type(file)");
ok(S_ISREG($stat[ST_MODE]), "S_ISREG(file)");
ok(!S_ISDIR($stat[ST_MODE]), "!S_ISDIR(file)");
is($stat[ST_SIZE], 3, "size(file)");

# ensure tests (chmod() does not work reliably on Windows)

SKIP : {
    skip("stat_ensure() not supported (yet) on $^O", 9)
        if $^O =~ /^(cygwin|dos|MSWin32)$/;
    ok(chmod(0644, $path), "chmod(0644)");

    is(stat_ensure($path, mode => 0644), 0, "stat_ensure(0644)");
    @stat = stat($path);
    is(($stat[ST_MODE] & 07777), 0644, "mode=0644");

    is(stat_ensure($path, mode => "+020"), 1, "stat_ensure(+020)");;
    @stat = stat($path);
    is(($stat[ST_MODE] & 07777), 0664, "mode=0664");

    is(stat_ensure($path, mode => "-" . S_IROTH), 1, "stat_ensure(-S_IROTH)");;
    @stat = stat($path);
    is(($stat[ST_MODE] & 07777), 0660, "mode=0660");

    is(stat_ensure($path, mode => 0751), 1, "stat_ensure(0751)");
    @stat = stat($path);
    is(($stat[ST_MODE] & 07777), 0751, "mode=0751");
}
