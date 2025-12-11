package Neo4j::Bolt::DateTime;
# ABSTRACT: Representation of Neo4j date/time related structs

$Neo4j::Bolt::DateTime::VERSION = '0.5001';

use v5.12;
use warnings;

use parent 'Neo4j::Types::DateTime';

# Full days since the Unix epoch
sub days {
  my $self = shift;
  if (defined $self->{epoch_secs}) {  # DateTime / LocalDateTime
    return int( $self->{epoch_secs} / 86400 ) - 1 if $self->{epoch_secs} < 0;  # floor
    return int( $self->{epoch_secs} / 86400 );
  }
  elsif (defined $self->{epoch_days}) {  # Date
    return $self->{epoch_days};
  }
  else {  # Time / LocalTime
    return undef;
  }
}

# Seconds since the start of the day
sub seconds {
  my $self = shift;
  if (defined $self->{epoch_secs}) {  # DateTime / LocalDateTime
    return $self->{epoch_secs} % 86400;
  }
  elsif (defined $self->{epoch_days}) {  # Date
    return undef;
  }
  else {  # Time / LocalTime
    return int( $self->{nsecs} / 1e9 );
  }
}

# Nanoseconds since the start of the second
sub nanoseconds {
  my $self = shift;
  if (defined $self->{epoch_secs}) {  # DateTime / LocalDateTime
    return $self->{nsecs};
  }
  elsif (defined $self->{epoch_days}) {  # Date
    return undef;
  }
  else {  # Time / LocalTime
    return $self->{nsecs} % 1e9;
  }
}

sub epoch {
  my $self = shift;
  if (defined $self->{epoch_secs}) {  # DateTime / LocalDateTime
    return $self->{epoch_secs};
  }
  elsif (defined $self->{epoch_days}) {  # Date
    return $self->{epoch_days} * 86400;
  }
  else {  # Time / LocalTime
    return int( $self->{nsecs} / 1e9 );
  }
}

# https://neo4j.com/docs/cypher-manual/5/values-and-types/temporal/#_temporal_value_types
my %TYPE = (
  Date          => 'DATE',
  DateTime      => 'ZONED DATETIME',
  LocalDateTime => 'LOCAL DATETIME',
  Time          => 'ZONED TIME',
  LocalTime     => 'LOCAL TIME',
);
sub type {
  $TYPE{ shift->{neo4j_type} }
}

sub tz_name {
  my $self = shift;
  if (defined $self->{offset_secs} && ! defined $self->{tz_name}) {
    my $hours = $self->{offset_secs} / -3600;
    return sprintf 'Etc/GMT%+i', $hours
      if $hours == int $hours && $hours >= -14 && $hours <= 12;
  }
  return $self->{tz_name};
}

sub tz_offset {
  shift->{offset_secs}
}

sub as_DateTime {
  my ($self) = @_;
  require DateTime;
  my $dt;
  for ($self->{neo4j_type}) {
    /^Date$/ && do {
      return DateTime->from_epoch( epoch => $self->{epoch_days}*86400 );
    };
    /^DateTime$/ && do {
      $dt = DateTime->from_epoch( epoch => $self->{epoch_secs} );
      $dt->set_nanosecond( $self->{nsecs} // 0 );
      $dt->set_time_zone(sprint("%+05d", $self->{offset_secs}/3600));
    };
    /^LocalDateTime$/ && do {
      $dt = DateTime->from_epoch( epoch => $self->{epoch_secs} );
      $dt->set_nanosecond( $self->{nsecs} // 0 );
      $dt->set_time_zone('floating');
    };
    /^Time$/ && do {
      $dt->DateTime->from_epoch( epoch => $self->{nsecs} / 1000000000 );
      $dt->set_nanosecond($self->{nsecs} % 1000000000);
      $dt->set_time_zone(sprint("%+05d", $self->{offset_secs}/3600));
    };
    /^LocalTime$/ && do {
      $dt->DateTime->from_epoch( epoch => $self->{nsecs} / 1000000000 );
      $dt->set_nanosecond($self->{nsecs} % 1000000000);
    };
  }
  return $dt;
}

1;

__END__

=head1 NAME

Neo4j::Bolt::DateTime - Representation of a Neo4j date/time related structure

=head1 SYNOPSIS

 $q = "RETURN datetime('2021-01-21T12:00:00-0500')";
 $dt = ( $cxn->run_query($q)->fetch_next )[0];

 $neo4j_type = $dt->{neo4j_type}; # Date, Time, DateTime, LocalDateTime, LocalTime
 $epoch_days = $dt->{epoch_days};
 $epoch_secs = $dt->{epoch_secs};
 $secs = $dt->{secs};
 $nanosecs = $dt->{nsecs};
 $offset_secs = $dt->{offset_secs};

 $perl_dt = $node->as_DateTime;

=head1 DESCRIPTION

L<Neo4j::Bolt::DateTime> instances are created by executing
a Cypher query that returns one of the date/time Bolt structures
from the Neo4j database.
They can also be created locally and passed to Neo4j as
query parameter. See L<Neo4j::Types::Generic/"DateTime">.

The values in the Bolt structures are described at L<https://neo4j.com/docs/bolt/current/bolt/structure-semantics/>. The Neo4j::Bolt::DateTime objects possess values
for the keys that are relevant to the underlying date/time structure.

This class conforms to the L<Neo4j::Types::DateTime> API,
which offers an object-oriented interface to the underlying
date/time component values. This is entirely optional to use.

Use the L</as_DateTime> method to obtain an equivalent L<DateTime>
object that is probably easier to use.

=head1 METHODS

This class provides the following methods defined by
L<Neo4j::Types::DateTime>:

=over

=item * L<B<days()>|Neo4j::Types::DateTime/"days">

=item * L<B<epoch()>|Neo4j::Types::DateTime/"epoch">

=item * L<B<nanoseconds()>|Neo4j::Types::DateTime/"nanoseconds">

=item * L<B<seconds()>|Neo4j::Types::DateTime/"seconds">

=item * L<B<type()>|Neo4j::Types::DateTime/"type">

=item * L<B<tz_name()>|Neo4j::Types::DateTime/"tz_name">

=item * L<B<tz_offset()>|Neo4j::Types::DateTime/"tz_offset">

=back

The following additional method is provided:

=over

=item as_DateTime()

 $perl_dt  = $dt->as_DateTime;
 
 $node_id = $simple->{_node};
 @labels  = @{ $simple->{_labels} };
 $value1  = $simple->{property1};
 $value2  = $simple->{property2};

Obtain a L<DateTime> object equivalent to the Neo4j structure returned
by the database. Time and LocalTime objects generate a DateTime whose date is the
first day of the Unix epoch (1970-01-01).

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::DateTime>, L<DateTime>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=head1 LICENSE

This software is Copyright (c) 2024 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
