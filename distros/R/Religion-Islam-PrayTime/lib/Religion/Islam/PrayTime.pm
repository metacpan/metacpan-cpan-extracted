#=Copyright Infomation
#==========================================================
#Module Name       : Religion::Islam::PrayTime
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.islamware.com, http://www.mewsoft.com
#Contact Email      : support@islamware.com, support@mewsoft.com
#Copyrights  2013-2014 IslamWare. All rights reserved.
#==========================================================
package Religion::Islam::PrayTime;

use strict;
use Carp;
use POSIX;
use Time::Local;
use constant PI => 4 * atan2(1, 1);	#3.1415926535897932

our $VERSION = '1.06';
#=========================================================#
sub new {
my ($class, $methodID) = @_;
    
	my $self = bless {}, $class;
    #------------------------ Constants --------------------------
    # Calculation Methods
	$self->{Jafari} = 0;						# Ithna Ashari
	$self->{Karachi} = 1;					# University of Islamic Sciences, Karachi
	$self->{ISNA} = 2;						# Islamic Society of North America (ISNA)
	$self->{MWL} = 3;						# Muslim World League (MWL)
	$self->{Makkah} = 4;					# Umm al-Qura, Makkah
	$self->{Egypt} = 5;						# Egyptian General Authority of Survey
	$self->{Tehran} = 6;					# Institute of Geophysics, University of Tehran
	$self->{Custom} = 7;					# Custom Setting

    # Juristic Methods
    $self->{Shafii} = 0;						# Shafii (standard)
	$self->{Hanafi} = 1;					# Hanafi

    # Adjusting Methods for Higher Latitudes
    $self->{None} = 0;							# No adjustment
    $self->{MidNight} = 1;					# middle of night
    $self->{OneSeventh} = 2;				# 1/7th of night
    $self->{AngleBased} = 3;				# angle/60th of night

    # Time Formats
    $self->{Time24} = 0;					# 24-hour format
    $self->{Time12} = 1;					# 12-hour format
    $self->{Time12NS} = 2;				# 12-hour format with no suffix
    $self->{Float} = 3;						# floating point number

	$self->{decimal_size} = 2;			# decimal size for Float time format

    # Time Names
    $self->{timeNames} = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Sunset', 'Maghrib', 'Isha'];

    $self->{InvalidTime} = '-----';			# The string used for invalid times

    #---------------------- Global Variables --------------------
    $self->{calcMethod} =  5;				# Calculation method
    $self->{asrJuristic} = 0;					# Juristic method for Asr
    $self->{dhuhrMinutes} = 0;				# minutes after mid-day for Dhuhr
    $self->{adjustHighLats} = 0;			# adjusting method for higher latitudes

    $self->{timeFormat}   = 0;				# time format

    $self->{lat} = 0;								# latitude
    $self->{lng} = 0;								# longitude
    $self->{timeZone} = 0;					# time-zone
    $self->{JDate} = 0;							# Julian date
    
	#--------------------- Technical Settings --------------------
    $self->{numIterations} = 1;				# number of iterations needed to compute times
    #------------------- Calc Method Parameters --------------------
    #$self->{methodParams};
	
	$self->{am} = "am";
	$self->{pm} = "pm";

	$methodID += 0;
	$self->PrayTime($methodID);

    return $self;
}
#=========================================================#
sub PrayTime {
my ($self, $methodID) = @_;
	
	#  $self->{methodParams}->{methodNum} = array(fa, ms, mv, is, iv);
	#	fa : fajr angle
	#	ms : maghrib selector (0 = angle; 1 = minutes after sunset)
	#	mv : maghrib parameter value (in angle or minutes)
	#	is : isha selector (0 = angle; 1 = minutes after maghrib)
	#	iv : isha parameter value (in angle or minutes)

	$methodID += 0;
	$self->{methodParams}{$self->{Jafari}} = [16, 0, 4, 0, 14];
	$self->{methodParams}{$self->{Karachi}} = [18, 1, 0, 0, 18];
	$self->{methodParams}{$self->{ISNA}} = [15, 1, 0, 0, 15];
	$self->{methodParams}{$self->{MWL}} = [18, 1, 0, 0, 17];
	$self->{methodParams}{$self->{Makkah}} = [18.5, 1, 0, 1, 90];
	$self->{methodParams}{$self->{Egypt}} = [19.5, 1, 0, 0, 17.5];
	$self->{methodParams}{$self->{Tehran}} = [17.7, 0, 4.5, 0, 14];
	$self->{methodParams}{$self->{Custom}} = [18, 1, 0, 0, 17];
	$self->setCalcMethod($methodID);
}
#=========================================================#
# -------------------- Interface Functions --------------------
# return prayer times for a given date
sub getDatePrayerTimes {
my ($self, $year, $month, $day, $latitude, $longitude, $timeZone) = @_;
	$self->{lat} = $latitude;
	$self->{lng} = $longitude;
	$self->{timeZone} = $timeZone;
	$self->{JDate} = $self->julianDate($year, $month, $day) - ($longitude/(15* 24));
	return $self->computeDayTimes();
}

