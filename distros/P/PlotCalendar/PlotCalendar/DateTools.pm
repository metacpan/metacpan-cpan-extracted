package PlotCalendar::DateTools;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( Day_of_Year Days_in_Month Decode_Day_of_Week Day_of_Week Add_Delta_Days Day_of_Week_to_Text Month_to_Text Days_in_Year ); 

$VERSION = sprintf "%d.%02d", q$Revision: 1.0 $ =~ m#(\d+)\.(\d+)#;

use Carp;
require Time::DaysInMonth;
require Time::JulianDay;

my %data;

$data{MONTHS} = { '1' => 'Jan',
                '2' => 'Feb',
                '3' => 'Mar',
                '4' => 'Apr',
                '5' => 'May',
                '6' => 'Jun',
                '7' => 'Jul',
                '8' => 'Aug',
                '9' => 'Sep',
                '10' => 'Oct',
                '11' => 'Nov',
                '12' => 'Dec',
                  };

$data{LONGMONTHS} = { '1' => 'January',
                        '2' => 'February',
                        '3' => 'March',
                        '4' => 'April',
                        '5' => 'May',
                        '6' => 'June',
                        '7' => 'July',
                        '8' => 'August',
                        '9' => 'September',
                        '10' => 'October',
                        '11' => 'November',
                        '12' => 'December',
                      };

$data{DAYS} = { '7' => 'Sun',
                '1' => 'Mon',
                '2' => 'Tue',
                '3' => 'Wed',
                '4' => 'Thu',
                '5' => 'Fri',
                '6' => 'Sat',
              };

$data{LONGDAYS} = { '7' => 'Sunday',
                    '1' => 'Monday',
                    '2' => 'Tuesday',
                    '3' => 'Wednesday',
                    '4' => 'Thursday',
                    '5' => 'Friday',
                    '6' => 'Saturday',
                  };

# ****************************************************************
sub Day_of_Year { # done
    my ($yr,$mon,$day) = @_;

    my $jd = julian_day($yr, $mon, $day);
    my $jdjan = julian_day($yr, 1, 1);

    return $jd-$jdjan+1;
}

# ****************************************************************
sub Days_in_Month { # done
    my ($yr,$mon) = @_;

    return days_in($yr, $mon);;
}

# ****************************************************************
sub Decode_Day_of_Week { # done
    my $dayname = shift;

    $dayname =~ tr/A-Z/a-z/; #lowercase it
    my $dow;
    for ($dow=1; $dow<=7; $dow++) {
        if (index($data{LONGDAYS}{$dow},"\u$dayname") == 0) {last;}
    }

    return $dow;
}

# ****************************************************************
sub Day_of_Week { # done
    my ($yr,$mon,$day) = @_;

    my $jd = julian_day($yr, $mon, $day);
    my $dow = day_of_week($jd);
    if ($dow == 0) { $dow = 7; }
    
    return $dow;
}

# ****************************************************************
sub Add_Delta_Days { # done
    my ($yr,$mon,$day, $numdays) = @_;

    my $jd = julian_day($yr, $mon, $day);

    $jd += $numdays;

    ($yr, $mon, $day) = inverse_julian_day($jd);

    return ($yr,$mon,$day);
}

# ****************************************************************
sub Day_of_Week_to_Text { # done
    my $dow = shift;

    return $data{LONGDAYS}{$dow};
}

# ****************************************************************
sub Month_to_Text { # done
    my $mon = shift;

    return $data{LONGMONTHS}{$mon};
}

# ****************************************************************
sub Days_in_Year { # done
    my $yr = shift;
    my $mon = shift;
    my $days = 0;
    for (my $i=1;$i<=$mon;$i++) {
        $days += days_in($yr,$i);
    }

    return $days;
}

1;
__END__

=head1 NAME

PlotCalendar::DateTools - This is an all perl replacement for parts of
                          Date::Calc. I'd love to use it, but I ran into
                          trouble installing the compiled C onto my 
                          hosting service account, since I can't
                          do a compile over there (it'd cost $$)
                          So I have reproduced those functions I needed
                          in perl. Oh well.

=head1 SYNOPSIS

  require PlotCalendar::DateTools;

  my ($day, $month, $year) = (5,3,1999);
  my $dayname = 'Tuesday';

    # ----    initialize tool

      my $dow = Day_of_Year($yr,$mon,$day);

    my $numdays = Days_in_Month($yr,$mon);

    my $dow = Decode_Day_of_Week($dayname);

    my $dowfirst = Day_of_Week($yr,$mon,$day);

    my ($nyr, $nmon, $nday) = Add_Delta_Days($yr,$mon,$day, $numdays);

    my $dayname = Day_of_Week_to_Text($dow)

    my $month = Month_to_Text($mon);

    my $doy = Day_of_Year($year,$mon,$day);

=head1 DESCRIPTION

    A perl-only clone of a subset of Date::Calc

=head1 AUTHOR

    Alan Jackson
    April 1999
    ajackson@icct.net

=head1 REQUIREMENTS

    Requires modules : 
            Exporter
            Carp
            Time::DaysInMonth
            Time::JulianDay

=head1 SEE ALSO

PlotCalendar::Month
PlotCalendar::Day

=cut
