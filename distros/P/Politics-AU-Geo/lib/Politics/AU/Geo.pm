package Politics::AU::Geo;

=pod

=head1 NAME

Politics::AU::Geo - An ORLite-based ORM Database API

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Storable       2.20 ();
use Math::Polygon  1.01 ();
use Params::Util   0.38 ();
use ORLite::Mirror 1.15 ();

our $VERSION = '0.01';

use Politics::AU::Geo::Electorates;
use Politics::AU::Geo::Polygons;

# Set up the ORLite::Mirror integration for the dataset
sub import {
	my $class  = shift;
	my $params = Params::Util::_HASH(shift) || {};

	# Pass through any params from above
	$params->{url}    ||= 'http://myrepresentatives.org/db.gz';
	$params->{maxage} ||= 30 * 24 * 60 * 60; # One week

	# Prevent double-initialisation
	$class->can('orlite') or
	ORLite::Mirror->import( $params, '-DEBUG' );

	return 1;
}





######################################################################
# Custom Methods

=pod

=head2 geo2electorates

  my @electorates = Politics::AU::Geo->geo2electorates( -33.895922, 151.110022 );

The C<geo2electorates> method takes a latitude and longitude and resolves the
set of electorates that the point is within.

Returns a list of L<Politics::AU::Geo::Electorates> objects, or throws an
exception on error.

=cut

sub geo2electorates {
	my $class     = shift;
	my $latitude  = shift;
	my $longitude = shift;

	# Do a first-pass query to find the electorates that we match
	# the general bounding boxes for.
	my @electorates = Politics::AU::Geo::Electorates->select(
		'WHERE bblat2 <= ? and bblat1 >= ? and bblong1 <= ? and bblong2 >= ?',
		$latitude,
		$latitude,
		$longitude,
		$longitude,
	);

	# Count the number of electorates per house
	my %filter = ();
	foreach ( @electorates ) {
		$filter{$_->house_id}++;
	}

	# Polygon filter any electorates where we have more than one for the house
	@electorates = grep {
		$filter{$_->house_id} == 1
		or
		$_->point_in_polygon( $latitude, $longitude )
	} @electorates;

	return @electorates;
}

1;

__END__

=pod

=head2 dsn

  my $string = Foo::Bar->dsn;

The C<dsn> accessor returns the dbi connection string used to connect
to the SQLite database as a string.

=head2 dbh

  my $handle = Foo::Bar->dbh;

To reliably prevent potential SQLite deadlocks resulting from multiple
connections in a single process, each ORLite package will only ever
maintain a single connection to the database.

During a transaction, this will be the same (cached) database handle.

Although in most situations you should not need a direct DBI connection
handle, the C<dbh> method provides a method for getting a direct
connection in a way that is compatible with ORLite's connection
management.

Please note that these connections should be short-lived, you should
never hold onto a connection beyond the immediate scope.

The transaction system in ORLite is specifically designed so that code
using the database should never have to know whether or not it is in a
transation.

Because of this, you should B<never> call the -E<gt>disconnect method
on the database handles yourself, as the handle may be that of a
currently running transaction.

Further, you should do your own transaction management on a handle
provided by the <dbh> method.

In cases where there are extreme needs, and you B<absolutely> have to
violate these connection handling rules, you should create your own
completely manual DBI-E<gt>connect call to the database, using the connect
string provided by the C<dsn> method.

The C<dbh> method returns a L<DBI::db> object, or throws an exception on
error.

=head2 selectall_arrayref

The C<selectall_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectall_hashref

The C<selectall_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_array

The C<selectrow_array> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 selectrow_hashref

The C<selectrow_hashref> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction.

It takes the same parameters and has the same return values and error
behaviour.

=head2 prepare

The C<prepare> method is a direct wrapper around the equivalent
L<DBI> method, but applied to the appropriate locally-provided connection
or transaction

It takes the same parameters and has the same return values and error
behaviour.

In general though, you should try to avoid the use of your own prepared
statements if possible, although this is only a recommendation and by
no means prohibited.

=head2 pragma

  # Get the user_version for the schema
  my $version = Foo::Bar->pragma('user_version');

The C<pragma> method provides a convenient method for fetching a pragma
for a datase. See the SQLite documentation for more details.

=head1 SUPPORT

Politics::AU::Geo is based on L<ORLite> 1.22.

Documentation created by L<ORLite::Pod> 0.06.

For general support please see the support section of the main
project documentation.

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
