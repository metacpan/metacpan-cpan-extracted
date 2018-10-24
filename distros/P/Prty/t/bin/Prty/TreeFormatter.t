#!/usr/bin/env perl

package Prty::TreeFormatter::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

use Prty::Unindent;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::TreeFormatter');
}

# -----------------------------------------------------------------------------

sub test_unitTest_new: Test(2) {
    my $self = shift;

    my $t = Prty::TreeFormatter->new([
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
    $self->is(ref($t),'Prty::TreeFormatter');

    my $lineA = $t->get('lineA');
    $self->isDeeply($lineA,[
        [0,0,'A'],
        [1,1,'B'],
        [2,1,'C'],
        [3,0,'D'],
        [2,1,'E'],
        [2,0,'F'],
        [3,0,'G'],
        [4,0,'H'],
        [1,1,'I'],
        [1,1,'J'],
        [2,1,'K'],
        [2,0,'L'],
        [1,0,'M'],
        [2,0,'N'],
    ]);

    $self->set(obj=>$t);
}

sub test_unitTest_tree: Test(1) {
    my $self = shift;

    my $t = $self->get('obj');

    $self->is($t->asText,Prty::Unindent->string(q~
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

    $self->is($t->asText(-format=>'debug'),Prty::Unindent->string(q~
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

    $self->is($t->asText(-format=>'compact'),Prty::Unindent->string(q~
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
Prty::TreeFormatter::Test->runTests;

# eof
