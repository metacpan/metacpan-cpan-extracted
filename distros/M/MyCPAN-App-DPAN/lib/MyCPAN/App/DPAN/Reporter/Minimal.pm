package MyCPAN::App::DPAN::Reporter::Minimal;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Reporter::Base);
use vars qw($VERSION $reporter_logger $collator_logger);
$VERSION = '1.281';

use Carp;
use Cwd;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(catfile rel2abs file_name_is_absolute);
use Log::Log4perl;

BEGIN {
	$reporter_logger = Log::Log4perl->get_logger( 'Reporter' );
	$collator_logger = Log::Log4perl->get_logger( 'Collator' );
	}

=encoding utf8

=head1 NAME

MyCPAN::App::DPAN::Reporter::Minimal - Save the minimum information that dpan needs

=head1 SYNOPSIS

Use this in the C<dpan> config by specifying it as the reporter class:

	# in dpan.config
	reporter_class  MyCPAN::App::DPAN::Reporter::Minimal

=head1 DESCRIPTION

This class takes the result of examining a distribution and saves only
the information that dpan needs to create the PAUSE index files. It's
a very small text file with virtually no processing overhead compared
to YAML.

=head2 Methods

=over 4

=item get_reporter

C<get_reporter> sets the C<reporter> key in the notes. The value is a
code reference that takes the information collected about a
distribution and dumps it as a YAML file.

See L<MyCPAN::Indexer::Tutorial> for details about what
C<get_reporter> expects and should do.

If C<relative_paths_in_report> is true, the reports removes the base
path up to I<author/id>.

=item get_report_file_extension

Returns the extension for report files.

=cut

sub get_report_file_extension { 'txt' }

sub get_reporter
	{
	my( $self ) = @_;

	# why is this here?
	my $base_dir = $self->get_config->dpan_dir;

	if( $self->get_config->organize_dists )
		{
		$base_dir = catfile( $base_dir, qw(authors id) );
		}

	my $reporter = sub {
		my( $info ) = @_;

		unless( defined $info )
			{
			$reporter_logger->error( "info is undefined!" );
			return;
			}

		my( %Found_canonical, %Current_version, @packages_to_write );
		MODULE: foreach my $module ( @{ $info->{dist_info}{module_info} || [] } )
			{
			# skip if we are ignoring those packages?
			my $version = $module->{version_info}{value} || 'undef';
			$version = $version->numify if eval { $version->can('numify') };

			unless( defined $module->{primary_package} )
				{
				no warnings 'uninitialized';
				$reporter_logger->warn( "No primary package for $module->{name}" );
				next MODULE;
				}

			next MODULE if $Found_canonical{ $module->{primary_package} };
			{
			no warnings qw(uninitialized numeric);
			next MODULE if $version < $Current_version{ $module->{primary_package} };
			}

			$Current_version{ $module->{primary_package} } = $version;
			$Found_canonical{ $module->{primary_package} } = 1 if
				$module->{primary_package} eq $module->{module_name_from_file_guess};

			# this should be an absolute path
			my $dist_file = $info->{dist_info}{dist_file};

			if( $self->get_config->relative_paths_in_report )
				{
				# XXX: what if there isn't an authors/id?
				$dist_file =~ s/^.*authors.id.//;
				$dist_file =~ tr|\\|/|; # translate windows \ to Unix /, cheating
				}

			$reporter_logger->warn( "No dist file for $module->{name}" )
				unless defined $dist_file;

			push @packages_to_write, [
				$module->{primary_package},
				$version,
				$dist_file,
				];
			}

		if( $info->{run_info}{completed} )
			{
			$self->_write_success_file( $info, \@packages_to_write );
			}
		else
			{
			$self->_write_error_file( $info );
			}
		1;
		};

	$self->set_note( 'reporter', $reporter );
	}

sub _write_success_file
	{
	my( $self, $info, $packages ) = @_;

	my $out_path = $self->get_report_path( $info );
	open my($fh), ">:utf8", $out_path or
	$reporter_logger->fatal( "Could not open $out_path to record success report: $!" );

	print $fh "# Primary package [TAB] version [TAB] dist file [newline]\n";

	foreach my $tuple ( @$packages )
		{
		print $fh join "\t", @$tuple;
		print $fh "\n";
		}

	close $fh;

	# check that the file is where it should be
	$reporter_logger->error( "$out_path is missing!" ) unless -e $out_path;

	return 1;
	}

