package Perl::Metrics2;

=pod

=head1 NAME

Perl::Metrics2 - Perl metrics storage and processing engine

=head1 DESCRIPTION

B<THIS IS AN EXPERIMENTAL MODULE AND MAY CHANGE WITHOUT NOTICE>

B<Perl::Metrics2> is a 2nd-generation implementation of the Perl Code
Metrics System.

The Perl Code Metrics System is a module which provides a Perl document
metrics processing engine, and a database in which to store the
resulting metrics data.

The intent is to be able to take a large collection of Perl documents,
and relatively easily parse the files and run a series of processes on
the documents.

The resulting data can then be stored, and later used to generate useful
information about the documents.

=head2 General Structure

Perl::Metrics2 consists of two primary elements. Firstly, an
L<ORLite> database that stores the metrics informationg.

See L<Perl::Metrics2::FileMetrics> for the data class stored in the
database.

The second element is a plugin structure for creating metrics packages,
so that the metrics capture can be done independant of the underlying
mechanisms used for parsing, storage and analysis.

See L<Perl::Metrics2::Plugin> for more information.

=head2 Getting Started

C<Perl::Metrics2> comes with on default plugin,
L<Perl::Metrics2::Plugin::Core>, which provides a sampling of metrics.

To get started load the module, providing the database location as a
param (it will create it if needed). Then call the C<process_directory>
method, providing it with an absolute path to a directory of Perl code
on the local filesystem.

C<Perl::Metrics> will work on the files in the directory, and when it
finishes you will have a nice database full of metrics data about your
files.

Of course, how you actually USE that data is up to you, but you can
query L<Perl::Metrics2::FileMetric> just like any other L<ORLite>
database once you have collected it all.

=head1 METHODS

=cut

use 5.008005;
use strict;
use Carp                   ();
use DBI                    ();
use Time::HiRes            ();
use Time::Elapsed          ();
use File::Spec             ();
use File::Next             ();
use File::HomeDir          ();
use File::ShareDir         ();
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();
use Params::Util           ();
use Process                ();
use Process::Storable      ();
use Process::Delegatable   ();
use PPI::Util              ();
use PPI::Document          ();
use PPI::Cache             ();
use Module::Pluggable;

our $VERSION = '0.06';

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'Perl-Metrics2',
	'Perl-Metrics2.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('Perl-Metrics2'),
	'timeline',
);

use ORLite          1.21 ();
use ORLite::Migrate 0.03 {
	file         => ORLITE_FILE,
	create       => 1,
	timeline     => ORLITE_TIMELINE,
	user_version => 3,
};

use Perl::Metrics2::CpanFile ();





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_,
		plugins => {},
	}, $class;

	# Load the plugins
	foreach my $plugin ( $class->plugins ) {
		eval "require $plugin";
		die $@ if $@;
		$self->{plugins}->{$plugin} = $plugin->new;
	}

	# Study if needed.
	if ( $self->study ) {
		# If a document is present in all of the plugins
		# use a more efficient single scalar.
		my $all  = scalar keys %{$self->{plugins}};
		my $sql = 'SELECT md5, package FROM file_metric';
		my $sth = $self->prepare($sql) or die("prepare: $DBI::errstr");
		$sth->execute or die("execute: $DBI::errstr");
		my %seen = ();
		while ( my $row = $sth->fetchrow_arrayref ) {
			my $md5 = $row->[0];
			my $pkg = $row->[1];
			unless ( $seen{$md5} ) {
				$seen{$md5} ||= {};
			}
			unless ( ref $seen{$md5} ) {
				# All registered already
				next;
			}
			$seen{$md5}->{$pkg} = 1;
			if ( scalar keys %{$seen{$md5}} == $all ) {
				$seen{$md5} = 1;
			}
		}
		$sth->finish or die("finish: $DBI::errstr");
		$self->{seen} = \%seen;
	}

	# Initialise the PPI cache if available
	if ( $self->cache ) {
		PPI::Cache->import( path => $self->cache );
	}

	return $self;
}

sub study {
	$_[0]->{study};
}

sub cache {
	$_[0]->{cache};
}

