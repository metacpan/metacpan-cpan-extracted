#!/usr/bin/env perl -w
use strict;
use warnings;
use Sys::Info::Constants qw(OSID);
use Test::Sys::Info;

driver_ok( OSID );
