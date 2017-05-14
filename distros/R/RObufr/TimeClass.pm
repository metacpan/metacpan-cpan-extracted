#
##  Copyright (c) 1995-2004 University Corporation for Atmospheric Research
## All rights reserved
#
#/**----------------------------------------------------------------------    
# @file       TimeClass.pm
#
# Class for dealing with UTC and GPS times in various representations
#  
# @author     Chris Bogart
# @since      08/29/96
# @version    $URL: svn://lynx.cosmic.ucar.edu/trunk/src/perllib/TimeClass.pm $ $Id: TimeClass.pm 15056 2012-08-09 20:57:55Z jasonlin $
# @example    my $tc = TimeClass->new->set_yrdoy_gps('2004.004');
# @           my $gps = $tc->get_gps;
# @           my ($year, $month, $day, $hour, $minute, $second) = $tc->get_utc;
# -----------------------------------------------------------------------*/

package TimeClass;

use strict;
use Time::Local;
use List::Util;

#---------------------------------------------------------------------------
## Global variables
#---------------------------------------------------------------------------

# number of seconds between unix time base (1970)
# and gps time base (jan 6, 1980).  This neglects
# the growing leap second offset (now 11 seconds)
$TimeClass::GPSSEC = 315964800;


# This file contains a table of when leap seconds were added, but
# it has been taken out because it depends upon the presence of Bernese GNSS software.
$TimeClass::OFFSETFN = '';

$TimeClass::ignore_leapsec = 1;  # If true, do not do leap second conversion


#/**----------------------------------------------------------------------    
# @sub       new
# 
# Create a new TimeClass object
# 
# @parameter  type      Type of object (normally 'TimeClass' unless subclassed)
# @return     A blessed TimeClass object
# @example    my $tc = TimeClass->new;
# ----------------------------------------------------------------------*/
sub new
{
    my $type = shift;
    my $self = {};
    bless $self, $type;
    return $self;
}

#/**----------------------------------------------------------------------    
# @sub       set_gps
# 
# Create a new TimeClass object
# 
# @parameter  self     a TimeClass object
# @           gps_time The GPS time in seconds
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_gps
{
    my $self = shift;
    $self->_reset;
    $self->{"gps"} = shift;
    return $self;
}



#/**----------------------------------------------------------------------    
# @sub       set
# 
# Set from another time object
# 
# @parameter  set_to   a TimeClass object
# @           set_from a TimeClass object
# @return     new      a TimeClass object
# ----------------------------------------------------------------------*/
sub set { %{$_[0]} = %{$_[1]}; $_[0]; }


#/**----------------------------------------------------------------------    
# @sub       set_j2000
# 
# Set j2000 time
# 
# @parameter  self     a TimeClass object
# @           j2000 time in seconds
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_j2000
{
   my $self = shift;
   $self->_reset;
   $self->{"gps"} = (shift) + 630763200;
   $self;
}


#/**----------------------------------------------------------------------    
# @sub       get_j2000
# 
# Get j2000 time
# 
# @parameter  self     a TimeClass object
# @return     j2000 time, seconds
# ----------------------------------------------------------------------*/
sub get_j2000
{
   my $self = shift;
   return $self->get_gps - 630763200;
}


#/**----------------------------------------------------------------------    
# @sub       set_julian
# 
# Set Julian Date
# 
# @parameter  self     a TimeClass object
# @           julian date in days
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_julian
{
   my $self = shift;
   $self->_reset;
   my $julian = shift;
   $self->set_j2000(0);
   $self->inc_sec_gps( ($julian - 2451545.0) * (3600.0 * 24) );
   $self;
}

#/**----------------------------------------------------------------------    
# @sub       get_julian
# 
# Get Julian Date
# 
# @parameter  self     a TimeClass object
# @return     julian time, days
# ----------------------------------------------------------------------*/
sub get_julian
{
   my $self = shift;
   return ($self->get_j2000 / (3600*24.0) + 2451545);
}


#/**----------------------------------------------------------------------    
# @sub       set_tai93
# 
# Set TAI93 time
# 
# @parameter  self     a TimeClass object
# @           tai93 time in seconds (Seconds since 1/1/1993)
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_tai93
{
   my $self = shift;
   $self->_reset;
   $self->{"gps"} = (shift) + 409881608;
   $self;
}


#/**----------------------------------------------------------------------    
# @sub       get_tai93
# 
# Get TAI93 time
# 
# @parameter  self     a TimeClass object
# @return     Seconds since 1/1/1993
# ----------------------------------------------------------------------*/
sub get_tai93
{
   my $self = shift;
   return $self->get_gps - 409881608;   # Seconds since 1/1/1993
}


#/**----------------------------------------------------------------------    
# @sub       set_emp_utc
# 
# Set time from empress date 
# 
# @parameter  self     a TimeClass object
# @           empress date (assumed to be UTC) in format YYYYMMDDHHMMSS
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_emp_utc 
{ 
    my $self = shift;
    my $emp = shift;
    $self->_reset;

# Debug checks

    die "Illegal date: $emp" if (length($emp)<14);
    $self->set_utc( 
            substr($emp, 0, 4),
            substr($emp, 4, 2),
            substr($emp, 6, 2),
            substr($emp, 8, 2),
            substr($emp, 10, 2),
            substr($emp, 12, 2)  );

    return $self;
}


#/**----------------------------------------------------------------------    
# @sub       set_utc
# 
# Set UTC time from yr, mo, day, hr, min, sec
# Note: NOT the same order or convention as
#    unix time routines require
# 
# @parameter  self     a TimeClass object
# @           yr, mo, day, hr, min, sec -- Month 1-12, yr 4 digits
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_utc 
{
    my ($self, @gmstuff) = @_;

    $self->{"utc year"} = four_digit_year($gmstuff[0]);
    $self->{"utc month"} = $gmstuff[1];
    $self->{"utc day"} = $gmstuff[2];
    $self->{"utc hour"} = $gmstuff[3];
    $self->{"utc minute"} = $gmstuff[4];
    $self->{"utc second"} = $gmstuff[5];
    $self->_utc2unix;
}

