#!/usr/bin/env perl

use strict;
use warnings;

use Test::Perl::Critic::Policy qw( all_policies_ok );

all_policies_ok(
    -policies => [ 'ProhibitComplexDoubleSigils' ],
);