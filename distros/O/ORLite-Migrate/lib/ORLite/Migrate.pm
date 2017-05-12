package ORLite::Migrate;

# See POD at end of file for documentation

use 5.006;
use strict;
use Carp              ();
use File::Spec 3.2701 ();
use File::Path   2.04 ();
use File::Basename    ();
use Params::Util 0.37 ();
use DBI          1.58 ();
use DBD::SQLite  1.21 ();
use ORLite       1.28 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.10';
	@ISA     = 'ORLite';
}

sub import {
	my $class = ref $_[0] || $_[0];

	# Check for debug mode
	my $DEBUG = 0;
	if ( defined Params::Util::_STRING($_[-1]) and $_[-1] eq '-DEBUG' ) {
		$DEBUG = 1;
		pop @_;
	}

	# Check params and apply defaults
	my %params;
	if ( defined Params::Util::_STRING($_[1]) ) {
		# Migrate needs at least two params
		Carp::croak("ORLite::Migrate must be invoked in HASH form");
	} elsif ( Params::Util::_HASH($_[1]) ) {
		%params = %{ $_[1] };
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}
	if ( $params{timeline} and not defined $params{create} ) {
		$params{create} = 1;
	}
	$params{create} = $params{create} ? 1 : 0;
	unless (
		defined Params::Util::_STRING($params{file})
		and (
			$params{create}
			or
			-f $params{file}
		)
	) {
		Carp::croak("Missing or invalid file param");
	}
	unless ( defined $params{readonly} ) {
		$params{readonly} = $params{create} ? 0 : ! -w $params{file};
	}
	unless ( defined $params{tables} ) {
		$params{tables} = 1;
	}
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}
	unless ( Params::Util::_CLASS($params{package}) ) {
		Carp::croak("Missing or invalid package class");
	}

	unless (
		Params::Util::_DRIVER($params{timeline}, 'ORLite::Migrate::Timeline')
		or
		($params{timeline} and -d $params{timeline} and -r $params{timeline})
	) {
		Carp::croak("Missing or invalid timeline");
	}

	# We don't support readonly databases
	if ( $params{readonly} ) {
		Carp::croak("ORLite::Migrate does not support readonly databases");
	}

	# Get the schema version
	my $file     = File::Spec->rel2abs($params{file});
	my $created  = ! -f $params{file};
	if ( $created ) {
		# Create the parent directory
		my $dir = File::Basename::dirname($file);
		unless ( -d $dir ) {
			my @dirs = File::Path::mkpath( $dir, { verbose => 0 } );
			$class->prune(@dirs) if $params{prune};
		}
		$class->prune($file) if $params{prune};
	}
	my $dsn      = "dbi:SQLite:$file";
	my $dbh      = DBI->connect($dsn);
	my $version  = $dbh->selectrow_arrayref('pragma user_version')->[0];
	$dbh->disconnect;

	# We're done with the prune setting now
	$params{prune} = 0;

	# Handle the migration class
	if ( Params::Util::_DRIVER($params{timeline}, 'ORLite::Migrate::Timeline') ) {
		my $timeline = $params{timeline}->new(
			dbh => DBI->connect($dsn),
		);
		$timeline->upgrade( $params{user_version} );

	} else {
		my $timeline = File::Spec->rel2abs($params{timeline});
		my @plan     = plan( $params{timeline}, $version );

		# Execute the migration plan
		if ( @plan ) {
			# Does the migration plan reach the required destination
			my $destination = $version + scalar(@plan);
			if (
				exists $params{user_version}
				and
				$destination != $params{user_version}
			) {
				die "Schema migration destination user_version mismatch (got $destination, wanted $params{user_version})";
			}

			# Load the modules needed for the migration
			require Probe::Perl;
			require File::pushd;
			require IPC::Run3;

			# Locate our Perl interpreter
			my $perl = Probe::Perl->find_perl_interpreter;
			unless ( $perl ) {
				Carp::croak("Unable to locate your perl executable");
			}

			# Execute each script
			my $pushd = File::pushd::pushd($timeline);
			foreach my $patch ( @plan ) {
				my $stdin = "$file\n";
				if ( $DEBUG ) {
					print STDERR "Applying schema patch $patch...\n";
				}
				my $ok = IPC::Run3::run3( [ $perl, $patch ], \$stdin, \undef, $DEBUG ? undef : \undef );
				if ( ! $ok or $? != 0 ) {
					Carp::croak("Migration patch $patch failed, database in unknown state");
				}
			}

			# Migration complete, set user_version to new state
			$dbh = DBI->connect($dsn);
			$dbh->do("pragma user_version = $destination");
			$dbh->disconnect;
		}
	}

	# Hand off to the regular constructor
	$class->SUPER::import(
		\%params,
		$DEBUG ? '-DEBUG' : ()
	);
}





#####################################################################
# Simple Methods

sub patches {
	my $dir = shift;

	# Find all files in a directory
	local *DIR;
	opendir( DIR, $dir )       or die "opendir: $!";
	my @files = readdir( DIR ) or die "readdir: $!";
	closedir( DIR )            or die "closedir: $!";

	# Filter to get the patch set
	my @patches = ();
	foreach ( @files ) {
		next unless /^migrate-(\d+)\.pl$/;
		$patches["$1"] = $_;
	}

	return @patches;
}

