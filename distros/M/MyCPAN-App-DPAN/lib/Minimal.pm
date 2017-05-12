package MyCPAN::App::DPAN::Reporter::Minimal;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Reporter::Base);
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Carp;
use Cwd;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(catfile rel2abs);
use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

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

=cut

sub get_report_file_extension { 'txt' }

sub get_reporter
	{
	#TRACE( sub { get_caller_info } );

	my( $self ) = @_;

	my $base_dir = $self->get_config->backpan_dir;
	
	if( $self->get_config->organize_dists )
		{
		$base_dir = catfile( $base_dir, qw(authors id) );
		}
	
	my $reporter = sub {
		my( $info ) = @_;

		unless( defined $info )
			{
			$logger->error( "info is undefined!" );
			return;
			}

		my $out_path = $self->get_report_path( $info );

		open my($fh), ">", $out_path or 
			$logger->fatal( "Could not open $out_path to record report: $!" );

		print $fh "# Primary package [TAB] version [TAB] dist file [newline]\n";
		
		MODULE: foreach my $module ( @{ $info->{dist_info}{module_info} || [] } )
			{
			# skip if we are ignoring those packages?
			my $version = $module->{version_info}{value} || 'undef';
			$version = $version->numify if eval { $version->can('numify') };

			unless( defined $module->{primary_package} )
				{
				$logger->warn( "No primary package for $module->{name}" );				
				next MODULE;
				}

			# this should be an absolute path
			my $dist_file = $info->{dist_info}{dist_file};

			$dist_file =~ s/^.*authors.id.// if $self->get_config->organize_dists;
			
			$logger->warn( "No dist file for $module->{name}" )
				unless defined $dist_file;

			print $fh join "\t",
				$module->{primary_package},
				$version,
				$dist_file;

			print $fh "\n";
			}
		close $fh;

		$logger->error( "$out_path is missing!" ) unless -e $out_path;

		1;
		};

	$self->set_note( 'reporter', $reporter );
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

	$logger->trace( "Final words from the DPAN Reporter" );

	my %dirs_needing_checksums;

	use CPAN::PackageDetails 0.22;
	my $package_details = CPAN::PackageDetails->new(
		allow_packages_only_once => 0
		);

	$logger->info( "Creating index files" );

	$self->_init_skip_package_from_config;
	
	require version;
	FILE: foreach my $file ( $self->get_latest_module_reports )
		{
		$logger->debug( "Processing output file $file" );
		
		open my($fh), '<', $file or do {
			$logger->error( "Could not open [$file]: $!" );
			next FILE;
			};
		
		my @packages;
		PACKAGE: while( <$fh>  )
			{
			next PACKAGE if /^\s*#/;
			
			chomp;
			my( $package, $version, $dist_file ) = split /\t/;
			$version = undef if $version eq 'undef';
			
			unless( defined $package && length $package )
				{
				$logger->debug( "File $file line $.: no package! Line is [$_]" );
				next PACKAGE;
				}

			if( $self->get_config->organize_dists )
				{
				my $backpan_dir = ($self->get_config->backpan_dir)[0];
				$dist_file = catfile( 
					$backpan_dir, 
					qw(authors id),
					$dist_file
					);
				}
			
			$logger->debug( "dist_file is now [$dist_file]" );
			next PACKAGE unless -e $dist_file; # && $dist_file =~ m/^\Q$backpan_dir/;
			my $dist_dir = dirname( $dist_file );
			$dirs_needing_checksums{ $dist_dir }++;

			# broken crap that works on Unix and Windows to make cpanp
			# happy. It assumes that authors/id/ is in front of the path
			# in 02packages.details.txt
			( my $path = $dist_file ) =~ s/.*authors.id.//g;

			$path =~ s|\\+|/|g; # no windows paths.

			if( $self->skip_package( $package ) )
				{
				$logger->debug( "Skipping $package: excluded by config" );
				next PACKAGE;
				}
			
			push @packages, [ $package, $version, $path ];
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
backpan_dir (some things might have moved around), gets the reports for 

=cut

sub get_latest_module_reports
	{
	my( $self ) = @_;
	$logger->info( "In get_latest_module_reports" );
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
	$logger->debug( "Adding extra reports [@$extra_reports]" );

	@files;
	}

sub _get_all_reports
	{
	my( $self ) = @_;
	
	my $report_dir = $self->get_success_report_dir;
	$logger->debug( "Report dir is $report_dir" );

	opendir my($dh), $report_dir or
		$logger->fatal( "Could not open directory [$report_dir]: $!");	
	
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
	my @dirs = do {
		my $item = $self->get_config->backpan_dir || '';
		split /\s+/, $item;
		};
	$logger->debug( "Queue directories are [@dirs]" );
	
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
	$logger->debug( "Extra reports directory is [$dir]" );

	my $cwd = cwd();
	$logger->debug( "Extra reports directory does not exist! Cwd is [$cwd]" )
		unless -d $dir;
	
	my $glob = catfile(
		$dir,
		"*." . $self->get_report_file_extension
		);
	$logger->debug( "glob pattern is [$glob]" );
	
	my @reports = glob( $glob );
	$logger->debug( "Got extra reports [@reports]" );
	
	return \@reports;
	}
	
=item create_index_files

Creates the 02packages.details.txt.gz and 03modlist.txt.gz files. If there
is a problem, it logs a fatal message and returns nothing. If everything works,
it returns true.

It initially creates the 02packages.details.txt.gz as a temporary file. Before
it moves it to its final name, it checks the file with CPAN::PackageDetails::check_file
to ensure it is valid. If it isn't, it stops the process.

=cut

sub create_index_files
	{
	my( $self ) = @_;
	my $index_dir = do {
		my $d = $self->get_config->backpan_dir;
		
		# there might be more than one if we pull from multiple sources
		# so make the index in the first one.
		my $abs = rel2abs( ref $d ? $d->[0] : $d );
		$abs =~ s/authors.id.*//;
		catfile( $abs, 'modules' );
		};
	
	mkpath( $index_dir ) unless -d $index_dir; # XXX

	my $_02packages_name = '02packages.details.txt.gz';
	my $packages_file = catfile( $index_dir, $_02packages_name );

	my $package_details = $self->get_note( 'package_details' );
	
	# inside write_file, the module writes to a temp file then renames
	# it. It doesn't do any other checking. Should some of this be in
	# there, though?
	
	# before we start, ensure that there are some entries. check_files
	# checks this too, but I want to die earlier with a better message
	my $count = $package_details->count;
	
	unless( $count > 0 )
		{
		$logger->fatal( "There are no entries to put into $_02packages_name!" );	
		return;			
		}
		
	# now, write the file. Even though write_file writes to a temporary
	# file first, that doesn't protect us from overwriting a good 02packages
	# with a bad one at this level.
	{ # scope for $temp_file
	my $temp_file = "$packages_file-$$-trial";
	$logger->info( "Writing $temp_file" );	
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
	$logger->debug( "Using dpan_dir => $dpan_dir" );	


	# Check the trial file for errors	
	unless( $self->get_config->i_ignore_errors_at_my_peril )
		{
		$logger->info( "Checking validity of $temp_file" );
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
				unlink $temp_file unless $logger->is_debug;
				$logger->logdie( "$temp_file has a problem and I have to abort:\n".
					"Deleting file (unless you're debugging)\n" .
					"$error" 
					) if defined $error;
				}
			}
		}

	# if we are this far, 02packages must be okay
	unless( rename( $temp_file => $packages_file ) )
		{
		$logger->fatal( "Could not rename $temp_file => $packages_file" );
		return;
		}
	}
	
	# there are no worries about 03modlist because it is just a stub.
	# there are no real data in it.
	$logger->info( 'Writing 03modlist.txt.gz' );	
	$self->create_modlist( $index_dir );

	$logger->info( 'Creating CHECKSUMS files' );	
	$self->create_checksums( $self->get_note( 'dirs_needing_checksums' ) );
	
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
	$logger->debug( "modules list file is [$module_list_file]");

	if( -e $module_list_file )
		{
		$logger->debug( "File [$module_list_file] already exists!" );
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
			$logger->error( "Couldn't create CHECKSUMS for $dir: $@" ) if $@;
			$logger->info(
				do {
					  if(    $rc == 1 ) { "Valid CHECKSUMS file is already present" }
					  elsif( $rc == 2 ) { "Wrote new CHECKSUMS file in $dir" }
					  else              { "updatedir unexpectedly returned an error" }
				} );
		}
	}
	
=back

=head1 TO DO

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan--app--dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
