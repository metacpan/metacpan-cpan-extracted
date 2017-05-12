#=Copyright Infomation
#==========================================================
#Module Name      : Religion::Islam::PrayerTimes
#Program Author   : Ahmed Amin Elsheshtawy
#Home Page          : http://www.islamware.com
#Contact Email      : support@islamware.com
#Copyrights © 2006 IslamWare. All rights reserved.
#==========================================================
#  Original c++ source code version Copyright by Fayez Alhargan, 2001
#  This is a module that computes prayer times and sunrise.
#==========================================================
package Religion::Islam::PrayerTimes;

use Carp;
use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our $VERSION = '1.02';

use Math::Complex;
use POSIX;

use constant{
	pi => 4 * atan2(1, 1),	# 3.1415926535897932;
	DToR => (pi / 180),
	RToH => (12 / pi),
	EarthRadius => 6378.14
	};

my $HStartYear =1420;
my $HEndYear = 1450;

our @MonthMap = qw(19410
	      19396  19337  19093  13613  13741  15210  18132  19913  19858  19110
	      18774  12974  13677  13162  15189  19114  14669  13469  14685  12986
	      13749  17834  15701  19098  14638  12910  13661  15066  18132  18085
	    );
our @gmonth = qw(31  31  28  31  30  31  30  31  31  30  31  30  31  31); #makes it circular m[0]=m[12] & m[13]=m[1]
our @smonth = qw(31  30  30  30  30  30  29  31  31  31  31  31  31  30); #makes it circular m[0]=m[12] & m[13]=m[1]

our %TimeZoneUS = (
							AL => -6,
							AK => -9,
							AZ => -7,
							AR => -6,
							CA => -8,
							CO => -7,
							CT => -5,
							DE => -5,
							DC => -5,
							FL => -5,
							GA => -5,
							GU => 10,
							HI => -10,
							ID => -7,
							IL => -6,
							IN => -6,
							IA => -6,
							KS => -6,
							KY => -5,
							LA => -6,
							ME => -5,
							MH => 12,
							MD => -5,
							MA => -5,
							MI => -5,
							MN => -6,
							MS => -6,
							MO => -6,
							MT => -7,
							'NE' => -6,
							NV => -8,
							NH => -5,
							NJ => -5,
							NM => -7,
							NY => -5,
							NC => -5,
							ND => -6,
							MP => 10,
							OH => -5,
							OK => -6,
							OR => -8,
							PA => -5,
							PR => -4,
							RI => -5,
							SC => -5,
							SD => -6,
							TN => -5,
							TX => -6,
							UT => -7,
							VT => -5,
							VI => -4,
							VA => -5,
							WA => -5,
							WV => -5,
							WI => -6,
							WY => -7,
						);

our %TimeZone = (
							'AA'=> -4,
							'AC'=>-4,
							'AE'=> 4,
							'AF'=>4.5,
							'AG'=>1,
							'AJ'=>4,
							'AL'=>1,
							'AM'=>4,
							'AN'=>1,
							'AO'=>1,
							'AR'=>-3,

							#'AS'=>'Australia',

							#'AT'=>'Ashmore and Cartier Islands',
							'AU'=>1,
							'AV'=>-4,
							'AX'=>-11,
							'BA'=>3,
							'BB'=>-4,
							'BC'=>2,
							'BD'=>-4,
							'BE'=>1,
							'BF'=>-5,
							'BG'=>6,
							'BH'=>-6,
							'BK'=>1,
							'BL'=>-4,
							#'BM'=>'Burma',
							'BN'=>1,
							'BO'=>2,
							'BP'=>11,
							'BR'=>'Brazil',
							#'BS'=>'Bassas da India',
							'BT'=>6,
							'BU'=>2,
							#'BV'=>'Bouvet Island',
							'BX'=>8,
							'BY'=>2,
							'CA'=>'Canada',
							'CB'=>7,
							'CD'=>1,
							'CE'=>5.5,
							'CF'=>1,
							'CG'=>1,
							'CH'=>8,
							'CI'=>-4,
							'CJ'=>-5,
							'CK'=>6.5,
							'CM'=>1,
							'CN'=>3,
							'CO'=>-5,
							#'CR'=>'Coral Sea Islands',
							'CS'=>-6,
							'CT'=>1,
							'CU'=>-5,
							'CV'=>-1,
							#'CW'=>'Avarua',
							'CY'=>2,
							'DA'=>1,
							'DJ'=>3,
							'DO'=>-4,
							'DR'=>-4,
							'EC'=>-5,
							'EG'=>2,
							'EI'=>0,
							'EK'=>1,
							'EN'=>2,
							'ER'=>3,
							'ES'=>-6,
							'ET'=>3,
							#'EU'=>'Europa Island',
							'EZ'=>1,
							'FG'=>3,
							'FI'=>2,
							'FJ'=>12,
							'FK'=>-4,
							#'FM'=>'Palikir',
							'FO'=>0,
							#'FP'=>'Clipperton Island',
							'FR'=>1,
							#'FS'=>'French Southern and Antarctic Lands',
							'GA'=>0,
							'GB'=>1,
							'GG'=>4,
							'GH'=>0,
							'GI'=>1,
							'GJ'=>-4,
							'GK'=>0,
							'GL'=>-3,
							'GM'=>1,
							#'GO'=>'Glorioso Islands',
							'GP'=>-4,
							'GR'=>2,
							'GT'=>-6,
							'GU'=>1,
							'GV'=>0,
							'GY'=>-4,
							'GZ'=>2,
							'HA'=>-5,
							'HK'=>8,
							#'HM'=>'Heard Island and McDonald Islands',
							'HO'=>-6,
							'HR'=>1,
							'HU'=>1,
							'IC'=>0,
							#Indonesia Centeral
							'ID'=>8,
							#Indonesia East
							'ID1'=>9,
							#Indonesia West
							'ID2'=>7,
							#'IM'=>'Isle of Man',
							'IN'=>5.5,
							#'IO'=>'British Indian Ocean Territory',
							#'IP'=>'Clipperton Island',
							'IR'=>3.5,
							'IS'=>2,
							'IT'=>1,
							'IV'=>0,
							'IZ'=>3,
							'JA'=>9,
							'JE'=>0,
							'JM'=>-5,
							'JN'=>1,
							'JO'=>2,
							#'JU'=>'Juan de Nova Island',
							'KE'=>3,
							'KG'=>5,
							'KN'=>9,
							'KR'=>12,
							'KS'=>9,
							'KT'=>-10,
							'KU'=>3,
							'KZ'=>6,
							'LA'=>7,
							'LE'=>2,
							'LG'=>2,
							'LH'=>2,
							'LI'=>0,
							'LO'=>1,
							'LS'=>1,
							'LT'=>2,
							'LU'=>1,
							'LY'=>2,
							'MA'=>3,
							'MB'=>-4,
							#'MC'=>'Macau',
							'MD'=>2,
							'MF'=>3,
							'MG'=>8,
							'MH'=>-4,
							'MI'=>2,
							'MK'=>1,
							'ML'=>0,
							'MN'=>1,
							'MO'=>0,
							'MP'=>4,
							'MR'=>0,
							'MT'=>1,
							'MU'=>4,
							'MV'=>5,
							'MX'=>'Mexico',
							'MY'=>8,
							'MZ'=>2,
							'NC'=>11,
							#'NE'=>'Alofi',
							'NF'=>11.5,
							'NG'=>1,
							'NH'=>11,
							'NI'=>1,
							'NL'=>1,
							#'NM'=>'No Man\'s Land',
							'NO'=>1,
							'NP'=>7.75,
							'NR'=>12,
							'NS'=>-3,
							'NT'=>-4,
							'NU'=>-6,
							'NZ'=>12,
							'PA'=>-4,
							#'PC'=>'Adamstown',
							'PE'=>-5,
							'PK'=>5,
							'PL'=>1,
							'PM'=>-5,
							'PO'=>0,
							'PP'=>10,
							'PR'=>-4,
							'PU'=>0,
							'QA'=>3,
							'RE'=>4,
							#'RM'=>'Majuro',
							'RO'=>2,
							'RP'=>8,

							#'RS'=>'Russia',
							'RS1'=>2,
							'RS2'=>4,
							'RS3'=>4,
							'RS4'=>5,
							'RS5'=>6,
							'RS6'=>7,
							'RS7'=>8,
							'RS8'=>9,
							'RS9'=>10,
							'RS10'=>11,
							'RS11'=>12,

							'RW'=>2,
							'SA'=>3,
							'SB'=>-3,
							'SC'=>-4,
							'SE'=>4,
							'SF'=>2,
							'SG'=>0,
							#'SH'=>'Jamestown',
							'SI'=>1,
							'SL'=>0,
							'SM'=>1,
							'SN'=>8,
							'SO'=>3,
							'SP'=>1,
							'ST'=>-4,
							'SU'=>2,
							#'SV'=>'Svalbard',
							'SW'=>1,
							#'SX'=>'South Georgia and the South Sandwich Islands',
							'SY'=>2,
							'SZ'=>1,
							'TD'=>-4,
							#'TE'=>'Tromelin Island',
							'TH'=>7,
							'TI'=>6,
							'TK'=>-5,
							#'TL'=>'Tokelau',
							'TN'=>13,
							'TO'=>0,
							'TP'=>0,
							'TS'=>1,
							#'TT'=>'East Timor',
							'TU'=>2,
							'TV'=>12,
							'TW'=>8,
							'TX'=>5,
							'TZ'=>3,
							'UG'=>3,
							'UK'=>0,
							'UP'=>2,
							#'US'=>'United States',
							'UV'=>0,
							'UY'=>-3,
							'UZ'=>5,
							'VC'=>-4,
							'VE'=>-4,
							'VI'=>-4,
							'VM'=>7,
							'VT'=>1,
							'WA'=>1,
							'WE'=>2,
							'WF'=>12,
							'WI'=>0,
							'WS'=>-11,
							'WZ'=>2,
							'YI'=>1,
							'YM'=>3,
							'ZA'=>2,
							'ZI'=>2
							);

