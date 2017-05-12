#!/usr/bin/perl
#
# edit_ticket.pl -- edit an RT ticket.

use strict;
use warnings;

use RT::Client::REST;
use RT::Client::REST::Ticket;

unless (@ARGV >= 3) {
    die "Usage: $0 username password ticket_id attribute value1, value2..\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

RT::Client::REST::Ticket->be_transparent($rt);

my ($id, $attr, @vals) = @ARGV;
my $ticket = RT::Client::REST::Ticket->new(
    id  => $id,
    $attr, 1 == @vals ? @vals : \@vals,
);

use Data::Dumper;
print Dumper($ticket);
