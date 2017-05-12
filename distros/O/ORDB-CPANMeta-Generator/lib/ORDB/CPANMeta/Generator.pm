package ORDB::CPANMeta::Generator;

=pod

=head1 NAME

ORDB::CPANMeta::Generator - Generator for the CPAN Meta database

=head1 DESCRIPTION

This is the module that is used to generate the "CPAN Meta" database.

For more information, and to access this database as a consumer, see
the L<ORDB::CPANMeta> module.

The bulk of the work done in this module is actually achieved with:

L<CPAN::Mini> - Fetching the index and dist tarballs

L<CPAN::Mini::Visit> - Expanding and processing the tarballs

L<Xtract> - Preparing the SQLite database for distribution

=head1 METHODS

=cut

use 5.008005;
use strict;
use Carp                     ();
use File::Spec          3.29 ();
use File::Path          2.07 ();
use File::Remove        1.42 ();
use File::HomeDir       0.86 ();
use File::Basename         0 ();
use Module::CoreList    2.46 ();
use Parse::CPAN::Meta 1.4200 ();
use Params::Util        1.00 ();
use Getopt::Long        2.34 ();
use DBI                1.609 ();
use CPAN::Meta      2.112621 ();
use CPAN::Mini         0.576 ();
use CPAN::Mini::Visit   1.14 ();
use Xtract::Publish     0.12 ();

our $VERSION = '0.12';

use Object::Tiny 1.06 qw{
	minicpan
	sqlite
	publish
	visit
	trace
	delta
	prefer_bin
	warnings
	dbh
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor creates a new processor/generator.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Set the default path to the database
	unless ( defined $self->sqlite ) {
		$self->{sqlite} = File::Spec->catdir(
			File::HomeDir->my_data,
			($^O eq 'MSWin32' ? 'Perl' : '.perl'),
			'ORDB-CPANMeta-Generator',
			'metadb.sqlite',
		);
	}

	# Set the default path to the publishing location
	unless ( exists $self->{publish} ) {
		$self->{publish} = 'cpanmeta';
	}

	return $self;
}

=pod

=head2 dir

The C<dir> method returns the directory that the SQLite
database will be written into.

=cut

sub dir {
	File::Basename::dirname($_[0]->sqlite);
}

=pod

=head2 dsn

The C<dsn> method returns the L<DBI> DSN that is used to connect
to the generated database.

=cut

sub dsn {
	"DBI:SQLite:" . $_[0]->sqlite
}





######################################################################
# Main Methods

=pod

=head2 run

The C<run> method executes the process that will produce and fill the
final database.

=cut

