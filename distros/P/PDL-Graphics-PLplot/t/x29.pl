#  Sample plots using date / time formatting for axes
#
#  Copyright (C) 2007 Andrew Ross
#  Perl/PDL version 2008 Doug Hunt
#
#  This file is part of PLplot.
#
#    PLplot is free software; you can redistribute it and/or modify
#  it under the terms of the GNU Library General Public License as published
#  by the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  PLplot is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public License
#  along with PLplot; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#--------------------------------------------------------------------------
# main
# 
# Draws several plots which demonstrate the use of date / time formats for
# the axis labels.
# Time formatting is done using the system strftime routine. See the 
# documentation of this for full details of the available formats.
#
# 1) Plotting temperature over a day (using hours / minutes)
# 2) Plotting 
#
# Note: Times are stored as seconds since the epoch (usually 1st Jan 1970). 
# 
#--------------------------------------------------------------------------

use strict;
use warnings;
use PDL;
use PDL::Graphics::PLplot;
use Time::Local;
use List::Util;

use constant PI => 4*atan2(1,1);

# Parse command line arguments 
plParseOpts (\@ARGV, PL_PARSE_SKIP | PL_PARSE_NOPROGRAM);

# Initialize plplot 
plinit();

# Change the escape character to a '@' instead of the default '#'
plsesc('@');

plot1();

plot2();

plot3();

plot4();

# Don't forget to call plend() to finish off!
plend();

exit(0);

# Plot a model diurnal cycle of temperature 
sub plot1 {

    # Data points every 10 minutes for 1 day 
    my $npts = 73;

    my $xmin = 0;
    my $xmax = 60.0*60.0*24.0; # Number of seconds in a day
    my $ymin = 10.0;
    my $ymax = 20.0;

    my $x = $xmax * sequence($npts)/$npts;
    my $y = 15.0 - 5.0*cos(2*PI*sequence($npts)/$npts);
    my $xerr1 = $x-60.0*5.0;
    my $xerr2 = $x+60.0*5.0;
    my $yerr1 = $y-0.1;
    my $yerr2 = $y+0.1;
    
    pladv(0);

    plsmaj(0.0,0.5);
    plsmin(0.0,0.5);
    plvsta();
    plwind($xmin, $xmax, $ymin, $ymax);

    # Draw a box with ticks spaced every 3 hour in X and 1 degree C in Y.
    plcol0(1);

    # Set time format to be hours:minutes
    pltimefmt("%H:%M");
    plbox(3.0*60*60, 3, 1, 5, "bcnstd", "bcnstv");

    plcol0(3);
    pllab("Time (hours:mins)", "Temperature (degC)", '@frPLplot Example 29 - Daily temperature');
    
    plcol0(4);

    plline($x, $y);
    plcol0(2);
    plerrx($npts, $xerr1,$xerr2,$y);
    plcol0(3);
    plerry($npts, $x,$yerr1,$yerr2);

    plsmin(0.0,1.0);
    plsmaj(0.0,1.0);

}

# Plot the number of hours of daylight as a function of day for a year 
sub plot2 {

    # Latitude for London
    my $lat = 51.5;

    my $npts = 365;

    my $xmin = 0;
    my $xmax = $npts*60.0*60.0*24.0;
    my $ymin = 0;
    my $ymax = 24;
    
    # Formula for hours of daylight from 
    # "A Model Comparison for Daylength as a Function of Latitude and 
    # Day of the Year", 1995, Ecological Modelling, 80, pp 87-95.
    my $j = sequence($npts);
    my $x = $j * 60.0*60.0*24.0;
    my $p = asin(0.39795*cos(0.2163108 + 2*atan(0.9671396*tan(0.00860*($j-186)))));
    my $y = 24.0 - (24.0/PI) * 
	acos( (sin(0.8333*PI/180.0) + sin($lat*PI/180.0)*sin($p) ) / 
	      (cos($lat*PI/180)*cos($p)) );

    plcol0(1);
    # Set time format to be abbreviated month name followed by day of month 
    pltimefmt("%b %d");
    plprec(1,1);
    plenv($xmin, $xmax, $ymin, $ymax, 0, 40);

    plcol0(3);
    pllab("Date", "Hours of daylight", '@frPLplot Example 29 - Hours of daylight at 51.5N');
    
    plcol0(4);

    plline($x, $y);

    plprec(0,0);
    
}

# Return a 1D PDL consisting of the minimum of each pairwise
# element of the two input 1D PDLs
sub my_minover { return cat($_[0], $_[1])->xchg(0,1)->minimum }

