#!perl

use strict;
use warnings;

# VERSION

my $p1 = Package::Localize->new('Foo');
my $p2 = Package::Localize->new('Foo');

print $p1->inc;
print $p1->inc;

print $p2->inc;