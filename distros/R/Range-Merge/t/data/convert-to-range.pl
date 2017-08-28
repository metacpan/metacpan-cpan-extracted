#!/usr/bin/perl

#
# Copyright (C) 2016 J. Maslak
# All Rights Reserved - See License
#

use Socket;

MAIN: {
    while (my $line=<STDIN>) {
        chomp($line);
        my (@parts) = split /\t/, $line;
       
        my $cidr = shift(@parts); 
        my ($net, $range) = $cidr =~ m/^([\d\.]+)\/(\d+)$/;
        if (!defined($range)) { die("Line $line"); }

        my $begin = unpack('N', inet_aton($net));
        $end = $begin + 2**(32-$range) - 1;

        print "$begin-$end\t", join("\t", @parts), "\n";
    }
}