sub _write_error_file
	{
	my( $self, $info ) = @_;

	my $out_path = $self->get_report_path( $info );
	open my($fh), ">:utf8", $out_path or
	$reporter_logger->fatal( "Could not open $out_path to record error report: $!" );

	print $fh "ERRORS:\n",
		map { sprintf "%s: %s\n", $_, $info->{run_info}{$_} || '' }
		qw( error fatal_error extraction_error );

	use Data::Dumper;
	print $fh '-' x 73, "\n";
	print $fh Dumper( $info );

	close $fh;

	# check that the file is where it should be
	$reporter_logger->error( "$out_path is missing!" ) unless -e $out_path;

	return 1;
	}

=item get_collator

This Reporter class also implements its Collator since the two are
coupled by the report format. It's a wrapper around C<final_words>,
which previously did the same thing.

=cut

sub get_collator
	{
	#TRACE( sub { get_caller_info } );

	my( $self ) = @_;

	my $collator = sub {
		$self->final_words;
		unless( eval { $self->create_index_files } )
			{
			$self->set_note( 'epic_fail', $@ );
			return;
			}
		return 1;
		};

	$self->set_note( $_[0]->collator_type, $collator );

	1;
	}

=item final_words

Runs after all the reporting for all distributions has finished. This
creates a C<CPAN::PackageDetails> object and stores it as the C<package_details>
notes. It store the list of directories that need fresh F<CHECKSUMS> files
in the C<dirs_needing_checksums> note.

The checksums and index file creation are split across two steps so that
C<dpan> has a chance to do something between the analysis and their creation.

=cut

sub final_words
	{
	# This is where I want to write 02packages and CHECKSUMS
	my( $self ) = @_;

	$collator_logger->trace( "Final words from the DPAN Reporter" );

	my %dirs_needing_checksums;

	use CPAN::PackageDetails 0.22;
	my $package_details = CPAN::PackageDetails->new(
		allow_packages_only_once => 0
		);

	$collator_logger->info( "Creating index files" );

	$self->_init_skip_package_from_config;

	require version;
	FILE: foreach my $file ( $self->get_latest_module_reports )
		{
		$collator_logger->debug( "Processing output file $file" );

		unless( -e $file )
			{
			$collator_logger->debug( "No success report for [$file]" );
			next FILE;
			}

		open my($fh), '<:utf8', $file or do {
			$collator_logger->error( "Could not open [$file]: $!" );
			next FILE;
			};

		my @packages;
		PACKAGE: while( <$fh>  )
			{
			next PACKAGE if /^\s*#/;

			chomp;
			my( $package, $version, $dist_file ) = split /\t/;
			$version = undef if $version eq 'undef';
			$collator_logger->warn( "$package has no distribution file: $file" )
				unless defined $dist_file;

			unless( defined $package && length $package  )
				{
				$collator_logger->debug( "File $file line $.: no package! Line is [$_]" );
				next PACKAGE;
				}

			my $full_path = $dist_file;

			unless( file_name_is_absolute( $full_path ) )
				{
				my $dpan_dir = $self->get_config->dpan_dir;

				# if we're using organize_dists, we created an authors/id
				# directory under dpan_dir, so we have to put those
				# three pieces together
				if( $self->get_config->organize_dists )
					{
					$full_path = catfile(
						$dpan_dir,
						qw(authors id),
						$dist_file
						) ;
					}
				# otherwise, every path should be relative to $dpan_dir
				# I'm not sure that is actually true though if dpan_dir
				# is the current directory, and there is an authors/id
				# under it
				elsif( $self->get_config->relative_paths_in_report )
					{
					my $f1 = catfile(
						$dpan_dir,
						$dist_file
						);

					my $f2 = catfile(
						$dpan_dir,
						qw(authors id),
						$dist_file
						);

					( $full_path ) = grep { -e } ( $f1, $f2 )
					}
				}

			{
			no warnings 'uninitialized';
			$collator_logger->debug( "dist_file is now [$dist_file]" );
			$collator_logger->debug( "full_path is now [$full_path]" );
			}

			next PACKAGE unless defined $full_path && -e $full_path;
			my $dist_dir = dirname( $full_path );
			$dirs_needing_checksums{ $dist_dir }++;

			# broken crap that works on Unix and Windows to make cpanp
			# happy. It assumes that authors/id/ is in front of the path
			# in 02packages.details.txt
			( my $path = $dist_file ) =~ s/.*authors.id.//g;

			no warnings 'uninitialized';
			$path =~ s|\\+|/|g; # no windows paths.

			if( $self->skip_package( $package ) )
				{
				$collator_logger->debug( "Skipping $package: excluded by config" );
				next PACKAGE;
				}

			push @packages, [ $package, $version, $path ]
				if( $package and $version and $path );
			}

		# Some distros declare the same package in multiple files. We
		# only want the one with the defined or highest version
		my %Seen;
		no warnings;

		my @filtered_packages =
			grep { ! $Seen{$_->[0]}++ }
			map { my $s = $_; $s->[1] = 'undef' unless defined $s->[1]; $s }
			sort {
				$a->[0] cmp $b->[0]
					||
				$b->[1] cmp $a->[1]  # yes, versions are strings
				}
			@packages;

		foreach my $tuple ( @filtered_packages )
			{
			my( $package, $version, $path ) = @$tuple;

			eval { $package_details->add_entry(
				'package name' => $package,
				version        => $version,
				path           => $path,
				) } or warn "Could not add $package $version from $path! $@\n";
			}
		}

	$self->set_note( 'package_details', $package_details );
	$self->set_note( 'dirs_needing_checksums', [ keys %dirs_needing_checksums ] );

	1;
	}