#==========================================================
#==========================================================
sub new {
my ($class, %args) = @_;
    
	my $self = bless {}, $class;
	
	# Defaults
	$self->{JuristicMethod} = 1;			# Standard
	$self->CalculationMethod(3);		# Egyptian General Authority of Survey
	$self->{SafetyTime} = 0.016388;	 # 59 seconds, safety time
	$self->{ReferenceAngle} = 45;
	$self->{EidPrayerTime} = 4.2;		# Eid Prayer Time  4.2
	$self->{DaylightSaving} = 0;

	# Cairo as the default location
	$self->{Latitude} = 30.050;
	$self->{Longitude} = 31.250;
	$self->{Altitude} = 22;
	$self->{TimeZone} = 2;
	
	$self->{TimeMode} = 0; # 12 or 24 hour time format

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++;
	$year += 1900;

    return $self;
}
#==========================================================
# Safety time  in hours should be 0.016383h. 59seconds, safety time
sub SafetyTime {
my ($self) = shift; 
	$self->{SafetyTime} = shift if @_;
	return $self->{SafetyTime};
}
#==========================================================
#Juristic Methods:
#		1)-Standard (Imams Shafii, Hanbali, and Maliki),
#		2)-Hanafi
#Aser = 1 or  2
#The Henfy (asr=2), Shafi (asr=1, Omalqrah asr=1)
sub JuristicMethod {
my ($self, $method) = @_;
	
	if (!defined $method || int($method) < 1 || int($method) > 2) {
		return $self->{JuristicMethod};
	}
	$self->{JuristicMethod} = $method;
	return $self->{JuristicMethod};
}
#==========================================================
# Calculation Method 
#1:	Umm Al-Qura Committee
#2:	Muslim World League
#3:	Egyptian General Authority of Survey
#4:	University Of Islamic Sciences, Karachi
#5:	ISNA, Islamic Society of North America
sub CalculationMethod {
my ($self, $method) = @_;
	
	if (!defined $method || int($method) < 1 || int($method) > 5) {
		return $self->{CalculationMethod};
	}

	$self->{CalculationMethod} = $method;

	if ($method == 1) {# Umm Al-Qura Committee
		$self->{FajerAngle} = 19;
		$self->{IshaAngle} = 0;
		$self->{IshaFixedTime} = 1.5;
	} 
	elsif ($method == 2) {# Muslim World League 
		$self->{FajerAngle} = 18;
		$self->{IshaAngle} = 17;
		$self->{IshaFixedTime} = 1.5;
	} 
	elsif ($method == 3) {# Egyptian General Authority of Survey 
		$self->{FajerAngle} = 19.5;
		$self->{IshaAngle} = 17.5;
		$self->{IshaFixedTime} = 1.5;
	} 
	elsif ($method == 4) { # University Of Islamic Sciences, Karachi
		$self->{FajerAngle} = 18;
		$self->{IshaAngle} = 18;
		$self->{IshaFixedTime} = 1.5;
	}
	elsif ($method == 5) { # ISNA, Islamic Society of North America 
		$self->{FajerAngle} = 15;
		$self->{IshaAngle} = 15;
		$self->{IshaFixedTime} = 1.5;
	}
	
	return $self->{CalculationMethod};
}
#==========================================================
sub FajerAngle{
my ($self) = shift;
	$self->{FajerAngle} = shift if @_;
	return $self->{FajerAngle};
}
#==========================================================
sub IshaAngle{
my ($self) = shift;
	$self->{IshaAngle} = shift if @_;
	return $self->{IshaAngle};
}
#==========================================================
sub IshaFixedTime{
my ($self) = shift;
	$self->{IshaFixedTime} = shift if @_;
	return $self->{IshaFixedTime};
}
#==========================================================
#Reference Angle suggested by Rabita  45
#latude (radian) that should be used for places above -+65.5 should be 45deg as suggested by Rabita
sub ReferenceAngle{
my ($self) = shift;
	$self->{ReferenceAngle} = shift if @_;
	return $self->{ReferenceAngle};
}
#==========================================================
# Eid Prayer Time  4.2
sub EidPrayerTime{
my ($self) = shift;
	$self->{EidPrayerTime} = shift if @_;
	return $self->{EidPrayerTime};
}
#==========================================================
# Longitude in radians
sub Longitude{
my ($self) = shift;
	$self->{Longitude} = shift if @_;
	return $self->{Longitude};
}
#==========================================================
# Latitude in radians
sub Latitude {
my ($self) = shift;
	$self->{Latitude} = shift if @_;
	return $self->{Latitude};
}
#==========================================================
# HeightdifW			: param[3]: The place western herizon height difference in meters
# HeightdifE			: param[4]: The place eastern herizon height difference in meters
sub Altitude{
my ($self) = shift;
	$self->{Altitude} = shift if @_;
	return $self->{Altitude};
}
#==========================================================
# Time Zone difference from GMT
sub TimeZone{
my ($self) = shift;
	$self->{TimeZone} = shift if @_;
	return $self->{TimeZone};
}
#==========================================================
# Q. What is daylight saving? Ans. Many countries try to adopt their work time by subtracting
# from their clocks one hour in the Fall and Winter seasons. 
sub DaylightSaving {
my ($self) = shift;
my ($time);	
	
	if (@_) {
			$time = shift;
			if ($time > 0) {
				$self->{DaylightSaving} = 1;
			}
			else {$self->{DaylightSaving} = 0;}
	}
	return $self->{DaylightSaving};
}
#==========================================================
sub TimeMode {
my ($self, $mode) = @_;
	
	if (!defined $mode) {
		return $self->{TimeMode};
	}
	$mode = $mode ? 1: 0;
	$self->{TimeMode} = $mode;
	return $self->{TimeMode};
}
#==========================================================
sub FormatTime{
my ($self, $time) = @_;
my ($hour, $min, $sec, $am);

	$hour = int ($time);
	$min = int (60.0*($time- $hour));
	if ($min == 60)  {$hour++; $min = 0;}
	if ($min < 0) {$min = -$min;}

	$min = sprintf("%02d", $min);
	$hour = sprintf("%02d", $hour);
	
	if (!$self->{TimeMode}) { # 12 hour mode
		$am = ($hour > 12)? 'pm': 'am';
		if ($hour >12) {$hour -= 12;}
	}
	else {
			$am = "";
	}

	return ($hour, $min, $am);
}
#==========================================================
sub GregorianMonthLength {
my ($self, $month, $year) = @_;
	
    # Compute the last date of the month for the Gregorian calendar.
    if ($month == 2)
      {
			return 29 if ($year % 4 == 0 && $year % 100 != 0) || ($year % 400 == 0);
      }
    return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month - 1];
}
#==========================================================
sub IslamicLeapYear {
my ($self, $year) = @_;
      # True if year is an Islamic leap year
    return ((((11 * $year) + 14) % 30) < 11) ? 1 : 0;
}
#==========================================================
sub IslamicMonthLength {
my ($self, $month, $year) = @_;
    # Last day in month during year on the Islamic calendar.
    return ($month % 2 == 1) || ($month == 12 && IslamicLeapYear($year)) ? 30 : 29;
  }