sub seen {
	my $self = shift;
	my $md5  = shift;
	my $seen = $self->{seen}->{$md5};

	# Document was seen by none
	return 0 unless $seen;

	# Document was seen by all
	return 1 if not ref $seen;

	# Seen by a specific plugin?
	if ( @_ ) {
		return 1 if $seen->{$_[0]};
	}

	return 0;
}





#####################################################################
# Main Methods

sub process_cache {
	my $self = shift;
	unless ( $self->cache ) {
		Carp::croak("No cache provided, cannot process_cache");
	}
	unless ( $self->study ) {
		Carp::croak("Must have study true to process_cache");
	}

	$| = 1;

	# Remove indexes to speed up inserts
	$self->trace("Removing indexes for faster inserts...");
	foreach my $col ( qw{ md5 name package value version } ) {
		my $sql = "DROP INDEX IF EXISTS file_metric__$col";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	# Find all the files in the cache
	$self->trace("Processing cache directory " . $self->cache . "...");
	$self->begin;
	my $count  = 0;
	my $files  = 0;
	my $cache  = PPI::Document->get_cache;
	my $search = File::Next::files( {
		sort_files => 1,
	}, $self->cache );
	while ( my @file = $search->() ) {
		$file[1] =~ /([a-f0-9]+)\.ppi\z/ or next;
		(++$files % 100) or print '.';

		# Filter out things we've done already
		my $md5 = $1;
		$self->seen($md5) and next;
		print "$1\n";

		# Fetch the document from the cache
		my $document = $cache->get_document($md5);
		unless ( $document ) {
			warn("Failed to retrieve $md5 from the cache");
			next;
		}

		# Process the document
		$self->process_document(
			document => $document,
			md5      => $md5,
			hintsafe => 1,
		);
		next if ++$count % 100;
		$self->commit_begin;
	}
	$self->commit;
	print "\n";

	# Add the indexes back to the database
	$self->trace("Restoring indexes...");
	foreach my $col ( qw{ md5 name package value version } ) {
		my $sql = "CREATE INDEX IF NOT EXISTS file_metric__$col ON file_metric ( $col )";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	return 1;
}

sub process_distribution {
	my $self = shift;

	# Get and check the directory name
	my $path = File::Spec->canonpath(shift);
	unless ( defined Params::Util::_STRING($path) ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -d $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	# Find the documents
	my $files = $self->find_files($path);
	my @files = File::Find::Rule->ignore_svn->no_index->perl_module->in($path);
	$self->trace("$path: Found " . scalar(@files) . " files");
	foreach my $file ( @files ) {
		$self->trace($file);
		$self->process_file($file);
	}
	return 1;
}

sub process_file {
	my $self = shift;

	# Get and check the filename
	my $path = File::Spec->canonpath(shift);
	unless ( defined Params::Util::_STRING($path) ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -f $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	if ( $self->study ) {
		# If and only if every plugin has seen the document
		# we can shortcut and don't need to load it.
		my $md5 = PPI::Util::md5hex_file($path);
		return 1 if $self->seen($md5);
	}

	# Load the document
	my $document = PPI::Document->new( $path,
		readonly => 1,
	);
	unless ( $document ) {
		 warn("Failed to parse '$path'");
		 next;
	}
	$self->process_document(
		document => $document,
	);
}

# Forcefully process a docucment
sub process_document {
	my $self     = shift;
	my %params   = (@_ > 1) ? @_ : ( document => $_[0] );
	my $document = $params{document};
	my $md5      = $params{md5} || $document->hex_id;
	my $hintsafe = $params{hintsafe};

	# Filter out plugins we don't need to rerun
	# and sort plugins with destructive last
	my $plugins = $self->{plugins};
	my @names   = sort {
		$plugins->{$a}->destructive <=> $plugins->{$b}->destructive
		or
		$a cmp $b
	} grep {
		not $self->seen($md5, $_)
	} keys %$plugins;

	# Create the plugin objects
	foreach my $name ( @names ) {
		# Clone the document if the plugin is destructive, UNLESS it is the
		# last destructive plugin. If so, let it destroy the document anyway
		# since we won't be needing it any more.
		if ( $plugins->{$name}->destructive and $name ne $names[-1] ) {
			# Run the plugin on a copy
			my $copy = $document->clone;
			$plugins->{$name}->process_document(
				document => $document,
				md5      => $md5,
				hintsafe => $hintsafe,
			);
		} else {
			$plugins->{$name}->process_document(
				document => $document,
				md5      => $md5,
				hintsafe => $hintsafe,
			);
		}
	}

	return 1;
}

sub index_distribution {
	my $self     = shift;
	my $release  = shift;
	my $path     = shift;
	my $hintsafe = !! shift;

	# Find the documents
	my $files = $self->perl_files($path);

	# Generate the md5 checksums for the files
	my %md5 = map {
		$_ => PPI::Util::md5hex_file(
			File::Spec->catfile($path, $_)
		)
	} sort keys %$files;

	# Flush and push the files into the database
	unless ( $hintsafe ) {
		Perl::Metrics2::CpanFile->delete(
			'where release = ?', $release,
		);
	}
	foreach my $file ( sort keys %$files ) {
		Perl::Metrics2::CpanFile->create(
			release   => $release,
			file      => $file,
			md5       => $md5{$file},
			indexable => $files->{$file},
		);
	}

	return 1;
}





#####################################################################
# Index Optimisation Methods

my @INDEX = (
	[ 'file_metric', 'md5'       ],
	[ 'file_metric', 'name'      ],
	[ 'file_metric', 'package'   ],
	[ 'file_metric', 'value'     ],
	[ 'file_metric', 'version'   ],
	[ 'cpan_file',   'release'   ],
	[ 'cpan_file',   'file'      ],
	[ 'cpan_file',   'md5'       ],
	[ 'cpan_file',   'indexable' ],
);

sub index_remove {
	my $self = shift;

	$self->trace("Removing indexes...");
	foreach ( @INDEX ) {
		my $sql = "DROP INDEX IF EXISTS $_->[0]__$_->[1]";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	return 1;
}

sub index_restore {
	my $self = shift;

	$self->trace("Restoring indexes...");
	foreach ( @INDEX ) {
		my $sql = "CREATE INDEX IF NOT EXISTS $_->[0]__$_->[1] ON $_->[0] ( $_->[1] )";
		$self->trace($sql);
		Perl::Metrics2->do($sql);
	}

	return 1;
}





######################################################################
# File Search

sub perl_files {
	my $class = shift;
	my $path  = shift;

	# Find the basic file list
	my @basic = File::Find::Rule->ignore_svn->perl_file->relative->in($path);
	my %files = map { $_ => 0 } @basic;

	# Find the subset that will be indexed
	# If parsing the META.yml failes, don't ignore anything
	eval {
		my @index = File::Find::Rule->ignore_svn->no_index->perl_module->relative->in($path);
		foreach ( @index ) {
			$files{$_} = 1;
		}
	};

	return \%files;
}

sub perl_modules {
	my $class = shift;
	my $path  = shift;

	# Find the basic file list
	my @basic = File::Find::Rule->ignore_svn->perl_module->relative->in($path);
	my %files = map { $_ => 0 } @basic;

	# Find the subset that will be indexed
	# If parsing the META.yml failes, don't ignore anything
	eval {
		my @index = File::Find::Rule->ignore_svn->no_index->perl_module->relative->in($path);
		foreach ( @index ) {
			$files{$_} = 1;
		}
	};

	return \%files;
}





#####################################################################
# Support Methods

sub selectcol_index {
	my ($dbh, $stmt, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr);
	return unless $sth;
	$sth->execute(@bind) || return;
	my $column = $attr->{Columns} ? $attr->{Columns}->[0] : 1;
	my $value  = undef;
	$sth->bind_col($column, \$value) || return;
	my $row  = 0;
	my %hash = ();
	if ( my $max = $attr->{MaxRows} ) {
		while ( $sth->fetch ) {
			last if ++$row > $max;
			$hash{$value} = 1;
		}
	} else {
		while ( $sth->fetch ) {
			$hash{$value} = 1;			
		}
	}
	return \%hash;
}

sub in {
	my $self = shift;
	my $sql  = '( ' . join( ', ', map { '?' } @_ ) . ' )';
	return ( $sql, @_ );
}

sub trace {
	print STDERR map { "# $_\n" } @_[1..$#_];
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
