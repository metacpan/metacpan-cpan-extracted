use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Duration;
# ABSTRACT: Represents a Neo4j temporal duration value
$Neo4j::Driver::Type::Duration::VERSION = '0.47';

# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::Duration';
use parent 'Neo4j::Driver::Type::Temporal';


sub _parse {
	my ($self) = @_;
	
	if ( ! exists $self->{T} ) {  # JSON format
		$self->{T} = $self->{data};
	}
	
	my ($minus, $years, $months, $weeks, $days, $hours, $mins, $secs, $nanos) = $self->{T} =~ m/^(-)?P(?:([-0-9.]+)Y)?(?:([-0-9.]+)M)?(?:([-0-9.]+)W)?(?:([-0-9.]+)D)?(?:T(?:([-0-9.]+)H)?(?:([-0-9.]+)M)?(?:([-0-9]+)(?:[,.]([0-9]+))?S)?)?$/;
	
	my $sign = $minus ? -1 : 1;
	$self->{months} = $sign * ( ($years // 0) * 12 + ($months // 0) );
	$self->{days} = $sign * ( ($weeks // 0) * 7 + ($days // 0) );
	$self->{seconds} = $sign * ( ($hours // 0) * 3600 + ($mins // 0) * 60 + ($secs // 0) );
	$self->{nanoseconds} = 0;
	if (defined $nanos) {
		$nanos = sprintf '%-9s', $nanos;
		$nanos =~ tr/ /0/;
		$self->{nanoseconds} = ($secs =~ m/^-/ ? -1 : 1) * $sign * $nanos;
	}
}


sub months {
	my ($self) = @_;
	exists $self->{months} or $self->_parse;
	return $self->{months};
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


1;