# return prayer times for a given timestamp
sub getPrayerTimes {
my ($self, $timestamp, $latitude, $longitude, $timeZone) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime($timestamp);
	$mon++;
	$year += 1900;
	return $self->getDatePrayerTimes($year, $mon, $mday, $latitude, $longitude, $timeZone);
}

# return prayer times for a given date in a hash
sub getDatePrayerTimesHash {
my ($self, $year, $month, $day, $latitude, $longitude, $timeZone) = @_;
	my %times;
	@times{@{$self->{timeNames}}} = $self->getDatePrayerTimes($year, $month, $day, $latitude, $longitude, $timeZone);
	return %times;
}

# return prayer times for a given timestamp in a hash
sub getPrayerTimesHash {
my ($self, $timestamp, $latitude, $longitude, $timeZone) = @_;
	my %times;
	@times{@{$self->{timeNames}}} = $self->getPrayerTimes($timestamp, $latitude, $longitude, $timeZone);
	return %times;
}

# set the calculation method
sub setCalcMethod {
my ($self, $methodID) = @_;
	$self->{calcMethod} = $methodID;
}

# set the juristic method for Asr
sub setAsrMethod {
my ($self, $methodID) = @_;
	if ($methodID < 0 || $methodID > 1) {return};
	$self->{asrJuristic} = $methodID;
}

# set the angle for calculating Fajr
sub setFajrAngle {
my ($self, $angle) = @_;
	$self->setCustomParams($angle, undef, undef, undef, undef);
}

#set the angle for calculating Maghrib
sub setMaghribAngle {
my ($self, $angle) = @_;
	$self->setCustomParams(undef, 0, $angle, undef, undef);
}

# set the angle for calculating Isha
sub setIshaAngle {
my ($self, $angle) = @_;
	$self->setCustomParams(undef, undef, undef, 0, $angle);
}

# set the minutes after mid-day for calculating Dhuhr
sub setDhuhrMinutes {
my ($self, $minutes) = @_;
	$self->{dhuhrMinutes} = $minutes;
}

#set the minutes after Sunset for calculating Maghrib
sub setMaghribMinutes {
my ($self, $minutes) = @_;
	$self->setCustomParams(undef, 1, $minutes, undef, undef);
}

#set the minutes after Maghrib for calculating Isha
sub setIshaMinutes {
my ($self, $minutes) = @_;
	$self->setCustomParams(undef, undef, undef, 1, $minutes);
}

# set custom values for calculation parameters
sub setCustomParams {
my ($self, @params) = @_;
	for (my $i=0; $i<5; $i++)  {
		if (!defined($params[$i])) {
			$self->{methodParams}->{$self->{Custom}}[$i] = $self->{methodParams}->{$self->{calcMethod}}[$i];
		}
		else {
			$self->{methodParams}->{$self->{Custom}}[$i] = $params[$i];
		}
	}
	$self->{calcMethod} = $self->{Custom};
}

# set adjusting method for higher latitudes
sub setHighLatsMethod {
my ($self, $methodID) = @_;
	$self->{adjustHighLats} = $methodID;
}

