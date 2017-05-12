################################################################################
#
# $Id: Calendar.pm 211 2009-05-25 06:05:50Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::Calendar -- 

=head1 SYNOPSIS

 use TaskForest::LocalTime;

 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &LocalTime::localtime();
 #
 # THE MONTH IS 1-BASED, AND THE YEAR IS THE FULL YEAR
 # (i.e.,  $mon++; $year += 1900; is not required)

 &LocalTime::setTime({ year  => $year,
                                   month => $mon,
                                   day   => $day,
                                   hour  => $hour,
                                   min   => $min,
                                   sec   => $sec,
                                   tz    => $tz
                                   });
 # ...
 ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &LocalTime::localtime(); 
 #
 # THE MONTH IS 1-BASED, AND THE YEAR IS THE FULL YEAR
 # (i.e.,  $mon++; $year += 1900; is not required)

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides support for Calendar functions

=head1 METHODS

=cut

package TaskForest::Calendar;
use strict;
use warnings;
use Carp;
use DateTime;
use Time::Local;
use Data::Dumper;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


my $time_offset = 0;

# ------------------------------------------------------------------------------
=pod

=over 4

=item setTime()

 Usage     : &LocalTime::setTime({ year  => $year,
                                   month => $mon,
                                   day   => $day,
                                   hour  => $hour,
                                   min   => $min,
                                   sec   => $sec,
                                   tz    => $tz
                                   });
 Purpose   : This method 'sets' the current time to the time specified, in the
             timezone specified. 
 Returns   : Nothing 
 Argument  : A hash of values
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub canRunToday {
    my $args = shift;

    my $rules = $args->{rules};
    my $tz    = $args->{tz};

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::ft($tz);

    # for each rule, see if today applies (yes or no or inconclusive).
    # default is no.
    # last matching rule that returns yes or no wins

    my $today_hash = {
        sec   => $sec,
        min   => $min,
        hour  => $hour,
        mday  => $mday,
        mon   => $mon,
        year  => $year,
        wday  => $wday,
        yday  => $yday,
        isdst => $isdst,
    };

    my $ok = '-';
    foreach my $rule (@$rules) {
        $rule =~ s/\#.*//;
        next unless $rule =~ /\S/;
        my $match = doesRuleMatch($today_hash, $rule);
        if ($match eq '+' or $match eq '-') {
            $ok = $match;
        }
        elsif ($match eq 'N/A') {
            # not applicable - do nothing
        }
        else {
            return $match;
        }
    }

    return $ok;
}