=item get_latest_module_reports

Return the list of interesting reports for this indexing run.  This
re-runs the queuer to get the final list of distributions in
dpan_dir (some things might have moved around), gets the reports for

=cut

sub get_latest_module_reports
	{
	my( $self ) = @_;
	$reporter_logger->info( "In get_latest_module_reports" );
	my $report_names_by_dist_names = $self->_get_report_names_by_dist_names;

	my $all_reports = $self->_get_all_reports;


	my %Seen = ();
	my $report_dir = $self->get_success_report_dir;

	no warnings 'uninitialized';
	my @files =
		map  { catfile( $report_dir, $_->[-1] ) }
		grep { ! $Seen{$_->[0]}++ }
		map  { [ /^(.*)-(.*)\.txt\z/, $_ ] }
		reverse
		sort
		keys %$report_names_by_dist_names;

	my $extra_reports = $self->_get_extra_reports || [];

	push @files, @$extra_reports;
	$reporter_logger->debug( "Adding extra reports [@$extra_reports]" );

	@files;
	}

sub _get_all_reports
	{
	my( $self ) = @_;

	my $report_dir = $self->get_success_report_dir;
	$reporter_logger->debug( "Report dir is $report_dir" );

	opendir my($dh), $report_dir or
		$reporter_logger->fatal( "Could not open directory [$report_dir]: $!");

	my @reports = readdir( $dh );

	\@reports;
	}

# this generates a list of report names based on what should
# be there according to the dist that we just indexed. There
# might be many reports for different versions or modules no
# longer in the DPAN, so we don't want those
sub _get_report_names_by_dist_names
	{
	my( $self ) = @_;

	# We have to recreate the queue because we might have moved
	# things around with organize_dists
	my $queuer = $self->get_coordinator->get_component( 'queue' );

	# these are the directories to index
	my @dirs = $self->get_config->dpan_dir;
	$reporter_logger->debug( "Queue directories are [@dirs]" );

	# This is the list of distributions in the indexed directories
	my $dists = $queuer->_get_file_list( @dirs );

	# The code in this map is duplicated from MyCPAN::Indexer::Reporter::Base
	# in get_report_filename. That method assumes it's getting a big data
	# structure, so I need to refactor out this bit to _dist2report or
	# something. I'll get it to work here first.
	my %dist_reports = map {
		( my $basename = basename( $_ ) ) =~ s/\.(tgz|tar\.gz|zip)$//;
		my $report_name = join '.', $basename, $self->get_report_file_extension;
		( $report_name, $_ );
		} @$dists;

	return \%dist_reports;
	}

sub _get_extra_reports
	{
	my( $self ) = @_;

	return [] unless $self->get_config->exists( 'extra_reports_dir' );

	my $dir = $self->get_config->extra_reports_dir;
	return [] unless defined $dir;
	$reporter_logger->debug( "Extra reports directory is [$dir]" );

	my $cwd = cwd();
	$reporter_logger->debug( "Extra reports directory does not exist! Cwd is [$cwd]" )
		unless -d $dir;

	my $glob = catfile(
		$dir,
		"*." . $self->get_report_file_extension
		);
	$reporter_logger->debug( "glob pattern is [$glob]" );

	my @reports = glob( $glob );
	$reporter_logger->debug( "Got extra reports [@reports]" );

	return \@reports;
	}

=item create_index_files

