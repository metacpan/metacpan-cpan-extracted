use strict;
use warnings;

use Test::More;

use lib '.';
use t::test;

# Tricky: try and see if this user can use ping sockets
plan skip_all => "Not Linux: skipping ping socket tests" unless $^O =~ /linux/;

my $proc = '/proc/sys/net/ipv4/ping_group_range';
open(my $fh, '<', $proc)
    or plan skip_all => "Cannot open $proc ($!): skipping ping socket tests";

my $groups = <$fh>;
defined $groups
    or plan skip_all => "/proc/sys/net/ipv4/ping_group_range is empty: skipping ping socket tests";
$groups =~ /^([0-9]+)\h+([0-9]+)$/
    or plan skip_all => "Cannot parse /proc/sys/net/ipv4/ping_group_range: skipping ping socket tests";
my @gids = split / /, $);
my $user_in_ping_group;
for my $gid (@gids) {
    if ($1 <= $gid && $2 >= $gid) {
        $user_in_ping_group = 1;
        last;
    }
}
$user_in_ping_group
    or plan skip_all => "Current user's group is not allowed to use ping sockets: skipping ping socket tests";

t::test::run_tests('icmp_ps', {
    unreachable => '192.168.0.197',
    reserved    => '192.0.2.0',
});
