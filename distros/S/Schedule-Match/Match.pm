# -*- mode: perl -*-
#
# $Id: Match.pm,v 1.7 2000/03/28 13:20:01 tai Exp $
#

package Schedule::Match;

=head1 NAME

 Schedule::Match - Handles and detects clash between pattern-based schedules

=head1 SYNOPSIS

 use Schedule::Match qw(scheck rcheck isleap uthash expand localtime);

 # hash structure of handled schedule
 $this = {
   life => 3600, # how long each execution of schedule lasts (in second)
   t_mh => '*',  # minute of the hour      - in crontab(5) format
   t_hd => '*',  # hour of the day         - in crontab(5) format
   t_dw => '*',  # day of the week         - in crontab(5) format
   t_dm => '*',  # date of the month       - in crontab(5) format
   t_wm => '*',  # week of the month       - in crontab(5) format
   t_my => '*',  # month of the year       - in crontab(5) format
   t_yt => '*',  # year (of the time)      - in crontab(5) format
   t_om => '*',  # occurrence in the month - in crontab(5) format
 };

 # create hash structure from given time
 $that = uthash($time, $life);

 @when = scheck($this, $that, ...); # list clash (duration not considered)
 @when = rcheck($this, $that, ...); # list clash (duration     considered)

 $bool = isleap($year);         # check for leap year
 @list = expand($expr, \@fill); # expand each crontab(5) expression

 @time = localtime($time);      # feature enhanced localtime(3)

=head1 DESCRIPTION

This library allows you to manage schedule which has structure
similar to crontab(5) format. It offers methods to detect clash
between schedules (with or without duration considered), and
can also tell when, and how often they clash.

From the viewpoint of data structure, one major difference
compared to crontab(5) is a concept of duration. Each schedule
has its own duration, and clash detection can be done upon that.
For more information on data structure, please consult
SCHEDULE STRUCTURE section below.

All schedules are assumed to be in the same timezone. You will
have to align them beforehand if not.

Currently available methods are as follows:

=over 4

=cut

require Exporter;

use strict;

use Carp;
use Time::Local;

use vars qw(@ISA @EXPORT_OK $VERSION $DEBUG $WILD);

@ISA       = qw(Exporter);
@EXPORT_OK = qw(scheck rcheck isleap uthash expand localtime $WILD);

$VERSION = '0.07';

## Wildcard schedule which matches with any schedule
$WILD = {
    t_mh => '*', t_hd => '*', t_dm => '*', t_my => '*',
    t_yt => '*', t_dw => '*', t_wm => '*', t_om => '*',
};

## Used for debugging
$DEBUG = 0;

## Template used to expand schedule pattern
my $FILL = {
    t_mh => [0..59],
    t_hd => [0..23],
    t_dm => [1..31],
    t_my => [0..11],
    t_yt => [1970..2037],
    t_dw => [0..6],
    t_wm => [1..6],
    t_om => [1..5],
};

## Major timespan in seconds
my $DSEC = 3600 * 24;
my $WSEC = $DSEC *   7;
my $MSEC = $DSEC *  31;
my $YSEC = $DSEC * 366;

=item @when = lcheck($this, $deep, $keep, $init, $last);

Returns list of UNIX times which is a time given schedule
gets invoked.

=cut
sub lcheck {
    ;
}

=item @when = scheck($this, $that, $deep, $keep, $init, $last);

Detects clash between given schedules _without_ considering
duration. Returns the list of clash time (empty if not).
It is safe to assume the list is sorted.

Options are:

=over 4

=item - $deep

Sets the "depth" of clash detection. If set to false, it will
report only one clash (first one) per day.

=item - $keep

Sets the maximum number of clashes to detect. Defaults to 1.

=item - $init

Set the starting time of timespan to do the detection.
Defaults to the moment this method is called.

=item - $done

Set the closing time of timespan to do the detection.
Defaults to 3 years after $init.

=back

