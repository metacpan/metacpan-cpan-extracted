use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Generic::DateTime;
# ABSTRACT: Generic representation of a Neo4j temporal instant value
$Neo4j::Types::Generic::DateTime::VERSION = '2.00';

use parent 'Neo4j::Types::DateTime';


sub new {
	# uncoverable pod - see Generic.pod
	my ($class, $dt, $tz) = @_;
	
	if (ref $dt eq '') {
		my $days = int $dt / 86400;
		$dt = {
			days => $dt < 0 ? $days - 1 : $days,  # floor
			seconds => $dt % 86400,
		};
		if ($tz && 0x40 & ord substr $tz, 0, 1) {
			$dt->{tz_name} = $tz;
		}
		else {
			$dt->{tz_offset} = $tz;
		}
	}
	
	if (defined $dt->{seconds} && ! defined $dt->{nanoseconds}) {
		$dt->{nanoseconds} = 0;
	}
	if (! defined $dt->{seconds} && defined $dt->{nanoseconds}) {
		$dt->{seconds} = 0;
	}
	return bless $dt, __PACKAGE__;
}


sub days { shift->{days} }
sub seconds { shift->{seconds} }
sub nanoseconds { shift->{nanoseconds} }
sub tz_offset { shift->{tz_offset} }


sub tz_name {
	my ($self) = @_;
	
	if ( ! exists $self->{tz_name} && defined $self->{tz_offset} ) {
		if ( $self->{tz_offset} == 0 ) {
			return $self->{tz_name} = 'Etc/GMT';
		}
		my $hours = $self->{tz_offset} / -3600;
		if ( $hours != int $hours || $hours > 12 || $hours < -14 ) {
			return $self->{tz_name} = undef;
		}
		$self->{tz_name} = sprintf 'Etc/GMT%+i', $hours;
	}
	
	return $self->{tz_name};
}

1;
