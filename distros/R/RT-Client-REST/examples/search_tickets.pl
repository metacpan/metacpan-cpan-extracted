#!/usr/bin/perl
#
# show_ticket.pl -- retrieve an RT ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless (@ARGV >= 2) {
    die "Usage: $0 username password\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

my $ticket = RT::Client::REST::Ticket->new(rt => $rt);

my $results;
try {
    $results = $ticket->search(
        limits => [
            { attribute => 'id', operator => '>=', value => '1' },
        ],
        orderby => 'subject',
    );
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message;
};

my $count = $results->count;
print "There are $count results that matched your query\n";

my $iterator = $results->get_iterator;
while (my $ticket = &$iterator) {
    print "Id: ", $ticket->id, "; owner: ", $ticket->owner,
        "; Subject: ", $ticket->subject, "\n";
}
