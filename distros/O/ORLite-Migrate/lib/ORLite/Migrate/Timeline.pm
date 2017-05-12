package ORLite::Migrate::Timeline;

=pod

=head1 NAME

ORLite::Migrate::Timeline - ORLite::Migrate timelines contained in a single class

=head1 SYNOPSIS

  package My::Timeline;
  
  use strict;
  use base 'ORLite::Migrate::Timeline';
  
  sub upgrade1 { $_[0]->do(<<'END_SQL') }
  CREATE TABLE foo (
      bar INTEGER NOT NULL PRIMARY KEY,
  )
  END_SQL
  
  sub upgrade2 {
      my $self = shift;
      $self->do('TRUNCATE TABLE foo');
      foreach ( 1 .. 10 ) {
          $self->do( 'INSERT INTO foo VALUES ( ? )', {}, $_ );
      }
  }
  
  1;

=head1 DESCRIPTION

The default L<ORLite::Migrate> timeline implementation makes use of separate
Perl "patch" scripts to move the database schema timeline forwards.

This solution is preferred because the separate scripts provide process
isolation between your migration and run-time code. That is, the code that
migrates the schema a single step forwards is guarenteed to never use the same
variables or load the same modules or interact strangely with any other patch
scripts, or with the main program.

However, to execute a sub-script your program needs to reliably know where the
Perl executable that launched it is and in some situations this is difficult or
infeasible.

B<ORLite::Migrate::Timeline> provides an alternative mechanism for specifying the
migration timeline which adds the ability to run migration timelines in strange
Perl environments at the cost of losing process isolation for your patch code.

When using this method, extra caution should be taken to avoid all use of global
variables, and to strictly avoid loading large amounts of data into memory or
using magic Perl modules such as L<Aspect> or L<UNIVERSAL::isa> which might
have a global impact on your program.

To use this method, create a new class which inherits from
L<ORLite::Migrate::Timeline> and create a C<upgrade1> method. When encountering
a new unversioned SQLite database, the migration planner will execute this
C<upgrade1> method and set the schema version to 1 once completed.

To make further changes to the schema, you add additional C<upgrade2>,
C<upgrade3> and so on.

=head1 METHODS

A series of convenience methods are provided for you by the base class to
assist in making your schema patch code simpler and easier.

=cut

use 5.006;
use strict;
use warnings;
use DBI          ();
use DBD::SQLite  ();
use Params::Util ();

our $VERSION = '1.10';





######################################################################
# Constructor

=pod

=head2 new

  my $timeline = My::Class->new(
      dbh => $DBI_db_object,
  );

The C<new> method is called internally by L<ORLite::Migrate> on the timeline
class you specify to construct the timeline object.

The constructor takes a single parameter which should be a L<DBI::db>
database connection to your SQLite database.

Returns an instance of your timeline class, or throws an exception (dies) if
not passed a DBI connection object, or the database handle is not C<AutoCommit>.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the database handle
	unless ( Params::Util::_INSTANCE( $self->dbh, 'DBI::db' ) ) {
		die "Missing or invalid dbh database handle";
	}
	unless ( $self->dbh->{AutoCommit} ) {
		die "Database connection must be AutoCommit";
	}

	return $self;
}





#######################################################################
# Internal Methods

=pod

=head2 upgrade

  $timeline->upgrade(10);

The C<update> method is called on the timeline object by L<ORLite::Migrate>
to trigger the sequential execution of the individual C<upgradeN> methods.

The first method to be called will be the method one greater than the current
value of the C<user_revision> pragma, and the last method to be called will be
the target revision, the first parameter to the method.

