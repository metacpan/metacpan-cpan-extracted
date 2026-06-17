#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';

use Test::Perl::Critic::Policy qw(all_policies_ok);

all_policies_ok( -policies => ['Misc::ProhibitMethodsInStringConcat'], );
