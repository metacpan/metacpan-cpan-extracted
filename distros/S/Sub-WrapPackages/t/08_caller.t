#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

my $pre;

use Sub::WrapPackages;
use lib 't/lib';
use a;

my @caller_noargs = a::a_caller();
my @caller_witharg0 = a::a_caller(0);
my @caller_caller_noargs = a::a_caller_caller();
my @caller_caller_witharg0 = a::a_caller_caller(0);
my @caller_caller_witharg1 = a::a_caller_caller(1);
my @caller_caller_witharg2 = a::a_caller_caller(2);

# wrap after getting correct data to compare with
Sub::WrapPackages::wrapsubs(
    packages => [qw(a)],
    pre => sub { $pre .= join(", ", @_); },
);

my @wrapped_caller_noargs = a::a_caller();
$wrapped_caller_noargs[2] = $caller_noargs[2];
is($pre, 'a::a_caller', "pre works for no args");
is_deeply(\@wrapped_caller_noargs, \@caller_noargs,
    "wrapped -> caller() works");

$pre = '';
my @wrapped_caller_witharg0 = a::a_caller(0);
$wrapped_caller_witharg0[2] = $caller_witharg0[2];
is($pre, 'a::a_caller, 0', "pre works with an arg");
is_deeply(\@wrapped_caller_witharg0, \@caller_witharg0,
    "wrapped -> caller(0) works");

my @wrapped_caller_caller_noargs = a::a_caller_caller();
$wrapped_caller_caller_noargs[2] = $caller_caller_noargs[2];
is_deeply(\@wrapped_caller_caller_noargs, \@caller_caller_noargs,
    "wrapped -> wrapped -> caller() works");

my @wrapped_caller_caller_witharg0 = a::a_caller_caller(0);
$wrapped_caller_caller_witharg0[2] = $caller_caller_witharg0[2];
is_deeply(\@wrapped_caller_caller_witharg0, \@caller_caller_witharg0,
    "wrapped -> wrapped -> caller(0) works");

my @wrapped_caller_caller_witharg1 = a::a_caller_caller(1);
$wrapped_caller_caller_witharg1[2] = $caller_caller_witharg1[2];
is_deeply(\@wrapped_caller_caller_witharg1, \@caller_caller_witharg1,
    "wrapped -> wrapped -> caller(1) works");

my @wrapped_caller_caller_witharg2 = a::a_caller_caller(2);
# expect an empty list here, so no munging!
is_deeply(\@wrapped_caller_caller_witharg2, \@caller_caller_witharg2,
    "wrapped -> wrapped -> caller(2) works");
