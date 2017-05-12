package Perl::Metrics;

=pod

=head1 NAME

Perl::Metrics - The Perl Code Metrics System

=head1 SYNOPSIS

  # Load or create the metrics database
  use Perl::Metrics '/var/cache/perl/metrics.sqlite';
  
  # Index and process a directory of code
  Perl::Metrics->process_directory( '/home/adam/code/mycpan' );

=head1 DESCRIPTION

The Perl Code Metrics System is a module which provides a Perl document
metrics processing engine, and a database in which to store the
resulting metrics data.

The intent is to be able to take a large collection of Perl documents,
and relatively easily parse the files and run a series of processes on
the documents.

The resulting data can then be stored, and later used to generate useful
information about the documents.

=head2 General Structure

Perl::Metrics consists of two primary components. Firstly, a
L<Class::DBI>/L<SQLite> database that stores the metrics informationg.

See L<Perl::Metrics::File> and L<Perl::Metrics::Metric> for the two
data classes stored in the database.

Secondly, a plugin structure for creating metrics packages that can
interoperate with the system, allowing it to take care of document
processing and data storage while the plugin can concentrate on the
actual generation of the metrics.

See L<Perl::Metrics::Plugin> for more information.

=head2 Getting Started

C<Perl::Metrics> comes with on default plugin,
L<Perl::Metrics::Plugin::Core>, which provides a sampling of metrics.

To get started load the module, providing the database location as a
param (it will create it if needed). Then call the C<process_directory>
method, providing it with an absolute path to a directory of Perl code
on the local filesystem.

C<Perl::Metrics> will quitely sit there working away, and then when it
finishes you will have a nice database full of metrics data about your
files.

Of course, how you actually USE that data is up to you, but you can
query L<Perl::Metrics::File> and L<Perl::Metrics::Metric> for the data
just like any other L<Class::DBI> database once you have collected it
all.

=head1 METHODS

=cut

use 5.00503;
use strict;
use Carp                   ();
use DBI                    ();
use File::Spec             ();
use PPI::Util              ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use Module::Pluggable;

use vars qw{$VERSION $TRACE};
BEGIN {
	$VERSION = '0.09';
	
	# Enable the trace flag to show trace messages during the
	# main processing loops in this class
	$TRACE = 0 unless defined $TRACE;
}

# The database structure
my $SQLITE_CREATE = <<'END_SQL';
CREATE TABLE files (
	path    TEXT    NOT NULL,
	checked INTEGER NOT NULL,
	hex_id  TEXT    NOT NULL,
	PRIMARY KEY (path)
);
CREATE TABLE metrics (
	hex_id  TEXT    NOT NULL,
	package TEXT    NOT NULL,
	version NUMERIC,
	name    TEXT    NOT NULL,
	value   TEXT,
	PRIMARY KEY (hex_id, package, name)
)
END_SQL

# Load the components
use Perl::Metrics::CDBI   ();
use Perl::Metrics::File   ();
use Perl::Metrics::Metric ();
use Perl::Metrics::Plugin ();





#####################################################################
# Setup Methods

sub import {
	my $class = shift;
	my $file  = shift or Carp::croak(
		"Did not provide a database location when loading Perl::Metrics"
		);

	# Do we already have a DSN defined?
	if ( $Perl::Metrics::CDBI::DSN ) {
		Carp::croak("Perl::Metrics has already been initialised with database $Perl::Metrics::CDBI::DSN");
	}

	# Set the file
	$Perl::Metrics::CDBI::DSN = "dbi:SQLite:dbname=$file";

	# Does the file already exist?
	# If not we'll need to create the tables now
	my $create = ! -f $file;

	# Do a test connection to the database
	my $dbh = Perl::Metrics::CDBI->db_Main;

	# Create the database if needed
	if ( $create ) {
		foreach my $sql_create_table ( split /;/, $SQLITE_CREATE ) {
			# Execute the table creation SQL
			$dbh->do( $sql_create_table ) or Carp::croak(
				"Error creating database table",
				$dbh->errstr,
				);
		}
	}

	1;
}





