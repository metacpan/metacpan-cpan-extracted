use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::DateTime;
# ABSTRACT: Represents a Neo4j temporal instant value
$Neo4j::Driver::Type::DateTime::VERSION = '0.44';

# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::DateTime';
use parent 'Neo4j::Driver::Type::Temporal';


use Test::More ();  # debug crash on Win32
my $TestingWin32 = $ENV{HARNESS_ACTIVE} && $^O =~ /Win32/;  # debug crash on Win32
sub _parse {
	my ($self) = @_;
	
	if ( ! exists $self->{T} ) {  # JSON format
		$self->{T} = $self->{data};
	}
Test::More::diag "INSIDE DateTime _parse $self->{T}" if $TestingWin32;  # debug crash on Win32
	
	my ($days, $hours, $mins, $secs, $nanos, $tz) = $self->{T} =~ m/^(?:([-+]?[0-9]{4,}-[0-9]{2}-[0-9]{2}))?T?(?:([0-9]{2}):([0-9]{2}):([0-9]{2})(?:[,.]([0-9]+))?)?(.*)$/;
	
	if (defined $days) {
Test::More::diag "BEFORE require Time::Piece" if $TestingWin32;  # debug crash on Win32
		require Time::Piece;
Test::More::diag "BEFORE strptime" if $TestingWin32;  # debug crash on Win32
		my $t = Time::Piece->strptime($1, '%Y-%m-%d');
Test::More::diag "BEFORE Time::Piece mjd" if $TestingWin32;  # debug crash on Win32
		$days = $t->mjd - 40587;
	}
	$self->{days} = $days;
	
Test::More::diag "BEFORE _parse secs" if $TestingWin32;  # debug crash on Win32
	if (defined $secs) {
		$secs = $hours * 3600 + $mins * 60 + $secs;
		if (defined $nanos) {
			$nanos = sprintf '%-9s', $nanos;
			$nanos =~ tr/ /0/;
			$nanos = 0 + $nanos;
		}
		else {
			$nanos = 0;
		}
		
Test::More::diag "BEFORE _parse tz" if $TestingWin32;  # debug crash on Win32
		if ($tz eq 'Z') {
			$self->{tz_name} = 'Etc/GMT';
			$self->{tz_offset} = 0;
		}
		else {
			my ($sign, $h, $m, $name) = $tz =~ m/(?:([-+])([0-9]{2}):([0-9]{2}))?(?:\[([^\]]+)\])?/;
			$self->{tz_name} = $name;
			if (defined $h) {
				$h = "$sign$h";
				$m = "$sign$m";
				$self->{tz_offset} = $h * 3600 + $m * 60;
				if ( ! defined $name && $m == 0 && $h >= -12 && $h <= 14 ) {
					$self->{tz_name} = sprintf 'Etc/GMT%+i', $h * -1;
				}
			}
		}
	}
	$self->{seconds} = $secs;
	$self->{nanoseconds} = $nanos;
Test::More::diag "END DateTime _parse" if $TestingWin32;  # debug crash on Win32
}


sub days {
	my ($self) = @_;
	exists $self->{days} or $self->_parse;
	return $self->{days};
}


sub seconds {
	my ($self) = @_;
	exists $self->{seconds} or $self->_parse;
	return $self->{seconds};
}


sub nanoseconds {
	my ($self) = @_;
	exists $self->{nanoseconds} or $self->_parse;
	return $self->{nanoseconds};
}


sub tz_name {
	my ($self) = @_;
	exists $self->{tz_name} or $self->_parse;
	return $self->{tz_name};
}


sub tz_offset {
	my ($self) = @_;
	exists $self->{tz_offset} or $self->_parse;
	return $self->{tz_offset};
}


1;