# set the time format
sub setTimeFormat {
my ($self, $timeFormat) = @_;
	$self->{timeFormat} = $timeFormat;
}

sub am_pm {
my ($self, $am, $pm) = @_;
	$self->{am} = $am;
	$self->{pm} = $pm;
	return ($self->{am}, $self->{pm});
}

# convert float hours to 24h format
sub floatToTime24 {
my ($self, $time) = @_;
	if (!$time) {return $self->{InvalidTime}};
	$time = $self->fixhour($time+ 0.5/ 60);  #add 0.5 minutes to round
	my $hours = floor($time);
	my $minutes = floor(($time- $hours)* 60);
	return $self->twoDigitsFormat($hours). ':'. $self->twoDigitsFormat($minutes);
}

# convert float hours to 12h format
sub floatToTime12 {
my ($self, $time, $noSuffix) = @_;
	$noSuffix ||= "";
	if (!$time) {return $self->{InvalidTime}};
	$time = $self->fixhour($time+ 0.5/ 60);  # add 0.5 minutes to round
	my $hours = floor($time);
	my $minutes = floor(($time- $hours)* 60);
	my $suffix = $hours >= 12 ? $self->{pm} : $self->{am};
	$hours = ($hours+ 12- 1)% 12+ 1;
	return $hours. ':'. $self->twoDigitsFormat($minutes). ($noSuffix ? '' : $suffix);
}

# convert float hours to 12h format with no suffix
sub floatToTime12NS {
my ($self, $time) = @_;
	return $self->floatToTime12($time, 1);
}

#---------------------- Calculation Functions -----------------------
# References:
# http://www.ummah.net/astronomy/saltime
# http://aa.usno.navy.mil/faq/docs/SunApprox.html

# compute declination angle of sun and equation of time
sub sunPosition {
my ($self, $jd) = @_;

	my $D = $jd - 2451545.0;

	my $g = $self->fixangle(357.529 + 0.98560028* $D);
	my $q = $self->fixangle(280.459 + 0.98564736* $D);
	my $L = $self->fixangle($q + 1.915* $self->dsin($g) + 0.020* $self->dsin(2*$g));
	my $R = 1.00014 - 0.01671* $self->dcos($g) - 0.00014* $self->dcos(2*$g);
	my $e = 23.439 - 0.00000036* $D;

	my $d = $self->darcsin($self->dsin($e)* $self->dsin($L));
	my $RA = $self->darctan2($self->dcos($e)* $self->dsin($L), $self->dcos($L))/ 15;
	
	my $RA = $self->fixhour($RA);
	my $EqT = $q/15 - $RA;
	
	return ($d, $EqT);
}

# compute equation of time
sub equationOfTime {
my ($self, $jd) = @_;
	my @sp = $self->sunPosition($jd);
	return $sp[1];
}

# compute declination angle of sun
sub sunDeclination {
my ($self, $jd) = @_;
	my @sp = $self->sunPosition($jd);
	return $sp[0];
}

# compute mid-day (Dhuhr, Zawal) time
sub computeMidDay {
my ($self, $t) = @_;
	my $T = $self->equationOfTime($self->{JDate}+ $t);
	my $Z = $self->fixhour(12- $T);
	return $Z;
}

# compute time for a given angle G
sub computeTime {
my ($self, $G, $t) = @_;
	my $D = $self->sunDeclination($self->{JDate}+ $t);
	my $Z = $self->computeMidDay($t);
	my $V = 1/15* $self->darccos((-$self->dsin($G)- $self->dsin($D)* $self->dsin($self->{lat}))/($self->dcos($D)* $self->dcos($self->{lat})));
	return ($Z+ ($G>90 ? -$V : $V));
}

# compute the time of Asr
# Shafii: step=1, Hanafi: step=2
sub computeAsr {
my ($self, $step, $t) = @_;
	my $D = $self->sunDeclination($self->{JDate}+ $t);
	my $G = -$self->darccot($step+ $self->dtan(abs($self->{lat}- $D)));
	return $self->computeTime($G, $t);
}

