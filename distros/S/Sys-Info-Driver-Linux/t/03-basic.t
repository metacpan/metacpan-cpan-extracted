#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::Sys::Info;

printf STDERR "UNAME: %s\n", qx(uname -a) || 'unknown';

driver_ok('Linux');
