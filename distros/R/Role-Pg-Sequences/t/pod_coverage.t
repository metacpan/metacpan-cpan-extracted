#!/usr/bin/perl

use strict;
use warnings;

use Test::Pod::Coverage tests=>1;
pod_coverage_ok( "Role::Pg::Sequences", "Role::Pg::Sequences is covered" );
