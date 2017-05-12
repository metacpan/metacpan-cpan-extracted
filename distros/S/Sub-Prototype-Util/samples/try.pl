#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use lib qw<blib/lib>;

use Sub::Prototype::Util qw<flatten recall wrap>;

my @a = qw<a b c>;
print "At the beginning, \@a contains :\n", Dumper(\@a);

my @args = ( \@a, 1, { d => 2 }, undef, 3 );
print "Our arguments are :\n", Dumper(\@args);

my $proto = '\@$;$';
my @flat = flatten $proto, @args; # ('a', 'b', 'c', 1, { d => 2 })
print "When flatten with prototype $proto, this gives :\n", Dumper(\@flat);

recall 'CORE::push', @args; # @a contains 'a', 'b', 'c', 1, { d => 2 }, undef, 3
print "After recalling CORE::push with \@args, \@a contains :\n", Dumper(\@a);

my $splice = wrap 'CORE::splice';
my @b = $splice->(\@a, 4, 2);
print "After calling wrapped splice with \@a, it contains :\n", Dumper(\@a);
print "What was returned :\n", Dumper(\@b);
