#!/usr/bin/perl
#
# edit_ticket.pl -- edit an RT ticket.

use strict;
use warnings;

use RT::Client::REST;
use RT::Client::REST::Group;

unless (@ARGV >= 3) {
    die "Usage: $0 username password group_id [key-value pairs]\n";
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
    @ARGV
)->store;

use Data::Dumper;
print Dumper($group);
