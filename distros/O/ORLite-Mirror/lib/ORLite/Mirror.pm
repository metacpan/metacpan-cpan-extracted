package ORLite::Mirror;

use 5.006;
use strict;
use Carp                          ();
use File::Copy                    ();
use File::Spec               0.80 ();
use File::Path               2.04 ();
use File::Remove             1.42 ();
use File::HomeDir            0.69 ();
use File::ShareDir           1.00 ();
use Params::Util             0.33 ();
use LWP::UserAgent          5.806 ();
use LWP::Online              1.07 ();
use ORLite                   1.37 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.24';
	@ISA     = 'ORLite';
}





#####################################################################
# Code Generation

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
		# Support the short form "use ORLite 'http://.../db.sqlite'"
		%params = (
			url      => $_[1],
			readonly => undef, # Automatic
			package  => undef, # Automatic
		);
	} elsif ( Params::Util::_HASH($_[1]) ) {
		%params = %{ $_[1] };
	} else {
		Carp::croak("Missing, empty or invalid params HASH");
	}

	# Check for incompatible create option
	if ( $params{create} and ref($params{create}) ) {
		Carp::croak("Cannot supply complex 'create' param to ORLite::Mirror");
	}

	# Autodiscover the package if needed
	unless ( defined $params{package} ) {
		$params{package} = scalar caller;
	}
	my $pversion = $params{package}->VERSION || 0;
	my $agent    = "$params{package}/$pversion";

	# Normalise boolean settings
	my $show_progress = $params{show_progress} ? 1 : 0;
	my $env_proxy     = $params{env_proxy}     ? 1 : 0;

	# Use array-based objects by default, they are smaller and faster
	unless ( defined $params{array} ) {
		$params{array} = 1;
	}

	# Find the maximum age for the local database copy
	my $maxage = delete $params{maxage};
	unless ( defined $maxage ) {
		$maxage = 86400;
	}
	unless ( Params::Util::_NONNEGINT($maxage) ) {
		Carp::croak("Invalid maxage param '$maxage'");
	}

	# Find the stub database
	my $stub = delete $params{stub};
	if ( $stub ) {
		$stub = File::ShareDir::module_file(
			$params{package} => 'stub.db'
		) if $stub eq '1';
		unless ( -f $stub ) {
			Carp::croak("Stub database '$stub' does not exist");
		}
	}

	# Check when we should update
	my $update = delete $params{update};
	unless ( defined $update ) {
		$update = $stub ? 'connect' : 'compile';
	}
	unless ( $update =~ /^(?:compile|connect)$/ ) {
		Carp::croak("Invalid update param '$update'");
	}

	# Determine the mirror database directory
	my $dir = File::Spec->catdir(
		File::HomeDir->my_data,
		($^O eq 'MSWin32' ? 'Perl' : '.perl'),
		'ORLite-Mirror',
	);

	# Create it if needed
	unless ( -e $dir ) {
		my @dirs = File::Path::mkpath( $dir, { verbose => 0 } );
		$class->prune(@dirs) if $params{prune};
	}

	# Determine the mirror database file
	my $file = $params{package} . '.sqlite';
	$file =~ s/::/-/g;
	my $db = File::Spec->catfile( $dir, $file );

	# Download compressed files with their extention first
	my $url  = delete $params{url};
	my $path = ($url =~ /(\.gz|\.bz2)$/) ? "$db$1" : $db;
	unless ( -f $path ) {
		$class->prune($path) if $params{prune};
	}

	# Are we online (fake to true if the URL is local)
	my $online = !! ( $url =~ /^file:/ or LWP::Online::online() );
	unless ( $online or -f $path or $stub ) {
		# Don't have the file and can't get it
		Carp::croak("Cannot fetch database without an internet connection");
	}

	# If the file doesn't exist, sync at compile time.
	my $STUBBED = 0;
	unless ( -f $db ) {
		if ( $update eq 'connect' and $stub ) {
			# Fallback option, use the stub
			File::Copy::copy( $stub => $db ) or
			Carp::croak("Failed to copy in stub database");
			$STUBBED = 1;
		} else {
			$update = 'compile';
		}
		$class->prune($db) if $params{prune};
	}

	# We've finished with all the pruning we'll need to do
	$params{prune} = 0;

	# Don't update if the file is newer than the maxage
	my $mtime = (stat($path))[9] || 0;
	my $old   = (time - $mtime) > $maxage;
	if ( not $STUBBED and -f $path ? ($old and $online) : 1 ) {
		# Create the default useragent
		my $useragent = delete $params{useragent};
		unless ( $useragent ) {
			$useragent = LWP::UserAgent->new(
				agent         => $agent,
				timeout       => 30,
				show_progress => $show_progress,
				env_proxy     => $env_proxy,
			);
		}

		# Fetch the archive
		my $response = $useragent->mirror( $url => $path );
		unless ( $response->is_success or $response->code == 304 ) {
			Carp::croak("Error: Failed to fetch $url");
		}

		# Decompress if we pulled an archive
		my $refreshed = 0;
		if ( $path =~ /\.gz$/ ) {
			unless ( $response->code == 304 and -f $path ) {
				require IO::Uncompress::Gunzip;
				IO::Uncompress::Gunzip::gunzip(
					$path      => $db,
					BinModeOut => 1,
				) or Carp::croak("gunzip($path) failed");
				$refreshed = 1;
			}
		} elsif ( $path =~ /\.bz2$/ ) {
			unless ( $response->code == 304 and -f $path ) {
				require IO::Uncompress::Bunzip2;
				IO::Uncompress::Bunzip2::bunzip2(
					$path      => $db,
					BinModeOut => 1,
				) or Carp::croak("bunzip2($path) failed");
				$refreshed = 1;
			}
		}

		# If we updated the file, add any extra indexes that we need
		if ( $refreshed and $params{index} ) {
			my $dbh = DBI->connect( "DBI:SQLite:$db", undef, undef, {
				RaiseError => 1,
				PrintError => 1,
			} );
			foreach ( @{$params{index}} ) {
				my ($table, $column) = split /\./, $_;
				$dbh->do("CREATE INDEX idx__${table}__${column} ON $table ( $column )");
			}
			$dbh->disconnect;
		}
	}

	# Mirrored databases are always readonly.
	$params{file}     = $db;
	$params{readonly} = 1;

	# If and only if they update at connect-time, replace the
	# original dbh method with one that syncs the database.
	if ( $update eq 'connect' ) {
		# Generate the archive decompression fragment
		my $decompress = '';
		if ( $path =~ /\.gz$/ ) {
			$decompress = <<"END_PERL";
	unless ( \$response->code == 304 and -f \$PATH ) {
		my \$sqlite = \$class->sqlite;
		require File::Remove;
		unless ( File::Remove::remove(\$sqlite) ) {
			Carp::croak("Error: Failed to flush '\$sqlite'");
		}

		require IO::Uncompress::Gunzip;
		IO::Uncompress::Gunzip::gunzip(
			\$PATH      => \$sqlite,
			BinModeOut => 1,
		) or Carp::croak("Error: gunzip(\$PATH) failed");
	}

END_PERL
		} elsif ( $path =~ /\.bz2$/ ) {
			$decompress = <<"END_PERL";
	unless ( \$response->code == 304 and -f \$PATH ) {
		my \$sqlite = \$class->sqlite;
		require File::Remove;
		unless ( File::Remove::remove(\$sqlite) ) {
			Carp::croak("Error: Failed to flush '\$sqlite'");
		}

		require IO::Uncompress::Bunzip2;
		IO::Uncompress::Bunzip2::bunzip2(
			\$PATH      => \$sqlite,
			BinModeOut => 1,
		) or Carp::croak("Error: bunzip2(\$PATH) failed");
	}

END_PERL
		}

		# Combine to get the final merged append code
		$params{append} = <<"END_PERL";
use Carp ();

use vars qw{ \$REFRESHED };
BEGIN {
	\$REFRESHED = 0;
	# delete \$$params{package}::{DBH};
}

my \$URL  = '$url';
my \$PATH = '$path';

sub refresh {
	my \$class = shift;
	my \%param = \@_;

	require LWP::UserAgent;
	my \$useragent = LWP::UserAgent->new(
		agent         => '$agent',
		timeout       => 30,
		show_progress => !! \$param{show_progress},
	);

	# Set the refresh flag now, so the call to ->pragma won't
	# head off into an infinite recursion.
	\$REFRESHED = 1;

	# Save the old schema version
	my \$old_version = \$class->pragma('user_version');

	# Flush the existing database
	require File::Remove;
	if ( -f \$PATH and not File::Remove::remove(\$PATH) ) {
		Carp::croak("Error: Failed to flush '\$PATH'");
	}

	# Fetch the archive
	my \$response = \$useragent->mirror( \$URL => \$PATH );
	unless ( \$response->is_success or \$response->code == 304 ) {
		Carp::croak("Error: Failed to fetch '\$URL'");
	}

$decompress
	# The new schema version must match the previous or stub version
	my \$version = \$class->pragma('user_version');
	unless ( \$version == \$old_version ) {
		Carp::croak("Schema user_version mismatch (got \$version, wanted \$old_version)");
	}

	return 1;
}

no warnings 'redefine';
sub connect {
	my \$class = shift;
	unless ( \$REFRESHED ) {
		\$class->refresh(
			show_progress => $show_progress,
			env_proxy     => $env_proxy,
		);
	}
	DBI->connect( \$class->dsn, undef, undef, {
		RaiseError => 1,
		PrintError => 0,
	} );
}
END_PERL
	}

	# Hand off to the main ORLite class
	$class->SUPER::import(
		\%params,
		$DEBUG ? '-DEBUG' : ()
	);
}

