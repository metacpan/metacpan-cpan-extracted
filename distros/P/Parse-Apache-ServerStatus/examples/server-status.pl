#!/usr/bin/perl
use strict;
use warnings;
use Parse::Apache::ServerStatus;

$|++;
my $prs = Parse::Apache::ServerStatus->new(
    url => 'http://localhost/server-status',
    timeout => 10
);

my @order    = qw/p r i _ S R W K D C L G I . ta tt ts bs br/;
my $interval = 10;
my $header   = 20;

while ( 1 ) {
    print map { sprintf("%8s", $_) } @order;
    print "\n";
    for (my $i = 0; $i <= $header; $i++) {
        my $stat = $prs->get or die $prs->errstr;
        print map { sprintf("%8s", $stat->{$_}) } @order;
        print "\n";
        sleep($interval);
    }
}
