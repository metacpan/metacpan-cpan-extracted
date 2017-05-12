#!perl
use strict;
use warnings;

use Ruby -all;

my $s = "foobarbaz";

puts $s->gsub(Regexp->new('([fo])'), sub{ $_[0]->succ->upcase });

puts $s->reverse->sub(Regexp->new('a'), 'A');

p(Regexp->new('\w(\w)\w')->match('*foobar*')->to_a);


