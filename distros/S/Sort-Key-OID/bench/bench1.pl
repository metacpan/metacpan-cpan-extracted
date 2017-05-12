#!/usr/bin/perl

use Benchmark qw(cmpthese);

use Sort::Key::Natural qw(natsort);
use Sort::Key::OID qw(oidsort);

my $n = 1000000;

my @data;

for (0..$n) {
    my $l = rand;
    my $len = int(12 * $l * $l * $l * $l);
    push @data,
        join('.',
             map {
                 my $r = rand;
                 int(0xffff * $r * $r * $r * $r * $r * $r)
             } 0..$len);
}

cmpthese(-1, { oidsort => sub { my @sorted = oidsort @data },
               natsort => sub { my @sorted = natsort @data } } );
