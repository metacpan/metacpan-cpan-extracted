#!/usr/bin/perl
# $Id: architecture.t 387 2010-08-01 21:12:51Z whynot $

package main;
use strict;
use warnings;
use version 0.50;

use t::TestSuite;
use Regexp::Common qw| debian RE_debian_architecture |;
use Test::More;

our $VERSION = qv q|0.2.3|;

my @askdebian;
if(
  $ENV{RCD_ASK_DEBIAN} &&
 ($ENV{RCD_ASK_DEBIAN} eq q|all| ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\barchitecture\b}) ) {
    local $/ = "\n";
    @askdebian = qx|/usr/bin/dpkg-architecture -L|                          or
      die
        q|(ASK_DEBIAN) was requested, |             .
        q|however (dpkg-architecture) has failed; | .
        q|most probably, that's not Debian at all|;
    chomp @askdebian                              }

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests => 4 + @{$patterns{match_architecture}} + @askdebian;

my $pat = q|openbsd-arm|;
ok $pat =~ m|$RE{debian}{architecture}|,
  q|/$RE{debian}{architecture}/ matches|;
ok $pat =~ RE_debian_architecture(), q|&RE_debian_architecture() .|;
my $re = $RE{debian}{architecture};
ok $pat =~ m|$re|, q|$re = $RE{debian}{architecture} .|;
ok $RE{debian}{architecture}->matches($pat),
  q|$RE{debian}{architecture}->matches .|;
diag q|finished (main::RCD_base)|                   if $t::TestSuite::Verbose;

t::TestSuite::RCD_process_patterns(
  patterns => $patterns{match_architecture},
  re_m     => qr|^$RE{debian}{architecture}$|,
  re_g     => qr|$RE{debian}{architecture}{-keep}| );

ok m|^$re$|, qq|? $_|                                       foreach @askdebian

# vim: syntax=perl
