#!/usr/bin/perl
#
# show_ticket.pl -- retrieve an RT ticket.

use strict;
use warnings;

use Data::Dumper;
use Error qw(:try);
use RT::Client::REST;

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

my $id = shift(@ARGV);
my @types = @ARGV;

my @ids = $rt->get_transaction_ids(
    parent_id => $id,
    (@types ?
        (1 == @types ?
            (transaction_type => shift(@types))
            : (transaction_type => \@types))
        : ()
    ),
);

for my $tid (@ids) {
    my $t = $rt->get_transaction(parent_id => $id, id => $tid);
    print Dumper($t);
}
