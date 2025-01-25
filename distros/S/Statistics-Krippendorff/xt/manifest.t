#!/usr/bin/perl
use warnings;
use strict;

use Test2::V0;

unless (eval { require ExtUtils::Manifest }) {
    plan(skip_all => 'ExtUtils::Manifest needed to check manifest');
}

plan(tests => 2);

is [ ExtUtils::Manifest::manicheck() ], [], 'no missing';
is [ ExtUtils::Manifest::filecheck() ], [], 'no extra';
