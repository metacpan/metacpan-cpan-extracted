#!/usr/bin/perl
#
# show_ticket.pl -- retrieve an RT ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless (@ARGV >= 4) {
    die "Usage: $0 username password type_of_object ticket_id\n Example: $0 user pass ticket 888\n";
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
my $type = shift(@ARGV);
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
print Dumper($rt->get_links('type' => $type, 'id' => $id));

