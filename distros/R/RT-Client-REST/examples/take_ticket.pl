#!/usr/bin/perl
#
# take_ticket.pl -- take a ticket.

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
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

try {
    RT::Client::REST::Ticket->new(
        rt => $rt,
        id => shift(@ARGV),
    )->take;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};