Creates the F<02packages.details.txt.gz> and F<03modlist.txt.gz>
files. If there is a problem, it logs a fatal message and returns
nothing. If everything works, it returns true.

It initially creates the F<02packages.details.txt.gz> as a temporary
file. Before it moves it to its final name, it checks the file with
C<CPAN::PackageDetails::check_file> to ensure it is valid. If it
isn't, it stops the process.

=cut

sub create_index_files
	{
	my( $self ) = @_;
	my $index_dir = do {
		my $d = $self->get_config->dpan_dir;

		# there might be more than one if we pull from multiple sources
		# so make the index in the first one.
		my $abs = rel2abs( $d );
		$abs =~ s/authors.id.*//;
		catfile( $abs, 'modules' );
		};

	mkpath( $index_dir ) unless -d $index_dir; # XXX

	my $_02packages_name = '02packages.details.txt.gz';
	my $packages_file = catfile( $index_dir, $_02packages_name );

	my $package_details = $self->get_note( 'package_details' );
	if( -e catfile( $index_dir, '.svn' ) )
		{
		$package_details->set_header( 'X-SVN-Id', '$Id$' );
		}

	# inside write_file, the module writes to a temp file then renames
	# it. It doesn't do any other checking. Should some of this be in
	# there, though?

	# before we start, ensure that there are some entries. check_files
	# checks this too, but I want to die earlier with a better message
	my $count = $package_details->count;

	unless( $count > 0 )
		{
		$collator_logger->fatal( "There are no entries to put into $_02packages_name!" );
		return;
		}

	# now, write the file. Even though write_file writes to a temporary
	# file first, that doesn't protect us from overwriting a good 02packages
	# with a bad one at this level.
	{ # scope for $temp_file
	my $temp_file = "$packages_file-$$-trial";
	$collator_logger->info( "Writing $temp_file" );
	$package_details->write_file( $temp_file );

	# We tell it to start in $index_dir, but that might have authors/id under it
	# and that prefix won't show up in 02packages. That's a problem when we want
	# to find packages and compare their paths. CPAN::PackageDetails might consider
	# stripping authors/id
	#
	# Note: CPANPLUS always assumes authors/id, even for full paths.
	my $dpan_dir = dirname( $index_dir );
	my $dpan_authors_id = catfile( $dpan_dir, qw( authors id ) );

	# if there is an authors/id under the dpan_dir, let's give that path to
	# check_file
	$dpan_dir = $dpan_authors_id if -d $dpan_authors_id;
	$collator_logger->debug( "Using dpan_dir => $dpan_dir" );


	# Check the trial file for errors
	unless( $self->get_config->i_ignore_errors_at_my_peril )
		{
		$collator_logger->info( "Checking validity of $temp_file" );
		my $at;
		my $result = eval { $package_details->check_file( $temp_file, $dpan_dir ) }
			or $at = $@;

		if( defined $at )
			{
			# _interpret_check_file_error can nerf an error based
			# on configuration. Maybe you don't care about a
			# particular error.
			my $error = $self->_interpret_check_file_error( $at );

			if( defined $error )
				{
				unlink $temp_file unless $collator_logger->is_debug;
				$collator_logger->logdie( "$temp_file has a problem and I have to abort:\n".
					"Deleting file (unless you're debugging)\n" .
					"$error"
					) if defined $error;
				}
			}
		}

	# if we are this far, 02packages must be okay
	unless( rename( $temp_file => $packages_file ) )
		{
		$collator_logger->fatal( "Could not rename $temp_file => $packages_file" );
		return;
		}
	}

	# there are no worries about 03modlist because it is just a stub.
	# there are no real data in it.
	$collator_logger->info( 'Writing 03modlist.txt.gz' );
	$self->create_modlist( $index_dir );

	$collator_logger->info( 'Creating CHECKSUMS files' );
	$self->create_checksums( $self->get_note( 'dirs_needing_checksums' ) );

	$collator_logger->info( 'Updating mailrc and whois files' );
	$self->update_whois;

	1;
	}

sub _interpret_check_file_error
	{
	my( $self, $at ) = @_;

	my $error_message = do {
		if( not ref $at )
			{
			$at;
			}
		# eventually this will filter the missing files and still
		# complain for the left over ones
		elsif( exists $at->{missing_in_file} )
			{
			if( $self->get_config->ignore_missing_dists ) {
				undef;
				}
			else {
				"Some distributions in the repository do not show up in the file\n\t" .
					join( "\n\t", @{ $at->{missing_in_file} } )
				}
			}
		# eventually this will filter the missing dists and still
		# complain for the left over ones
		elsif( exists $at->{missing_in_repo} )
			{
			if( $self->get_config->ignore_extra_dists ) {
				undef;
				}
			else {
				"The file has distributions that do not appear in the repository\n\t" .
					join( "\n\t", @{ $at->{missing_in_repo} } )
				}
			}
		else { 'Unknown error!' }
		};

	}