1;

=pod

=head1 NAME

ORLite::Mirror - Extend ORLite to support remote SQLite databases

=head1 SYNOPSIS

  # Regular ORLite on a readonly SQLite database
  use ORLite 'path/mydb.sqlite';
  
  # The equivalent for a remote (optionally compressed) SQLite database
  use ORLite::Mirror 'http://myserver/path/mydb.sqlite.gz';
  
  # All available additional options specified
  use ORLite::Mirror {
      url           => 'http://myserver/path/mydb.sqlite.gz',
      maxage        => 3600,
      show_progress => 1,
      env_proxy     => 1,
      prune         => 1,
      index         => [
          'table1.column1',
          'table1.column2',
      ],
  };

=head1 DESCRIPTION

L<ORLite> provides a readonly ORM API when it loads a readonly SQLite
database from your local system.

By combining this capability with L<LWP>, L<ORLite::Mirror> goes one step
better and allows you to load a SQLite database from any arbitrary URI in
readonly form as well.

As demonstrated in the synopsis above, you using L<ORLite::Mirror> in the
same way, but provide a URL instead of a file name.

If the URL explicitly ends with a '.gz' or '.bz2' then L<ORLite::Mirror>
will decompress the file before loading it.

=head1 OPTIONS

B<ORLite::Mirror> adds an extensive set of options to those provided by the
underlying L<ORLite> library.

