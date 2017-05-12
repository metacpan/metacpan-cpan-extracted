#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: http://www.mewsoft.com
# Email  : support@mewsoft.com
# Copyrights (c) 2000-2015 Mewsoft Corporation. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Religion::Islam::Qibla;

use Carp;
use strict;
use warnings;
use Math::Trig;

our $VERSION = '4.0';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
    my ($class, %args) = @_;
	my $self = bless {}, $class;
	# Default destination point is the  Kabah Lat=21 Deg N, Long 40 Deg E
	$self->{DestLat} = $args{DestLat}? $args{DestLat}: 21.423333; # 21.423333;
	$self->{DestLong} = $args{DestLong}? $args{DestLong}: 39.823333; # 39.823333;
    return $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DestLat {
my ($self) = shift; 
	$self->{DestLat} = shift if @_;
	return $self->{DestLat};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DestLong {
my ($self) = shift; 
	$self->{DestLong} = shift if @_;
	return $self->{DestLong};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 #Converting from Degrees, Minutes and Seconds to Decimal Degrees
sub DegreeToDecimal {
my ($self, $degrees, $minutes, $seconds) = @_;
	return $degrees + ($minutes / 60) + ($seconds / 3600);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Converting from Decimal Degrees to Degrees, Minutes and Seconds
sub DecimalToDegree {
my ($self, $decimal_degree) = @_;
my ($degrees, $minutes, $seconds, $ff);
     
    $degrees = int($decimal_degree);
    $ff = $decimal_degree - $degrees;
    $minutes = int(60 * $ff);
    $seconds = 60 * ((60 * $ff) - $minutes);
	return ($degrees, $minutes, $seconds);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The shortest distance between points 1 and 2 on the earth's surface is
# d = arccos{cos(Dlat) - [1 - cos(Dlong)]cos(lat1)cos(lat2)}
# Dlat = lab - lat2
# Dlong = 10ng - long2
# lati, = latitude of point i
# longi, = longitude of point i

#Conversion of grad to degrees is as follows:
#Grad=400-degrees/0.9 or Degrees=0.9x(400-Grad)

#Latitude is determined by the earth's polar axis. Longitude is determined
#by the earth's rotation. If you can see the stars and have a sextant and
#a good clock set to Greenwich time, you can find your latitude and longitude.

# one nautical mile equals to:
#   6076.10 feet
#   2027 yards
#   1.852 kilometers
#   1.151 statute mile

# Calculates the distance between any two points on the Earth
sub  GreatCircleDistance {
my ($self, $orig_lat , $dest_lat, $orig_long, $dest_long) = @_;
my ($d, $l1, $l2, $i1, $i2);
    
    $l1 = deg2rad($orig_lat);
    $l2 = deg2rad($dest_lat);
    $i1 = deg2rad($orig_long);
    $i2 = deg2rad($dest_long);
    
    $d = acos(cos($l1 - $l2) - (1 - cos($i1 - $i2)) * cos($l1) * cos($l2));
    # One degree of such an arc on the earth's surface is 60 international nautical miles NM
    return rad2deg($d * 60);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Calculates the direction from one point to another on the Earth
# a = arccos{[sin(lat2) - cos(d + lat1 - 1.5708)]/cos(lat1)/sin(d) + 1}
# Great Circle Bearing
sub GreatCircleDirection {
my ($self, $orig_lat, $dest_lat, $orig_long, $dest_long, $distance) = @_;
my ($a, $b, $d, $l1, $l2, $i1, $i2, $result, $dlong);
    
	$l1 = deg2rad($orig_lat);
	$l2 = deg2rad($dest_lat);
	$d = deg2rad($distance / 60); # divide by 60 for nautical miles NM to degree

	$i1 = deg2rad($orig_long);
	$i2 = deg2rad($dest_long);
	$dlong = $i1 - $i2;

	$a = sin($l2) - cos($d + $l1 - pi / 2);
	$b = acos($a / (cos($l1) * sin($d)) + 1);
	if ((abs($dlong) < pi && $dlong < 0) || (abs($dlong) > pi && $dlong > 0) ) {
        #$b = (2 * pi) - $b;
    }
	$result = rad2deg($b);

	return $result;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#The Equivalent Earth redius is 6,378.14 Kilometers.
# Calculates the direction of the Qibla from any point on
# the Earth From North Clocklwise
sub QiblaDirection_ {
my ($self, $orig_lat, $orig_long) = @_;
my ($distance, $bearing);
    
	# Kabah Lat=21 Deg N, Long 40 Deg E
	$distance = $self->GreatCircleDistance($orig_lat, $self->{DestLat}, $orig_long, $self->{DestLong});
	$bearing = $self->GreatCircleDirection($orig_lat, $self->{DestLat}, $orig_long, $self->{DestLong}, $distance);

    if ($orig_lat > $self->{DestLat}) {
        #$bearing += 180;
    }

	return $bearing;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Determine Qibla direction using basic spherical trigonometric formula
# Return float Qibla Direction from the north direction in degrees
sub QiblaDirection__ {
    
    my ($self, $orig_lat, $orig_long) = @_;

    #$orig_lat = 35.3833;
    #$orig_long = 119.0166;
    #Saudi Arabia, Riyadh Qibla = 245,  Qibla Direction: 244.53 degees from true North,  Distance from Ka'bah in Makkah: 790.18 km

    my $numerator   = sin(deg2rad($self->{DestLong} - $orig_long));

    my $denominator = (cos(deg2rad($orig_lat)) * tan(deg2rad($self->{DestLat}))) -
                      (sin(deg2rad($orig_lat)) * cos(deg2rad($self->{DestLong} - $orig_long)));

    my $q = rad2deg(atan($numerator / $denominator));

    if ($orig_lat > $self->{DestLat}) {
        #$q += 180;
    }
    
    # Yemen, Sanaa = -35.57 from North = 324.43 from North
    if ($q < 0) {
        #$q += 360;
    }
    return $q;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This is the only algorithm working with all other confirmed calculations
# See JS code source at http://www.moonsighting.com/qibla.html
sub QiblaDirection {
    
    my ($self, $lat, $lon) = @_;

    #$orig_lat = 35.3833;
    #$orig_long = 119.0166;
    #Saudi Arabia, Riyadh Qibla = 245,  Qibla Direction: 244.53 degees from true North,  Distance from Ka'bah in Makkah: 790.18 km

	my $latk = deg2rad($self->{DestLat});
	my $longk = deg2rad($self->{DestLong});
	my $phi = deg2rad($lat);
	my $lambda = deg2rad($lon);
	my $qiblad = rad2deg(atan2(sin($longk - $lambda), cos($phi)*tan($latk)-sin($phi)*cos($longk-$lambda)));
    if ($qiblad < 0) {
        $qiblad += 360;
    }
	return $qiblad;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=cuts
public function getQibla () 
{
    // The geographical coordinates of the Ka'ba
    $K_latitude  = 21.423333;
    $K_longitude = 39.823333;
    
    $latitude  = $this->lat;
    $longitude = $this->long;

    $numerator   = sin(deg2rad($K_longitude - $longitude));
    $denominator = (cos(deg2rad($latitude)) * tan(deg2rad($K_latitude))) -
                   (sin(deg2rad($latitude)) 
                   * cos(deg2rad($K_longitude - $longitude)));

    $q = atan($numerator / $denominator);
    $q = rad2deg($q);
    
    if ($this->lat > 21.423333) {
        $q += 180;
    }
    
    return $q;
}

<script><!--
PI = Math.PI;
var win = null;
function calculate(lat, lon) {
	if (isNaN(lat+0.0) || isNaN(lon+0.0)) {
		alert("Non-numeric entry/entries");
		return "???";
	}
	if ((lat-0.0)>(90.0-0.0) || (lat-0.0)<(-90.0-0.0)) {
		alert("Latitude must be between -90 and 90 degrees");
		return "???";
	}
	if ((lon-0.0)>(180.0-0.0) || (lon-0.0)<(-180.0-0.0)) {
		alert("Longitude must be between -180 and 180 degrees");
		return "???";
	}

	if ((lat+0.0==21.4) && (lon+0.0==39.8)) return "Any Direction";
	latk = 21.4225*PI/180.0;
	longk = 39.8264*PI/180.0;
	phi = lat*PI/180.0;
	lambda = lon*PI/180.0;
	qiblad = 180.0/PI*Math.atan2(Math.sin(longk-lambda), Math.cos(phi)*Math.tan(latk)-Math.sin(phi)*Math.cos(longk-lambda));
	return (qiblad);
}

    
=cut

1;

=head1 NAME

Religion::Islam::Qibla - Calculates the Muslim Qiblah Direction, Great Circle Distance, and Great Circle Direction

=head1 SYNOPSIS

	use Religion::Islam::Qibla;
	#create new object with default options, Destination point is Kabah Lat=21 Deg N, Long 40 Deg E
	my $qibla = Religion::Islam::Qibla->new();
	
	# OR
	#create new object and set your destination point Latitude and/or  Longitude
	my $qibla = Religion::Islam::Qibla->new(DestLat => 21, DestLong => 40);
	
	# Calculate the Qibla direction From North Clocklwise for Cairo : Lat=30.1, Long=31.3
	my $Latitude = 30.1;
	my $Longitude = 31.3;
	my $QiblaDirection = $qibla->QiblaDirection($Latitude, $Longitude);
	print "The Qibla Direction for $Latitude and $Longitude From North Clocklwise is: " . $QiblaDirection ."\n";
	
	# Calculates the distance between any two points on the Earth
	my $orig_lat = 31; my $dest_lat = 21; my $orig_long = 31.3; $dest_long = 40;
	my $distance = $qibla->GreatCircleDistance($orig_lat , $dest_lat, $orig_long, $dest_long);
	print "The distance is: $distance \n";

	# Calculates the direction from one point to another on the Earth. Great Circle Bearing
	my $direction = $qibla->GreatCircleDirection($orig_lat, $dest_lat, $orig_long, $dest_long, $distance);
	print "The direction is: $direction \n";
	
	# You can get and set the distination point Latitude and Longitude
	# $qibla->DestLat(21);		#	set distination Latitude
	# $qibla->DestLong(40);	# set distincatin Longitude
	print "Destination Latitude:" . $qibla->DestLat();
	print "Destination Longitude:" . $qibla->DestLong();

=head1 DESCRIPTION

This module calculates the Qibla direction where muslim prayers directs their face. It 
also calculates and uses the Great Circle Distance and Great Circle Direction.

=head1 SEE ALSO

L<Date::HijriDate>
L<Religion::Islam::Quran>
L<Religion::Islam::PrayTime>
L<Religion::Islam::PrayerTimes>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@islamware.com> <support@mewsoft.com>
Website: http://www.islamware.com   http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2015 by Ahmed Amin Elsheshtawy support@islamware.com, support@mewsoft.com
L<http://www.islamware.com>  L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