#---------------------- Compute Prayer Times -----------------------
# compute prayer times at given julian date
sub computeTimes {
my ($self, @times) = @_;

	my @t = $self->dayPortion(@times);

	my $Fajr    = $self->computeTime(180- $self->{methodParams}->{$self->{calcMethod}}[0], $t[0]);
	my $Sunrise = $self->computeTime(180- 0.833, $t[1]);
	my $Dhuhr   = $self->computeMidDay($t[2]);
	my $Asr     = $self->computeAsr(1+ $self->{asrJuristic}, $t[3]);
	my $Sunset  = $self->computeTime(0.833, $t[4]);
	my $Maghrib = $self->computeTime($self->{methodParams}->{$self->{calcMethod}}[2], $t[5]);
	my $Isha    = $self->computeTime($self->{methodParams}->{$self->{calcMethod}}[4], $t[6]);

	return ($Fajr, $Sunrise, $Dhuhr, $Asr, $Sunset, $Maghrib, $Isha);
}

# compute prayer times at given julian date
sub computeDayTimes {
my ($self) = @_;
	my @times = (5, 6, 12, 13, 18, 18, 18); #default times

	for (my $i=1; $i<=$self->{numIterations}; $i++) {
		@times = $self->computeTimes(@times);
	}
	@times = $self->adjustTimes(@times);
	return $self->adjustTimesFormat(@times);
}

# adjust times in a prayer time array
sub adjustTimes {
my ($self, @times) = @_;

	for (my $i=0; $i<7; $i++) {
		$times[$i] += $self->{timeZone} - $self->{lng}/15;
	}

	$times[2] += $self->{dhuhrMinutes}/60; #Dhuhr
	
	# Maghrib
	if ($self->{methodParams}->{$self->{calcMethod}}[1] == 1) {
		$times[5] = $times[4] + $self->{methodParams}->{$self->{calcMethod}}[2]/60;
	}
	
	# Isha
	if ($self->{methodParams}->{$self->{calcMethod}}[3] == 1) {
		$times[6] = $times[5]+ $self->{methodParams}->{$self->{calcMethod}}[4]/60;
	}

	if ($self->{adjustHighLats} != $self->{None}) {
		@times = $self->adjustHighLatTimes(@times);
	}
	return @times;
}

# convert times array to given time format
sub adjustTimesFormat {
my ($self, @times) = @_;

	if ($self->{timeFormat} == $self->{Float}) {
		map {$_ = sprintf("%0.$self->{decimal_size}f", $_)} @times;
		return @times;
	};

	for (my $i=0; $i<7; $i++) {
		if ($self->{timeFormat} == $self->{Time12}) {
			$times[$i] = $self->floatToTime12($times[$i]);
		}
		elsif ($self->{timeFormat} == $self->{Time12NS}) {
			$times[$i] = $self->floatToTime12($times[$i], 1);
		}
		else {
			$times[$i] = $self->floatToTime24($times[$i]);
		}
	}
	return @times;
}
sub decimal_size { 
my ($self, $size) = @_;
	$self->{decimal_size} = $size;
}

sub numeric { 
my ($self, $n) = @_;
    if (($n=~/^\d+$/) || ($n=~ /^\d+\.$/) || ($n=~ /^\d+\.\d+$/) || ($n=~ /^\.\d+$/)) {
		return 1;
    }
	return 0;
}

# adjust Fajr, Isha and Maghrib for locations in higher latitudes
sub adjustHighLatTimes {
my ($self, @times) = @_;

	my $nightTime = $self->timeDiff($times[4], $times[1]); # sunset to sunrise

	# Adjust Fajr
	my $FajrDiff = $self->nightPortion($self->{methodParams}->{$self->{calcMethod}}[0])* $nightTime;

	if (!numeric($times[0]) || $self->timeDiff($times[0], $times[1]) > $FajrDiff) {
		$times[0] = $times[1]- $FajrDiff;
	}

	# Adjust Isha
	my $IshaAngle = ($self->{methodParams}->{$self->{calcMethod}}[3] == 0) ? $self->{methodParams}->{$self->{calcMethod}}[4] : 18;

	my $IshaDiff = $self->nightPortion($IshaAngle)* $nightTime;

	if (!numeric($times[6]) || $self->timeDiff($times[4], $times[6]) > $IshaDiff) {
		$times[6] = $times[4]+ $IshaDiff;
	}

	# Adjust Maghrib
	my $MaghribAngle = ($self->{methodParams}->{$self->{calcMethod}}[1] == 0) ? $self->{methodParams}->{$self->{calcMethod}}[2] : 4;

	my $MaghribDiff = $self->nightPortion($MaghribAngle)* $nightTime;

	if (!numeric($times[5]) || $self->timeDiff($times[4], $times[5]) > $MaghribDiff) {
		$times[5] = $times[4]+ $MaghribDiff;
	}

	return @times;
}