As all upgrade methods are contained in a single class, a high level of control
is assumed and so the execution plan will not be calculated in advance. The 
C<upgrade> method will simply start rolling forwards and keep going until it
reaches the target version (or die's trying).

Returns true if all (zero or more) upgrade methods executed without throwing
an exception.

Throws an exception (dies) if any C<upgradeN> method throws an exception, or
if the migration process expects to find a particular numeric C<upgradeN>
method and cannot do so.

=cut

sub upgrade {
	my $self = shift;
	my $want = Params::Util::_POSINT(shift);
	my $have = $self->pragma('user_version');

	# Roll the schema forwards
	while ( $want and $want > $have ) {

		# Find the migration step
		my $method = "upgrade" . ++$have;
		unless ( $self->can($method) ) {
			die "No migration path to user_version $want";
		}

		# Run the migration step
		unless ( eval { $self->$method } ) {
			die "Schema migration failed during $method: $@";
		}

		# Confirm completion
		$self->pragma( 'user_version' => $have );
	}

	return 1;
}





######################################################################
# Support Methods

=pod

=head2 do

The C<do> method is a convenience which provides a direct wrapper over the
L<DBI> method C<do>. It takes the same parameters and returns the same results.

=cut

sub do {
	shift->dbh->do(@_);
}

=pod

=head2 selectall_arrayref

The C<selectall_arrayref> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectall_arrayref>. It takes the same parameters
and returns the same results.

=cut

sub selectall_arrayref {
	shift->dbh->selectall_arrayref(@_);
}

=pod

=head2 selectall_hashref

The C<selectall_hashref> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectall_hashref>. It takes the same parameters
and returns the same results.

=cut

sub selectall_hashref {
	shift->dbh->selectall_hashref(@_);
}

=pod

=head2 selectcol_arrayref

The C<selectcol_arrayref> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectcol_arrayref>. It takes the same parameters
and returns the same results.

=cut

sub selectcol_arrayref {
	shift->dbh->selectcol_arrayref(@_);
}

=pod

=head2 selectrow_array

The C<selectrow_array> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectrow_array>. It takes the same parameters
and returns the same results.

=cut

sub selectrow_array {
	shift->dbh->selectrow_array(@_);
}

=pod

=head2 selectrow_arrayref

The C<selectrow_arrayref> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectrow_arrayref>. It takes the same parameters
and returns the same results.

=cut

sub selectrow_arrayref {
	shift->dbh->selectrow_arrayref(@_);
}

=pod

=head2 selectrow_hashref

The C<selectrow_hashref> method is a convenience which provides a direct
wrapper over the L<DBI> method C<selectrow_hashref>. It takes the same parameters
and returns the same results.

=cut

sub selectrow_hashref {
	shift->dbh->selectrow_hashref(@_);
}

=pod

=head2 pragma

  # Get a pragma value
  my $locking = $self->pragma('locking_mode');
  
  # Set a pragma value
  $self->pragma( synchronous => 0 );

The C<pragma> method provides a convenience over the top of the C<PRAGMA> SQL
statement, and allows the convenience query and change of SQLite pragmas.

For example, if your application wanted to switch SQLite auto vacuuming off
and instead control vacuuming of the database manually, you could do something
like the following.

    # Disable auto-vacuuming because we'll only fill this once.
    # Do a one-time vacuum so we start with a clean empty database.
    $dbh->pragma( auto_vacuum => 0 );
    $dbh->do('VACUUM');

=cut

sub pragma {
	$_[0]->do("pragma $_[1] = $_[2]") if @_ > 2;
	$_[0]->selectrow_arrayref("pragma $_[1]")->[0];
}

=pod

=head2 table_exists

The C<table_exists> method is a convenience to check for the existance of a
table already. Most of the time this isn't going to be needed because the
schema revisioning itself guarentees there is or is not an existing table of
a particular name.

However, occasionally you may encounter a situation where your L<ORLite> module
is sharing a SQLite database with other code, or you are taking over control
of a table from a plugin, or similar.

In these situations it provides a small amount of added safety to be able to
say things like.

  sub upgrade25 {
      my $self = shift;
      if ( $self->table_exists('foo') ) {
          $self->do('DROP TABLE foo');
      }
  }

Returns true (1) if the table exists or false (0) if not.

=cut

sub table_exists {
	$_[0]->selectrow_array(
		"select count(*) from sqlite_master where type = 'table' and name = ?",
		{}, $_[1],
	);
}

=pod

=head2 column_exists

The C<column_exists> method is a convenience to check for the existance of a
column already. It has somewhat less uses than the similar C<table_exists> and
is mainly used when a column may exist on various miscellaneous developer
versions of databases, or where the table structure may be variable across
different groups of users.

Returns true (1) if the table exists or false (0) if not.

=cut

sub column_exists {
	$_[0]->table_exists( $_[1] )
		or $_[0]->selectrow_array( "select count($_[2]) from $_[1]", {} );
}

=pod

=head2 dbh

If you need to do something to the database outside the scope of the methods
described above, the C<dbh> method can be used to get access to the database
connection directly.

This is discouraged as it can allow your migration code to create changes that
might cause unexpected problems. However, in the 1% of cases where the methods
above are not enough, using it with caution will allow you to make changes that
would not otherwise be possible.

=cut

sub dbh {
	$_[0]->{dbh};
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Migrate>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