#/**----------------------------------------------------------------------    
# @sub       set_utcII
# 
# Set UTC time from yr, day of yr, hr, min, sec
# 
# @parameter  self     a TimeClass object
# @           yr, day of yr, hr, min, sec 
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_utcII
{
    my ($self, @gmstuff)  = @_;

    $self->{"utc year"}   = four_digit_year($gmstuff[0]);
    ($self->{"utc month"}, $self->{"utc day"}) = 
      find_date ($gmstuff[0], $gmstuff[1]);
    $self->{"utc hour"}   = $gmstuff[2];
    $self->{"utc minute"} = $gmstuff[3];
    $self->{"utc second"} = $gmstuff[4];
    $self->_utc2unix;
}


#/**----------------------------------------------------------------------    
# @sub       set_unix
# 
# Set time from seconds since the unix epoch (1/1/1970)
# 
# @parameter  self     a TimeClass object
# @           seconds since the unix epoch (1/1/1970)
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_unix 
{
    my ($self, $unix) = @_;
    $self->_reset;
    $self->{"unix"} = $unix;
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub       set_uars
# 
# Set time from UARS day number (day 1.0 = Sept 12, 1991 at midnight UTC)
# 
# @parameter  self     a TimeClass object
# @           UARS day number (need not be an integer)
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_uars
{
  my ($self, $uarsday) = @_;
  $self->_reset;
  $self->{"gps"} = 368668800 + (86400 * $uarsday);
  return $self;
}


#/**----------------------------------------------------------------------    
# @sub       now
# 
# Set current UTC time (from system time clock)
# 
# @parameter  self     a TimeClass object
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub now { $_[0]->set_unix(time); }


#/**----------------------------------------------------------------------    
# @sub       get_gps
# 
# Return gps seconds, compensating for
# leap seconds if necessary
# 
# @parameter  self     a TimeClass object
# @return     gps seconds since 1/6/1980
# ----------------------------------------------------------------------*/
sub get_gps
{
    my $self = shift;
    if (!exists $self->{"gps"})
    {
        if (exists $self->{"unix"})
        {
            $self->{"gps"}  = $self->{"unix"} - $TimeClass::GPSSEC + find_leapsec($self->{"unix"} - $TimeClass::GPSSEC);
        }
    } 
    return $self->{"gps"} if (exists $self->{"gps"});
    die "Time not set";
}


#/**----------------------------------------------------------------------    
# @sub       get_gpsweek_day
# 
# Return gps week and day
# 
# @parameter  self     a TimeClass object
# @return     gps week
# @           gps day
# ----------------------------------------------------------------------*/
sub get_gpsweek_day
{
    my $self = shift;
    $self->get_gps;
    my $week = int($self->{"gps"} / (7 * 24 * 3600) );
    my $day = int(($self->{"gps"} - ($week * 7 * 24 * 3600)) / (24 * 3600));
    return ($week, $day);
}


#/**----------------------------------------------------------------------    
# @sub       set_gpsweek_day
# 
# Set gps week and day
# 
# @parameter  self     a TimeClass object
# @           gps week
# @           gps day
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_gpsweek_day
{
    my $self = shift;
    my $gpsweek = shift;
    my $gpsday = shift;

    die "Day must be between 0 and 6" if $gpsday > 6 || $gpsday < 0;

    $self->_reset;
    $self->{"gps"} = $gpsweek * 7 * 24 * 3600 + $gpsday * 24 * 3600;
    $self;
}


#/**----------------------------------------------------------------------    
# @sub       get_compact_date_utc
# 
# Return UTC date in %02d/%02d/%02d %02d:%02d:%02d format
# 
# @parameter  self     a TimeClass object
# @return     UTC date string
# ----------------------------------------------------------------------*/
sub get_compact_date_utc
{
    my $self = shift;
    $self->_create_utc;
    sprintf  "%02d/%02d/%02d %02d:%02d:%02d",
	$self->{"utc month"},
	$self->{"utc day"},
	two_digit_year($self->{"utc year"}),
	$self->{"utc hour"},
	$self->{"utc minute"},
	$self->{"utc second"};
}


#/**----------------------------------------------------------------------    
# @sub       get_compact_date_gps
# 
# Return GPS date in %02d/%02d/%02d %02d:%02d:%02d format
# 
# @parameter  self     a TimeClass object
# @return     GPS date string
# ----------------------------------------------------------------------*/
sub get_compact_date_gps
{
    my $self = shift;
    $self->_create_gps_breakdown;
    sprintf  "%02d/%02d/%02d %02d:%02d:%02d",
	$self->{"gps month"},
	$self->{"gps day"},
	two_digit_year($self->{"gps year"}),
	$self->{"gps hour"},
	$self->{"gps minute"},
	$self->{"gps second"};
}

#/**----------------------------------------------------------------------    
# @sub       get_yrdoyhms_gps
# 
# Return GPS yr, doy, hour, minute, second
# 
# @parameter  self     a TimeClass object
# @return     yr, doy, hour, minute, second
# ----------------------------------------------------------------------*/
sub get_yrdoyhms_gps {
    my $self = shift;
    $self->_create_gps_breakdown;
    return ($self->{"gps year"}, 
	    $self->{"gps doy"}, 
	    $self->{"gps hour"},
	    $self->{"gps minute"},
	    $self->{"gps second"});
}


#/**----------------------------------------------------------------------    
# @sub       get_unix
# 
# Return unix time in seconds since 1/1/1970
# 
# @parameter  self     a TimeClass object
# @return     unix seconds
# ----------------------------------------------------------------------*/
sub get_unix  
{
    my $self = shift;
    if (!exists $self->{"unix"})
    {
        if (exists $self->{"gps"})
        {
            $self->{"unix"}  = $self->{"gps"} + $TimeClass::GPSSEC - find_leapsec($self->{"gps"});
        }
    } 
    return $self->{"unix"} if (exists $self->{"unix"});
    die "Time not set";
}


#/**----------------------------------------------------------------------    
# @sub       set_emp_gps
# 
# Set time from an empress format (YYYYMMDDHHMMSS) time string in GPS time
# 
# @parameter  self     a TimeClass object
# @           date/time string
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_emp_gps 
{
    my ($self, $empgps) = @_;

    die "Illegal date: $empgps" if (length($empgps)<14);
    $self->_reset;
    $self->{"gps"} = Time::Local::timegm (
        substr($empgps, 12, 2),
        substr($empgps, 10, 2),
        substr($empgps, 8, 2),
        substr($empgps, 6, 2),
        substr($empgps, 4, 2)-1,
        substr($empgps, 0, 4)-1900) - $TimeClass::GPSSEC;
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub       get_emp_gps
# 
# Get time in empress format (YYYYMMDDHHMMSS) in GPS time system
# 
# @parameter  self     a TimeClass object
# @return     empress format (YYYYMMDDHHMMSS) time/date string
# ----------------------------------------------------------------------*/
sub get_emp_gps 
{
    my $self = shift;
    $self->_create_gps_breakdown;
    sprintf("%04d%02d%02d%02d%02d%02d",
        $self->{"gps year"},
        $self->{"gps month"},
        $self->{"gps day"},
        $self->{"gps hour"},
        $self->{"gps minute"},
        $self->{"gps second"});
}

#/**----------------------------------------------------------------------    
# @sub       get_stamp_gps
# 
# Get time in COSMIC time stamp format (YYYY.DDD.HH.MM.SS) in GPS time system
# 
# @parameter  self     a TimeClass object
# @return     time stamp format (YYYY.DDD.HH.MM.SS) time/date string
# ----------------------------------------------------------------------*/
sub get_stamp_gps 
{
    my $self = shift;
    $self->_create_gps_breakdown;
    sprintf("%04d.%03d.%02d.%02d.%02d",
        $self->{"gps year"},
        $self->{"gps doy"},
        $self->{"gps hour"},
        $self->{"gps minute"},
        $self->{"gps second"});
}

#/**----------------------------------------------------------------------    
# @sub       get_stamp_utc
# 
# Get time in COSMIC time stamp format (YYYY.DDD.HH.MM.SS) in UTC time system
# 
# @parameter  self     a TimeClass object
# @return     time stamp format (YYYY.DDD.HH.MM.SS) time/date string
# ----------------------------------------------------------------------*/
sub get_stamp_utc
{
    my $self = shift;
    $self->_create_utc;
    sprintf("%04d.%03d.%02d.%02d.%02d",
        $self->{"utc year"},
        $self->{"utc doy"},
        $self->{"utc hour"},
        $self->{"utc minute"},
        $self->{"utc second"});
}


#/**----------------------------------------------------------------------    
# @sub       get_emp_utc
# 
# Get time in empress format (YYYYMMDDHHMMSS) in UTC time system
# 
# @parameter  self     a TimeClass object
# @return     empress format (YYYYMMDDHHMMSS) time/date string
# ----------------------------------------------------------------------*/
sub get_emp_utc 
{
    my $self = shift;
    $self->_create_utc;
    sprintf("%04d%02d%02d%02d%02d%02d",
        $self->{"utc year"},
        $self->{"utc month"},
        $self->{"utc day"},
        $self->{"utc hour"},
        $self->{"utc minute"},
        $self->{"utc second"});
}


#/**----------------------------------------------------------------------    
# @sub    get_datestring_local    
# 
# Get local time (not Greenwich mean) date string
# 
# @parameter  self     a TimeClass object
# @return     local 'monthname day, year'
# ----------------------------------------------------------------------*/
sub get_datestring_local 
{
    my $self = shift;

    my $retval = "";

    $retval = $self->get_monthname_local;
    $retval .= " " . $self->{"local day"} . ", ";
    $retval .= $self->{"local year"};

    return $retval;
}


#/**----------------------------------------------------------------------    
# @sub    get_datestring_utc
# 
# Get UTC date string
# 
# @parameter  self     a TimeClass object
# @return     local 'monthname day, year'
# ----------------------------------------------------------------------*/
sub get_datestring_utc 
{
    my $self = shift;

    my $retval = "";

    $retval = $self->get_monthname_utc;
    $retval .= " " . $self->{"utc day"} . ", ";
    $retval .= $self->{"utc year"};

    return $retval;
}


#/**----------------------------------------------------------------------    
# @sub    get_datestring_gps
# 
# Get GPS time date string
# 
# @parameter  self     a TimeClass object
# @return     local 'monthname day, year'
# ----------------------------------------------------------------------*/
sub get_datestring_gps 
{
    my $self = shift;

    my $retval = "";

    $retval = $self->get_monthname_gps;
    $retval .= " " . $self->{"gps day"} . ", ";
    $retval .= $self->{"gps year"};

    return $retval;
 
}


#/**----------------------------------------------------------------------    
# @sub    get_timestring_local
# 
# Get local (not Greenwich) time string 
# 
# @parameter  self     a TimeClass object
# @return     local time in HH:MM:SS format
# ----------------------------------------------------------------------*/
sub get_timestring_local
{
    my $self = shift;

    $self->_create_local;
    sprintf(" %02d:%02d:%02d", $self->{"local hour"} , 
                    $self->{"local minute"},  $self->{"local second"});
}


#/**----------------------------------------------------------------------    
# @sub    get_timestring_utc
# 
# Get UTC time string 
# 
# @parameter  self     a TimeClass object
# @return     UTC time in HH:MM:SS format
# ----------------------------------------------------------------------*/
sub get_timestring_utc
{
    my $self = shift;

    $self->_create_utc;
    sprintf(" %02d:%02d:%02d", $self->{"utc hour"} , 
                    $self->{"utc minute"},  $self->{"utc second"});
}


#/**----------------------------------------------------------------------    
# @sub    get_timestring_gps
# 
# Get GPS time string 
# 
# @parameter  self     a TimeClass object
# @return     GPS time in HH:MM:SS format
# ----------------------------------------------------------------------*/
sub get_timestring_gps
{
    my $self = shift;

    $self->_create_gps_breakdown;
    sprintf(" %02d:%02d:%02d", $self->{"gps hour"} , 
                    $self->{"gps minute"},  $self->{"gps second"});
}


#/**----------------------------------------------------------------------    
# @sub    get_datetimestring_gps
# 
# Get GPS time/date string 
# 
# @parameter  self     a TimeClass object
# @return     GPS time in Month Day, year HH:MM:SS format
# ----------------------------------------------------------------------*/
sub get_datetimestring_gps 
{
    my $self = shift;

    return ($self->get_datestring_gps . " " . $self->get_timestring_gps);
}


#/**----------------------------------------------------------------------    
# @sub    get_bernestamp_gps
# 
# Get a time stamp in the Bernese format:  12-JUL-00 10:51
# 
# @parameter  self     a TimeClass object
# @return     GPS time in DD-MMM-YY HH:MM format
# ----------------------------------------------------------------------*/
sub get_bernestamp_gps 
{
  my $self = shift;
  
  my ($yr, $mon, $day, $hr, $min, $sec) = $self->get_ymdhms_gps;
  
  $yr = two_digit_year($yr);
  ($mon = $TimeClass::monthnames{$mon}) =~ tr/a-z/A-Z/;
  
  return sprintf ("%02d-$mon-%02d %02d:%02d", $day, $yr, $hr, $min);
}


#/**----------------------------------------------------------------------    
# @sub    get_datetimestring_utc
# 
# Get UTC time/date string 
# 
# @parameter  self     a TimeClass object
# @return     UTC time in Month Day, year HH:MM:SS format
# ----------------------------------------------------------------------*/
sub get_datetimestring_utc 
{
    my $self = shift;

    return ($self->get_datestring_utc . " " . $self->get_timestring_utc);
}

#/**----------------------------------------------------------------------    
# @sub   dec_day_utc  
# 
# Decrement the day in UTC time
# 
# @parameter  self     a TimeClass object
# @           days     Days to decrement (default = 1)
# @return     self     Timeclass object with several days earlier time
# ----------------------------------------------------------------------*/
sub dec_day_utc 
{
    my $self = shift;
    my $decrement = shift;
    $decrement = 1 if ! defined $decrement;

    $self->inc_day_utc(-$decrement);
}

#/**----------------------------------------------------------------------    
# @sub   inc_sec_unix
# 
# Increment seconds in unix time
# 
# @parameter  self     a TimeClass object
# @           increment in seconds, default = 1
# @return     self     Timeclass object with several seconds later time
# ----------------------------------------------------------------------*/
sub inc_sec_unix
{
    my $self = shift;
    my $increment = shift;
    $increment = 1 unless defined $increment;

    $self->set_unix($self->get_unix + $increment);
    $self;
}


#/**----------------------------------------------------------------------    
# @sub   inc_sec_gps
# 
# Increment seconds in gps time
# 
# @parameter  self     a TimeClass object
# @           increment in seconds, default = 1
# @return     self     Timeclass object with several seconds later time
# ----------------------------------------------------------------------*/
sub inc_sec_gps
{
    my $self = shift;
    my $increment = shift;
    $increment = 1 if ! defined $increment;
    $self->set_gps($self->get_gps + $increment);
    $self;
}


#/**----------------------------------------------------------------------    
# @sub   inc_day_utc
# 
# Increment days in utc time
# 
# @parameter  self     a TimeClass object
# @           increment in days, default = 1
# @return     self     Timeclass object with several days later time
# ----------------------------------------------------------------------*/
sub inc_day_utc 
{
    my $self = shift;
    my $increment = shift;
    $increment = 1 if ! defined $increment;

    $self->inc_sec_unix($increment * 24 * 3600);
    $self->_create_utc;
}


#/**----------------------------------------------------------------------    
# @sub   inc_month_utc
# 
# Increment months in utc time
# 
# @parameter  self     a TimeClass object
# @           increment in months, default = 1
# @return     self     Timeclass object with several months later time
# ----------------------------------------------------------------------*/
sub inc_month_utc 
{
    my $self = shift;
    my $increment = shift;
    $increment = 1 if ! defined $increment;

    $self->_create_utc;
    $self->{"utc month"} += $increment;
    if ($self->{"utc month"} > 12)
    {
        $self->{"utc year"} += int(($self->{"utc month"} - 1) / 12);
    }
    elsif ($self->{"utc month"} < 1)
    {
	$self->{"utc year"} += int(($self->{"utc month"} - 1) / 12 - 1);
    }
    $self->{"utc month"} = ($self->{"utc month"} % 12) ;
    $self->{"utc month"} = 12 if !$self->{"utc month"};
    $self->_utc2unix;
}


#/**----------------------------------------------------------------------    
# @sub   get_year_utc
# 
# Get UTC year
# 
# @parameter  self     a TimeClass object
# @return     UTC year
# ----------------------------------------------------------------------*/
sub get_year_utc
{
    my $self = shift;
    $self->_create_utc;
    return $self->{"utc year"};
}


#/**----------------------------------------------------------------------    
# @sub   get_month_utc
# 
# Get UTC month
# 
# @parameter  self     a TimeClass object
# @return     UTC month
# ----------------------------------------------------------------------*/
sub get_month_utc 
{
    my $self = shift;
    $self->_create_utc;
    return $self->{"utc month"};
}


#/**----------------------------------------------------------------------    
# @sub   get_day_utc
# 
# Get UTC day
# 
# @parameter  self     a TimeClass object
# @return     UTC day
# ----------------------------------------------------------------------*/
sub get_day_utc
{
    my $self = shift;
    $self->_create_utc;
    return $self->{"utc day"};
}


#/**----------------------------------------------------------------------    
# @sub   get_doy_utc
# 
# Get UTC doy
# 
# @parameter  self     a TimeClass object
# @return     UTC doy
# ----------------------------------------------------------------------*/
sub get_doy_utc
{
    my $self = shift;
    $self->_create_utc;
    return $self->{"utc doy"};
}

#/**----------------------------------------------------------------------    
# @sub   get_doy_gps
# 
# Get GPS doy
# 
# @parameter  self     a TimeClass object
# @return     GPS doy
# ----------------------------------------------------------------------*/
sub get_doy_gps
{
    my $self = shift;
    $self->_create_gps_breakdown;
    return $self->{"gps doy"};
}


#/**----------------------------------------------------------------------    
# @sub   get_hour_utc
# 
# Get UTC hour
# 
# @parameter  self     a TimeClass object
# @return     UTC hour
# ----------------------------------------------------------------------*/
sub get_hour_utc
{
    my $self = shift;
    $self->_create_utc;
    return $self->{"utc hour"};
}


#/**----------------------------------------------------------------------    
# @sub   get_year_gps
# 
# Get GPS year
# 
# @parameter  self     a TimeClass object
# @return     GPS year
# ----------------------------------------------------------------------*/
sub get_year_gps { 
    my $self = shift;
    $self->_create_gps_breakdown;
    return $self->{"gps year"};
}


#/**----------------------------------------------------------------------    
# @sub   get_month_gps
# 
# Get GPS month
# 
# @parameter  self     a TimeClass object
# @return     GPS month
# ----------------------------------------------------------------------*/
sub get_month_gps 
{
    my $self = shift;
    $self->_create_gps_breakdown;
    return $self->{"gps month"};
}


#/**----------------------------------------------------------------------    
# @sub   get_hour_gps
# 
# Get GPS hour
# 
# @parameter  self     a TimeClass object
# @return     GPS hour
# ----------------------------------------------------------------------*/
sub get_hour_gps
{
    my $self = shift;
    $self->_create_gps_breakdown;
    return $self->{"gps hour"};
}


#/**----------------------------------------------------------------------    
# @sub   get_utc
# 
# Get UTC time: year, month, day, hour, minute, second
# 
# @parameter  self     a TimeClass object
# @return     UTC time (6 values)
# ----------------------------------------------------------------------*/
sub get_utc
{
    my $self = shift;
    $self->_create_utc;
    return ($self->{"utc year"},
            $self->{"utc month"},
            $self->{"utc day"},
            $self->{"utc hour"},
            $self->{"utc minute"},
            $self->{"utc second"});

}


# Note:  These are used by outside routines before calling TimeClass routines
%TimeClass::rev_monthnames =
    ( "Jan"=>1,
      "Feb"=>2,
      "Mar"=>3,
      "Apr"=>4,
      "May"=>5,
      "Jun"=>6,
      "Jul"=>7,
      "Aug"=>8,
      "Sep"=>9,
      "Oct"=>10,
      "Nov"=>11,
      "Dec"=>12 );

%TimeClass::monthnames =
    ( 1=>"Jan",
      2=>"Feb",
      3=>"Mar",
      4=>"Apr",
      5=>"May",
      6=>"Jun",
      7=>"Jul",
      8=>"Aug",
      9=>"Sep",
      10=>"Oct",
      11=>"Nov",
      12=>"Dec" );

#/**----------------------------------------------------------------------    
# @sub get_monthname_gps
# 
# Get month name from number
# 
# @parameter  self     a TimeClass object
# @return     month name
# ----------------------------------------------------------------------*/
sub get_monthname_gps
{
    my $self = shift;
    return $TimeClass::monthnames{$self->get_month_gps};
}

#/**----------------------------------------------------------------------    
# @sub get_monthname_local
# 
# Get month name from number
# 
# @parameter  self     a TimeClass object
# @return     month name
# ----------------------------------------------------------------------*/
sub get_monthname_local
{
    my $self = shift;
    return $TimeClass::monthnames{$self->get_month_local};
}
 
#/**----------------------------------------------------------------------    
# @sub get_monthname_utc
# 
# Get month name from number
# 
# @parameter  self     a TimeClass object
# @return     month name
# ----------------------------------------------------------------------*/
sub get_monthname_utc
{
    my $self = shift;
    return $TimeClass::monthnames{$self->get_month_utc};
}                                                                               

#/**----------------------------------------------------------------------    
# @sub  set_ymdhms_gps
# 
# Set GPS time from yr, mo, day, hr, min, sec
# 
# @parameter  self     a TimeClass object
# @           yr, mon, day, hr, min, sec
# @return     self
# ----------------------------------------------------------------------*/
sub set_ymdhms_gps
{
    my $self = shift;
    my ($yr, $mo, $dy, $hr, $mi, $se) = @_;

    $self->_reset;
    $self->{"gps"} = Time::Local::timegm(int($se), $mi, $hr, $dy, $mo-1, 
		three_digit_year($yr)) - $TimeClass::GPSSEC + ($se - int($se));
    return $self;
}

#/**----------------------------------------------------------------------    
# @sub  set_yrdoy_gps
# 
# Set GPS time from 'YY.DDD' or 'YYYY.DDD'
# 
# @parameter  self     a TimeClass object
# @           string:  'YY.DDD' or 'YYYY.DDD'
# @return     self
# ----------------------------------------------------------------------*/
sub set_yrdoy_gps 
{
    my $self = shift;
    my $yrdoy = shift;

    $self->_reset;
    my ($yr, $doy)  = $yrdoy =~ /^(\d+)\.(\d+)$/; 
    my ($mo, $mday) = find_date ($yr, $doy);

    $self->{"gps"}  = 
      Time::Local::timegm(0,0,0, $mday, $mo-1, three_digit_year($yr)) - 
	$TimeClass::GPSSEC;
    return $self;
}

#/**----------------------------------------------------------------------    
# @sub  set_yrdoyhms_gps
# 
# Set GPS time from yr, doy, hr, min, sec
# 
# @parameter  self     a TimeClass object
# @           year, day of year, hour, minute and second (need not be an integer)
# @return     self
# ----------------------------------------------------------------------*/
sub set_yrdoyhms_gps 
{
    my $self = shift;
    my ($yr, $doy, $hr, $min, $sec) = @_;

    $self->_reset;
    my ($mo, $mday) = find_date ($yr, $doy);

    $self->{"gps"}  = 
      Time::Local::timegm(int($sec), $min, $hr, $mday, $mo-1, three_digit_year($yr)) - 
	$TimeClass::GPSSEC + ($sec - int($sec));
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub  set_yrfrac_gps
# 
# Set GPS time from a year with a fractional part
# 
# @parameter  self     a TimeClass object
# @           yr       a floating point year (eg 1997.04544)
# @return     self
# ----------------------------------------------------------------------*/
sub set_yrfrac_gps {
    my $self = shift;
    my $yr   = shift; # includes fractional part

    $self->_reset;

    my $month_days = find_month_days(int($yr));
    my $daysThisYear = List::Util::sum(@$month_days);

    my $doy = (($yr - int($yr)) * $daysThisYear) + 1;  # includes fractional part

    my ($mo, $mday) = find_date (int($yr), int($doy));

    my $hr  = ($doy - int($doy)) * 24; # includes fractional part
    my $min = ($hr  - int($hr))  * 60; # includes fractional part
    my $sec = ($min - int($min)) * 60; # includes fractional part

    $self->{"gps"}  = 
      Time::Local::timegm(int($sec), int($min), int($hr), $mday, $mo-1, three_digit_year(int($yr))) - 
	$TimeClass::GPSSEC + ($sec - int($sec));
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub  set_yrdoyfrac_gps
# 
# Set GPS time from a year and a day of year with a fractional part
# 
# @parameter  self     a TimeClass object
# @           yr       a year (eg 1997)
# @           doy      a day of year with a fractional part (eg 105.398383)
# @return     self
# ----------------------------------------------------------------------*/
sub set_yrdoyfrac_gps {
    my $self = shift;
    my $yr   = shift;
    my $doy  = shift; # includes fractional part

    $self->_reset;

    my ($mo, $mday) = find_date ($yr, int($doy));

    my $hr  = ($doy - int($doy)) * 24; # includes fractional part
    my $min = ($hr  - int($hr))  * 60; # includes fractional part
    my $sec = ($min - int($min)) * 60; # includes fractional part

    $self->{"gps"}  = 
      Time::Local::timegm(int($sec), int($min), int($hr), $mday, $mo-1, three_digit_year(int($yr))) - 
	$TimeClass::GPSSEC + ($sec - int($sec));
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub  set_yrdoy_utc
# 
# Set UTC time from 'YY.DDD' or 'YYYY.DDD'
# 
# @parameter  self     a TimeClass object
# @           string:  'YY.DDD' or 'YYYY.DDD'
# @return     self
# ----------------------------------------------------------------------*/
sub set_yrdoy_utc 
{
    my $self = shift;
    my $yrdoy = shift;
    my ($yr, $doy) = $yrdoy =~ /^(\d+)\.(\d+)$/; 
    my ($mo, $mday) = find_date ($yr, $doy);

    $self->_reset;
    $self->{"unix"} = Time::Local::timegm(0,0,0, $mday, $mo-1, three_digit_year($yr));
    return $self;
}


#/**----------------------------------------------------------------------    
# @sub  get_yrdoy_gps
# 
# Get GPS time in 'YYYY.DDD' format
# 
# @parameter  self     a TimeClass object
# @return     YYYY.DDD
# ----------------------------------------------------------------------*/
sub get_yrdoy_gps
{
    my $self = shift;

    $self->_create_gps_breakdown;
    sprintf("%04d.%03d", four_digit_year($self->{"gps year"}), $self->{"gps doy"});
}


#/**----------------------------------------------------------------------    
# @sub  get_yrdoy_local
# 
# Get local time in 'YY.DDD' format
# 
# @parameter  self     a TimeClass object
# @return     YY.DDD
# ----------------------------------------------------------------------*/
sub get_yrdoy_local
{
    my $self = shift;

    $self->_create_local;
    sprintf("%04d.%03d", four_digit_year($self->{"local year"}), $self->{"local doy"});
}


#/**----------------------------------------------------------------------    
# @sub  get_yrdoy_utc
# 
# Get UTC time in 'YY.DDD' format
# 
# @parameter  self     a TimeClass object
# @return     YY.DDD
# ----------------------------------------------------------------------*/
sub get_yrdoy_utc
{
    my $self = shift;

    $self->_create_utc;
    sprintf("%04d.%03d", four_digit_year($self->{"utc year"}), $self->{"utc doy"});
}


#/**----------------------------------------------------------------------    
# @sub  four_digit_year
#
# Either output the four digit year of the object,
# or if there's an argument, consider it a year
# and convert to four digits -- regardless of whether
# the argument is a 2, 3, or 4 digit year.
#
# This will have to be
# rewritten in 2050 because it assumes 2-digit
# years are between 1968 and 2050.  I hope we're
# not still converting 2 to 4 digit years in 2050;
# haven't we learned anything from the Y2K snafu?
# Note to grandchildren: get a clue.
#
# @parameter  self     a TimeClass object
# @           (optional) year
# @return     YYYY
# ----------------------------------------------------------------------*/
sub four_digit_year
{
    my ($self, $arg) = @_;
    if (!defined $arg)
    {
        $arg = $self->get_year_utc if ref $self;
        $arg = $self if !ref $self;
    }
    return 1900 + $arg if $arg>68 && $arg<150;
    return 2000 + $arg if $arg<51 and $arg > -1;
    return $arg if $arg < 9999 && $arg > 999;
    die "$arg -- unknown year";
}


#/**----------------------------------------------------------------------    
# @sub  two_digit_year
#
# Either output the two digit year of the object,
# or if there's an argument, consider it a year
# and convert to two digits -- regardless of whether
# the argument is a 2, 3, or 4 digit year.
#
# @parameter  self     a TimeClass object
# @           (optional) year
# @return     YY
# ----------------------------------------------------------------------*/
sub two_digit_year
{
    my ($self, $arg) = @_;
    if (!defined $arg)
    {
        $arg = $self->get_year_utc if ref $self;
        $arg = $self if !ref $self;
    }
    four_digit_year($arg) % 100;
}


#/**----------------------------------------------------------------------    
# @sub  three_digit_year
#
#  UNIX utc represents the year as number of years since
#  1900; so years after 1999 are three digits; e.g.
#  2019 is 119.  This is the same as two_digit_year
#  for years before 2000.
#
#  As of 1997 the Empress database doesn't handle dates
#  after Dec 31 2019.
#
# Either output the three digit year of the object,
# or if there's an argument, consider it a year
# and convert to three digits -- regardless of whether
# the argument is a 2, 3, or 4 digit year.
#
#
# @parameter  self     a TimeClass object
# @           (optional) year
# @return     YY[Y]
# ----------------------------------------------------------------------*/
sub three_digit_year
{
    my ($self, $arg) = @_;
    if (!defined $arg)
    {
        $arg = $self->get_year_utc if ref $self;
        $arg = $self if !ref $self;
    }
    four_digit_year($arg)-1900;
}


#/**----------------------------------------------------------------------    
# @sub  get_mjd
#
#  Get Modified Julian Day (based on gps time, not utc time)
#
# @parameter  self     a TimeClass object
# @return     Modified Julian Day
# ----------------------------------------------------------------------*/
sub get_mjd {
  my $self = shift;

  return ($self->get_gps / 86400) + 44244;  # 44244 is the number of days between
                                            # the modified julian day epoch and the GPS epoch
}


#/**----------------------------------------------------------------------    
# @sub  set_mjd
#
#  Set object based on input Modified Julian Day (based on gps time, not utc time)
#
# @parameter  self     a TimeClass object
# @           mjd      the time in MJD
# ----------------------------------------------------------------------*/
sub set_mjd {
  my $self = shift;
  my $mjd  = shift;

  die "input MJD time before GPS epoch" if (($mjd - 44244) < 0);

  $self->set_gps (($mjd - 44244) * 86400);
}



#/**----------------------------------------------------------------------    
# @sub  get_ymdhms_gps
#
# Get GPS time broken down
#
# @parameter  self     a TimeClass object
# @return     gps year, month, day, hour, minute and second 
# ----------------------------------------------------------------------*/
sub get_ymdhms_gps {
    my $self = shift;
    $self->_create_gps_breakdown();
    return ($self->{"gps year"},
            $self->{"gps month"},
            $self->{"gps day"},
            $self->{"gps hour"},
            $self->{"gps minute"},
            $self->{"gps second"});

}


#/**----------------------------------------------------------------------    
# @sub  find_dayofyr
#
# convert year, month, day to day of year
#
# @parameter  year (4 digit)
# @           month (1-12)
# @           day   (1-31)
# @return     day of year (1-366)
# ----------------------------------------------------------------------*/
sub find_dayofyr {

    my($year,$month,$date) = @_;  # get parms

    my $month_days = find_month_days ($year);

    my $dayofyear = 0;
    for (my $i = 1; $i < $month; $i++) {
	$dayofyear += $$month_days[$i];
    }
    $dayofyear += $date;

    $dayofyear;
}


#/**----------------------------------------------------------------------    
# @sub  find_date
#
# convert year, doy to month and date
#
# @parameter  year
# @           doy
# @return     month, day
# ----------------------------------------------------------------------*/
sub find_date {

    my($yr, $doy) = @_;  # get parms

    my $month_days = find_month_days ($yr);

    my $i;
    for ($i = 1; $i <= 12; $i++) {
	last if ($doy <= $$month_days[$i]);
	$doy -= $$month_days[$i];
    }
    my $month = $i;
    return ($month, $doy);
}

#/**----------------------------------------------------------------------    
# @sub  month2daterange
#
# Convert a year and month number to a daterange.
#
# @parameter  year
# @           month
# @return     YYYY.DDD-DDD
# ----------------------------------------------------------------------*/
sub month2daterange {

  my($yr, $mon) = @_;  # get parms

  # Find YYYY.DDD.AAA for input YYYY MM
  my $sdoy = find_dayofyr ($yr, $mon, 1);
  my $month_days = find_month_days ($yr);

  die "bad month: $mon (must be an integer 1-12)" if (int($mon) != $mon || $mon < 1 || $mon > 12);

  return sprintf "%04d.%03d-%03d", $yr, $sdoy, ($sdoy + $$month_days[$mon] - 1);
}


#/**----------------------------------------------------------------------    
# @sub  find_leapsec
#
# Given an input gps time value, return the
# number of leap seconds needed to subtract
# between utc and gps time
#
# @parameter  gps time 
# @return     number of leapseconds
# ----------------------------------------------------------------------*/
sub find_leapsec {

  my $tin = shift;

  return 0 if ($TimeClass::ignore_leapsec);

  my ($lsdate, $offset, @dates, @offsets, $sec, $min, $hr,
      $day, $mon, $d, $myoffset, $yr, $utcidx);

  # Read in table of leap seconds.  
  open (LS, $TimeClass::OFFSETFN) || die "Cannot open $TimeClass::OFFSETFN";
  @dates = (); @offsets = ();
  while (defined(my $line = <LS>)) {
    my ($offset, $yr, $mo, $dy) = split(' ', $line);
    next unless (defined($yr) && $yr =~ /^\d\d\d\d$/);

    push (@dates,   sprintf ("%04d%02d%02d000000", $yr, $mo, $dy));
    push (@offsets, $offset);
  }

  # First stab at time conversion (without leap second correction)
  ($sec, $min, $hr, $day, $mon, $yr, $d, $d, $d) = gmtime($tin + $TimeClass::GPSSEC);
  $mon++; # month is a zero-based array

  # Determine number of leap seconds for input date
  $utcidx = sprintf ("%04d%02d%02d%02d%02d%02d",
                     $yr+1900, $mon, $day, $hr, $min, $sec);
  while ($utcidx > shift @dates) {
    $myoffset = shift @offsets;
    last if (@offsets == 0);
  }

  return $myoffset;
}

#/**----------------------------------------------------------------------
# @sub  find_month_days
#
# Given an input year, compute an array of days in each month (1-based)
#
# @parameter  year
# @return     Array ref: 1-based array of days in each month, 1-12
# ----------------------------------------------------------------------*/
sub find_month_days {

  my $yr = shift;

    my $feb = 28;
    if    ($yr % 4   == 0) {$feb = 29;}
    if    ($yr % 100 == 0) {$feb = 28;}
    if    ($yr % 400 == 0) {$feb = 29;}
    my @months = (0, 31, $feb, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  return \@months;
}


#--------------------------------------------------------------------------------------
## Utility routines (internal use only)
#--------------------------------------------------------------------------------------

# Clear out TimeClass object
sub _reset
{
    my $self = shift;

    undef %$self;
}

# 
# Set gps year, month, day, etc. from unix or gps time
# 
sub _create_gps_breakdown
{
    my $self = shift;
    my $gpssec = $self->get_gps;
    my @mkta = gmtime($gpssec + $TimeClass::GPSSEC);
    my $frac = $gpssec - int($gpssec);
    $self->{"gps second"} = $mkta[0] + $frac; # restore fractional part
    $self->{"gps minute"} = $mkta[1];
    $self->{"gps hour"} = $mkta[2];
    $self->{"gps day"} = $mkta[3];
    $self->{"gps month"} = $mkta[4] + 1;
    $self->{"gps year"} = $mkta[5] + 1900;
    $self->{"gps doy"} = $mkta[7] + 1;
    return $self;
}

#
#  Set local year, month, day, etc. from unix or gps time
#
sub _create_local
{
    my $self = shift;
    return if exists $self->{"local second"};
    my @mkta = localtime($self->get_unix);
    $self->{"local second"} = $mkta[0];
    $self->{"local minute"} = $mkta[1];
    $self->{"local hour"}   = $mkta[2];
    $self->{"local day"}    = $mkta[3];
    $self->{"local month"}  = $mkta[4] + 1;
    $self->{"local year"}   = $mkta[5] + 1900;
    $self->{"local doy"}    = $mkta[7] + 1;
    return $self;
}

#
#  Set utc year, month, day, etc. from unix or gps time
#
sub _create_utc
{
    my $self = shift;
    return if exists $self->{"utc second"};

    my $unix = $self->get_unix;
    my @mkta = gmtime($unix);
    my $frac = $unix - int($unix);
    $self->{"utc second"} = $mkta[0] + $frac; # restore fractional part
    $self->{"utc minute"} = $mkta[1];
    $self->{"utc hour"} = $mkta[2];
    $self->{"utc day"} = $mkta[3];
    $self->{"utc month"} = $mkta[4] + 1;
    $self->{"utc year"} = $mkta[5] + 1900;
    $self->{"utc doy"} = $mkta[7] + 1;
    return $self;
}

# Convert utc time to unix seconds
sub _utc2unix
{
    my $self = shift;

    my $sec = $self->{"utc second"};
    my $frac = $sec - int($sec);

    my $unix = Time::Local::timegm(
        $sec,
        $self->{"utc minute"},    
        $self->{"utc hour"},    
        $self->{"utc day"},    
        $self->{"utc month"} - 1,    
        $self->{"utc year"} - 1900);
    $self->_reset;
    $self->{"unix"} = $unix + $frac; # restore fractional part
    $self->{"unix"} = 0 if ($unix eq "0 but true");
    return $self;
}


#
######################################################################
# TimeRange, subclass of TimeClass
######################################################################
#
package TimeRange;

use strict;

@TimeRange::ISA = qw(TimeClass);

#/**----------------------------------------------------------------------    
# @sub       set_daterange
# 
# Create a new TimeClass object with a date range in it.
# This creates a TimeClass object with start and end times in it as
# well.
# 
# @parameter  self     a TimeClass object
# @           daterange:  YYYY.DDD or YYYY.DDD-DDD or YYYY.DDD-YYYY.DDD or 
#                         YYYY.DDD,YYYY.DDD-DDD,YYYY.DDD-YYYY.DDD
# @return     self     a TimeClass object
# ----------------------------------------------------------------------*/
sub set_daterange
{
    my $self = shift;
    my $range = shift;

    my @sections = split (/\,/, $range);
    $self->_reset;

    foreach my $range (@sections) {

      my @parts = split (/[\.\-]/, $range);
      my $tc = TimeClass->new;
      if      (@parts == 2) {
	push (@{$self->{"startgps"}}, $tc->set_yrdoy_gps($range)->get_gps);
	push (@{$self->{"endgps"}},   $tc->set_yrdoy_gps($range)->get_gps);
      } elsif (@parts == 3) {
	my $start = sprintf ("%04d.%03d", @parts[0,1]);
	my $end   = sprintf ("%04d.%03d", @parts[0,2]);
	push (@{$self->{"startgps"}}, $tc->set_yrdoy_gps($start)->get_gps);
	push (@{$self->{"endgps"}},   $tc->set_yrdoy_gps($end)->get_gps);
      } elsif (@parts == 4) {
	my $start = sprintf ("%04d.%03d", @parts[0,1]);
	my $end   = sprintf ("%04d.%03d", @parts[2,3]);
	push (@{$self->{"startgps"}}, $tc->set_yrdoy_gps($start)->get_gps);
	push (@{$self->{"endgps"}},   $tc->set_yrdoy_gps($end)->get_gps);
      }
    }
    $self->{"gps"}  = $self->{"startgps"}[0];  # earliest time.
    return $self;
}

#/**----------------------------------------------------------------------    
# @sub       get_dates
# 
# Retrieve a list of YYYY.DDD strings from the input TimeRange object, 
# Based on the input increment in days (default = 1 day).
# 
# @parameter  self     a TimeRange object
# @           inc      optional:  time increment.  Defaults to one day.
# @return     self     a TimeRange object
# ----------------------------------------------------------------------*/
sub get_dates {
    my $self  = shift;
    my $inc   = shift || 1;
    my @dates = ();
    my $tc    = TimeClass->new;

    SECTION:
    for (my $i=0;$i<@{$self->{"startgps"}};$i++) {
      my $time = $self->{"startgps"}[$i];
      my $end  = $self->{"endgps"}[$i];

      DAY:
      while (1) {
	last DAY if ($time > $end);
	push (@dates, $tc->set_gps($time)->get_yrdoy_gps);
	$time += ($inc*86400);
      }
    }

    return @dates;
}



#
#  SOME TIME INFORMATION NOT CURRENTLY USED -- COULD BE USEFUL IN THE FUTURE...
#
#Description: A time stream together with a format comprise the archival parameter time. Listed below are values
#for the same instant in time (0 hours, 0 minutes, 0 seconds, October 1, 1986) for the four time streams the CERES
#DMS would be most likely to use, displayed in the Julian date format:
#
#2446704.50026620 in International Atomic Time (TAI) = continuous count of seconds at the uniform rate of the
#atomic clock.
#
#2446704.50000000 in Coordinated Universal Time (UTC) = TAI - accumulated leap seconds, in sync with the
#diurnal cycle.
#(minor editorial correction to preceding line .. Pdn)
#
#2446704.50063870 in Terrestrial Dynamical Time (TAI) = UTC + 32.184 seconds.
#(minor editorial correction to preceding line .. Pdn)
#
#2446704.50063868 in Barycentric Dynamical Time (TDB) ~ TDT + 0.001658 * sin(g) + 0.000014 * sin(2g) in
#seconds where g = 357.53 + 0.9856003 * (JD - 2451545.0) in degrees.
#
#Utilizing the UTC time stream value for the same time instant as above, its representations in the two formats the
#CERES DMS would be most likely to use are:
#
#CCSDS ASCII Format A Julian Date
#1986-10-01T00:00:00.0Z 2446704.5000000
#




1;
