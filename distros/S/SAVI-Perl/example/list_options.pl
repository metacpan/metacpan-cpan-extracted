#!/usr/local/bin/perl -w

use SAVI;
use strict;

my $savi = new SAVI();

ref $savi or print "Error initializing savi: " . SAVI->error_string($savi) . " ($savi)\n" and die;

printf("%-25s\tSetting\n", "Option");
print '-' x 39 . "\n";

foreach ($savi->options()) {
    my ($value, $status) = $savi->get($_);
    defined($value) or print "Error getting option $_ " . $savi->error_string($status) . " ($status)\n" and next;
    printf("%-25s\t$value\n", $_);
}