#####################################################################
# Perl::Metrics Methods

=pod

=head2 index_file $absolute_path

The C<index_file> method takes a single absolute file path and creates
an entry in the C<files> index, referencing the file name to its
C<hex_id> for later use.

Note that this does not execute any metrics on the file, merely allows
the system to "remember" the file for later.

=cut

sub index_file {
	my $class = shift;

	# Get and check the filename
	my $path = File::Spec->canonpath(shift);
	unless ( defined $path and ! ref $path and $path ne '' ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -f $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;
	my @f = stat(_);

	$class->_trace("Indexing $path... ");

	# Get the current record, if it exists
	my $file = Perl::Metrics::File->retrieve( $path );

	# If we already have a record, and it's checked time
	# is higher than the mtime of the file, the existing
	# hex_id is corrent and we can shortcut.
	if ( $file and $file->checked > $f[9] ) {
		$class->_trace("unchanged.\n");
		return $file;
	}

	# At this point we know we'll need to go to the expense of
	# generating the MD5hex value.
	my $md5hex = PPI::Util::md5hex_file( $path )
		or Carp::croak("Cannot index '$path'. Failed to generate hex_id");

	if ( $file ) {
		# Update the record to the new values
		$class->_trace("updating.\n");
		$file->checked(time);
		$file->hex_id($md5hex);
		$file->update;
	} else {
		# Create a new record
		$class->_trace("inserting.\n");
		$file = Perl::Metrics::File->insert( {
			path    => $path,
			checked => time,
			hex_id  => $md5hex,
			} );
	}

	$file;
}

=pod

=head2 index_directory $absolute_path

As for C<index_file>, the C<index_directory> method will recursively scan
down a directory tree, locating all Perl files and adding them to the
file index.

Returns the number of files added.

=cut

sub index_directory {
	my $class = shift;

	# Get and check the directory name
	my $path = shift;
	unless ( defined $path and ! ref $path and $path ne '' ) {
		Carp::croak("Did not pass a directory name to index_directory");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. Directory does not exist") unless -d $path;
	Carp::croak("Cannot index '$path'. No read permissions")      unless -r _;
	Carp::croak("Cannot index '$path'. No enter permissions")     unless -x _;

	# Search for all the applicable files in the directory
	$class->_trace("Search for files in $path...\n");
	my @files = File::Find::Rule->perl_file->in( $path );
	$class->_trace("Found " . scalar(@files) . " file(s).\n");

	# Sort the files so we index in deterministic order
	$class->_trace("Sorting files...\n");
	@files = sort @files;

	# Index the files
	$class->_trace("Indexing files...\n");
	foreach my $file ( @files ) {
		$class->index_file( $file );
	}

	scalar(@files);
}

=pod

=head2 process_index

The C<process_index> method is the primary method for generating metrics
data. It triggering a metrics generation pass for all metrics on all files
currently in the index.

=cut

sub process_index {
	my $class = shift;

	# Create the plugin objects
	foreach my $plugin ( $class->plugins ) {
		$class->_trace("STARTING PLUGIN $plugin...\n");
		eval "require $plugin";
		die $@ if $@;
		$plugin->new->process_index;
	}

	1;
}

=pod

=head2 process_directory $absolute_path

The C<process_directory> method is a convenience method. It runs an
C<index_directory> call for the directory, and then triggers a
C<process_index> call after the index has been populated.

=cut

sub process_directory {
	my $class = shift;
	$class->index_directory( $_[0] );
	$class->process_index;
}





#####################################################################
# Support Methods

sub _trace {
	my $class = shift;
	return 1 unless $TRACE;
	print @_;
}

1;

=pod

=head1 TO DO

- Provide a more useful set of default plugins

- Provide the option to process for a subset of plugins

- Implemented automatic integration with L<PPI::Cache>

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