sub run {
	my $self = shift;

	# Normalise
	$self->{prefer_bin} = $self->prefer_bin ? 1 : 0;

	# Create the output directory
	File::Path::make_path($self->dir);
	unless ( -d $self->dir ) {
		Carp::croak("Failed to create '" . $self->dir . "'");
	}

	# Clear the database if it already exists
	unless ( $self->delta ) {
		if ( -f $self->sqlite ) {
			File::Remove::remove($self->sqlite);
		}
		if ( -f $self->sqlite ) {
			Carp::croak("Failed to clear " . $self->sqlite);
		}
	}

	# Update the minicpan if needed
	if ( Params::Util::_HASH($self->minicpan) ) {
		CPAN::Mini->update_mirror(
			trace         => $self->trace,
			no_conn_cache => 1,
			%{$self->minicpan},
		);
		$self->{minicpan} = $self->minicpan->{local};
	}

	# Connect to the database
	my $dbh = DBI->connect($self->dsn);
	unless ( $dbh ) {
		Carp::croak("connect: \$DBI::errstr");
	}

	# Create the tables
	$dbh->do(<<'END_SQL');
CREATE TABLE IF NOT EXISTS meta_distribution (
	release TEXT NOT NULL,
	meta INTEGER,
	meta_name TEXT,
	meta_version TEXT,
	meta_abstract TEXT,
	meta_generated TEXT,
	meta_from TEXT,
	meta_license TEXT
);
END_SQL

	$dbh->do(<<'END_SQL');
CREATE TABLE IF NOT EXISTS meta_dependency (
	release TEXT NOT NULL,
	module TEXT NOT NULL,
	version TEXT NULL,
	phase TEXT NOT NULL,
	core REAL NULL
)
END_SQL

	### NOTE: This does nothing right now but will later.
	# Build the index of seen archives.
	# While building the index, remove entries
	# that are no longer in the minicpan.
	my $ignore = undef;
	if ( $self->delta ) {
		$dbh->begin_work;
		my %seen  = ();
		my $dists = $dbh->selectcol_arrayref(
			'SELECT DISTINCT release FROM meta_distribution'
		);
		foreach my $dist ( @$dists ) {
			my $one  = substr($dist, 0, 1);
			my $two  = substr($dist, 0, 2);
			my $path = File::Spec->catfile(
				$self->minicpan,
				'authors', 'id',
				$one, $two,
				split /\//, $dist,
			);
			if ( -f $path ) {
				# Add to the ignore list
				$seen{$dist} = 1;
				next;
			}

			# Clear the release from the database
			$dbh->do(
				'DELETE FROM meta_distribution WHERE release = ?',
				{}, $dist,
			);
		}
		$dbh->do(
			'DELETE FROM meta_dependency WHERE release NOT IN '
			. '( SELECT release FROM meta_distribution )',
		);
		$dbh->commit;

		# NOW we need to start ignoring something
		$ignore = [
			sub {
				$seen{ $_[0]->{dist} }
			}
		];
	}

	# Clear indexes for speed
	$self->drop_indexes( $dbh );

	# Run the visitor to generate the database
	$dbh->begin_work;
	my @meta_dist = ();
	my @meta_deps = ();
	my $visitor   = CPAN::Mini::Visit->new(
		acme       => 1,
		warnings   => $self->warnings,
		minicpan   => $self->minicpan,
		# This does nothing now but will later
		ignore     => $ignore,
		prefer_bin => $self->prefer_bin,
		callback   => sub {
			print STDERR "$_[0]->{dist}\n" if $self->trace;
			my $the  = shift;
			my $meta = undef;
			my @deps = ();
			my $dist = {
				release => $the->{dist},
				meta    => 0,
			};
			my $yaml_file = File::Spec->catfile(
				$the->{tempdir}, 'META.yml',
			);
			my $json_file = File::Spec->catfile(
				$the->{tempdir}, 'META.json',
			);
			if ( -f $json_file ) {
				$meta = eval {
					CPAN::Meta->load_file($json_file)
				};
			} elsif ( -f $yaml_file ) {
				$meta = eval {
					CPAN::Meta->load_file($yaml_file)
				};
			}
			unless ( $@ or not defined $meta ) {
				$dist->{meta}           = 1;
				$dist->{meta_name}      = $meta->name;
				$dist->{meta_version}   = $meta->version;
				$dist->{meta_abstract}  = $meta->abstract;
				$dist->{meta_generated} = $meta->generated_by;
				$dist->{meta_generated} =~ s/,.+//;
				$dist->{meta_license}   = join ', ', $meta->licenses;
				$dist->{meta_from}      = undef;

				# Fetch the dependency blocks
				my $core = $meta->effective_prereqs;
				foreach my $when ( qw{ configure build test runtime } ) {
					my $requires = $core->requirements_for($when, 'requires');
					my $hash     = $requires->as_string_hash;
					push @deps, map { +{
						release => $the->{dist},
						phase   => $when,
						module  => $_,
						version => $hash->{$_},
					} } sort keys %$hash;
				}
			}
			$dbh->do(
				'INSERT INTO meta_distribution VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )', {},
				$dist->{release},
				$dist->{meta},
				$dist->{meta_name},
				$dist->{meta_version},
				$dist->{meta_abstract},
				$dist->{meta_generated},
				$dist->{meta_from},
				$dist->{meta_license},
			);
			$dbh->do(
				'INSERT INTO meta_dependency VALUES ( ?, ?, ?, ?, ? )', {},
				$_->{release},
				$_->{module},
				$_->{version},
				$_->{phase},
				$_->{module} eq 'perl'
					? $_->{version}
					: scalar Module::CoreList->first_release(
						$_->{module}, $_->{version},
					),
			) foreach @deps;
			unless ( $the->{counter} % 100 ) {
				$dbh->commit;
				$dbh->begin_work;
			}
		},
	);
	$visitor->run;
	$dbh->commit;

	# Generate the indexes
	$self->create_indexes( $dbh );

	# Clean and optimise the database
	$dbh->do('PRAGMA user_version = 10');
	$dbh->do('VACUUM');
	$dbh->do('ANALYZE main');

	# Publish the database to the current directory
	if ( defined $self->publish ) {
		print STDERR "Publishing the generated database...\n" if $self->trace;
		Xtract::Publish->new(
			from   => $self->sqlite,
			sqlite => $self->publish,
			trace  => $self->trace,
			raw    => 0,
			gz     => 1,
			bz2    => 1,
			lz     => 1,
		)->run;
	}

	return 1;
}





######################################################################
# Index Management

use constant INDEX => (
	[ 'meta_distribution', 'release' ],
	[ 'meta_dependency',   'release' ],
	[ 'meta_dependency',   'phase'   ],
	[ 'meta_dependency',   'module'  ],
);

sub drop_indexes {
	my $self = shift;
	my $dbh  = shift;
	foreach my $i ( INDEX ) {
		$dbh->do("DROP INDEX IF EXISTS $i->[0]__$i->[1]");
	}
	return 1;
}

sub create_indexes {
	my $self = shift;
	my $dbh  = shift;
	foreach my $i ( INDEX ) {
		$self->create_index( $dbh, @$i );
	}
	return 1;
}

sub create_index {
	$_[1]->do("CREATE INDEX IF NOT EXISTS $_[2]__$_[3] on $_[2] ( $_[3] )");
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORDB-CPANMeta-Generator>

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
