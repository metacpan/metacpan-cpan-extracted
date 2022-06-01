#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless (eval { require ExtUtils::Manifest }) {
    plan(skip_all => 'ExtUtils::Manifest needed to check manifest');
}

plan(tests => 2);

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'no missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'no extra';
