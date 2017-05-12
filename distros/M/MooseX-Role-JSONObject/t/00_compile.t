#!/usr/bin/perl

use v5.012;
use strict;
use warnings;
use Test::More 0.98 tests => 1;

use_ok $_ for qw(
    MooseX::Role::JSONObject
);
