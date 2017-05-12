#!/usr/bin/perl
#
# show_queue.pl -- retrieve an RT queue.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Queue;

unless (@ARGV >= 3) {
    die "Usage: $0 username password queue_id\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

my $queue;
try {
    $queue = RT::Client::REST::Queue->new(
        rt  => $rt,
        id  => shift(@ARGV),
    )->retrieve;
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

use Data::Dumper;
print Dumper($queue);