=cut
sub scheck {
    my $exp0 = shift;
    my $exp1 = shift;
    my $deep = shift;
    my $keep = shift || 1;
    my $init = shift || time;
    my $last = shift || $init + $YSEC * 5;
    my $pack;
    my $want;
    my @keep;

    print STDERR "[scheck] entered.\n" if $DEBUG;

    ## Expand and then logically mix schedules.
    ##
    ## Note if two schedule logically never overwrap, some
    ## part of the resulting schedule won't contain anything
    ## (undef in this case), allowing the code to bailout early.
    while (my($key, $val) = each %{$FILL}) {
        $pack->{$key} = &shrink(&expand($exp0->{$key}, $val),
                                &expand($exp1->{$key}, $val)) || return;
    }

    ## Put a mark on wanted t_wm, t_dw, and t_om.
    foreach (@{$pack->{t_dw}}) { $want->{t_dw}->{$_} = 1; }
    foreach (@{$pack->{t_wm}}) { $want->{t_wm}->{$_} = 1; }
    foreach (@{$pack->{t_om}}) { $want->{t_om}->{$_} = 1; }

    ## Convert hour and minute into second beforehand
    foreach (@{$pack->{t_hd}}) { $_ *= 3600; }
    foreach (@{$pack->{t_mh}}) { $_ *=   60; }

    ## Initialize maximum date for each month
    my @NMAX = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

    ##
    ## Check if there's any valid date in overwrapping part
    ## of the schedule. It there is one, it means it'll clash
    ## on that date.
    ##

    my($t_yt, $t_my, $t_dm, $t_hd, $t_mh, $base, $time, @time);

  T_YT:
    foreach $t_yt (@{$pack->{t_yt}}) {

        ## Check for leap year to change maximum date of Feburary.
        $NMAX[1] = &isleap($t_yt) ? 29 : 28;

      T_MY:
        foreach $t_my (@{$pack->{t_my}}) {

          T_DM:
            foreach $t_dm (@{$pack->{t_dm}}) {
                ## Skip if the date is invalid (such as Feb 31).
                next if $t_dm > $NMAX[$t_my];

                $base = timelocal(0, 0, 0, $t_dm, $t_my, $t_yt - 1900);

                last T_YT if $last < $base;
                next T_YT if $base < $init - $YSEC;
                next T_MY if $base < $init - $MSEC;
                next T_DM if $base < $init - $DSEC;

                @time = &localtime($base);

                ## If all reverse-calculated entries were marked as
                ## "WANTED", it means the day is valid (and so really
                ## clashes).
                next unless ($want->{t_dw}->{$time[6]} &&
                             $want->{t_wm}->{$time[9]} &&
                             $want->{t_om}->{$time[10]});

                ## Record time of clash in the day.
                foreach $t_hd (@{$pack->{t_hd}}) {
                    foreach $t_mh (@{$pack->{t_mh}}) {
                        ## Time of the clash
                        $time = $base + $t_mh + $t_hd;

                        last T_YT if $last < $time;
                        next      if $time < $init;

                        last T_YT if push(@keep, $time) >= $keep;
                        next T_DM unless ($deep);
                    }
                }
            }
        }
    }

    wantarray ? @keep : $keep[0];
}

=item $list = rcheck($exp0, $exp1, $deep, $keep, $init, $done);

Detects clash between given schedules _with_ duration considered.

This is almost compatible with B<scheck> except that $deep and $keep
option does not work as expected (for current implementation). For
$deep, it is always set to 1, and for $keep, you would need to
specify much larger value (I cannot give the exact number since
it depends on how often two schedules clash).

=cut
sub rcheck {
    my $exp0 = shift;
    my $exp1 = shift;
    my $deep = shift;
    my $keep = shift || 1;
    my $init = shift || time;
    my $last = shift || $init + $YSEC * 3;
    my @keep;
    my @run0;
    my @run1;

    print STDERR "[rcheck] entered.\n" if $DEBUG;

    ## Obtain list of starting time for each schedule pattern.
    ##
    ## NOTE:
    ## Since there's no way of knowing how much of the retrieved
    ## schedule elements overwrap, it is impossible to guarantee
    ## the minimum number of clashes reported (i.e. $keep).
    @run0 = &scheck($WILD, $exp0, 1, $keep, $init - $exp0->{life}, $last);
    @run1 = &scheck($WILD, $exp1, 1, $keep, $init - $exp1->{life}, $last);

    ## Compare each invocation of schedule pattern, to see if there's
    ## any clash or not.
  LOOP:
    foreach (@run0) {
        my $t0 = $_;
        my $t1 = $_ + $exp0->{life};
        foreach (@run1) {
            my $u0 = $_;
            my $u1 = $_ + $exp1->{life};

            ## If there's no overwrapping part, bailout.
            last if $t1 < $u0;
            next if $t0 > $u1;

            ## Record the time of clash and quit if enough was found.
            if ($t0 <= $u0 && $u0 <= $t1) {
                last LOOP if push(@keep, $u0) >= $keep;
            }
            elsif ($u0 <= $t0 && $t0 <= $u1) {
                last LOOP if push(@keep, $t0) >= $keep;
            }
        }
    }

    wantarray ? @keep : $keep[0];
}

=item $bool = isleap($year);

Returns wheather given year is leap year or not. Returns true
if it is, false otherwise.

=cut
sub isleap {
    ($_[0] % 4) == 0 && (($_[0] % 100) != 0 || ($_[0] % 400) == 0);
}

=item $hash = uthash($time[, $life]);

Create schedule structure from given UNIX time. Optionally, you
can also set the duration of created schedule (which defaults to 0).

=cut
sub uthash {
    my $time = shift;
    my $life = shift;
    my @time = &localtime($time);

    return {
        life => $life,           # life (in second)
        t_mh => $time[1],        # minute of the hour
        t_hd => $time[2],        # hour of the day
        t_dm => $time[3],        # day of the month
        t_my => $time[4],        # month of the year
        t_yt => $time[5] + 1900, # year (of the time)
        t_dw => $time[6],        # date of the week
        t_wm => $time[9],        # week of the month
        t_om => $time[10],       # occurrence in the month
    };
}

=item @time = localtime($time);

