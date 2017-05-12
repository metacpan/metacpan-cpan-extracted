#!/usr/bin/perl
package Morpheus::Test::Merge;

use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use Symbol;

use lib 'lib';

use Morpheus::Utils qw(merge);

sub general : Test(2) {
    my $v1 = { a => 1, b => 2 };
    my $p1 = { b => 3, c => 4 };
    is_deeply(merge($v1, $p1), { a => 1, b => 2, c => 4 }, "basic test");

    my $v2 = { a => 1, b => { b1 => 2, b2 => 3 }, c => { c1 => 4 } };
    my $p2 = { b => { b2 => 5, b3 => 6 }, c => { c1 => 7, c2 => 8 } };
    is_deeply(merge($v2, $p2), { a => 1, b => { b1 => 2, b2 => 3, b3 => 6 }, c => { c1 => 4, c2 => 8 } }, "deeper recursion");
}

sub immutability : Test(2) {
    my $v = { a => 1, b => 2 };
    my $v_copy = { %$v };
    my $p = { b => 3, c => 4 };
    my $p_copy = { %$p };
    merge($v, $p);
    is_deeply($v, $v_copy, "merge preserves value");
    is_deeply($p, $p_copy, "merge preserves patch");
}

sub globs1 : Test(4) {
    my $v = gensym;
    %{*{$v}} = ( a => 1, b => 2 );
    ${*{$v}} = "text1";
    my $p = gensym;
    %{*{$p}} = ( b => 3, c => 4 );
    @{*{$p}} = ( "e1", "e2" );

    my $r = merge($v, $p);
    is(ref $r, "GLOB", "globs merged into globs");
    is_deeply(\%{*{$r}}, { a => 1, b => 2, c => 4 }, "hash in glob");
    is_deeply(\@{*{$r}}, ["e1", "e2"], "array in glob");
    is(${*{$r}}, "text1", "scalar in glob");
}

sub globs2 : Test(3) {
    my $v = { a => "b" };
    my $p = gensym;
    %{*{$p}} = ( a => "c" );

    my $r = merge($v, $p);
    is(ref $r, "GLOB", "hash and glob merged into glob");
    is_deeply(\%{*{$r}}, { a => "c" }, "hash in glob");
    is_deeply(${*{$r}}, { a => "b" }, "scalar in glob");
}


__PACKAGE__->new->runtests;
