#=Copyright Infomation
#==========================================================
#Module Name      : Religion::Islam::PrayTime
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page          : http://www.islamware.com, http://www.mewsoft.com
#Contact Email      : support@islamware.com, support@mewsoft.com
#Copyrights © 2013 IslamWare. All rights reserved.
#==========================================================

	#print "Content-type: text/html;charset=utf-8\n\n";
	$|=1; 
	
	use Religion::Islam::PrayTime;

	$date = time();
	$latitude = 30.0599;		# Cairo, Egypt
	$longitude = 31.2599;		# Cairo, Egypt
	$timeZone = 2;				# Cairo, Egypt

	($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime(time);
	$mon++; 	$year += 1900;
	#$year = 2013; $month = 12; $day = 5;
	print "Today:  $mon/$mday/$year \n";
	
	$prayTime = Religion::Islam::PrayTime->new($calcMethod);

	#Calculation Method: 0..7
	#	0		Ithna Ashari
	#	1		University of Islamic Sciences, Karachi
	#	2		Islamic Society of North America (ISNA)
	#	3		Muslim World League (MWL)
	#	4		Umm al-Qura, Makkah
	#	5		Egyptian General Authority of Survey
	#	6		Custom Setting
	#	7		Institute of Geophysics, University of Tehran
	$calcMethod = 5; 
	$prayTime->setCalcMethod($calcMethod);

    # Time Formats: 0..3
    #	0	24-hour format
    #	1	12-hour format
    #	2	12-hour format with no suffix
    #	3	floating point number
	$prayTime->setTimeFormat(1);
	
	#Juristic method for Asr: 0..1
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
	
	# these functions return array or times
	#@times = $prayTime->getPrayerTimes($date, $latitude, $longitude, $timeZone);
	#@times = $prayTime->getDatePrayerTimes($year, $month, $day, $latitude, $longitude, $timeZone);
	#print "Fajr\tSunrise\tDhuhr\tAsr\tSunset\tMaghrib\tIsha\n";
	#print join "\t", @times , "\n";
	
	# these functions return named hash array or times
	%times = $prayTime->getDatePrayerTimesHash($year, $month, $day, $latitude, $longitude, $timeZone);
	#%times = $prayTime->getPrayerTimesHash($date, $latitude, $longitude, $timeZone);
	while (($k, $v) = each %times) {
		print "$k: $v\n";
	}
#=========================================================#
#=========================================================#
