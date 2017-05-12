#!/usr/bin/perl
# $Id: package.t 394 2010-08-07 15:10:03Z whynot $

package main;
use strict;
use warnings;
use version 0.50; our $VERSION = qv q|0.2.1|;
use t::TestSuite   qw| RCD_process_patterns     |;
use Regexp::Common qw| debian RE_debian_package |;
use Test::More;

my @askdebian;
if(
  $ENV{RCD_ASK_DEBIAN} &&
 ($ENV{RCD_ASK_DEBIAN} eq q|all| ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\bpackage\b}) ) {
    local $/ = "\n";
    @askdebian =
      qx|/usr/bin/dpkg-query --showformat '\${Package}\\n' --show|      or die
      q|(ASK_DEBIAN) was requested, however (dpkg-query) has failed; | .
      q|most probably, that's not Debian at all|;
    chomp @askdebian                         }

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests => 4 + @{$patterns{match_package}} + @askdebian;

my $pat = q|xyz|;
ok $pat =~ m|$RE{debian}{package}|, q|/$RE{debian}{package}/ matches|;
ok $pat =~ RE_debian_package(), q|&RE_debian_package() .|;
my $re = $RE{debian}{package};
ok $pat =~ m|$re|, q|$re = $RE{debian}{package} .|;
ok $RE{debian}{package}->matches($pat), q|$RE{debian}{package}->matches .|;
diag q|finished (main::base)|                       if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>        $patterns{match_package},
  re_m     =>      qr|^$RE{debian}{package}$|,
  re_g     => qr|$RE{debian}{package}{-keep}| );

ok m|^$re$|, qq|? $_|                                       foreach @askdebian

# vim: syntax=perl
