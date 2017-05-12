#!/usr/bin/perl
# $Id: version.t 489 2014-01-16 22:50:27Z whynot $

use strict;
use warnings;
package main;

use version 0.50; our $VERSION = qv q|0.2.2|;

use t::TestSuite   qw| RCD_process_patterns     |;
use Regexp::Common qw| debian RE_debian_version |;
use Test::More;

my @askdebian;
if(                    $ENV{RCD_ASK_DEBIAN} &&
 ($ENV{RCD_ASK_DEBIAN} eq q|all|         ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\bversion\b}   )  )              {
    @askdebian =
      qx|/usr/bin/dpkg-query --showformat '\${Version}\\n' --show|      or die
      q|(ASK_DEBIAN) was requested, however (dpkg-query) has failed; | .
      q|most probably, that's not Debian at all|;
    chomp @askdebian;
    diag sprintf q|@askdebian before: %5i|, scalar @askdebian;
    my $mark = '';
    @askdebian = grep { $mark ne $_ ? $mark = $_ : '' } sort @askdebian;
    diag sprintf q|@askdebian  after: %5i|, scalar @askdebian }

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests => 4 + @{$patterns{match_version}} + @askdebian;

my $pat = q|2:345-67|;
ok $pat =~ m|$RE{debian}{version}|, q|/$RE{debian}{version}/ matches|;
ok $pat =~ RE_debian_version, q|&RE_debian_version() .|;
my $re = $RE{debian}{version};
ok $pat =~ m|$re|, q|$re = $RE{debian}{version} .|;
ok $RE{debian}{version}->matches($pat), q|$RE{debian}{version}->matches .|;
diag q|finished (main::base)|                       if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>    $patterns{match_version},
  re_m   =>    qr|^$RE{debian}{version}$|,
  re_g => qr|$RE{debian}{version}{-keep}| );

ok m|^$re$|, qq|? $_|                                      foreach @askdebian;

# vim: syntax=perl
