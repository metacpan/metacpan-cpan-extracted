#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Net::Todoist;

my $nt       = Net::Todoist->new();
my @timezone = $nt->getTimezones();

if (@timezone) {
    ok( grep { $_->[1] and $_->[1] eq "(GMT+0800) Beijing" } @timezone );
}
elsif ( $nt->errstr ) {
    diag( "Warn: " . $nt->errstr );
    ok(1);
}
else {
    fail("Can't get timezones and no HTTP error");
}

done_testing();

1;
