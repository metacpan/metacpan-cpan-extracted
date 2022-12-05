#!/usr/bin/perl
#
# comment_on_ticket.pl -- add comment to an RT ticket.

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless ( @ARGV >= 4 ) {
    die "Usage: $0 username password ticket_id comment\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );
$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

my $ticket = RT::Client::REST::Ticket->new(
    rt => $rt,
    id => shift(@ARGV),
);

try {
    $ticket->comment(
        message => shift(@ARGV),
        cc      => [qw(dmitri@abc.com dmitri@localhost)],
        bcc     => [qw(dmitri@localhost)],
    );
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

use Data::Dumper;
print Dumper($ticket);