# the night portion used for adjusting times in higher latitudes
sub nightPortion {
my ($self, $angle) = @_;
	if ($self->{adjustHighLats} == $self->{AngleBased}) {return 1/60* $angle;}
	if ($self->{adjustHighLats} == $self->{MidNight}) {return 1/2;}
	if ($self->{adjustHighLats} == $self->{OneSeventh}) {return 1/7;}
}

# convert hours to day portions
sub dayPortion {
my ($self, @times) = @_;
	for (my $i=0; $i<7; $i++) {
		$times[$i] = $times[$i]/24;
	}
	return @times;
}

#---------------------- Misc Functions -----------------------
# compute the difference between two times
sub timeDiff {
my ($self, $time1, $time2) = @_;
	return $self->fixhour($time2- $time1);
}

# add a leading 0 if necessary
sub twoDigitsFormat {
my ($self, $num) = @_;
	return ($num <10) ? '0'. $num : $num;
}

#    ---------------------- Julian Date Functions -----------------------
#    calculate julian date from a calendar date
sub julianDate {
my ($self, $year, $month, $day) = @_;
	if ($month <= 2) {
		$year -= 1;
		$month += 12;
	}
	my $A = floor($year/ 100);
	my $B = 2-$A+floor($A/ 4);
	my $JD = floor(365.25*($year+4716))+floor(30.6001* ($month+ 1))+$day+$B-1524.5;
	return $JD;
}

# convert a calendar date to julian date (second method)
sub calcJD {
my ($self, $year, $month, $day) = @_;

	my $J1970 = 2440588.0;
	my $ms = timelocal(0, 0, 0, $day, $month-1, $year-1900);
	my $days = floor($ms/ (1000 * 60 * 60* 24));
	return $J1970+ $days- 0.5;
}

#    ---------------------- Trigonometric Functions -----------------------
#     degree sin
sub dsin {
my ($self, $d) = @_;
        return sin($self->dtr($d));
    }
#     degree cos
sub dcos {
my ($self, $d) = @_;
        return cos($self->dtr($d));
    }
#     degree tan
sub dtan {
my ($self, $d) = @_;
        return tan($self->dtr($d));
}
#     degree arcsin
sub darcsin {
my ($self, $x) = @_;
        return $self->rtd(asin($x));
}
#    degree arccos
sub darccos {
my ($self, $x) = @_;
        return $self->rtd(acos($x));
    }
#    degree arctan
sub darctan {
my ($self, $x) = @_;
        return $self->rtd(atan($x));
    }
#    degree arctan2
sub darctan2 {
my ($self, $y, $x) = @_;
        return $self->rtd(atan2($y, $x));
    }
#    degree arccot
sub darccot {
my ($self, $x) = @_;
        return $self->rtd(atan(1/$x));
    }
#    degree to radian
sub dtr {
my ($self, $d) = @_;
        return ($d * PI) / 180.0;
    }
#    radian to degree
sub rtd {
my ($self, $r) = @_;
        return ($r * 180.0) / PI;
    }
#    range reduce angle in degrees.
sub fixangle {
my ($self, $a) = @_;
        $a = $a - 360.0 * floor($a / 360.0);
        $a = ($a < 0) ? ($a + 360.0) : $a;
        return $a;
    }
#    range reduce hours to 0..23
sub fixhour {
my ($self, $a) = @_;
        $a = $a - 24.0 * floor($a / 24.0);
        $a = $a < 0 ? $a + 24.0 : $a;
        return $a;
    }