#==========================================================
#Set the prayer location to calculate for.
sub PrayerLocation {
my ($self, %args) = @_;
	
	$self->{Latitude} = $args{Latitude};		# Latitude
	$self->{Longitude} = $args{Longitude};	# Longitude
	$self->{Altitude} = $args{Altitude};			#HeightdifW			: param[3]: The place western herizon height difference in meters
	$self->{TimeZone} = $args{TimeZone};	# Time Zone difference from GMT
	my $key; my $value;
	#while (($key, $value)=each(%args)) {print ("PrayerLocation: $key =  $value\n");}
}
#==========================================================
#=PrayerTimes
#  For international prayer times see Islamic Fiqah Council of the Muslim
#  World League:  Saturday 12 Rajeb 1406H, concerning prayer times and fasting
#  times for countries of high latitudes.
#  This program is based on the above.
#
# Arguments:
#   yg, mg, dg : Date in Greg
#   param[0]				: Safety time  in hours should be 0.016383h
#   longtud,latud		: param[1],[2] : The place longtude and latitude in radians
#   HeightdifW			: param[3]: The place western herizon height difference in meters
#   HeightdifE			: param[4]: The place eastern herizon height difference in meters
#   Zonh						:param[5]: The place zone time dif. from GMT  West neg and East pos in decimal hours
#  fjrangl					: param[6]: The angle (radian) used to compute Fajer prayer time (OmAlqrah  -19 deg.)
#  ashangl					: param[7]: The angle (radian) used to compute Isha  prayer time
#								  ashangl=0 then use  (OmAlqrah: ash=SunSet+1.5h)
#  asr							: param[8]: The Henfy (asr=2) Shafi (asr=1, Omalqrah asr=1)
#  param[9]				: latude (radian) that should be used for places above -+65.5 should be 45deg as suggested by Rabita
#  param[10]				: The Isha fixed time from Sunset
#
#  Output:
#  lst[]...lst[n], 
#	1:	 Fajer 
#	2:	 Sunrise
#	3:	 Zohar
#	4:	 Aser
#	5:	 Magreb
#	6:	 Isha
#	7:	 Fajer using exact Rabita method for places >48
#	8:	 Ash   using exact Rabita method for places >48
#	9: Eid Prayer Time
#          for places above 48 lst[1] and lst[6] use a modified version of
#          Rabita method that tries to eliminate the discontinuity
#         all in 24 decimal hours
#
#returns flag	:0 if there are problems, flag:1 no problems
#=cut

