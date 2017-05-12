#!/usr/bin/perl
#
# show_ticket.pl -- retrieve an RT ticket.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Attachment;

unless (@ARGV >= 3) {
    die "Usage: $0 username password ticket_id attachment_id\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);
RT::Client::REST::Object->be_transparent($rt);

my $att;
try {
    $att = RT::Client::REST::Attachment->new(
        id  => shift(@ARGV),
        parent_id  => shift(@ARGV),
    );
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

use Data::Dumper;
print Dumper($att);