=item skip_package( PACKAGE )

Returns true if the indexer should ignore PACKAGE.

By default, this skips the Perl special packages specified by the
ignore_packages configuration. By default, ignore packages is:

	main
	MY
	MM
	DB
	bytes
	DynaLoader

To set a different list, configure ignore_packages with a space
separated list of packages to ignore:

	ignore_packages main Foo Bar::Baz Test

Note that this only ignores those exact packages. You can't configure
this with regex or wildcards (yet).

=cut

BEGIN {
my $initialized = 0;
my %skip_packages;

sub _skip_package_initialized { $initialized }

sub _init_skip_package_from_config
	{
	my( $self, $Notes ) = @_;

	%skip_packages =
		map { $_, 1 }
		grep { defined }
		split /\s+/,
		$self->get_config->ignore_packages || '';

	$initialized = 1;
	}

sub skip_package
	{
	my( $self, $package ) = @_;

	exists $skip_packages{ $package }
	}
}

=item create_package_details

Not yet implemented. Otehr code needs to be refactored and show up
here.

=cut

sub create_package_details
    {
    my( $self, $index_dir ) = @_;


    1;
    }

=item create_modlist

If a modules/03modlist.data.gz does not already exist, this creates a
placeholder which defines the CPAN::Modulelist package and the method
C<data> in that package. The C<data> method returns an empty hash
reference.

=cut

sub create_modlist
	{
	my( $self, $index_dir ) = @_;

	my $module_list_file = catfile( $index_dir, '03modlist.data.gz' );
	$collator_logger->debug( "modules list file is [$module_list_file]");

	if( -e $module_list_file )
		{
		$collator_logger->debug( "File [$module_list_file] already exists!" );
		return 1;
		}

	my $fh = IO::Compress::Gzip->new( $module_list_file );
	print $fh <<"HERE";
File:        03modlist.data
Description: This a placeholder for CPAN.pm
Modcount:    0
Written-By:  Id: $0
Date:        @{ [ scalar localtime ] }

package CPAN::Modulelist;

sub data { {} }

1;
HERE

	close $fh;
	}

=item update_whois


00whois.xml     01mailrc.txt.gz

=cut

sub update_whois
	{
	my( $self, $index_dir ) = @_;
	require MyCPAN::App::DPAN::CPANUtils;

	my $success = 0;

	# no matter the situation, start over. I don't like this situation
	# so much, but it's more expedient then parsing the xml file to look
	# for missing users
	unlink map { my $f = catfile(
		$self->get_config->dpan_dir,
		'authors',
		MyCPAN::App::DPAN::CPANUtils->$_()
		);

		$f;
		} qw( mailrc_filename whois_filename );

	if( $self->get_config->use_real_whois )
		{
		my $result = MyCPAN::App::DPAN::CPANUtils->pull_latest_whois(
			$self->get_config->dpan_dir, $collator_logger
			);
		if( $result == 2 )
			{
			$success = 1;
			}
		else
			{
			warn "Could not pull whois files from CPAN\n";
			$success = 0;
			}

		}

	unless( $success )
		{
		MyCPAN::App::DPAN::CPANUtils->make_fake_whois(
			$self->get_config->dpan_dir, $collator_logger
			);
		}

	my %authors = $self->get_all_authors;

	$self->update_01mailrc( \%authors );

	$self->update_00whois( \%authors );

	return 1;
	}

=item get_all_authors

Walk the repository and extract all of the actual authors in the repo.

=cut

sub get_all_authors
	{
	my( $self ) = @_;

	my $author_map = do {
		my $file = $self->get_config->author_map;
		if( defined $file )
			{
			my $hash;
			unless( -e $file )
				{
				$collator_logger->error( "Author map file [$file] does not exist" );
				{};
				}
			elsif( open my($fh), '<:utf8', $file )
				{
				while( <$fh> )
					{
					chomp;
					my( $pause_id, $full_name ) = split /\s+/, $_, 2;
					$hash->{uc $pause_id} = $full_name || $self->get_config->pause_full_name;
					}
				$hash;
				}
			else
				{
				$collator_logger->error( "Could not open author map file [$file]: $!" );
				{};
				}
			}
		else { {} }
		};

	my $old_cwd = cwd();
	my $id_dir = catfile( $self->get_config->dpan_dir, 'authors', 'id' );
	chdir $id_dir;

	my @authors_in_repo = map { basename( $_ ) } glob( "*/*/*" );
	chdir $old_cwd;

	my %authors = map {
		$_,
		$author_map->{$_} || $self->get_config->pause_full_name
		} @authors_in_repo;

	%authors;
	}

