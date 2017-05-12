#!/usr/bin/perl

use strict;
use warnings;

use Test::Pod::Coverage tests=>1;
pod_coverage_ok( "Role::Pg::Notify", "Role::Pg::Notify is covered" );