sub logs {
my ($self, $logs) = @_;
	if (!defined ($logs)) {
		return $self->{logs};
	}
	if ($logs eq "") {
		$self->{logs} = "";
	}
	else {
		$self->{logs} .= $logs . "\n";
	}
}
#=========================================================#
1;

=encoding utf-8

=head1 NAME

Religion::Islam::PrayTime - Calculates Muslim Prayers Times, Sunrise, and Sunset

=head1 SYNOPSIS

	use Religion::Islam::PrayTime;

	$date = time();
	$latitude = 30.0599;		# Cairo, Egypt
	$longitude = 31.2599;		# Cairo, Egypt
	$timeZone = 2;			# Cairo, Egypt
	
	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime(time);
	$mon++; 	$year += 1900;
	#$year = 2014; $month = 12; $day = 5;
	print "Today:  $mon/$mday/$year \n";
	
	$calcMethod = 4;
	$prayTime = Religion::Islam::PrayTime->new($calcMethod);

	# Calculation Method: 0..7
	#	0	Ithna Ashari
	#	1	University of Islamic Sciences, Karachi
	#	2	Islamic Society of North America (ISNA)
	#	3	Muslim World League (MWL)
	#	4	Umm al-Qura, Makkah
	#	5	Egyptian General Authority of Survey
	#	6	Institute of Geophysics, University of Tehran
	#	7	Custom Setting

	$calcMethod = 5;
	$prayTime->setCalcMethod($calcMethod);

	# Time Formats: 0..3
	#	0	24-hour format
	#	1	12-hour format
	#	2	12-hour format with no suffix
	#	3	floating point number
	$prayTime->setTimeFormat(1);
	
	# set text for am/pm suffix for other languages, defaults english
	$prayTime->am_pm("am", "pm");

	# Juristic method for Asr: 0..1
	#	0	Shafii (standard)
	#	1	Hanafi
	$prayTime->setAsrMethod(0);

	# Adjusting Methods for Higher Latitudes: 0..3
	#	0	No adjustment
	#	1	middle of night
	#	2	1/7th of night
	#	3	angle/60th of night
	$prayTime->setHighLatsMethod(0);

	# set the angle for calculating Fajr
	#$prayTime->setFajrAngle($angle);

	#set the angle for calculating Maghrib
	#$prayTime->setMaghribAngle($angle);

	# set the angle for calculating Isha
	#$prayTime->setIshaAngle($angle);

	# set the minutes after mid-day for calculating Dhuhr
	#$prayTime->setDhuhrMinutes($minutes);

	#set the minutes after Sunset for calculating Maghrib
	#$prayTime->setMaghribMinutes($minutes);

	#set the minutes after Maghrib for calculating Isha
	#$prayTime->setIshaMinutes($minutes);

	# these functions return array of times
	#@times = $prayTime->getPrayerTimes($date, $latitude, $longitude, $timeZone);
	#@times = $prayTime->getDatePrayerTimes($year, $month, $day, $latitude, $longitude, $timeZone);
	#print "Fajr\tSunrise\tDhuhr\tAsr\tSunset\tMaghrib\tIsha\n";
	#print join "\t", @times , "\n";

	# these functions return named hash array of times
	%times = $prayTime->getDatePrayerTimesHash($year, $month, $day, $latitude, $longitude, $timeZone);
	#%times = $prayTime->getPrayerTimesHash($date, $latitude, $longitude, $timeZone);
	while (($k, $v) = each %times) {
		print "$k: $v\n";
	}

=head1 DESCRIPTION

This module calculates Muslim prayers times, sunrise and sunset for any location on the earth.

=head1 SEE ALSO

L<Date::HijriDate>
L<Religion::Islam::Qibla>
L<Religion::Islam::Quran>
L<Religion::Islam::PrayTime>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@islamware.com> <support@mewsoft.com>
Website: http://www.islamware.com   http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2014 by Dr. Ahmed Amin Elsheshtawy webmaster@islamware.com,
L<http://www.islamware.com> 
L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