sub plot3 {


    # Calculate seconds since the Unix epoch for 2005-12-01 UTC.
    my $tstart = timegm(0,0,0,1,11,105); 
    
    my $npts = 62;

    my $xmin = $tstart;
    my $xmax = $xmin + $npts*60.0*60.0*24.0;
    my $ymin = 0.0;
    my $ymax = 5.0;
    
    my $i = sequence($npts);
    my $x = $xmin + $i*60.0*60.0*24.0;
    my $y = 1.0 + sin( 2*PI*$i / 7 ) + exp( (my_minover($i,$npts-$i)) / 31.0);

    pladv(0);

    plvsta();
    plwind($xmin, $xmax, $ymin, $ymax);

    plcol0(1);

    # Set time format to be ISO 8601 standard YYYY-MM-DD. Note that this is
    # equivalent to %f for C99 compliant implementations of strftime.
    pltimefmt("%Y-%m-%d");

    # Draw a box with ticks spaced every 14 days in X and 1 hour in Y. 
    plbox(14*24.0*60.0*60.0,14, 1, 4, "bcnstd", "bcnstv");

    plcol0(3);
    pllab("Date", "Hours of television watched", '@frPLplot Example 29 - Hours of television watched in Dec 2005 / Jan 2006');
    
    plcol0(4);

    plssym(0.0,0.5);
    plpoin($x, $y, 2);
    plline($x, $y);

}