sub doesRuleMatch {
    my ($today, $rule) = @_;

    # [+|-] ( [ [first | second | third | fourth | fifth] [last] DOW ]  | (YYYY|*)/(MM|*)/(DD|*) )
    # trim white space 
    $rule =~ s/^\s+//;
    $rule =~ s/\s+$//;
    $rule =~ tr/A-Z/a-z/;
    
    my @components = split(/\s+/, $rule);
    return "No components" unless (@components);

    my $plus_or_minus = '+';

    # if +/- isn't defined, assume it's a +
    #
    if ($components[0] eq '+' || $components[0] eq '-') {
        $plus_or_minus = shift(@components);
    }
    return "No components after plus or minus" unless (@components);

    
    my $nth = undef;
    my $dow = undef;
    my %offsets = ( first => 1, second => 2, third => 3, fourth => 4, fifth => 5, last => -1, every => 0, );
    my %dows = (  sun => 0 , mon => 1, tue => 2, wed => 3, thu => 4, fri => 5, sat => 6, );
    
    # if the second item is _/_/_, then assume that there is no nth DOW
    
    if (defined $offsets{$components[0]}) {
        return "No components after offset" if (scalar(@components) < 2);
        
        $nth = $offsets{$components[0]};
        
        if ($components[1] eq 'last') {
            $nth = ($nth > 0)? $nth * -1 : -1;
            splice(@components, 1, 1);  # get rid of 'last'
        }
        return "No components after offset last" if (scalar(@components) < 2);
 
        $dow = $dows{substr($components[1], 0, 3)};

        # now get rid of the first 2
        splice(@components, 0, 2);
    }

    my ($y, $m, $d);
    if ($components[0]) {
        my $yyyymmdd = $components[0];
        my ($y, $m, $d) = split(/\//, $yyyymmdd);

        if (defined $nth) {
            return "Date of month not allowed when specifying day of week" if $d;  # can't have last Friday in 2009/November/1
            $d = '*';          # do this to make the check for keep_going easier
        }
        return "Date not specified in a valid format" unless ($y && $m && $d);

        if ($y ne '*') { $y *= 1; if ($y < 1970                ) { return "Invalid year";  } }
        if ($m ne '*') { $m *= 1; if ($m < 1 || $m > 12        ) { return "Invalid month"; } }
        if ($d ne '*') { $d *= 1; if ($d < 1 || $d > 31        ) { return "Invalid day"; } }


        # now try to eliminate based on yyyy mm and dd

        my $keep_going;

        if ( ($y eq '*' || $y == $today->{year})
             &&
             ($m eq '*' || $m == $today->{mon})
             &&
             ($d eq '*' || $d == $today->{mday})
            )
        {
            $keep_going = 1;
            $y = $today->{year};
            $m = $today->{mon};
            $d = $today->{mday};
        }
        else {
            $keep_going = 0;
        }

        return 'N/A' unless $keep_going;
        #return '-' unless $keep_going;

        # now we know that the date part matches.
        # now check for the day of week part, if present

        if (defined $nth && defined $dow) {
            # $nth could be 0 (every)

            if ($dow == $today->{wday}) {
                # check nth.  Check easy ones first
                #
                if ($nth == 0) { return $plus_or_minus; }

                # find days of week
                my $dates = findDaysOfWeek($y, $m, $dow);

                if ($nth > 0) { $nth--; } # so we can use it as an array subscript

                return '-' if $nth == 4 and scalar(@$dates) < 5;  # If the fifth dow does exist
                
                if ($dates->[$nth] == $today->{mday}) {
                    return $plus_or_minus;
                }
                else {
                    #return '-';
                    return 'N/A';
                }
            }
            else {
                #return '-';
                return 'N/A';
            }
        }
        else {
            return $plus_or_minus;
        }
             
    }

    return 'Applicable date range not present';

}

# returns an array of 4 or 5 mdays, each of which correspond to the nth dow of y/m
sub findDaysOfWeek {
    my ($y, $m, $dow) = @_;

    # find the first dow
    #my ($sec1,$min1,$hour1,$mday1,$mon1,$year1,$wday1,$yday1,$isdst1) = localtime(timelocal(0, 0, 0, 1, $m - 1, $y - 1900));
    my $dt = DateTime->new(year => $y,
                           month => $m,
                           day => 1,
                           hour => 0,
                           minute => 0,
                           second => 0,
        );
    my $wday1 = $dt->day_of_week;
    $wday1 = 0 if $wday1 == 7;
    
    # dow  $wday1  transform
    # 3    0       + 3       = 3
    # 3    1       + (3 - 1) = 2
    # 3    2       + (3 - 2) = 1
    # 3    3       + (3 - 3) = 0           
    # 3    4       + (3 - 4) = -1 + 7 = 6
    # 3    5       + (3 - 5) = -2 + 7 = 5
    # 3    6       + (3 - 6) = -3 + 7 = 4
    # 0    0       0
    # 0    1       0 - 1 + 7 = 6

    my @result = ();
    $result[0] = ($dow >= $wday1) ? $dow - $wday1 + 1 : $dow - $wday1 + 1 + 7;

    my @days_in_month = (-1, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    if ($m == 2 and $dt->is_leap_year()) {
        #$days_in_month[2] += ($y % 4) ? 0 : ($y % 100) ? 1 : ($y % 400) ? 0: 1;
        $days_in_month[2] ++;
    }

    my $days_in_month = $days_in_month[$m];

    my $next = 0;
    for (my $next = $result[0] + 7; $next <= $days_in_month; $next += 7) {
        push(@result, $next);
    }

    return (\@result);
}

1;
