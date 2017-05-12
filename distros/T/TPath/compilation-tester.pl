#!/usr/bin/perl 
#
# development tool for examining compilation

use v5.10;
use lib qw(t lib);
use ToyXMLForester;

my $f = ToyXMLForester->new;

my @expressions = grep /^\s*+[^#]/, <<'END' =~ /.*/mg;
a[@attr('b') - 1 = 0]
a[@attr('b')=1]
a[:ceil(@attr('b'))=1]
a[:ceil(@attr('b') + 1)=1]
a[b - 1 = 0]
a[b=1]
a[:ceil(b)=1]
a[:ceil(b + 1)=1]
END

for my $expr (@expressions) {
    my $e = $f->path($expr);
    say $e;
}
