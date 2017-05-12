#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More;

BEGIN {
    unless ( eval 'use Test::Exception; 1' ) {
        plan skip_all => "please install Test::Exception to run these tests"
    }
}

plan tests => 3;

throws_ok {
    my $sql_splitter = SQL::SplitStatement->new({
        keep_terminator  => 1,
        keep_terminators => 1
    })
} qr/can't be both assigned/,
'keep_terminator and keep_terminators both assigned';

lives_ok {
    my $sql_splitter = SQL::SplitStatement->new({
        keep_terminator  => 1
    })
}
'keep_terminator only';

lives_ok {
    my $sql_splitter = SQL::SplitStatement->new({
        keep_terminators  => 1
    })
}
'keep_terminators only';
