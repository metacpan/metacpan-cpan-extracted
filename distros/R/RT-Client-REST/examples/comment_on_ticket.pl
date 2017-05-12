#!/usr/bin/perl
#
# comment_on_ticket.pl -- add comment to an RT ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless (@ARGV >= 4) {
    die "Usage: $0 username password ticket_id comment\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

my $ticket = RT::Client::REST::Ticket->new(
    rt  => $rt,
    id  => shift(@ARGV),
);

try {
    $ticket->comment(
        message => shift(@ARGV),
        cc  => [qw(dmitri@abc.com dmitri@localhost)],
        bcc => [qw(dmitri@localhost)],
    );
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

use Data::Dumper;
print Dumper($ticket);
