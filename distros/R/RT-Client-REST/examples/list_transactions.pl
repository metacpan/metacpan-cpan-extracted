#!/usr/bin/perl
#
# list_transactions.pl -- list transactions associated with a ticket.

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::Transaction;
use RT::Client::REST::Ticket;

unless ( @ARGV >= 3 ) {
    die "Usage: $0 username password ticket_id\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );

$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

RT::Client::REST::Object->be_transparent($rt);

my $ticket = RT::Client::REST::Ticket->new( id => shift(@ARGV) );

my $results;
try {
    $results = $ticket->transactions;    #(type => 'Comment');
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

my $count = $results->count;
print "There are $count transactions\n";

my $iterator = $results->get_iterator;
while ( my $tr = &$iterator ) {
    print "Id: ", $tr->id, "; Type: ", $tr->type, "\n";
}
