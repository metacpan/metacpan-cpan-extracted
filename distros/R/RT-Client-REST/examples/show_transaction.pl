#!/usr/bin/perl
#
# show_transaction.pl -- retrieve an RT transaction.

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::Transaction;

unless ( @ARGV >= 3 ) {
    die "Usage: $0 username password ticket_id transaction_id\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );
$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

my $tr;
try {
    $tr = RT::Client::REST::Transaction->new(
        rt        => $rt,
        parent_id => shift(@ARGV),
        id        => shift(@ARGV),
    )->retrieve;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

use Data::Dumper;
print Dumper($tr);
