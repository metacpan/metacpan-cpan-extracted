#!/usr/bin/env perl

package Quiq::TreeFormatter::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Quiq::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::TreeFormatter');
}

# -----------------------------------------------------------------------------

sub test_unitTest_new: Test(2) {
    my $self = shift;

    my $t = Quiq::TreeFormatter->new([
        [0,'A'],
        [1,'B'],
        [2,'C'],
        [3,'D'],
        [2,'E'],
        [2,'F'],
        [3,'G'],
        [4,'H'],
        [1,'I'],
        [1,'J'],
        [2,'K'],
        [2,'L'],
        [1,'M'],
        [2,'N'],
    ]);
    $self->is(ref($t),'Quiq::TreeFormatter');

    my $lineA = $t->get('lineA');
    $self->isDeeply($lineA,[
        [0,0,'A'],
        [1,1,'B'],
        [1,2,'C'],
        [0,3,'D'],
        [1,2,'E'],
        [0,2,'F'],
        [0,3,'G'],
        [0,4,'H'],
        [1,1,'I'],
        [1,1,'J'],
        [1,2,'K'],
        [0,2,'L'],
        [0,1,'M'],
        [0,2,'N'],
    ]);

    $self->set(obj=>$t);
}

sub test_unitTest_tree: Test(1) {
    my $self = shift;

    my $t = $self->get('obj');

    $self->is($t->asText,Quiq::Unindent->string(q~
    +--A
       |
       +--B
       |  |
       |  +--C
       |  |  |
       |  |  +--D
       |  |
       |  +--E
       |  |
       |  +--F
       |     |
       |     +--G
       |        |
       |        +--H
       |
       +--I
       |
       +--J
       |  |
       |  +--K
       |  |
       |  +--L
       |
       +--M
          |
          +--N
    ~));
}

sub test_unitTest_debug: Test(1) {
    my $self = shift;

    my $t = $self->get('obj');

    $self->is($t->asText(-format=>'debug'),Quiq::Unindent->string(q~
    0 0 A
    1 1   B
    2 1     C
    3 0       D
    2 1     E
    2 0     F
    3 0       G
    4 0         H
    1 1   I
    1 1   J
    2 1     K
    2 0     L
    1 0   M
    2 0     N
    ~));
}

sub test_unitTest_compact: Test(1) {
    my $self = shift;

    my $t = $self->get('obj');

    $self->is($t->asText(-format=>'compact'),Quiq::Unindent->string(q~
    A
      B
        C
          D
        E
        F
          G
            H
      I
      J
        K
        L
      M
        N
    ~));
}

# -----------------------------------------------------------------------------

package main;
Quiq::TreeFormatter::Test->runTests;

# eof
