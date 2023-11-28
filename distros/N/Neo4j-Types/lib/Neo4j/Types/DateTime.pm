use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::DateTime;
# ABSTRACT: Represents a Neo4j temporal instant value
$Neo4j::Types::DateTime::VERSION = '2.00';

sub epoch {
	my ($self) = @_;
	
	return ($self->days // 0) * 86400 + ($self->seconds // 0);
}


sub type {
	my ($self) = @_;
	
	return 'DATE' unless defined $self->seconds;
	
	unless (defined $self->days) {
		return 'LOCAL TIME' unless defined $self->tz_offset;
		return 'ZONED TIME';
	}
	
	return 'LOCAL DATETIME' unless defined $self->tz_offset || defined $self->tz_name;
	return 'ZONED DATETIME';
}

1;
