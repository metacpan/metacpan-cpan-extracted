#!/usr/bin/perl
#
# list_transactions.pl -- list transactions associated with a ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Transaction;
use RT::Client::REST::Ticket;

unless (@ARGV >= 3) {
    die "Usage: $0 username password ticket_id\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);

$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

RT::Client::REST::Object->be_transparent($rt);

my $ticket = RT::Client::REST::Ticket->new(id => shift(@ARGV));

my $results;
try {
    $results = $ticket->transactions;#(type => 'Comment');
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message;
};

my $count = $results->count;
print "There are $count transactions\n";

my $iterator = $results->get_iterator;
while (my $tr = &$iterator) {
    print "Id: ", $tr->id, "; Type: ", $tr->type, "\n";
}
