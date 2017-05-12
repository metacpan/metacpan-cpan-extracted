#!/usr/bin/perl

use Storable;

my $ref = retrieve($ARGV[0]);
*fragments = \@{$ref};


print scalar(@fragments) . "\n";


sleep 10;
