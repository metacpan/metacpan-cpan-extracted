#!/usr/bin/perl
# $Id: changelog.t 489 2014-01-16 22:50:27Z whynot $

use strict;
use warnings;
package main;

use version 0.50; our $VERSION = qv q|0.2.5|;
use t::TestSuite   qw| RCD_process_patterns       |;
use Regexp::Common qw| debian RE_debian_changelog |;
use Test::More;

use File::Temp qw| tempfile |;

my @askdebian;
my $limit;
if(                                    $ENV{RCD_ASK_DEBIAN} &&
 ($ENV{RCD_ASK_DEBIAN} eq q|all|                         ||
  $ENV{RCD_ASK_DEBIAN} =~ m{\bchangelog(?:=([\w-]+))?\b}   )  )        {
    my $filter = $1 || (!defined $1 ? 5 : $1);
    my $match;
  ( $limit, $filter, $match ) =
      $filter =~ m{^[-_]?\d+$}       ? (     $filter, undef, undef ) :
      $filter && 1 == length $filter ? ( undef, undef, qr{^filter} ) :
                                       (     undef, $filter, undef );
    my $dirsource = q|/usr/share/doc|;
    opendir my $dh, $dirsource                                          or die
      q|(ASK_DEBIAN) has been requested, | .
      qq|however ($dirsource) doesn't open ($!)\nIs it *nix at all?|;
    my %stats;
    while( my $dn = readdir $dh )                   {
        -d qq|$dirsource/$dn|                                         or next;
        !($filter || $match)        ||
        $filter && $dn eq $filter   ||
        $match  && $dn =~ m{$match}                                   or next;
        foreach my $fn ( map qq|$dirsource/$dn/$_|,
          qw| changelog.Debian.gz changelog.gz | ) {
            -f $fn                                                    or next;
            my @stats = (( split m{/}, $fn )[-1], ( stat $fn )[7,9] );
            my $same =
            ( grep
                  $_->[0][0] eq $stats[0] &&
                  $_->[0][1] == $stats[1] &&
                  $_->[0][2] == $stats[2],
                values %stats )[0];
            push @{$stats{$same ? $same->[0][-1] : $fn}}, [ @stats, $fn ];
                                               last }}
    @askdebian = keys %stats;
    @askdebian                                                          or die
      q|(ASK_DEBIAN) has been requested, | .
      qq|however none (changelog.Debian) has been found\nIs it debian?| }

my %patterns = t::TestSuite::RCD_load_patterns;
plan tests => 4 + @{$patterns{match_changelog}} + @askdebian;

my $pat = <<'END_OF_CHANGELOG';
perl (6.0.0-1) unstable; urgency=high
  * At last!
 -- Eric Pozharski <whynot@cpan.org>  Thu, 01 Apr 2010 00:00:00 +0300
END_OF_CHANGELOG
ok $pat =~ m|$RE{debian}{changelog}|, q|/$RE{debian}{changelog}/ matches|;
ok $pat =~ RE_debian_changelog, q|&RE_debian_changelog() .|;
my $re = $RE{debian}{changelog};
ok $pat =~ m|$re|, q|$re = $RE{debian}{changelog} .|;
ok $RE{debian}{changelog}->matches( $pat ),
  q|$RE{debian}{changelog}->matches .|;
diag q|finished (main::RCD_base)|                   if $t::TestSuite::Verbose;

RCD_process_patterns(
  patterns   =>  $patterns{match_changelog},
  re_m    =>   qr|^$RE{debian}{changelog}$|,
  re_g => qr|$RE{debian}{changelog}{-keep}| );

open my $back_out, q|>&|, \*STDOUT;
$re = qr|$RE{debian}{changelog}{-keep}|;
my( %report, $total, $soft_limit, $weak_limit );
( $limit, $soft_limit, $weak_limit ) =
  $limit && !index( $limit, '_' ) ? ( undef, undef, substr $limit, 1 ) :
  $limit && $limit < 0            ? (          undef, -$limit, undef ) :
                                    (           $limit, undef, undef );
foreach my $chlog ( @askdebian ) {
    my $package = ( split '/', $chlog )[-2];
    my( $tfh, $tfn ) = tempfile qq|skip_$package-XXXX|;
    open STDOUT, q|>&|, $tfh;
    system qw| /bin/gunzip --stdout |, $chlog;
    open STDOUT, q|>&|, $back_out;
    seek $tfh, 0, 0;
    my $meat;
    read $tfh, $meat, -s $tfh;
    my $attempt = 0;
    while( 1 )           {
        $limit && $attempt >= $limit             ||
          $weak_limit && $attempt >= $weak_limit                     and last;
        my $check =
          qx| /usr/bin/dpkg-parsechangelog --offset $attempt --count 1 -l$tfn 2>/dev/null |;
        $?                                                             and die
          qq|(dpkg-parsechangelog) at ($attempt) has failed ($?)\n| .
          qq|that would probably help:\n$check |;
        if( !index $check, q|Source: unknown| ) {
            diag
              qq|($package) at ($attempt) | .
              q|(dpkg-parsechangelog) has failed, giving up|;
                                            last }
        my @entry;
        @entry = $meat =~ m{$re}s                                    if $meat;
        !$check && !@entry                                           and last;
        if( $check && !@entry )    {
            diag
              qq|($package) at ($attempt):\n| .
              qq|(dpkg-parsechangelog) has won:\n${check}|;
            $report{$package} = $attempt;
                               last }
        elsif( !$check && @entry ) {
            diag
                qq|($package) at ($attempt):\n| .
                qq|(\$RE{d}{changelog}) has won:\n|,
              join "\n", @entry;
            $report{$package} = $attempt;
                               last }
        push @entry, ( $entry[4] =~ m{urgency=([^,]+)} )[0];
        my $success;
        $success += $check =~ m{$_}gcs                                foreach 
          qr{\ASource: \Q$entry[1]\E\n},
          qr{\GVersion: \Q$entry[2]\E\n},
          qr{\GDistribution: \Q$entry[3]\E\n},
          qr{\GUrgency: \Q$entry[9]\E\n}i,
          qr{\GMaintainer: \Q$entry[6]\E\s+<?\Q$entry[7]\E>?\n},
          qr{\GDate: \Q$entry[8]\E\n};
        unless( $success == 6) {
            diag qq|($package) at ($attempt):\n${check}vs\n|,
              join "\n", @entry;
            $report{$package} = $attempt;
                           last }
        $meat = substr $meat, length $entry[0];
        $meat = substr $meat, 1                                          while
          $meat =~ m{^\s} }
    continue             {
               ++$attempt }
    ok                    !$report{$package} ||
                                 $weak_limit ||
      $soft_limit && $attempt >= $soft_limit,
      sprintf q|? %s/%s (%i) subchecks|,
        $package, ( split m{/}, $chlog )[-1], $attempt or BAIL_OUT q|you see|;
    unlink $tfn                                      unless $report{$package};
    $total += $attempt            }
diag qq|$_ failed at ($report{$_}) attempt|              foreach keys %report;
diag qq|subchecks: $total|                                      if @askdebian;

# vim: syntax=perl
