use v5.12;
use warnings;
use Test::More;
use Test::Neo4j::Types;
use Neo4j::Bolt;

# Conformance to Neo4j::Types requirements

plan tests => 6;


neo4j_node_ok 'Neo4j::Bolt::Node', sub {
	my ($class, $params) = @_;
	my $self = bless { %$params }, $class;
	# Neo4j::Bolt represents an unavailable element ID by using the legacy ID in its place
	$self->{element_id} //= $params->{id};
	return $self;
};


neo4j_relationship_ok 'Neo4j::Bolt::Relationship', sub {
	my ($class, $params) = @_;
	my $self = bless {
		%$params,
		start => $params->{start_id},
		end   => $params->{end_id},
	}, $class;
	# Neo4j::Bolt represents an unavailable element ID by using the legacy ID in its place
	$self->{element_id}       //= $params->{id};
	$self->{start_element_id} //= $params->{start_id};
	$self->{end_element_id}   //= $params->{end_id};
	return $self;
};


neo4j_path_ok 'Neo4j::Bolt::Path', sub {
	my ($class, $params) = @_;
	return bless [@{ $params->{elements} }], $class;
};


neo4j_point_ok 'Neo4j::Bolt::Point', sub {
	my ($class, $params) = @_;
	return bless {
		srid => $params->{srid},
		'x'  => $params->{coordinates}[0],
		'y'  => $params->{coordinates}[1],
		'z'  => $params->{coordinates}[2],
	}, $class;
};


neo4j_datetime_ok 'Neo4j::Bolt::DateTime', sub {
	my ($class, $params) = @_;
	
	# In Neo4j::Types::DateTime, either both or none of these are defined
	my $seconds = $params->{seconds};
	my $nanoseconds = $params->{nanoseconds};
	$seconds //= 0 if defined $nanoseconds;
	$nanoseconds //= 0 if defined $seconds;
	
	my $neo4j_type = 'DateTime';
	my $days = $params->{days};
	if (defined $days) {
		$neo4j_type = 'LocalDateTime' unless defined $params->{tz_offset} || defined $params->{tz_name};
		$neo4j_type = 'Date' unless defined $seconds;
	}
	else {
		$neo4j_type = 'LocalTime';
		$neo4j_type = 'Time' if defined $params->{tz_offset};
	}
	
	my $self = bless {
		neo4j_type  => $neo4j_type,
		offset_secs => $params->{tz_offset},
		tz_name     => $params->{tz_name},
	}, $class;
	
	if (! defined $seconds) {  # Date
		$self->{epoch_days} = $days;
	}
	if (! defined $days) {  # Time / LocalTime
		$self->{nsecs} = $seconds * 1e9 + $nanoseconds;
	}
	if (defined $days && defined $seconds) {  # DateTime / LocalDateTime
		$self->{epoch_secs} = $days * 86400 + $seconds;
		$self->{nsecs} = $nanoseconds;
	}
	
	return $self;
};


neo4j_duration_ok 'Neo4j::Bolt::Duration', sub {
	my ($class, $params) = @_;
	return bless {
		months => $params->{months} // 0,
		days   => $params->{days} // 0,
		secs   => $params->{seconds} // 0,
		nsecs  => $params->{nanoseconds} // 0,
	}, $class;
};


done_testing;
