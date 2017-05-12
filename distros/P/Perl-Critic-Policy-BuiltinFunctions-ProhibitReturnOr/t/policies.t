#!/usr/bin/perl

use strict;
use warnings;

use Test::Perl::Critic::Policy qw(all_policies_ok);
use Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr;

all_policies_ok;