# Compute prayer times and sunrise
sub PrayerTimes {
my ($self, $yg, $mg, $dg) = @_;
my (@lst, @param, %result);
	
	#print "PrayerTimes for :  $yg, $mg, $dg \n\n";
	$param[0] = $self->{SafetyTime};				# 59seconds, safety time
	$param[1] = $self->{Longitude}*DToR;		# Longitude in radians
	$param[2] = $self->{Latitude}*DToR;			# Latitude in radians
	$param[3] = $self->{Altitude};						#HeightdifW			: param[3]: The place western herizon height difference in meters
	$param[4] = $self->{Altitude};						#HeightdifE			: param[4]: The place eastern herizon height difference in meters
	$param[5] = $self->{TimeZone};									# Time Zone difference from GMT
	$param[6] = $self->{FajerAngle}*DToR;				# Fajer Angle  =19
	$param[7] = $self->{IshaAngle}*DToR;					# Isha Angle  if set to zero, then $param[10] must be 1.5
	$param[8] = $self->{JuristicMethod};						 #Aser=1, 2, Juristic Methods: Standard and Hanafi
	$param[9] = $self->{ReferenceAngle}*DToR;		# Reference Angle suggested by Rabita  45
	$param[10] = $self->{IshaFixedTime};					# Isha fixed time from sunset =1.5, if $param[7] > 0 then this is discarded
	$param[11] = $self->{EidPrayerTime}*DToR;		# Eid Prayer Time  4.2
#	   $param[0]= 0.016388;  # /* 59seconds, safety time */
#	   $param[1]=$longtud*DToR;  #/* Longitude in radians */
#	   $param[2]=$latud*DToR;
#	   $param[3]=22.0;
#	   $param[4]=22.0;
#	   $param[5]=$Zonh;    # /* Time Zone difference from GMT S.A. 2*/
#	   $param[6]=19.5*DToR; #/* Fajer Angle  =19 */
#	   $param[7]=17.5*DToR; #/* Isha Angle  if setto zero, then $param[10] must be 1.5*/
#	   $param[8]=1;    #/* Aser=1,2  OmAlrqah Aser=1*/
#	   $param[9]=45*DToR;   #/* Reference Angle suggested by Rabita  45*/ 
#	   $param[10]=1.5;  #/* Isha fixed time from sunset =1.5, if $param[7] >0 then this is discarded*/
#	   $param[11]=4.2*DToR; #/* Eid Prayer Time  4.2 */

#	for my $xx(0..$#param) {
#		print "Param: $xx = ". $param[$xx] . "\n";
#	}
	my $flag=1;
	my $flagrs;
	my $problm=0;

	my ($RA, $Decl);
	my ($Rise, $Transit, $Setting);
	my ($SINd, $COSd);
	my ($act, $H, $angl, $K, $cH);
	my ($X, $MaxLat);
	my ($H0, $Night, $IshRt, $FajrRt);
	my $HightCorWest=0;
	my $HightCorEast=0;
	my ($IshFix, $FajrFix);
	my $JD;

	#Main Local variables:
	#RA= Sun's right ascension
	#Decl= Sun's declination
	#H= Hour Angle for the Sun
	#K= Noon time
	#angl= The Sun altitude for the required time
	#flagrs: sunrise sunset flags
	#	0:no problem
	#	16: Sun always above horizon (at the ploes for some days in the year)
	#	32: Sun always below horizon

	# Compute the Sun various Parameters

	($JD, $Rise, $Transit, $Setting, $RA, $Decl, $flagrs) =
	$self->SunParamr($yg, $mg, $dg, -$param[1], $param[2], -$param[5]);

	# Compute General Values
	$SINd=sin($Decl)*sin($param[2]);
	$COSd=cos($Decl)*cos($param[2]);

	# Noon
	$K=$Transit;

	# Compute the height correction
	$HightCorWest=0; $HightCorEast=0;
	if ($flagrs==0 && fabs($param[2])<0.79 && ($param[4]!=0 || $param[3]!=0))
	{  # height correction not used for problematic places above 45deg
		$H0=$H=0;
		$angl=-0.83333*DToR;  # standard value  angl=50min=0.8333deg for sunset and sunrise
		$cH=(sin($angl)-$SINd)/($COSd);
		$H0=acos($cH);

		$X= EarthRadius*1000.0;  # meters
		$angl = -0.83333*DToR+(0.5*pi - asin($X/($X+$param[3])));
		$cH=(sin($angl)-$SINd)/($COSd);
		$HightCorWest=acos($cH);
		$HightCorWest=($H0-$HightCorWest)*(RToH);

		$angl=-0.83333*DToR+(0.5*pi-asin($X/($X+$param[4])));
		$cH=(sin($angl)-$SINd)/($COSd);

		$HightCorEast=acos($cH);
		$HightCorEast=($H0-$HightCorEast)*(RToH);
	}

	# Modify Sunrise,Sunset and Transit for problematic places
	if (!($flagrs==0 && fabs($Setting-$Rise)>1 && fabs($Setting-$Rise)<23))
	{ # There are problems in computing sun(rise,set)
		# This is because of places above -+65.5 at some days of the year
		#Note param[9] should be  45deg as suggested by Rabita
		$problm=1;
		if ($param[2]<0) {$MaxLat= -fabs($param[9]);} else {$MaxLat= fabs($param[9]);}
		#Recompute the Sun various Parameters using the reference param[9]

		#($JD, $Rise, $Transit, $Setting, $RA, $Decl, $RiseSetFlags)
		my ($JD, $Rise, $Transit, $Setting, $RA, $Decl, $flagrs) = 
		 $self->SunParamr($yg, $mg, $dg, -$param[1], $MaxLat, -$param[5]);
		$K = $Transit; # exact noon time

		#ReCompute General Values for the new reference param[9]
		$SINd=sin($Decl)*sin($MaxLat);
		$COSd=cos($Decl)*cos($MaxLat);
	}
   #-------------------------------------------------------------
	if($K<0) {$K=$K+24;}
	#print "[$Rise - $HightCorEast, K=$K] \n";
	$lst[2]=$Rise-$HightCorEast; #  Sunrise - Height correction
	$lst[3]= $K+ $param[0]; #  Zohar time+extra time to make sure that the sun has moved from zaowal
	$lst[5]= $Setting+$HightCorWest+ $param[0]; #Magrib= SunSet + Height correction + Safety Time
	#-------------------------------------------------------------
	# Asr time: Henfy param[8]=2, Shafi param[8]=1, OmAlqrah asr=1
	if($problm){# For places above 65deg
		$act=$param[8]+tan(fabs($Decl-$MaxLat));
	}
	else {#no problem
		$act=$param[8]+tan(fabs($Decl-$param[2])); # In the standard equations abs() is not used, but it is required for -ve latitude
	}

	$angl=atan(1.0/$act);
	$cH=(sin($angl)-$SINd)/($COSd);
	if(fabs($cH)>1.0)
	{
		$H=3.5;
		$flag=0; #problem in compuing Asr
	}
	else
	{
		$H=acos($cH);
		$H=$H*RToH;
	}

	$lst[4]=$K+$H+$param[0];  # Asr Time
	#-------------------------------------------------------------
	#Fajr Time
	$angl= -$param[6]; # The value -19deg is used by OmAlqrah for Fajr, but it is not correct, Astronomical twilight and Rabita use -18deg
	$cH=(sin($angl)-$SINd)/($COSd);
	if (fabs($param[2])<0.83776){#    If latitude<48deg
		#   no problem
		$H=acos($cH);
		$H=$H*RToH;  #convert radians to hours
		$lst[1]=$K-($H+$HightCorEast)+$param[0];    #Fajr time
		$lst[7]=$lst[1];
	}
	else
	{ # Get fixed ratio, data depends on latitutde sign
		if($param[2]<0){
			my ($IshFix, $FajrFix) = $self->GetRatior($yg, 12, 21, @param);
		}
		else{
			my ($IshFix, $FajrFix) = $self->GetRatior($yg, 6, 21, @param);
		}

		if (fabs($cH)>(0.45+1.3369*$param[6]))#   A linear equation I have interoduced
		{  # The problem occurs for places above -+48 in the summer
			$Night = 24-($Setting-$Rise);# Night Length
			$lst[1]=$Rise-$Night*$FajrFix;  #According to the general ratio rule
		}
		else
		{ # no problem
			$H=acos($cH);
			$H=$H*RToH;  #convert radians to hours
			$lst[1]=$K-($H+$HightCorEast)+$param[0]; #    Fajr time
		}

		$lst[7]=$lst[1];
		if (fabs($cH)>1)
		{  # The problem occurs for places above -+48 in the summer
			my ($IshRt, $FajrRt) = $self->GetRatior($yg, $mg, $dg, @param);
			$Night=24-($Setting-$Rise); #Night Length
			$lst[7]= $Rise-$Night*$FajrRt; # Accoording to Rabita Method
		}
		else
		{ # no problem
			$H = acos($cH);
			$H= $H*RToH;  #convert radians to hours
			$lst[7] = $K- ($H+$HightCorEast)+$param[0];    #Fajr time
		}
	}
	#-------------------------------------------------------------
    #  Isha prayer time
	if($param[7]!=0) # if Ish angle  not equal zero
    {
		$angl= -$param[7];
		$cH=(sin($angl)-$SINd)/($COSd);
		if (fabs($param[2])<0.83776) #   If latitude<48deg
		{     #no problem
			$H=acos($cH);
			$H=$H*RToH;  #convert radians to hours
			$lst[6]=$K+($H+$HightCorWest+$param[0]);    #Isha time, instead of  Sunset+1.5h
			$lst[8]=$lst[6];
		}
		else
		{
			if (fabs($cH)>(0.45+1.3369*$param[6]))  # A linear equation I have interoduced
			{   #The problem occurs for places above -+48 in the summer
				$Night=24-($Setting-$Rise); # Night Length
				$lst[6]=$Setting+$Night*$IshFix; # Accoording to Rabita Method
			}
			else
			{ #no problem
				$H=acos($cH);
				$H=$H*RToH;  #convert radians to hours
				$lst[6]=$K+($H+$HightCorWest+$param[0]);   # Isha time, instead of  Sunset+1.5h
			}

			if (fabs($cH)>1.0)
			{   #The problem occurs for places above -+48 in the summer
				my ($IshRt, $FajrRt) = $self->GetRatior($yg, $mg, $dg, @param);

				$Night=24-($Setting-$Rise); #Night Length
				$lst[8]=$Setting+$Night*$IshRt;  #According to the general ratio rule
			}
			else
			{
				$H=acos($cH);
				$H=$H*RToH;  #convert radians to hours
				$lst[8]=$K+($H+$HightCorWest+$param[0]);  #  Isha time, instead of  Sunset+1.5h
			}

			}
		}
	else
	{
		$lst[6]=$lst[5]+$param[10];  #Isha time OmAlqrah standard Sunset+fixed time (1.5h or 2h in Romadan)
		$lst[8]=$lst[6];
	}
	# -------------------------------------------------------------
	#    Eid prayer time
	$angl=$param[11]; # Eid Prayer time Angle is 4.2
	$cH=(sin($angl)-$SINd)/($COSd);
	if ((fabs($param[2])<1.134 || $flagrs==0) && fabs($cH)<=1.0)#    If latitude<65deg
	{#     no problem
		$H=acos($cH);
		$H=$H*RToH;  #convert radians to hours
		$lst[9]=$K-($H+$HightCorEast)+$param[0];#    Eid time
	}
	else
	{
		$lst[9]=$lst[2]+0.25;  #If no Sunrise add 15 minutes
	}
	#---------------------------------------------
	# return the result in a hash
	undef %result;
	$result{Flag} = $flag;	 # flag =0: means problem in compuing Asr
	
	$result{Fajr} = $lst[1] + $self->{DaylightSaving};
	$result{Sunrise} = $lst[2] + $self->{DaylightSaving};
	$result{Zohar} = $lst[3] + $self->{DaylightSaving};
	$result{Aser} = $lst[4] + $self->{DaylightSaving};
	$result{Maghrib} = $lst[5] + $self->{DaylightSaving};
	$result{Isha} = $lst[6] + $self->{DaylightSaving};
	$result{FajirRabita} = $lst[7] + $self->{DaylightSaving};	 #Fajer using exact Rabita method for places >48
	$result{IshaRabita} = $lst[8] + $self->{DaylightSaving};	#Ash using exact Rabita method for places >48
	$result{Eid} = $lst[9] + $self->{DaylightSaving};	 #Eid Prayer Time
	#for places above 48 lst[1] and lst[6] use a modified version of
	#Rabita method that tries to eliminate the discontinuity
	#all in 24 decimal hours
	return %result;
}
#==========================================================
sub atanxy{
my ($self, $x, $y) = @_;
	my $argm;
	if ($x==0)  {$argm=0.5*pi;} else {$argm=atan($y/$x);}
	if ($x>0 && $y<0) {$argm=2.0*pi+$argm;}
	if ($x<0) {$argm=pi+$argm;}
	return $argm;
}
#==========================================================
#==========================================================
# EclipToEquator(tht , 0, *RA,*Decl);
sub EclipToEquator{
my ($self, $lmdr, $betar) = @_;
my ($alph, $dltr);
#   Convert Ecliptic to Equatorial Coordinate
#   p.40 No.27, Peter Duffett-Smith book
#   input: lmdr,betar  in radians
#   output: alph,dltr in radians
	my $eps = 23.441884; # (in degrees) this changes with time
	my ($sdlt, $epsr);
	my ($x, $y, $alpr);
	my $rad = 0.017453292; # =pi/180.0

	$epsr = $eps * $rad; # convert to radians
	$sdlt = sin($betar)*cos($epsr)+cos($betar)*sin($epsr)*sin($lmdr);
	$dltr = asin($sdlt);
	$y = sin($lmdr)*cos($epsr)-tan($betar)*sin($epsr);
	$x = cos($lmdr);
	$alph = $self->atanxy($x, $y);
	return ($alph, $dltr);
}
#==========================================================
sub RoutinR2{
my ($self, $M, $e) = @_;
#   Routine R2:
#    Calculate the value of E
#    p.91, Peter Duffett-Smith book
  
	my $dt=1;
	my ($dE, $Ec);
	$Ec = $M;

	while (fabs($dt)>1e-9) {
		$dt =  $Ec - $e*sin($Ec)-$M;
		$dE = $dt/(1-$e*cos($Ec));
		$Ec = $Ec - $dE;
	}
	return $Ec;
}

