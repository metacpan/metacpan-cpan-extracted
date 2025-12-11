package Neo4j::Bolt::Duration;
# ABSTRACT: Representation of Neo4j duration struct

$Neo4j::Bolt::Duration::VERSION = '0.5001';

use v5.12;
use warnings;

use parent 'Neo4j::Types::Duration';

sub months {
  shift->{months}
}

sub days {
  shift->{days}
}

sub seconds {
  shift->{secs}
}

sub nanoseconds {
  shift->{nsecs}
}

sub as_DTDuration {
  my ($self) = @_;
  require DateTime::Duration;
  return DateTime::Duration->new(
    months => $self->{months},
    days => $self->{days},
    seconds => $self->{secs},
    nanoseconds => $self->{nsecs},
    );
}

1;

__END__

=head1 NAME

Neo4j::Bolt::Duration - Representation of a Neo4j duration structure

=head1 SYNOPSIS

 $q = "RETURN datetime('P1Y10MT5H30S')";
 $dt = ( $cxn->run_query($q)->fetch_next )[0];

 $months = $dt->{months};
 $days = $dt->{days};
 $secs = $dt->{secs};
 $nanosecs = $dt->{nsecs};

 $perl_dt = $node->as_DTDuration;

=head1 DESCRIPTION

L<Neo4j::Bolt::Duration> instances are created by executing
a Cypher query that returns a duration value
from the Neo4j database.
They can also be created locally and passed to Neo4j as
query parameter. See L<Neo4j::Types::Generic/"Duration">.

The values in the Bolt structure are described at L<https://neo4j.com/docs/bolt/current/bolt/structure-semantics/>. The Neo4j::Bolt::Duration object possesses integer values
for the keys C<months>, C<days>, C<secs>, and C<nsecs>.

This class conforms to the L<Neo4j::Types::Duration> API,
which offers an object-oriented interface to the duration's
component values. This is entirely optional to use.

Use the L</as_DTDuration> method to obtain an equivalent L<DateTime::Duration>
object that can be used in the L<DateTime> context (e.g., to perform time arithmetic).

=head1 METHODS

This class provides the following methods defined by
L<Neo4j::Types::Duration>:

=over

=item * L<B<days()>|Neo4j::Types::Duration/"days">

=item * L<B<months()>|Neo4j::Types::Duration/"months">

=item * L<B<nanoseconds()>|Neo4j::Types::Duration/"nanoseconds">

=item * L<B<seconds()>|Neo4j::Types::Duration/"seconds">

=back

The following additional method is provided:

=over

=item as_DTDuration()

 $perl_dt  = $dt->as_DTDuration;

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Duration>, L<DateTime>, L<DateTime::Duration>

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN

=head1 LICENSE

This software is Copyright (c) 2024 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
