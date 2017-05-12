#!/usr/bin/perl
#
# show_group.pl -- retrieve an RT group.

use strict;
use warnings;

use RT::Client::REST;
use RT::Client::REST::Group;

unless (@ARGV >= 3) {
    die "Usage: $0 username password group_id\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

my $group = RT::Client::REST::Group->new(
    rt  => $rt,
    id  => shift(@ARGV),
)->retrieve;

use Data::Dumper;
print Dumper($group);