sub plan {
	my $directory = shift;
	my $version   = shift;

	# Find the list of patches
	my @patches = patches( $directory );

	# Assemble the plan by integer stepping forwards
	# until we run out of timeline hits.
	my @plan = ();
	while ( $patches[++$version] ) {
		push @plan, $patches[$version];
	}

	return @plan;
}

1;

__END__

=pod

=head1 NAME

ORLite::Migrate - Extremely light weight SQLite-specific schema migration

=head1 SYNOPSIS

  # Build your ORM class using a patch timeline
  # stored in the shared files directory.
  use ORLite::Migrate {
      create       => 1,
      file         => 'sqlite.db',
      timeline     => File::Spec->catdir(
          File::ShareDir::module_dir('My::Module'), 'patches',
      ),
      user_version => 8,
  };

  # migrate-1.pl - A trivial schema patch
  #!/usr/bin/perl
  
  use strict;
  use DBI ();
  
  # Locate the SQLite database
  my $file = <STDIN>;
  chomp($file);
  unless ( -f $file and -w $file ) {
      die "SQLite file $file does not exist";
  }
  
  # Connect to the SQLite database
  my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$file");
  unless ( $dbh ) {
    die "Failed to connect to $file";
  }
  
  $dbh->do( <<'END_SQL' );
  create table foo (
      id integer not null primary key,
      name varchar(32) not null
  )
  END_SQL

=head1 DESCRIPTION

L<SQLite> is a light weight single file SQL database that provides an
excellent platform for embedded storage of structured data.

L<ORLite> is a light weight single class Object-Relational Mapper (ORM)
system specifically designed for (and limited to only) work with SQLite.

L<ORLite::Migrate> is a light weight single class Database Schema
Migration enhancement for L<ORLite>.

It provides a simple implementation of schema versioning within the
SQLite database using the built-in C<user_version> pragma (which is
set to zero by default).

When setting up the ORM class, an additional C<timeline> parameter is
provided, which should be either a monolithic timeline class, or a directory
containing standalone migration scripts.

A B<"timeline"> is a set of revisioned schema changed, to be applied in order
and representing the evolution of the database schema over time. The end of
the timeline, representing by the highest revision number, represents the
"current" anticipated schema for the application.

Because the patch sequence can be calculated from any arbitrary starting
version, by keeping the historical set of changes in your application as
schema patches it is possible for the user of any older application version
to install the most current version of an application and have their database
upgraded smoothly and safely.

The recommended location to store the migration timeline is a shared files
directory, locatable using one of the functions from L<File::ShareDir>.

The timeline for your application can be specified in two different forms,
with different advantages and disadvantages.

=head2 Timeline Directories

A Timeline Directory is a directory on the filesystem containing a set of
Perl scripts named in a consistent pattern.

These patch scripts are named in the form F<migrate-$version.pl>, where
C<$version> is the schema version to migrate to. A typical timeline
directory will look something like the following.

  migrate-01.pl
  migrate-02.pl
  migrate-03.pl
  migrate-04.pl
  migrate-05.pl
  migrate-06.pl
  migrate-07.pl
  migrate-08.pl
  migrate-09.pl
  migrate-10.pl

L<ORLite::Migrate> formulates a migration plan that starts at the
current database C<user_version> pragma value, executing the migration
script that has the version C<user_version + 1>, then executing
C<user_version + 2> and so on.

It will continue stepping forwards until it runs out of patches to
execute.

The main advantage of a timeline directory is that each patch is run
in its own process and interpreter. Hundreds of patches can be produced by
many different authors, with certainty that the changes described in each
will be executed as intended.

The main disadvantage of using a timeline directory is that your application
B<must> be able to identify the Perl interpreter it is run in so that it can
execute a sub-process. This may be difficult or impossible for cases such as
PAR-packaged applications and Perl interpreters embedded inside .exe wrappers
or larger non-Perl applications.

In general, it is recommended that you use the timeline directory approach
unless you encounter a situation in which sub-process execution (or locating
the patch files) is difficult.

=head2 Timeline Classes

A timeline class places all of the schema patches into a single Perl module,
with each patch represented as a method name.

The following is an example of a trivial timeline class.

  package t::lib::MyTimeline;
  
  use strict;
  use base 'ORLite::Migrate::Timeline';
  
  my $UPGRADE1 = <<'END_SQL';
  
  create table foo (
      id integer not null primary key,
      name varchar(32) not null
  );
  
  insert into foo values ( 1, 'foo' )
  
  END_SQL
  
  sub upgrade1 {
      my $self = shift;
      foreach ( split /;\s+/, $UPGRADE1 ) {
          $self->do($_);
      }
      return 1;
  }
  
  sub upgrade2 {
      $_[0]->do("insert into foo values ( 2, 'bar' )");
  }
  
  sub upgrade3 {
      $_[0]->do("insert into foo values ( 3, 'baz' )");
  }
  
  1;

As with the patch files, the current state of the C<user_version> pragma will
be examined, and each C<upgradeN> method will be called to advance the
schema forwards.

The main advantage of a timeline class is that you will not need to execute
sub-processes, and so a timeline class will continue to function even in
unusual or exotic process contents such as PAR packaging or .exe wrappers.

The main disadvantage of a timeline class is that the entire timeline code
must be loaded into memory no matter how many patch steps are needed (and stay
in memory after the migration has completed), and all patches share a common
interpreter and thus can potentially pollute or corrupt each other.

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