sub plot4 {

    # TAI-UTC (seconds) as a function of time.

    # Continuous time unit is Besselian years from whatever epoch is
    # chosen below.  Could change to seconds (or days) from the
    # epoch, but then would have to adjust xlabel_step below.
    my $scale   = 365.242198781;
    # MJD epoch (see <https://en.wikipedia.org/wiki/Julian_day>).
    # This is only set for illustrative purposes, and is overwritten
    # below for the time-representation reasons given in the
    # discussion below.
    my $epoch_year  = 1858;
    my $epoch_month = 11;
    my $epoch_day   = 17;
    my $epoch_hour  = 0;
    my $epoch_min   = 0;
    my $epoch_sec   = 0.;
    # To illustrate the time-representation issues of using the MJD
    # epoch, in 1985, MJD was roughly 46000 days which corresponds to
    # 4e9 seconds.  Thus, for the -DPL_DOUBLE=ON case where PLFLT is
    # a double which can represent continuous time to roughly 16
    # decimal digits of precision the time-representation error is
    # roughly ~400 nanoseconds.  Therefore the MJD epoch would be
    # acceptable for the plots below in the -DPL_DOUBLE=ON case.
    # However, that epoch is obviously not acceptable for the
    # -DPL_DOUBLE=OFF case where PLFLT is a float which can represent
    # continuous time to only ~7 decimal digits of precision
    # corresponding to a time representation error of 400 seconds (!)
    # in 1985.  For this reason, we do not use the MJD epoch below
    # and instead choose the best epoch for each case to minimize
    # time-representation issues.

    my $npts;
    my ($xmin, $xmax);
    my ($ymin, $ymax, $time_format, $if_TAI_time_format, $title_suffix);
    my ($xtitle, $xlabel_step);
    for ( my $kind = 0; $kind < 7; $kind++ )
    {
        if ( $kind == 0 )
        {
            # Choose midpoint to maximize time-representation precision.
            $epoch_year  = 1985;
            $epoch_month = 0;
            $epoch_day   = 2;
            $epoch_hour  = 0;
            $epoch_min   = 0;
            $epoch_sec   = 0.;
            plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
            $xmin = plctime(1950, 0, 2, 0, 0, 0);
            $xmax = plctime(2020, 0, 2, 0, 0, 0);
            $npts = 70 * 12 + 1;
            $ymin = 0.0;
            $ymax = 36.0;
            $time_format = "%Y%";
            $if_TAI_time_format = 1;
            $title_suffix = "from 1950 to 2020";
            $xtitle = "Year";
            $xlabel_step = 10;
        }
        elsif ( $kind == 1 || $kind == 2 )
        {
            # Choose midpoint to maximize time-representation precision.
            $epoch_year  = 1961;
            $epoch_month = 7;
            $epoch_day   = 1;
            $epoch_hour  = 0;
            $epoch_min   = 0;
            $epoch_sec   = 1.64757;
            plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
            $xmin = plctime(1961, 7, 1, 0, 0, 1.64757 - .20);
            $xmax = plctime( 1961, 7, 1, 0, 0, 1.64757 + .20);
            $npts = 1001;
            $ymin = 1.625;
            $ymax = 1.725;
            $time_format = "%S%2%";
            $title_suffix = "near 1961-08-01 (TAI)";
            $xlabel_step = 0.05 / ( $scale * 86400. );
            if ( $kind == 1 )
            {
                $if_TAI_time_format = 1;
                $xtitle = "Seconds (TAI)";
            }
            else
            {
                $if_TAI_time_format = 0;
                $xtitle = "Seconds (TAI) labelled with corresponding UTC";
            }
        }
        elsif ( $kind == 3 || $kind == 4 )
        {
            # Choose midpoint to maximize time-representation precision.
            $epoch_year  = 1963;
            $epoch_month = 10;
            $epoch_day   = 1;
            $epoch_hour  = 0;
            $epoch_min   = 0;
            $epoch_sec   = 2.6972788;
            plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
            $xmin = plctime(1963, 10, 1, 0, 0, 2.6972788 - .20);
            $xmax = plctime(1963, 10, 1, 0, 0, 2.6972788 + .20);
            $npts = 1001;
            $ymin = 2.55;
            $ymax = 2.75;
            $time_format = "%S%2%";
            $title_suffix = "near 1963-11-01 (TAI)";
            $xlabel_step = 0.05 / ( $scale * 86400. );
            if ( $kind == 3 )
            {
                $if_TAI_time_format = 1;
                $xtitle = "Seconds (TAI)";
            }
            else
            {
                $if_TAI_time_format = 0;
                $xtitle = "Seconds (TAI) labelled with corresponding UTC";
            }
        }
        elsif ( $kind == 5 || $kind == 6 )
        {
          # Choose midpoint to maximize time-representation precision.
          $epoch_year  = 2009;
          $epoch_month = 0;
          $epoch_day   = 1;
          $epoch_hour  = 0;
          $epoch_min   = 0;
          $epoch_sec   = 34.;
          plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
	  $xmin = plctime(2009, 0, 1, 0, 0, 34. - 5);
          $xmax = plctime(2009, 0, 1, 0, 0, 34. + 5);
          $npts = 1001;
          $ymin = 32.5;
          $ymax = 34.5;
          $time_format = "%S%2%";
          $title_suffix = "near 2009-01-01 (TAI)";
          $xlabel_step = 1. / ( $scale * 86400. );
	  if ( $kind == 5 )
            {
	      $if_TAI_time_format = 1;
	      $xtitle = "Seconds (TAI)";
            }
	  else
            {
	      $if_TAI_time_format = 0;
              $xtitle = "Seconds (TAI) labelled with corresponding UTC";
            }
        }

        my (@x, @y);
        for ( my $i = 0; $i < $npts; $i++ )
        {
	  $x[$i] = $xmin + $i * ( $xmax - $xmin ) / ( $npts - 1 );
          my $tai = $x[$i];
          plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
          my ($tai_year, $tai_month, $tai_day, $tai_hour, $tai_min, $tai_sec) = plbtime($tai);
          # Calculate residual using tai as the epoch to nearly maximize time-representation precision.
          plconfigtime( $scale, 0., 0., 0x0, 1, $tai_year, $tai_month, $tai_day, $tai_hour, $tai_min, $tai_sec );
          # Calculate continuous tai with new epoch.
          $tai = plctime( $tai_year, $tai_month, $tai_day, $tai_hour, $tai_min, $tai_sec );
          # Calculate broken-down utc (with leap seconds inserted) from continuous tai with new epoch.
          plconfigtime( $scale, 0., 0., 0x2, 1, $tai_year, $tai_month, $tai_day, $tai_hour, $tai_min, $tai_sec );
          my ($utc_year, $utc_month, $utc_day, $utc_hour, $utc_min, $utc_sec) = plbtime($tai);
          # Calculate continuous utc from broken-down utc using same epoch as for the continuous tai.
          plconfigtime( $scale, 0., 0., 0x0, 1, $tai_year, $tai_month, $tai_day, $tai_hour, $tai_min, $tai_sec );
          my $utc = plctime($utc_year, $utc_month, $utc_day, $utc_hour, $utc_min, $utc_sec);
          # Convert residuals to seconds.
          $y[$i] = ( $tai - $utc ) * $scale * 86400;
        }

        pladv( 0 );
        plvsta();
        plwind( $xmin, $xmax, $ymin, $ymax );
        plcol0( 1 );
        if ( $if_TAI_time_format ) {
            plconfigtime( $scale, 0., 0., 0x0, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
        } else {
            plconfigtime( $scale, 0., 0., 0x2, 1, $epoch_year, $epoch_month, $epoch_day, $epoch_hour, $epoch_min, $epoch_sec );
        }
        pltimefmt( $time_format );
        plbox( $xlabel_step, 0, 0, 0, "bcnstd",  "bcnstv" );
        plcol0( 3 );
        my $title  = '@frPLplot Example 29 - TAI-UTC ';
        $title .= $title_suffix;
        pllab( $xtitle, "TAI-UTC (sec)", $title );

        plcol0( 4 );

        plline( pdl(@x), pdl(@y) );
    }
}
