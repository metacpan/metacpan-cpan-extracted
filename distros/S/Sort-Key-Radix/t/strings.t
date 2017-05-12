#!/usr/bin/perl

use Test::More tests => 3;

use Sort::Key::Radix qw(skeysort ssort);

my @data = map { int(rand(200)-100) } 1..100_000;
my @good = sort @data;

is_deeply([skeysort {$_} @data], \@good, 'skeysort');
is_deeply([ssort @data], \@good, 'ssort');


my @hex = qw(339E84CBCF3C7 2739E84CBCF3C 31739E84CBCF3C);
is_deeply([skeysort { $hex[$_] } 0..$#hex], [1, 2, 0], "hex");
