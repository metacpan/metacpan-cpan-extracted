#!/usr/bin/perl

use Test::More tests => 4;
BEGIN { use_ok('Sort::Key') };

use Sort::Key qw(keysort nkeysort);

@data=map { rand(200)-100 } 1..10000;

is_deeply([keysort {$_} @data], [sort @data], 'id');
is_deeply([nkeysort {$_} @data], [sort {$a<=>$b} @data], 'n id');
is_deeply([nkeysort {$_ * $_} @data], [sort { $a*$a <=> $b*$b } @data], 'n sqr');