=item update_01mailrc

Ensure that every PAUSE ID that's in the repository shows up in the
F<authors/01mailrc.txt.gz> file. Any new IDs show up with the name
from the C<pause_full_name> configuration.

TO DO: offer a way to configure multiple new IDs

=cut

sub update_01mailrc
	{
	my( $self, $authors ) = @_;

	require IO::Uncompress::Gunzip;
	require IO::Compress::Gzip;

	my $d = $self->get_config->dpan_dir;
	my $mailrc_fh = do {
		my $file = catfile( $d, 'authors', '01mailrc.txt.gz' );
		IO::Uncompress::Gunzip->new( $file ) or do {
			carp "Could not open $file: $IO::Uncompress::Gunzip::GunzipError\n";
			undef;
			};
		};

	my $new_mailrc_fh = do {
		my $file = catfile( $d, 'authors', 'new-01mailrc.txt.gz' );
		my $z = IO::Compress::Gzip->new( $file )
        	or carp "gzip failed: $IO::Compress::Gzip::GzipError\n";
        };

	while( <$mailrc_fh> )
		{
		my( $pause_id, $name, $email ) = m/^
			alias \s+
			(\S+) \s+
			"
				(.*) \s+
				<
					(.*?)
				>
			"/x;

		delete $authors->{$pause_id};
		print { $new_mailrc_fh } $_;
		}

	foreach my $author ( keys %$authors )
		{
		print { $new_mailrc_fh } qq|alias $author "$authors->{$author}"\n|;
		}

	close $new_mailrc_fh;

	rename
		catfile( $d, 'authors', 'new-01mailrc.txt.gz' ),
		catfile( $d, 'authors', '01mailrc.txt.gz' );
	}

=item update_00whois

Ensure that every PAUSE ID that's in the repository shows up in the
F<authors/00whois.xml> file. Any new IDs show up with the name
from the C<pause_full_name> configuration.

=cut

sub update_00whois
	{
	my( $self, $authors ) = @_;

	my $d = $self->get_config->dpan_dir;

	my $file = catfile( $d, 'authors', '00whois.xml' );
	open my( $whois_fh ), "+<:utf8", $file
		or do {
			carp "Could not open $file: $!\n";
			return;
			};

	my $file_end = "</cpan-whois>\n";
	seek $whois_fh, - length( $file_end ), 2;

	foreach my $author ( keys %$authors )
		{
		my( $name, $email ) = # XXX need to encode
			map { my $x = $_;
				$x =~ s/&/&amp;/g;
				$x =~ s/</&lt;/g;
				$x =~ s/>/&gt;/g;
				$x =~ s/"/&quot;/g;
				$x;
				} $authors->{$author} =~ m/\s*(.+)\s+<(.+?)>/;

		print { $whois_fh } <<"AUTHOR";
 <cpanid>
  <id>$author</id>
  <type>author</type>
  <fullname>$name</fullname>
  <email>$email</email>
 </cpanid>
AUTHOR
		}

	print { $whois_fh } $file_end;

	close $whois_fh;

	1;
	}

=item create_checksums

Creates the CHECKSUMS file that goes in each author directory in CPAN.
This is mostly a wrapper around CPAN::Checksums since that already handles
updating an entire tree. We just do a little logging.

=cut

sub create_checksums
	{
	my( $self, $dirs ) = @_;

	require CPAN::Checksums;
	foreach my $dir ( @$dirs )
		{
		my $rc = eval{ CPAN::Checksums::updatedir( $dir ) };
			$reporter_logger->error( "Couldn't create CHECKSUMS for $dir: $@" ) if $@;
			$reporter_logger->info(
				do {
					  if(    $rc == 1 ) { "Valid CHECKSUMS file is already present" }
					  elsif( $rc == 2 ) { "Wrote new CHECKSUMS file in $dir" }
					  else              { "updatedir unexpectedly returned an error" }
				} );
		}
	}

=back

=head1 TO DO

How much time do you have?

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
