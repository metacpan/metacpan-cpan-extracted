package Miril::DateTime::ISO::Simple;

use strict;
use warnings;
use autodie;

use Time::Local qw(timelocal);
use POSIX qw(strftime);

use base 'Exporter';

our @EXPORT_OK = qw(time2iso iso2time);

sub iso2time {
	my $iso = shift;

	# 2009-11-26T16:55:34+02:00
	my $re = qr/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})([+-])(\d{2}):(\d{2})/;

	if ( $iso =~ $re ) {
		my $year = $1;
		my $month = $2 - 1;
		my $day = $3;
		my $hour = $4;
		my $min = $5;
		my $sec = $6;
		my $sign = $7;
		my $offset = $8*60*60 + $9*60;
		$offset = -$offset if $sign eq '-';

		my $local = time;
		my $gm = timelocal( gmtime $local );
		my $local_offset = $local - $gm;
		
		my $time = timelocal($sec, $min, $hour, $day, $month, $year);

		if ( $offset == $local_offset ) {
			return $time;
		} else {
			my $abs = abs($local_offset - $offset);
			$local_offset > $offset ? return $time + $abs : return $time - $abs;
		}
	}
}
	
sub time2iso {
	my $time = shift;

	# get timezone
	my $local = time;
	my $gm = timelocal( gmtime $local );
	my $sign = qw( + + - )[ $local <=> $gm ];
	my $tz = sprintf "%s%02d:%02d", $sign, (gmtime abs( $local - $gm ))[2,1];	

	# iso
	my @time = localtime $time;
	my $iso = strftime("%Y-%m-%dT%H:%M:%S$tz", @time);

	return $iso;
}

1;
