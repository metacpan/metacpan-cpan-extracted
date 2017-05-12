#!perl

use strict;
use warnings;
use Fcntl qw/O_EXCL/;
use POSIX qw/setlocale LC_ALL/;
use POSIX::RT::SharedMem qw/shared_open shared_unlink/;
use Test::More 0.88;
use Test::Fatal;

setlocale(LC_ALL, 'C');

my $random = int rand 1024;
my $name = "/test-posix-rt-$$-$random";

my $map;

eval { shared_unlink $name }; # pre-delete

is exception { shared_open $map, $name, '+>', size => 300 }, undef, "can open file '$name'";

{
	local $SIG{SEGV} = sub { die "Got SEGFAULT\n" };
	is exception { substr $map, 100, 6, "foobar" }, undef, 'Can write to map';
	ok($map =~ /foobar/, 'Can read written data from map');
}

my ($reader, $fh);
is exception { $fh = shared_open $reader, $name }, undef, 'Can open it readonly';

cmp_ok -s $fh, '>=', 300, 'File is (at least) 300 bytes';
ok -o $fh, 'File is owned by current user';
SKIP: {
	skip 'chmod is broken on ', 1 if $^O eq 'freebsd' or $^O eq 'darwin';
	ok chmod(0644, $fh), 'Can chmod handle';
}

like exception { shared_open my $failer, $name, '+>', flags => O_EXCL, size => 1024 }, qr/File exists/, 'Can\'t exclusively open an existing shared memory object';

is exception { shared_unlink $name }, undef, "Can unlink '$name'";

like exception { shared_open my $failer, $name }, qr/No such/, 'Can\'t open it anymore';

done_testing;