#==========================================================
# p.99 of the Peter Duffett-Smith book
sub SunParamr{
my ($self, $yg, $mg, $dg, $ObsLon, $ObsLat, $TimeZone)=@_;
my ( $Rise, $Transit, $Setting, $RA, $Decl, $RiseSetFlags);
my ($UT, $ET, $y, $L, $e, $M, $omg);
my ($eps, $T, $JD, $Ec);
my ($tnv, $v, $tht);
my ($K, $angl, $T1, $T2, $H, $cH);
	
	$RiseSetFlags = 0;

	$JD = $self->GCalendarToJD($yg, $mg, $dg);
	$T = ($JD + $TimeZone/24.0 - 2451545.0) / 36525.0;

	$L = 279.6966778+36000.76892*$T + 0.0003025*$T*$T; # in degrees
	while ($L > 360) {$L = $L-360;}
	while ($L < 0) {$L = $L+360;}
	$L = $L*pi/180.0;  # radians

	$M = 358.47583+35999.04975*$T-0.00015*$T*$T-0.0000033*$T*$T*$T;
	while ($M>360) {$M=$M-360;}
	while ($M<0) {$M=$M+360;}
	$M = $M*pi/180.0;

	$e=0.01675104-0.0000418*$T-0.000000126*$T*$T;
	$Ec=23.452294-0.0130125*$T-0.00000164*$T*$T+0.000000503*$T*$T*$T;
	$Ec=$Ec*pi/180.0;

	$y=tan(0.5*$Ec);
	$y=$y*$y;
	$ET=$y*sin(2*$L)-2*$e*sin($M)+4*$e*$y*sin($M)*cos(2*$L)-0.5*$y*$y*sin(4*$L)-5*0.25*$e*$e*sin(2*$M);
	$UT=$ET*180.0/(15.0*pi);   # from radians to hours

	$Ec = $self->RoutinR2($M, $e);
	$tnv = sqrt((1+$e)/(1-$e))*tan(0.5*$Ec);
	$v = 2.0*atan($tnv);
	$tht = $L+$v-$M;

	($RA, $Decl) = $self->EclipToEquator($tht,0);

	$K = 12-$UT-$TimeZone+$ObsLon*12.0/pi;  # (Noon)
	$Transit = $K;
	#  Sunrise and Sunset

	$angl = (-0.833333)*DToR;  # Meeus p.98
	$T1=(sin($angl)-sin($Decl)*sin($ObsLat));
	$T2=(cos($Decl)*cos($ObsLat));  # p.38  Hour angle for the Sun
	$cH=$T1/$T2;
	if ($cH>1)  {$RiseSetFlags = 16; $cH=1;}  #At this day and place the sun does not rise or set
	$H = acos($cH);
	$H = $H*12.0/pi;
	$Rise = $K-$H; 	       # Sunrise
	$Setting = $K+$H; # SunSet

	return ($JD, $Rise, $Transit, $Setting, $RA, $Decl, $RiseSetFlags);
}

#==========================================================
#  Function to obtain the ratio of the start time of Isha and Fajr at
#  a referenced latitude (45deg suggested by Rabita) to the night length
# void GetRatior(int yg,int mg,int dg,double param[],double *IshRt,double *FajrRt)
# ($IshFix, $FajrFix) = &GetRatior($yg, 12, 21, @param);
sub GetRatior{
my ($self, $yg, $mg, $dg, @param)=@_;
my ($IshRt, $FajrRt);

	my $flagrs;
	my ($RA, $Decl);
	my ($Rise,$Transit, $Setting);
	my ($SINd, $COSd);
	my ($H, $angl, $cH);
	my ($MaxLat);
	my ($FjrRf, $IshRf);
	my ($Night);

	if ($param[2]<0) {$MaxLat= -fabs($param[9]);} else {$MaxLat= fabs($param[9]);}

	($Rise, $Transit, $Setting, $RA, $Decl, $flagrs) =
	$self->SunParamr($yg, $mg, $dg, -$param[1], $MaxLat, -$param[5]);


	$SINd=sin($Decl)*sin($MaxLat);
	$COSd=cos($Decl)*cos($MaxLat);
	$Night=24-($Setting-$Rise);  #Night Length
	#Fajr
	$angl= -$param[6];
	$cH=(sin($angl)-$SINd)/($COSd);
	$H=acos($cH);
	$H=$H*RToH; # convert radians to hours
	$FjrRf=$Transit-$H-$param[0];    #Fajr time
	#Isha
	if ($param[7]!=0)  #if Ish angle  not equal zero
    {
		$angl= -$param[7];
		$cH=(sin($angl)-$SINd)/($COSd);
		$H=acos($cH);
		$H=$H*RToH;  #convert radians to hours
		$IshRf=$Transit+$H+$param[0];#    Isha time, instead of  Sunset+1.5h
     }
   else
    {
		$IshRf=$Setting+$param[10];  #Isha time OmAlqrah standard Sunset+1.5h
    }
	$IshRt= ($IshRf-$Setting)/$Night;  #Isha time ratio
	$FajrRt=($Rise-$FjrRf)/$Night;  #Fajr time ratio
	return ($IshRt, $FajrRt);
}
#==========================================================
=BH2GA
Name:    BH2GA                                                      
Type:    Procedure                                                 
Purpose: Finds Gdate(year,month,day) for Hdate(year,month,day=1)  	
Arguments:                                                         
Input: Hijrah  date: year:yh, month:mh                             
Output: Gregorian date: year:yg, month:mg, day:dg , day of week:dayweek
      and returns flag found:1 not found:0                         
