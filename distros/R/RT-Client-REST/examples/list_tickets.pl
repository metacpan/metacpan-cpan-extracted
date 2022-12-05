#!/usr/bin/perl
#
# list_tickets.pl -- list tickets in a queue

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::Queue;

unless ( @ARGV >= 3 ) {
    die "Usage: $0 username password queue_id\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );

$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

my $queue = RT::Client::REST::Queue->new( rt => $rt, id => shift(@ARGV) );

my $results;
try {
    $results = $queue->tickets;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

my $count = $results->count;
print "There are $count tickets\n";

my $iterator = $results->get_iterator;
while ( my $t = &$iterator ) {
    print "Id: ", $t->id, "; Status: ", $t->status,
      "; Subject ", $t->subject, "\n";
}
