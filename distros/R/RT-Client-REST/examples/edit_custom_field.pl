#!/usr/bin/perl
#
# edit_custom_field.pl -- set one or more custom fields

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless (@ARGV >= 3) {
    die "Usage: $0 username password ticket_id [key-value pairs]\n";
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

my %opts = @ARGV;
while (my ($cf, $value) = each(%opts)) {
    $ticket->cf($cf, $value);
}

try {
    $ticket->store;
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

use Data::Dumper;
print Dumper($ticket);
