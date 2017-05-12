#!/usr/bin/env perl

=pod

=head1 NAME

t/000-load.t - Net::SMS::ArxMobile unit tests

=head1 DESCRIPTION

Checks that the main class can be loaded.

=cut

use strict;
use warnings;
use Test::More tests => 1;

use Net::SMS::ArxMobile;

ok(1, "Net::SMS::ArxMobile v" . Net::SMS::ArxMobile->VERSION() . " loaded");