=head2 url

The compulsory C<url> parameter should be a string containing the remote
location of the SQLite database we will be mirroring.

B<ORLite::Mirror> supports downloading the database compressed, and then
transparently decompressing the file locally. Compression support is
controlled by the extension on the remote database. 

The extensions C<.gz> (for gunzip) and C<.bz2> (for bunzip2) are currently
supported.

=head2 maxage

The optional C<maxage> parameter controls how often B<ORLite::Mirror>
should check the remote server to see if the data has been updated.

This allows programs using the database to start quickly the majority of
the time, but continue to receive automatic updates periodically.

The value is the number of integer seconds we should avoid checking the
remote server for. The default is 86400 seconds (one 24 hour day).

=head2 show_progress

The optional C<show_progress> parameter will be passed through to the
underlying L<LWP::UserAgent> that will fetch the remote database file.

When set to true, it causes a progress bar to be displayed on the terminal
as the database file is downloaded.

=head2 env_proxy

The optional C<env_proxy> parameter will be passed through to the
underlying L<LWP::UserAgent> that will fetch the remote database file.

When set to true, it causes L<LWP::UserAgent> to read the location of a
proxy server from the environment.

=head2 prune

The optional C<prune> parameter should be used when the surrounding
program wants to avoid leaving files on the host system.

It causes any files or directories created during the operation of
B<ORLite::Mirror> to be deleted on program exit at C<END>-time.

=head2 index

One challenge when distributing SQLite database is the quantity of data
store on disk to support the indexes on your database.

For a moderately indexed database where all primary and foreign key columns
have indexes, the amount of data in the indexes can be nearly as large as
the data stored for the tables themselves.

Because each user of the database module will be interested in different
things, the indexes that the original creator chooses to place on the
database may not even be used at all and other valuable indexes may not
exist at all.

To allow sufficiently flexibility, we recommend that SQLite database be
distributed without any indexes. This greatly reduces the file size and
download time for the database file.

The optional C<index> parameter should then be used by each different
consumer of that module to index just the columns that are of specific
interest and will be used in the queries that will be run on the database.

The value should be set to an C<ARRAY> reference containing a list of
column names in C<tablename.columnname> form.

  index => [
      'table1.column1',
      'table1.column2',
  ],

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Mirror>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
