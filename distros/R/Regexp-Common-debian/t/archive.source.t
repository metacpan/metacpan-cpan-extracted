#!/usr/bin/perl
# $Id: archive.source.t 489 2014-01-16 22:50:27Z whynot $

use strict;
use warnings;
package main;

use version 0.50; our $VERSION = qv q|0.2.6|;

use t::TestSuite   qw| RCD_process_patterns |;
use Regexp::Common
qw| debian     RE_debian_archive_source_1_0
        RE_debian_archive_source_3_0_native
         RE_debian_archive_source_3_0_quilt
                RE_debian_archive_patch_1_0
          RE_debian_archive_patch_3_0_quilt |;
use Test::More;

my %askdebian;
if(                    $ENV{RCD_ASK_DEBIAN} &&
         ($ENV{RCD_ASK_DEBIAN} eq q|all| ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\bsource\b}) )                      {
    local $/ = '';
    my $lists = q|/var/lib/apt/lists|;
    opendir my $dh, $lists                                                  or
      die
        qq|(ASK_DEBIAN) was requested, however (opendir) ($lists) | .
        qq|has failed ($!), most probably, that's not Debian at all|;
    while( my $fn = readdir $dh )                              {
        $fn =~ m{.*_Sources$}                                         or next;
        open my $fh, q|<|, qq|$lists/$fn|;
        while( my $record = <$fh> )                           {
            $record =~ m{\nFiles:\h*\n((?:\s+[^\n]+\n)+)}s                  or
              die
                qq|(ASK_DEBIAN) was requested, however that record\n\n| .
                qq|${record}has no (Files:) line|;
            $askdebian{$_}++
              foreach map +( split m{\s} )[3], split m{\n}, $1 }}}

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests =>
  4 + @{$patterns{match_source_1_0}}        +
  4 + @{$patterns{match_source_3_0_native}} +
  4 + @{$patterns{match_source_3_0_quilt}}  +
  4 + @{$patterns{match_patch_1_0}}         +
  4 + @{$patterns{match_patch_3_0_quilt}}   +
  keys %askdebian;

my $pat = q|abc_012.orig.tar.gz|;
ok $pat =~ m|$RE{debian}{archive}{source_1_0}|,
  q|/$RE{debian}{archive}{source_1_0}/ matches|;
ok $pat =~ RE_debian_archive_source_1_0, q|RE_debian_archive_source_1_0() .|;
my $re = $RE{debian}{archive}{source_1_0};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{source_1_0} .|;
ok $RE{debian}{archive}{source_1_0}->matches( $pat ),
  q|$RE{debian}{archive}{source_1_0}->matches .|;
diag q|finished (main::base_source_1_0)|            if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns       =>       $patterns{match_source_1_0},
  re_m    =>   qr|^$RE{debian}{archive}{source_1_0}$|,
  re_g => qr|$RE{debian}{archive}{source_1_0}{-keep}| );

$pat = q|abc_012.tar.bz2|;
ok $pat =~ m|$RE{debian}{archive}{source_3_0_native}|,
  q|/$RE{debian}{archive}{source_3_0_native}/ matches|;
ok $pat =~ RE_debian_archive_source_3_0_native,
  q|RE_debian_archive_source_3_0_native() .|;
$re = $RE{debian}{archive}{source_3_0_native};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{source_3_0_native} .|;
ok $RE{debian}{archive}{source_3_0_native}->matches( $pat ),
  q|$RE{debian}{archive}{source_3_0_native}->matches .|;
diag q|finished (main::base_source_3_0_native)|     if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns       =>       $patterns{match_source_3_0_native},
  re_m   =>    qr|^$RE{debian}{archive}{source_3_0_native}$|,
  re_g => qr|$RE{debian}{archive}{source_3_0_native}{-keep}| );

$pat = q|abc_012.orig.tar.bz2|;
ok $pat =~ m|$RE{debian}{archive}{source_3_0_quilt}|,
  q|/$RE{debian}{archive}{source_3_0_quilt}/ matches|;
ok $pat =~ RE_debian_archive_source_3_0_quilt,
  q|RE_debian_archive_source_3_0_quilt() .|;
$re = $RE{debian}{archive}{source_3_0_quilt};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{source_3_0_quilt} .|;
ok $RE{debian}{archive}{source_3_0_quilt}->matches( $pat ),
  q|$RE{debian}{archive}{source_3_0_quilt}->matches .|;
diag q|finished (main::base_source_3_0_quilt)|      if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns       =>       $patterns{match_source_3_0_quilt},
  re_m   =>    qr|^$RE{debian}{archive}{source_3_0_quilt}$|,
  re_g => qr|$RE{debian}{archive}{source_3_0_quilt}{-keep}| );

$pat = q|abc_012-34.diff.gz|;
ok $pat =~ m|$RE{debian}{archive}{patch_1_0}|,
  q|/$RE{debian}{archive}{patch_1_0}/ matches|;
ok $pat =~ RE_debian_archive_patch_1_0, q|RE_debian_archive_patch_1_0() .|;
$re = $RE{debian}{archive}{patch_1_0};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{patch_1_0} .|;
ok $RE{debian}{archive}{patch_1_0}->matches( $pat ),
  q|$RE{debian}{archive}{patch_1_0}->matches .|;
diag q|finished (main::base_patch_1_0)|             if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns       =>       $patterns{match_patch_1_0},
  re_m    =>   qr|^$RE{debian}{archive}{patch_1_0}$|,
  re_g => qr|$RE{debian}{archive}{patch_1_0}{-keep}| );

$pat = q|abc_012-34.debian.tar.gz|;
ok $pat =~ m|$RE{debian}{archive}{patch_3_0_quilt}|,
  q|/$RE{debian}{archive}{patch_3_0_quilt}/ matches|;
ok $pat =~ RE_debian_archive_patch_3_0_quilt,
  q|RE_debian_archive_patch_3_0_quilt() .|;
$re = $RE{debian}{archive}{patch_3_0_quilt};
ok $pat =~ m|$re|, q|$re = $RE{debian}{archive}{patch_3_0_quilt} .|;
ok $RE{debian}{archive}{patch_3_0_quilt}->matches( $pat ),
  q|$RE{debian}{archive}{patch_3_0_quilt}->matches .|;
diag q|finished (main::base_patch_3_0_quilt)|       if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns       =>       $patterns{match_patch_3_0_quilt},
  re_m    =>   qr|^$RE{debian}{archive}{patch_3_0_quilt}$|,
  re_g => qr|$RE{debian}{archive}{patch_3_0_quilt}{-keep}| );

my @report;
if( %askdebian )             {
    ok  m[^$RE{debian}{archive}{source_1_0}$]        ||
        m[^$RE{debian}{archive}{patch_1_0}$]         ||
        m[^$RE{debian}{archive}{source_3_0_native}$] ||
        m[^$RE{debian}{archive}{source_3_0_quilt}$]  ||
        m[^$RE{debian}{archive}{patch_3_0_quilt}$]   ||
        m[^$RE{debian}{archive}{dsc}$],
      qq|? $_|                                             or push @report, $_
      foreach keys %askdebian }

diag $_                                                       foreach @report;

# vim: syntax=perl
