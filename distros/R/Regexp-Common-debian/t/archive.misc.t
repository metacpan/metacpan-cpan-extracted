#!/usr/bin/perl
# $Id: archive.misc.t 391 2010-08-04 10:50:16Z whynot $

package main;
use strict;
use warnings;
use version 0.50; our $VERSION = qv q|0.2.5|;

use t::TestSuite   qw| RCD_process_patterns |;
use Regexp::Common qw|
  debian
  RE_debian_archive_binary
  RE_debian_archive_dsc
  RE_debian_archive_changes                 |;
use Test::More;

my %askdebian;
if(
  $ENV{RCD_ASK_DEBIAN} &&
 ($ENV{RCD_ASK_DEBIAN} eq q|all| ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\bbinary\b}) ) {
    local $/ = '';
    my $lists = q|/var/lib/apt/lists|;
    opendir my $dh, $lists                                                  or
      die
        qq|(ASK_DEBIAN) was requested, however (opendir) ($lists) | .
        qq|has failed ($!), most probably, that's not Debian at all|;
    while( my $fn = readdir $dh )    {
        $fn =~ m{.*_Packages$}                                        or next;
        open my $fh, q|<|, qq|$lists/$fn|;
        while( my $record = <$fh> ) {
            $record =~ m{^Filename:\s.+/([^/\n]+)$}m                        or
              die
                qq|(ASK_DEBIAN) was requested, however that record\n\n| .
                qq|${record}has no (Filename:) line|;
            $askdebian{$1}++         }}     }

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests =>
  4 + @{$patterns{match_binary}}  +
  4 + @{$patterns{match_dsc}}     +
  4 + @{$patterns{match_changes}} +
  keys %askdebian;

my $pat = q|abc_012_i386.deb|;
ok $pat =~ m|$RE{debian}{archive}{binary}|,
  q|/$RE{debian}{archive}{binary}/ matches|;
ok $pat =~ RE_debian_archive_binary(), q|RE_debian_archive_binary() .|;
my $re = $RE{debian}{archive}{binary};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{binary} .|;
ok $RE{debian}{archive}{binary}->matches( $pat ),
  q|$RE{debian}{archive}{binary}->matches .|;
diag q|finished (main::base_binary)|                if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>                 $patterns{match_binary},
  re_m     =>      qr|^$RE{debian}{archive}{binary}$|,
  re_g     => qr|$RE{debian}{archive}{binary}{-keep}| );

$pat = q|abc_012-34.dsc|;
ok $pat =~ m|$RE{debian}{archive}{dsc}|,
  q|/$RE{debian}{archive}{dsc}/ matches|;
ok $pat =~ RE_debian_archive_dsc(), q|RE_debian_archive_dsc() .|;
$re = $RE{debian}{archive}{dsc};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{dsc} .|;
ok $RE{debian}{archive}{dsc}->matches( $pat ),
  q|$RE{debian}{archive}{dsc}->matches .|;
diag q|finished (main::base_dsc)|                   if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>                 $patterns{match_dsc},
  re_m     =>      qr|^$RE{debian}{archive}{dsc}$|,
  re_g     => qr|$RE{debian}{archive}{dsc}{-keep}| );

$pat = q|abc_012-34_ia64.changes|;
ok $pat =~ m|$RE{debian}{archive}{changes}|,
  q|/$RE{debian}{archive}{changes}/ matches|;
ok $pat =~ RE_debian_archive_changes(), q|RE_debian_archive_changes() .|;
$re = $RE{debian}{archive}{changes};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{changes} .|;
ok $RE{debian}{archive}{changes}->matches( $pat ),
  q|$RE{debian}{archive}{changes}->matches .|;
diag q|finished (main::base_changes)|               if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns =>                 $patterns{match_changes},
  re_m     =>      qr|^$RE{debian}{archive}{changes}$|,
  re_g     => qr|$RE{debian}{archive}{changes}{-keep}| );

my @report;
if( %askdebian )             {
    ok m[^$RE{debian}{archive}{binary}$], qq|? $_|         or push @report, $_
      foreach keys %askdebian }

diag $_                                                       foreach @report;

# vim: syntax=perl