=cut
# ($yg1, $mg1, $dg1, $dw2) = &BH2GA($yh2,$mh2);
sub BH2GA{
my ($self, $yh, $mh) = @_;
my ($yg, $mg, $dg, $dayweek);

	my ($flag, $Dy, $m, $b);
	my ($JD);
	my ($GJD);
	#Make sure that the date is within the range of the tables
	if ($mh<1) {$mh=12;}
	if ($mh>12) {$mh=1;}
	if ($yh<$HStartYear) {$yh=$HStartYear;}
	if ($yh>$HEndYear)   {$yh=$HEndYear;}

	$GJD = $self->HCalendarToJDA($yh,$mh,1);
	(undef, $yg, $mg, $dg) = $self->JDToGCalendar($GJD);
	$JD=$GJD;
	$dayweek=($JD+1)%7;
	$flag=1; #date has been found
	return ($flag, $yg, $mg, $dg, $dayweek);
}
#==========================================================
=HCalendarToJDA
Name:    HCalendarToJDA						
Type:    Function                                                  
Purpose: convert Hdate(year,month,day) to Exact Julian Day     	
Arguments:                                                         
Input : Hijrah  date: year:yh, month:mh, day:dh                    
Output:  The Exact Julian Day: JD                                  
=cut
# $GJD= &HCalendarToJDA($yh,$mh,1);
sub HCalendarToJDA{
my ($self, $yh, $mh, $dh) = @_;

	my ($flag, $Dy, $m, $b);
	my ($JD);
	my ($GJD);

	$JD = int ($self->HCalendarToJD($yh,1,1));#  estimate JD of the begining of the year
	$Dy = int ($MonthMap[$yh-$HStartYear]/4096); #  Mask 1111000000000000
	$GJD=$JD-3+$Dy;   #correct the JD value from stored tables
	$b = int ($MonthMap[$yh-$HStartYear]);
	$b=int ($b-$Dy*4096);
	for ($m=1; $m<$mh; $m++)
	{
		$flag = $b % 2;  #Mask for the current month
		if ($flag) {$Dy=30;} else {$Dy=29;}
		$GJD=$GJD+$Dy;   #Add the months lengths before mh
		$b=int (($b-$flag)/2);
	}
	$GJD=$GJD+$dh-1;
	return $GJD;
}
#==========================================================
=HMonthLength
Name:    HMonthLength						
Type:    Function                                                  
Purpose: Obtains the month length            		     	
Arguments:                                                         
Input : Hijrah  date: year:yh, month:mh                            
Output:  Month Length                                              
int HMonthLength(int yh,int mh)
=cut
sub HMonthLength{
my ($self, $yh, $mh) = @_;
 
	my ($flag, $Dy, $N, $m, $b);

	if ($yh<$HStartYear || $yh>$HEndYear)
	{
		$flag=0;
		$Dy=0;
	}
	else
	{
		$Dy=int ($MonthMap[$yh-$HStartYear]/4096); # Mask 1111000000000000
		$b=int($MonthMap[$yh-$HStartYear]);
		$b=int($b-$Dy*4096);
		for($m=1;$m<=$mh;$m++)
		{
			$flag = $b % 2;  #Mask for the current month
			if ($flag) {$Dy=30;} else {$Dy=29;}
			$b=int(($b-$flag)/2);
		}
   }
	return $Dy;
}
#==========================================================
=DayInYear
Name:    DayInYear							
Type:    Function                                                  
Purpose: Obtains the day number in the yea          		     	
Arguments:                                                         
Input : Hijrah  date: year:yh, month:mh  day:dh                    
Output:  Day number in the Year					
int DayinYear(int yh,int mh,int dh)
=cut
sub DayinYear{
my ($self, $yh, $mh, $dh) = @_;
  
	my ($flag, $Dy, $N, $m, $b, $DL);

	if ($yh<$HStartYear || $yh>$HEndYear)
	{
		$flag=0;
		$DL=0;
	}
	else
	{
		$Dy=int($MonthMap[$yh-$HStartYear]/4096); #  Mask 1111000000000000
		$b=int($MonthMap[$yh-$HStartYear]);
		$b=int($b-$Dy*4096);
		$DL=0;
		for ($m=1; $m<=$mh; $m++)
		{
			$flag = $b % 2;  #Mask for the current month
			if ($flag) {$Dy=30;} else {$Dy=29;}
			$b=int(($b-$flag)/2);
			$DL=int($DL+$Dy);
		}
		$DL=int($DL+$dh);
	}
	return $DL;
}
#==========================================================
=HYearLength
Name:    HYearLength						    	
Type:    Function                                                  
Purpose: Obtains the year length            		     	    	
Arguments:                                                         
Input : Hijrah  date: year:yh                                  	
Output:  Year Length                                               
int HYearLength(int yh)
=cut
sub HYearLength{
my ($self, $yh) = @_;
 
	my ($flag, $Dy, $N, $m, $b, $YL);

	if ($yh<$HStartYear || $yh>$HEndYear)
	{
		$flag=0;
		$YL=0;
	}
	else
	{
		$Dy=int($MonthMap[$yh-$HStartYear]/4096);  #Mask 1111000000000000
		$b=int($MonthMap[$yh-$HStartYear]);
		$b=int($b-$Dy*4096);
		$flag=$b % 2;  #Mask for the current month
		if ($flag) {$YL=30;} else {$YL=29;}
		for ($m=2; $m<=12; $m++)
		{
			$flag = $b % 2; #  Mask for the current month
			if ($flag) {$Dy=30;} else {$Dy=29;}
			$b=int(($b-$flag)/2);
			$YL=int($YL+$Dy);
		}
	}
	return $YL;
}

#==========================================================
=G2HA
Name:    G2HA                                                      
Type:    Procedure                                                 
Purpose: convert Gdate(year,month,day) to Hdate(year,month,day)    
Arguments:                                                         
Input: Gregorian date: year:yg, month:mg, day:dg                   
Output: Hijrah  date: year:yh, month:mh, day:dh, day of week:dayweek
      and returns flag found:1 not found:0                         
int  G2HA(int yg,int mg, int dg,int *yh,int *mh,int *dh,int *dayweek)
=cut
sub G2HA{
my ($self, $yg, $mg, $dg) = @_;
my ($yh, $mh, $dh, $dayweek);

	my ($yh1, $mh1, $dh1);
	my ($yh2, $mh2, $dh2);
	my ($yg1, $mg1, $dg1);
	my ($yg2, $mg2, $dg2);
	my ($df, $dw2);
	my ($flag);
	my ($J);
	my ($GJD, $HJD);


	$GJD = $self->GCalendarToJD($yg, $mg, $dg+0.5); # find JD of Gdate
	($yh1,$mh1, $dh1) = $self->JDToHCalendar($GJD);  # estimate the Hdate that correspond to the Gdate
	$HJD = $self->HCalendarToJDA($yh1, $mh1, $dh1);   #// get the exact Julian Day
	$df=int ($GJD-$HJD);
	$dh1=int($dh1+$df);
	while ($dh1>30)
	{
		$dh1=int($dh1-$self->HMonthLength($yh1, $mh1));
		$mh1++;
		if ($mh1>12) {$yh1++; $mh1=1;}
	}
	if ($dh1==30)
	{
		$mh2=int($mh1+1);
		$yh2=$yh1;
		if ($mh2>12) {$mh2=1;$yh2++;}
		($yg1, $mg1, $dg1, $dw2) = $self->BH2GA(int($yh2), int($mh2));
		$yg1=int($yg1);	$mg1= int($mg1);	$dg1 = int($dg1);	$dw2 = int($dw2);
		if ($dg==$dg1) {$yh1=$yh2;$mh1=$mh2;$dh1=1;} # Make sure that the month is 30days if not make adjustment
	}
   
	$J= int ($self->GCalendarToJD($yg,$mg,$dg)+2);
	$dayweek= $J % 7;
	#print "there $dayweek= $J % 7\n";
	$yh=$yh1;
	$mh=$mh1;
	$dh=$dh1;
	return ($flag, $yh, $mh, $dh, $dayweek);
}
#==========================================================
=H2GA
Name:    H2GA                                                      
Type:    Procedure                                                 
Purpose: convert Hdate(year,month,day) to Gdate(year,month,day)    
Arguments:                                                         
Input/Ouput: Hijrah  date: year:yh, month:mh, day:dh               
Output: Gregorian date: year:yg, month:mg, day:dg , day of week:dayweek
      and returns flag found:1 not found:0                         
