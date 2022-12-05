#!/usr/bin/perl
#
# show_queue.pl -- retrieve an RT queue.

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

my $queue;
try {
    $queue = RT::Client::REST::Queue->new(
        rt => $rt,
        id => shift(@ARGV),
    )->retrieve;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

use Data::Dumper;
print Dumper($queue);
