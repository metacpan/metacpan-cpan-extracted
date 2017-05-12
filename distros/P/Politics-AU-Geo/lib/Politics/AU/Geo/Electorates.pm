package Politics::AU::Geo::Electorates;

use strict;
use Politics::AU::Geo::Polygons;

our $VERSION = '0.01';

sub house_id {
	my $self = shift;
	join( '.', $self->state, $self->level, $self->house );
}

sub point_in_polygon {
	my $self      = shift;
	my $latitude  = shift;
	my $longitude = shift;

	# Load the polygon
	my @polygon = Politics::AU::Geo::Polygons->select(
		'where eid = ?', $self->eid,
	);
	unless ( @polygon ) {
		die("Failed to find polygon for electorate");
	}

	$polygon[0]->point_in_polygon( $latitude, $longitude );
}

1;

__END__

=pod

=head1 NAME

Politics::AU::Geo::Electorates - Politics::AU::Geo class for the electorates table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = Politics::AU::Geo::Electorates->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = Politics::AU::Geo::Electorates->select(
      'where eid > ? order by eid',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
electorates table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM electorates> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<Politics::AU::Geo::Electorates> objects when called in list context, or a
reference to an ARRAY of B<Politics::AU::Geo::Electorates> objects when called in scalar context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = Politics::AU::Geo::Electorates->count;
  
  # How many objects 
  my $small = Politics::AU::Geo::Electorates->count(
      'where eid > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
electorates table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM electorates> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head1 ACCESSORS

=head2 eid

  if ( $object->eid ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The electorates table was originally created with the
following SQL command.

  CREATE TABLE electorates
  (
  eid INTEGER PRIMARY KEY,
  bblat1 varchar(20) NOT NULL,
  bblat2 varchar(20) NOT NULL,
  bblong1 varchar(20) NOT NULL,
  bblong2 varchar(20) NOT NULL,
  name varchar(255) NOT NULL,
  state varchar(10) NOT NULL,
  level varchar(10) NOT NULL,
  house  varchar(255) NOT NULL
  )

=head1 SUPPORT

Politics::AU::Geo::Electorates is part of the L<Politics::AU::Geo> API.

See the documentation for L<Politics::AU::Geo> for more information.

=head1 AUTHOR

Jeffery Candiloro E<lt>jeffery@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Jeffery Candiloro.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