Note: The function will correct Hdate if day=30 and the month is 29 only
int  H2GA(int *yh,int *mh,int *dh, int *yg,int *mg, int *dg,int *dayweek)
=cut
sub H2GA{
my ($self, $yh, $mh, $dh, $yg, $mg, $dg, $dayweek) = @_;

	my ($found,$yh1,$mh1,$yg1,$mg1,$dg1,$dw1);

    #make sure values are within the allowed values
    if ($dh>30) {$dh=1;$mh++;}
    if ($dh<1)  {$dh=1; $mh--;}
    if ($mh>12) {$mh=1; $yh++;}
    if ($mh<1)  {$mh=12;$yh--;}

	 #find the date of the begining of the month
    ($found,  $yg, $mg, $dg, $dayweek) = $self->BH2GA($yh, $mh);
    $dg=$dg+$dh-1;
    
	($yg, $mg, $dg) = $self->GDateAjust($yg, $mg, $dg); #    Make sure that dates are within the correct values
    $dayweek=$dayweek+$dh-1;
    $dayweek=$dayweek % 7;

	 #find the date of the begining of the next month
   if ($dh==30)
   {
    $mh1=$mh+1;
    $yh1=$yh;
    if ($mh1>12) {$mh1=$mh1-12;$yh1++;}
    ($found, $yg1, $mg1, $dg1, $dw1) = $self->BH2GA($yh1, $mh1);
    if ($dg==$dg1) {$yh=$yh1;$mh=$mh1;$dh=1;} # Make sure that the month is 30days if not make adjustment
   }

   return ($found, $yg, $mg, $dg, $dayweek);
}
#==========================================================
=JDToGCalendar
Name:    JDToGCalendar						
Type:    Procedure                                                 
Purpose: convert Julian Day  to Gdate(year,month,day)              
Arguments:                                                         
Input:  The Julian Day: JD                                         
Output: Gregorian date: year:yy, month:mm, day:dd                  
double JDToGCalendar(double JD, int *yy,int *mm, int *dd)
=cut
# (undef, $yg, $mg, $dg) = &JDToGCalendar($GJD);
sub JDToGCalendar{
my ($self, $JD) = @_;
my ($yy, $mm, $dd);
my ($A, $B, $F);
my ($alpha, $C, $E);
my ($D, $Z);

	$Z = floor ($JD + 0.5);
	$F = ($JD + 0.5) - $Z;
	$alpha = int (($Z - 1867216.25) / 36524.25);
	$A = $Z + 1 + $alpha - $alpha / 4;
	$B = $A + 1524;
	$C = int (($B - 122.1) / 365.25);
	$D = (365.25 * $C);
	$E = int (($B - $D) / 30.6001);
	$dd = $B - $D - floor (30.6001 * $E) + $F;
	if ($E < 14){
		$mm = $E - 1;
	}
	else{
		$mm = $E - 13;
	}
	if ($mm > 2){
		$yy = $C - 4716;
	}
	else{
		$yy = $C - 4715;
	}

	$F=$F*24.0;
	return ($F, $yy, $mm, $dd);
}
#==========================================================
=GCalendarToJD
Name:    GCalendarToJD						
Type:    Function                                                  
Purpose: convert Gdate(year,month,day) to Julian Day            	
Arguments:                                                         
Input : Gregorian date: year:yy, month:mm, day:dd                  
Output:  The Julian Day: JD                                        
double GCalendarToJD(int yy,int mm, double dd)
=cut

sub GCalendarToJD{
my ($self, $yy, $mm, $dd) = @_;
my ($A, $B, $m, $y);
my ($T1, $T2, $Tr);
	# it does not take care of 1582correction assumes correct calender from the past

	if ($mm > 2) {
		$y = int($yy);
		$m = int ($mm);
	}
	else {
		$y = int ($yy - 1);
		$m = $mm + 12;
	}

	$A = int($y / 100);
	$B = int(2 - $A + $A / 4);
	$T1 = $self->ip (365.25 * ($y + 4716));
	$T2 = $self->ip (30.6001 * ($m + 1));
	$Tr = $T1+ $T2 + $dd + $B - 1524.5 ;
	return (int $Tr);
}
#==========================================================
=GLeapYear
Name:    GLeapYear						      
Type:    Function                                                  
Purpose: Determines if  Gdate(year) is leap or not            	
Arguments:                                                         
Input : Gregorian date: year				              
Output:  0:year not leap   1:year is leap                          
int GLeapYear(int year)
=cut
sub GLeapYear{
my ($self, $year) = @_;
my ($T);

	$T=0;
	if ($year % 4 ==0) {$T=1;} # leap_year=1;
	if ($year % 100 == 0)
	{
		$T=0;      #  years=100,200,300,500,... are not leap years
		if ($year % 400 ==0) {$T=1;} #   years=400,800,1200,1600,2000,2400 are leap years
	}
	return ($T);
}
#==========================================================
=GDateAjust
Name:    GDateAjust							
Type:    Procedure                                                 
Purpose: Adjust the G Dates by making sure that the month lengths  
	    are correct if not so take the extra days to next month or year
Arguments:                                                         
Input: Gregorian date: year:yg, month:mg, day:dg                   
Output: corrected Gregorian date: year:yg, month:mg, day:dg        
void GDateAjust(int *yg,int *mg,int *dg)
=cut
sub GDateAjust{
my ($self, $yg, $mg, $dg) = @_;
my ($dys);

	# Make sure that dates are within the correct values
	#   Underflow
	if ( $mg<1)  #months underflow
	{
		$mg=12+$mg;  # plus as the underflow months is negative
		$yg=$yg-1;
	}

	if ($dg<1) # days underflow
	{
		$mg= $mg-1; # month becomes the previous month
		$dg=$gmonth[$mg]+$dg; # number of days of the month less the underflow days (it is plus as the sign of the day is negative)
		if ($mg==2) {$dg=$dg+ $self->GLeapYear($yg)};
		if ($mg<1) # months underflow
		{
			$mg=12+$mg;  #plus as the underflow months is negative
			$yg=$yg-1;
		}
	}

	#Overflow
	if ($mg>12) #  months
	{
		$mg=$mg-12;
		$yg=$yg+1;
	}

	if($mg==2){
		$dys=int ($gmonth[$mg]+ $self->GLeapYear($yg) ); #  number of days in the current month
	}
	else{
		$dys=int($gmonth[$mg]);
	}

	if ($dg>$dys) #  days overflow
	{
		$dg=$dg-$dys;
		$mg=$mg+1;
		if ($mg==2)
		{
			$dys= int($gmonth[$mg]+ $self->GLeapYear($yg));#  number of days in the current month
			if ($dg>$dys)
			{
				$dg=$dg-$dys;
				$mg=$mg+1;
			}
		}

		if ($mg>12) # months
		{
			$mg=$mg-12;
			$yg=$yg+1;
		}
	}
	return ($yg, $mg, $dg);
}
#==========================================================
=DayWeek
  The day of the week is obtained as
  Dy=(Julian+1)%7
  Dy=0 Sunday
  Dy=1 Monday
  ...
  Dy=6 Saturday
