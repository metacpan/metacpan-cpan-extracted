################################################################################
#
# $Id: LocalTime.pm 211 2009-05-25 06:05:50Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::LocalTime - Module to provide local time.  Can be made to return requested values during testing.

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

This is a simple package that provides a location for the getLogDir
function that's used in a few places.

=head1 METHODS

=cut

package TaskForest::LocalTime;
use strict;
use warnings;
use Carp;
use DateTime;

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
sub setTime {
    my $args = shift;

    unless($args) {
        $time_offset = 0;
        return;
    }
    
    my $dt = DateTime->new( year   => $args->{year},
                            month  => $args->{month},
                            day    => $args->{day},
                            hour   => $args->{hour},
                            minute => $args->{min},
                            second => $args->{sec},
                            time_zone => $args->{tz},
        );

    my $desired_epoch = $dt->epoch();
    
    $time_offset = time() - $desired_epoch;
    
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item lt()

 Usage     : &LocalTime::setTime({ year  => $year,
                                   month => $mon,
                                   day   => $day,
                                   hour  => $hour,
                                   min   => $min,
                                   sec   => $sec,
                                   tz    => $tz
                                   });
             my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &LocalTime::lt();
 Purpose   : This method returns the localtime or the time that was previously
             set with setTime.  Time set with setTime will advance.             
 Returns   : Nothing 
 Argument  : A hash of values
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub lt {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time() - $time_offset ); $mon++; $year += 1900;

    return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
}



sub epoch {
    return time() - $time_offset;
}



sub ft {
    my $tz = shift;
    my $epoch = time() - $time_offset;
    my $dt = DateTime->from_epoch(epoch => $epoch);
    $dt->set_time_zone($tz);
    
    #return ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
    return ($dt->second,
            $dt->minute,
            $dt->hour,
            $dt->day,
            $dt->month,
            $dt->year,
            $dt->day_of_week % 7,
            undef,
            undef);
}



1;
