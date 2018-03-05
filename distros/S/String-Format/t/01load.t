#!/usr/bin/env perl
# vim: set ft=perl ts=4 sw=4:

# ======================================================================
# This is your basic "Do I compile?" test.
# ======================================================================

use strict;
use Test::More tests => 2;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };
use_ok('String::Format');
is_deeply \@warnings, [], 'No warnings';
