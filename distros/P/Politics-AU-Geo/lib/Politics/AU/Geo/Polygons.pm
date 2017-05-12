package Politics::AU::Geo::Polygons;

use strict;
use Storable      ();
use Params::Util  qw{_INSTANCE};
use Math::Polygon ();

our $VERSION = '0.01';

sub point_in_polygon {
	my $self      = shift;
	my $latitude  = shift;
	my $longitude = shift;

	# Inflate
	my $polygon = Storable::thaw($self->points);
	unless ( _INSTANCE($polygon, 'Math::Polygon') ) {
		die("Failed to deserialize the Math::Polygon object");
	}

	# Check
	if ( $polygon->contains([ $longitude, $latitude ]) ) {
		return 1;
	} else {
		return '';
	}
}

1;

__END__

=pod

=head1 NAME

Politics::AU::Geo::Polygons - Politics::AU::Geo class for the polygons table

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=head2 select

  # Get all objects in list context
  my @list = Politics::AU::Geo::Polygons->select;
  
  # Get a subset of objects in scalar context
  my $array_ref = Politics::AU::Geo::Polygons->select(
      'where pid > ? order by pid',
      1000,
  );

The C<select> method executes a typical SQL C<SELECT> query on the
polygons table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM polygons> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns a list of B<Politics::AU::Geo::Polygons> objects when called in list context, or a
reference to an ARRAY of B<Politics::AU::Geo::Polygons> objects when called in scalar context.

Throws an exception on error, typically directly from the L<DBI> layer.

=head2 count

  # How many objects are in the table
  my $rows = Politics::AU::Geo::Polygons->count;
  
  # How many objects 
  my $small = Politics::AU::Geo::Polygons->count(
      'where pid > ?',
      1000,
  );

The C<count> method executes a C<SELECT COUNT(*)> query on the
polygons table.

It takes an optional argument of a SQL phrase to be added after the
C<FROM polygons> section of the query, followed by variables
to be bound to the placeholders in the SQL phrase. Any SQL that is
compatible with SQLite can be used in the parameter.

Returns the number of objects that match the condition.

Throws an exception on error, typically directly from the L<DBI> layer.

=head1 ACCESSORS

=head2 pid

  if ( $object->pid ) {
      print "Object has been inserted\n";
  } else {
      print "Object has not been inserted\n";
  }

Returns true, or throws an exception on error.


REMAINING ACCESSORS TO BE COMPLETED

=head1 SQL

The polygons table was originally created with the
following SQL command.

  CREATE TABLE polygons
  (
  pid INTEGER PRIMARY KEY,
  eid INTEGER NOT NULL,
  points BLOB NOT NULL,
  CONSTRAINT eid_fk FOREIGN KEY(eid) REFERENCES Electorates(eid) ON UPDATE CASCADE ON DELETE RESTRICT
  )

=head1 SUPPORT

Politics::AU::Geo::Polygons is part of the L<Politics::AU::Geo> API.

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
