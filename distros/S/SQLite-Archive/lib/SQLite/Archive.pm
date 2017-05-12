package SQLite::Archive;

=pod

=head1 NAME

SQLite::Archive - Version-agnostic storage and manipulation of SQLite databases

=head1 DESCRIPTION

SQLite (and the Perl module for it L<DBD::SQLite>) is an extremely handy
database for storing various types of simple information.

However, as SQLite has developed, the binary structure of the SQLite
database format itself has changed and evolved, and continues to change
and evolve. As new releases come out, new versions of L<DBD::SQLite> are
also released with matching code.

This makes SQLite database files suboptimal (at best) for use in
distributing data sets between disparate systems.

At the same time, a giant raw .sql script says very little about the
data itself (such as which database and version it is intended for),
requires a client front end to throw the SQL script at, and it not
easily editable or manipulatable while dumped.

B<SQLite::Archive> provides a straight forward mechanism for exporting
(and importing) SQLite databases, and moving that data around as a
single file to (or from) other hosts.

It uses a regular tar archive, with the data stored in CSV files, and
the table structure stored in a create.sql file.

Given a SQLite archive file (B<SQLite::Archive> will take anything
supported by L<Archive::Extract>) it will extract the tarball to a
temporary directory, create a SQLite database (in a location of your
choice or also in a temp directory) and then populate the SQLite
database with the data from the archive.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp             'croak';
use File::Spec       ();
use File::Temp       ();
use Archive::Extract ();
use SQL::Script      ();
use Parse::CSV       ();
use DBI              ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor and Accessors

=pod

=head1 new

  SQLite::Archive->new( file => 'data.tar.gz' );
  SQLite::Archive->new( file => 'data.zip'    );
  SQLite::Archive->new( dir  => 'extracted'   );

The C<new> constructor creates a new SQLite archive object.

It takes a data source as either a C<file> param (which should be
an L<Archive::Extract>-compatible archive, or a C<dir> param (which
should contain the equivalent of the content of the archive, but
already expanded as single files).

Returns a new B<SQLite::Archive> object, or throws an exception
on error.

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;

	# Check the archive directory
	unless ( defined $self->dir ) {
		# Check the archive file
		unless ( -f $self->file ) {
			croak("The file '" . $self->file . "' does not exist");
		}

		# Extract the archive
		my $archive = Archive::Extract->new( archive => $self->file );
		my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
		$archive->extract( to => $tempdir ) or die $archive->error;
		$self->{dir}  = $archive->extract_path;
	}
	unless ( -d $self->dir ) {
		croak("The directory '" . $self->dir . "' does not exist");
	}

	# Locate all data files
	opendir( ARCHIVE, $self->dir ) or die "opendir: $!";
	my @files = sort readdir( ARCHIVE );
	closedir( ARCHIVE ) or die "closedir: $!";
	$self->{sql} = [ grep { /^\w+\.sql/ } @files ];
	$self->{csv} = [ grep { /^\w+\.csv/ } @files ];

	return $self;
}

sub uri {
	$_[0]->{uri};
}

sub file {
	$_[0]->{file};
}

sub dir {
	$_[0]->{dir};
}





#####################################################################
# Main Methods

=pod

=head1 create_db

  $dbh = $archive->create_db; # Temp file created
  $dbh = $archive->create_db( 'dir/sqlite.db' );

The C<create_db> method create a new (empty) SQLite database.

It optionally takes a single param of a path at which it should
create the SQLite file.

If created as a temp file, the database file will be destroyed
until END-time (as opposed to being destroyed when the DBI
connection handle goes out of scope).

Returns a L<DBI> connection (as a B<DBI::db> object) or throws
an exception on error.

=cut

sub create_db {
	my $self = shift;
	my $file = undef;
	if ( @_ ) {
		# Explicit file name
		die "CODE INCOMPLETE";
	} else {
		# Get a temp file name
		my $dir  = File::Temp::tempdir( CLEANUP => 1 );
		$file = File::Spec->catfile( $dir, 'sqlite.db' );
	}

	# Create the database
	my $db = DBI->connect( 'dbi:SQLite:' . $file );
	unless ( $db ) {
		croak("Failed to create test DB handle");
	}

	return $db;
}

=pod

=head1 build_db

  $dbh = $archive->build_db; # Temp file created
  $dbh = $archive->build_db( 'dir/sqlite.db' );

The C<build_db> method provides the main functionality for SQLite::Archive.

It creates a new SQLite database (at a temporary file if needed), executes
any SQL scripts, populates tables from any CSV files, and returns a DBI
handle.

Returns a BDI::db object, or throws an exception on error.

=cut

sub build_db {
	my $self = shift;
	my $dbh  = $self->create_db(@_);

	# Execute any SQL files first, in order
	my $dir = $self->dir;
	foreach my $sql ( @{$self->{sql}} ) {
		my $file = File::Spec->catfile( $dir, $sql );

		# Load the script
		my $script = SQL::Script->new;
		$script->read( $file );

		# Execute the script
		$script->run( $dbh );
	}

	# Now parse and insert any CSV data
	foreach my $csv ( @{$self->{csv}} ) {
		my $file = File::Spec->catfile( $dir, $csv );

		# Create the parser for the file
		my $parser = Parse::CSV->new(
			file   => $file,
			fields => 'auto',
			) or die "Failed to create CSV::Parser for $csv";
		my (undef, undef, $table) = File::Spec->splitpath($file);
		$table =~ s/\.csv$// or die "Failed to find table name";

		# Process the inserts
		# Don't bother chunking for now, just auto-commit.
		while ( my $row = $parser->fetch ) {
			my $sql = "INSERT INTO $table ( "
				. join( ', ',  keys %$row )
				. " ) values ( "
				. join( ', ', map { '?' } values %$row )
				. " )";
			$dbh->do( $sql, {}, values %$row ) and next;
			die "Table insert failed in $csv: $DBI::errstr";
		}
	}

	return $dbh;
}

1;

__END__

=pod

=head1 SUPPORT

No support is available for this module

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<SQLite::Temp>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
