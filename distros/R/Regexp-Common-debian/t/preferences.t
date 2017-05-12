#!/usr/bin/perl
# $Id: preferences.t 394 2010-08-07 15:10:03Z whynot $

package main;
use strict;
use warnings;
use version 0.50; our $VERSION = qv q|0.2.1|;
use t::TestSuite   qw| RCD_process_patterns         |;
use Regexp::Common qw| debian RE_debian_preferences |;
use Test::More;

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests => 4 + @{$patterns{match_preferences}};

my $pat = <<'END_OF_PREFERENCES';
Package: perl
Pin: version 6*
Pin-Priority: 100000
END_OF_PREFERENCES
ok $pat =~ m|$RE{debian}{preferences}|, q|/$RE{debian}{preferences}/ matches|;
ok $pat =~ RE_debian_preferences(), q|&RE_debian_preferences() .|;
my $re = $RE{debian}{preferences};
ok $pat =~ m|$re|, q|$re = $RE{debian}{preferences} .|;
ok $RE{debian}{preferences}->matches($pat),
  q|$RE{debian}{preferences}->matches .|;
diag q|finished (main::RCD_base)|                   if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>        $patterns{match_preferences},
  re_m     =>      qr|^$RE{debian}{preferences}$|,
  re_g     => qr|$RE{debian}{preferences}{-keep}| );

# vim: syntax=perl
