#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests=>6;

use Sub::Curried;

curry append  ($r, $l) { $l . $r }
curry prepend ($l, $r) { $l . $r }

my $ciao = append('!') << prepend('Ciao ');
is $ciao->('Bella'), 'Ciao Bella!', 'Simple composition';

my $fn2 = prepend('Hi ') << curry ($l, $r) { $l . $r }->('M');
is $fn2->('um'), 'Hi Mum', 'Composition including an anonymous function';

my $fn3 = prepend('Hi ') << curry ($l, $r) { $l . $r };
is $fn3->('M', 'um'), 'Hi Mum', 'Composition including an anonymous function';

my $fn4 = sub { 'un'.$_[0] } << prepend('blessed ');
is $fn4->('function'), 'unblessed function', 'Composition including a non-composable function';

my $fn5 = prepend('Ciao ') >> append('!');
is $fn5->('Bella'), 'Ciao Bella!', 'Reverse composition';

my $result6 = 'Bella' | prepend('Ciao ') | append('!');
is $result6, 'Ciao Bella!', 'Pipe operator';