Converts a time as returned by the time function to a 11-element
array with the time analyzed for the local time zone.

Except for appended 10th and 11th element, this is compatible with
built-in B<localtime>.

Appended 2 elements (10th and 11th) are "week of the month" and
"occurence in the month", both in 1-indexed style.

=cut
sub localtime {
    my $time = shift;
    my @time;

    $time = defined($time) ? $time : time;

    wantarray || return CORE::localtime($time);

    @time = CORE::localtime($time);
    @time,
    int(($time[3] + 7 - $time[6] + 6) / 7),
    int(($time[3]                + 6) / 7);
}

=item @list = expand($expr, \@fill);

Function to expand given crontab(5)-like expression to the list
of matching values. \@fill is used to expand wildcard.

=cut
sub expand {
    my $expr = shift;
    my $fill = shift;
    my @expr = split(m|/|, $expr);
    my @list = split(m|,|, $expr[0]);
    my @temp;
    my @last;
    my %seen;

    print STDERR "[expand] \$expr: $expr\n" if $DEBUG;

    ## Expand pattern, and then sort+uniq the resulting list
    foreach (@list) {
        push(@temp, @$fill) if m|^\*$|;
        push(@temp, $1)     if m|^(\d+)$|;
        push(@temp, $1..$2) if m|^(\d+)-(\d+)$|;
    }
    @temp = sort { $a <=> $b } grep { ! $seen{$_}++ } @temp;

    ## Pick out elements by "skip" value (to handle '*/n' notation)
    $expr[1]++;
    for (my $i = 0 ; $i <= $#temp ; $i += $expr[1]) {
        push(@last, $temp[$i]);
    }

    if ($DEBUG) {
        print STDERR "[expand] \@last: @last\n";
    }
    wantarray ? @last : $last[0];
}

##
# Function to logically combine two expanded schedule element
#
sub shrink {
    my %seen;
    my @list = grep { $seen{$_}++ } @_;

    if ($DEBUG) {
        print STDERR "[shrink] \@list: @list\n";
    }
    @list ? \@list : undef;
}

=back

=head1 SCHEDULE STRUCTURE

Below is a structure of schedule used in this library:

    life => duration of the schedule (in second)
    t_mh => minute of the hour
    t_hd => hour of the day
    t_dm => day of the month
    t_my => month of the year
    t_yt => year (of the time)
    t_dw => day of the week
    t_wm => week of the month
    t_om => occurrence in the month

As you can see, this is a simple hashtable. And for all t_*
entries, crontab(5)-like notation is supported. For this
notation, please consult crontab(5) manpage.

Next goes some examples. To make description short, I stripped
the text "Schedule lasting for an hour, starting from midnight"
off from each description. Please assume that when reading.

=item 1. on every Jan. 1.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '1',
        t_my => '0',
        t_yt => '*',
        t_dw => '*',
        t_wm => '*',
        t_om => '*',
    }

=item 2. on every 3rd Sunday.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '*',
        t_my => '*',
        t_yt => '*',
        t_dw => '0',
        t_wm => '*',
        t_om => '3',
    }

=item 3. on Monday of every 3rd week.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '*',
        t_my => '*',
        t_yt => '*',
        t_dw => '1',
        t_wm => '3',
        t_om => '*',
    }

=item 4. on every other day.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '*/1',
        t_my => '*',
        t_yt => '*',
        t_dw => '*',
        t_wm => '*',
        t_om => '*',
    }

=item 5. on every other 2 days, from January to May.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '*/2',
        t_my => '0-4',
        t_yt => '*',
        t_dw => '*',
        t_wm => '*',
        t_om => '*',
    }

=item 6. on the day which is Sunday _and_ the 1st day of the month.

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '1',
        t_my => '*',
        t_yt => '*',
        t_dw => '0',
        t_wm => '*',
        t_om => '*',
    }

=item 7. on Jan. 1, 1999

    $schedule = {
        life => 3600,
        t_mh => '0',
        t_hd => '0',
        t_dm => '1',
        t_my => '0',
        t_yt => '1999',
        t_dw => '*',
        t_wm => '*',
        t_om => '*',
    }

Got the idea? You need to be careful on how you specify pattern,
since it is possible to create pattern which never happens (Say, 
every Monday of 1st week which is 3rd Monday of the month).

Other key-value pair can be in the hash, but there is no gurantee
for those entries. It might clash with future enhancements to the
strcuture, or it might even be dropped when the internal copy
of the structure is made.

=head1 BUGS

Two potential bugs are currently known:

=over 4

=item UNIX-Y2K++ bug

Due to a feature of localtime(3), this cannot cannot handle year
beyond 2038. Since clash-detection code checks for the date in
the future, this library is likely to break before that (around
2030?).

=item Clash detection bug

When schedule(s) in question repeat in very short time (like every
minute), method rcheck might not be able to check through timespan
that is long enough.

This can be avoided if you specify HUGE value for $keep, but
then things will be so slow, I believe it is not practical.

=back

=head1 COPYRIGHT

Copyright 1999, Taisuke Yamada <tai@imasy.or.jp>.
All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