int DayWeek(long JulianD)
=cut
sub DayWeek{
my ($self, $JulianD) = @_;
my ($Dy);
	$Dy= int (($JulianD+1) % 7);
	return ($Dy);
}
#==========================================================
=HCalendarToJD
Name:    HCalendarToJD						
Type:    Function                                                  
Purpose: convert Hdate(year,month,day) to estimated Julian Day     	
Arguments:                                                         
Input : Hijrah  date: year:yh, month:mh, day:dh                    
Output:  The Estimated Julian Day: JD                              
double HCalendarToJD(int yh,int mh,int dh)
=cut
sub HCalendarToJD{
my ($self, $yh, $mh, $dh) = @_;
 my ($md, $yd);

	#Estimating The JD for hijrah dates
	#this is an approximate JD for the given hijrah date
	$md=($mh-1.0)*29.530589;
	$yd=($yh-1.0)*354.367068+$md+$dh-1.0;
	$yd=$yd+1948439.0; #  add JD for 18/7/622 first Hijrah date
	return $yd;
}
#==========================================================
=JDToHCalendar
Name:    JDToHCalendar						
Type:    Procedure                                                 
Purpose: convert Julian Day to estimated Hdate(year,month,day)	
Arguments:                                                         
Input:  The Julian Day: JD                                         
Output : Hijrah date: year:yh, month:mh, day:dh                    
void JDToHCalendar(double JD,int *yh,int *mh,int *dh)
=cut
#Estimating the hijrah date from JD
sub JDToHCalendar{
my ($self, $JD) = @_;
my ($yh, $mh, $dh);
my ($md, $yd);

	$yd=$JD-1948439.0;  # subtract JD for 18/7/622 first Hijrah date
	$md= $self->mod ($yd, 354.367068);
	$dh= int($self->mod($md+0.5, 29.530589)+1);
	$mh=int(($md/29.530589)+1);
	$yd=$yd-$md;
	$yh=int($yd/354.367068+1);
	if ($dh>30) {$dh=int($dh-30); $mh++;}
	if ($mh>12) {$mh=int($mh-12); $yh++;}
	return ($yh, $mh, $dh);
}
#==========================================================
=JDToHACalendar
Name:    JDToHACalendar						
Type:    Procedure                                                 
Purpose: convert Julian Day to  Hdate(year,month,day)	    	
Arguments:                                                         
Input:  The Julian Day: JD                                         
Output : Hijrah date: year:yh, month:mh, day:dh                    
void JDToHACalendar(double JD,int *yh,int *mh,int *dh)
=cut
sub JDToHACalendar{
my ($self, $JD) = @_;
my ($yh, $mh, $dh);
my ($yh1, $mh1,$dh1);
my ($yh2,$mh2,$dh2);
my ($yg1,$mg1,$dg1);
my ($yg2,$mg2,$dg2);
my ($df,$dw2);
my ($flag);
my ($J);
my ($GJD, $HJD);

	($yh1,$mh1,$dh1) = $self->JDToHCalendar($JD); # estimate the Hdate that correspond to the Gdate
	$HJD = $self->HCalendarToJDA(int($yh1), int($mh1), int($dh1));   #// get the exact Julian Day
	$df= int($JD+0.5-$HJD);
	$dh1= int($dh1+$df);
	while ($dh1>30)
	{
		$dh1= int($dh1-$self->HMonthLength($yh1,$mh1));
		$mh1++;
		if ($mh1>12) {$yh1++;$mh1=1;}
	}
	if ($dh1==30 && $self->HMonthLength($yh1,$mh1)<30)
	{
		$dh1=1;$mh1++;
	}
	if ($mh1>12)
	{
		$mh1=1;$yh1++;
	}

	#//   J=JD+2;  *dayweek=J%7;
	$yh=$yh1;
	$mh=$mh1;
	$dh=$dh1;

	return ($yh, $mh, $dh);
}
#==========================================================
# Purpose: return the integral part of a double value.
sub  ip{
my ($self, $x) = @_;
my ($fractional, $integral);
   ($fractional, $integral) = POSIX::modf($x);
  return $integral;
}
#==========================================================
#  Name: mod
#  Purpose: The mod operation for doubles  x mod y
sub mod{
my ($self, $x, $y) = @_;
my ($r, $d);

	$d=$x/$y;
	$r=int ($d);
	if ($r<0) {$r--;}
	$d=$x-$y*$r;
	$r= int($d);
	return $r;
}
#==========================================================
#Purpose: returns 0 for incorrect Hijri date and 1 for correct date
sub IsValid{
my ($self, $yh, $mh, $dh) = @_;
my ($valid);
	
	$valid=1;
	if ($yh<$HStartYear ||   $yh>$HEndYear)     {$valid=0;}
	if ($mh<1 || $mh>12 || $dh<1){
		$valid=0;
	}
	else{
		if ($dh>$self->HMonthLength($yh,$mh))   {$valid=0;}
	}
	return $valid;
}
#==========================================================
sub TimeZoneUS{
my ($self, $state) = @_;
		
	if (exists $TimeZoneUS{$state}) {
			return $TimeZoneUS{$state};
	}
	return undef;
}
#==========================================================
sub TimeZoneCountry{
my ($self, $country) = @_;
		
	if (exists $TimeZone{$country}) {
			return $TimeZone{$country};
	}
	return undef;
}
#==========================================================
1;
__END__

=head1 NAME

Religion::Islam::PrayerTimes - Calculates Muslim Prayers Times and Sunrise

=head1 SYNOPSIS

	use Religion::Islam::PrayerTimes;

	#create new object with default options
	my $prayer = Religion::Islam::PrayerTimes->new();
	
	#Juristic Methods:
	# 1 = Standard (Imams Shafii, Hanbali, and Maliki),
	#2  = Hanafi
	#The difference is in the Aser time only
	$prayer->JuristicMethod(1);
	
	# Calculation Method 
	#1:	Umm Al-Qura Committee
	#2:	Muslim World League
	#3:	Egyptian General Authority of Survey
	#4:	University Of Islamic Sciences, Karachi
	#5:	ISNA, Islamic Society of North America
	$prayer->CalculationMethod(3);
	
	# Q. What is daylight saving? Ans. Many countries try to adopt their work time by subtracting
	# from their clocks one hour in the Fall and Winter seasons. 
	$prayer->DaylightSaving(1);
	#print "DaylightSaving: ". $prayer->DaylightSaving() ."\n";
	
	# set the location to clculate prayer times for.
	# for Cairo, Egypt:
	# http://heavens-above.com/countries.asp
	$prayer->PrayerLocation(
									Latitude => 30.050,
									Longitude => 31.250,
									Altitude => 24,
									TimeZone => 2
								);
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon++; 	$year += 1900;

	#Adjust the Gregorian Dates by making sure that the month lengths  
	#are correct if not so take the extra days to next month or year.
	my ($yg0, $mg0, $dg0) = $prayer->GDateAjust($year, $mon, $mday);
	# Now calculate the prayer times. Times returns in hours decimal format

	#%result = $prayer->PrayerTimes($year, $mon, $mday);
	%result = $prayer->PrayerTimes($yg0, $mg0, $dg0);
	
	#print "Fajr: " . $result{Fajr} . "\n";
	#print "Sunrise: " . $result{Sunrise} . "\n";
	#print "Zohar: " . $result{Zohar} . "\n";
	#print "Aser: " . $result{Aser} . "\n";
	#print "Maghrib: " . $result{Maghrib} . "\n";
	#print "Isha: " . $result{Isha} . "\n";
	#print "Fajir Rabita: " . $result{FajirRabita} . "\n";	 #Fajer using exact Rabita method for places >48
	#print "Isha Rabita: " . $result{IshaRabita} . "\n";	#Ash using exact Rabita method for places >48
	#print "Eid Prayer Time: " . $result{Eid} . "\n";	 #Eid Prayer Time
	#print "\n";
	
	# set time mode for 12 or 24 hour for FormatTime function.
	$prayer->TimeMode(1);
	#print time formated
	#print "TimeMode: "  . $prayer->TimeMode() ."\n";

	my ($h, $m, $ap);

	($h, $m, $ap) = $prayer->FormatTime($result{Fajr});
	print "Fajr: $h:$m $ap\n";

	($h, $m, $ap) = $prayer->FormatTime($result{Sunrise});
	print "Sunrise: $h:$m $ap\n";

	($h, $m, $ap) = $prayer->FormatTime($result{Zohar});
	print "Zohar: $h:$m $ap\n";

	($h, $m, $ap) = $prayer->FormatTime($result{Aser});
	print "Aser: $h:$m $ap\n";

	($h, $m, $ap) = $prayer->FormatTime($result{Maghrib});
	print "Maghrib: $h:$m $ap\n";

	($h, $m, $ap) = $prayer->FormatTime($result{Isha});
	print "Isha: $h:$m $ap\n";
	
	#($h, $m, $ap) = $prayer->FormatTime($result{FajirRabita});
	#print "Fajir Rabita: $h:$m $ap\n";	 #Fajer using exact Rabita method for places >48

	#($h, $m, $ap) = $prayer->FormatTime($result{IshaRabita});
	#print "Isha Rabita: $h:$m $ap\n";	#Ash using exact Rabita method for places >48

	#($h, $m, $ap) = $prayer->FormatTime($result{Eid});
	#print "Eid Prayer Time: $h:$m $ap\n";	 #Eid Prayer Time

=head1 DESCRIPTION

This module calculates Muslim prayers times and sunrise for any location on the earth.

=head1 SEE ALSO

L<Religion::Islam::Qibla>
L<Religion::Islam::Quran>

=head1 AUTHOR

Ahmed Amin Elsheshtawy, E<lt>support@islamware.com<gt>
Website: http://www.islamware.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ahmed Amin Elsheshtawy support@islamware.com,
L<http://www.islamware.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
