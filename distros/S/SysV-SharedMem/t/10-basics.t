#!perl

use strict;
use warnings;
use SysV::SharedMem -all;
use Test::More;
use Test::Fatal;
use Test::Warnings;

my $map;
is(exception { shared_open $map, $0, '+>', size => 300, proj_id => 2 }, undef, "can open file '/name'");

{
	local $SIG{SEGV} = sub { die "Got SEGFAULT\n" };
	is(exception { substr $map, 100, 6, "foobar" }, undef, 'Can write to map');
	ok($map =~ /foobar/, 'Can read written data from map');
}

my $stat;
is(exception { $stat = shared_stat($map) }, undef, 'Can stat shared memory');

is $stat->{uid}, $>, 'uid matches process\' uid';

is $stat->{mode} & 0777, 0600, 'Owner can read and write';

is(exception { shared_chmod $map, 0600 }, undef, 'Can chmod shared memory');

is shared_stat($map)->{mode} & 0777, 0600;

is(exception { shared_remove $map }, undef, "Can unlink '/name'");

is(exception { shared_open my $copy, undef, '+<', id => shared_identifier($map) }, undef, 'Can reopen segment');

done_testing();
