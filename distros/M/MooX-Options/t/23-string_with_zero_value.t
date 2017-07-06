#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;

package Foo;
use Moo;
use MooX::Options;
option start_from => ( is => "ro", format => "s" );

package main;
local @ARGV = qw/--start_from 0/;
my $f = Foo->new_with_options;
my $n = $f->start_from;
is $n, 0, 'option with value 0 works';
$n++;
is $n, 1, 'and can be increment';

done_testing;
