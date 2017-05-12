#!/usr/bin/perl -w
# $File: //depot/OurNet-BBSAgent/t/BBSAgent.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 2408 $ $DateTime: 2001/11/23 12:33:47 $

use strict;
use Socket;
use Test::More;

sub _readline {
    my $fh = shift; my $line;

    while ($line = readline(*{$fh})) {
        last unless $line =~ /^#|^[\s\t\r]*$/;
    }

    $line =~ s/\r?\n?$// if defined($line);

    return $line;
}

my $addr;
my %sites = map { 
    open _; _readline(\*_);
    $addr = _readline(\*_);
    (substr($_, rindex($_, '/') + 1) => [$_, (split(':', $addr))[0]]);
} map {
    glob("$_/OurNet/BBSAgent/*.bbs")
} @INC;

plan tests => scalar keys(%sites) + 1;

require_ok('OurNet::BBSAgent');

while (my ($k, $v) = each %sites) { SKIP: {
    my ($site, $addr) = @{$v};
    my $obj;

    skip("not connected to $addr", 1)
	unless (defined Socket::inet_aton($addr));

    skip("$addr is down", 1)
        unless (eval{ $obj = OurNet::BBSAgent->new($site, 10) });

    isa_ok($obj, 'OurNet::BBSAgent', $addr);
} }
