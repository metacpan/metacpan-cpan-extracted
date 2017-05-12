#!/usr/bin/perl
#
# show_ticket.pl -- retrieve an RT ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
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

RT::Client::REST::Object->use_single_rt($rt);
RT::Client::REST::Object->use_autoget(1);
RT::Client::REST::Object->use_autosync(1);

my $ticket;
my $id = shift(@ARGV);
try {
    $ticket = RT::Client::REST::Ticket->new(
        id  => $id,
    );
} catch RT::Client::REST::UnauthorizedActionException with {
    die "You are not authorized to view ticket #$id\n";
} catch RT::Client::REST::Exception with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

use Data::Dumper;
print Dumper($ticket);

for my $cf (sort $ticket->cf) {
    print "Custom field '$cf'=", $ticket->cf($cf), "\n";
}
