#!/usr/bin/env perl

# $Id: implementation.t 7587 2011-04-16 16:00:36Z jonasbn $

use strict;
use  warnings;

use Test::More tests => 4;

use_ok('Perl::Critic::Policy::logicLAB::RequirePackageNamePattern');

ok(my $policy = Perl::Critic::Policy::logicLAB::RequirePackageNamePattern->new(), 'testing constructor');

isa_ok($policy, 'Perl::Critic::Policy::logicLAB::RequirePackageNamePattern');

can_ok($policy, qw(violates));
