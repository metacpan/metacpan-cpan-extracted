package MyCPAN::Indexer;
use strict;

use v5.14;

use warnings;
no warnings;

use parent qw(MyCPAN::Indexer::Component);
use subs qw(get_caller_info);
use vars qw($VERSION $logger);

$VERSION = '1.282';

=encoding utf8

=head1 NAME

MyCPAN::Indexer - Index a Perl distribution

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

=cut

use Carp qw(croak);
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use Probe::Perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Indexer' );
	}

__PACKAGE__->run( @ARGV ) unless caller;

=over 4

=item get_indexer()

A stand in for run_components later on.

=cut

sub get_indexer
	{
	my( $self ) = @_;

	1;
	}

sub component_type { $_[0]->indexer_type }
sub class { __PACKAGE__ }

=item run( DISTS )

Takes a list of distributions and indexes them.

=cut

sub run
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, @args ) = @_;

	$self->setup_run_info;

	DIST: foreach my $dist ( @args )
		{
		$logger->debug( "Dist is $dist\n" );

		unless( -e $dist )
			{
			$logger->error( "Could not find [$dist]" );
			next;
			}

		$logger->info( "Processing $dist\n" );

		$self->clear_dist_info;
		$self->setup_dist_info( $dist ) or next DIST;

		$self->examine_dist or next DIST;

		$self->set_run_info( 'completed', 1 );
		$self->set_run_info( 'run_end_time', time );

		$logger->info( "Finished processing $dist" );
		$logger->debug( sub { Dumper( $self ) } );
		}

	$self;
	}

=item examine_dist

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=item examine_dist_steps

Return a list of 3-element anonymous arrays that tell C<examine_dists>
what to do. The elements of each anonymous array are:

	1) the method to call (must be in indexing class or its parent classes)
	2) a text description of the method
	3) if a failure in that step should stop the exam: true or false

=cut

sub examine_dist_steps
	{
	my @methods = (
		#    method                error message                  fatal
		[ 'unpack_dist',        "Could not unpack distribution!",    1 ],
		[ 'find_dist_dir',      "Did not find distro directory!",    1 ],
		[ 'get_file_list',      'Could not get file list',           1 ],
		[ 'run_build_file',     "Could not run build file!",         0 ],
		[ 'parse_meta_files',   "Could not parse META.yml!",         0 ],
		[ 'find_modules',       "Could not find modules!",           1 ],
		[ 'examine_modules',    "Could not process modules!",        0 ],
		[ 'find_tests',         "Could not find tests!",             0 ],
		[ 'examine_tests',      "Could not process tests!",          0 ],
		);
	}

sub examine_dist
	{
	$logger->trace( sub { get_caller_info } );
	my( $self ) = @_;

	$self->set_run_info( 'examine_start_time', time );

	foreach my $tuple ( $self->examine_dist_steps )
		{
		my( $method, $error_msg, $die_on_error ) = @$tuple;
		$logger->debug( "Running examine_dist step [$method]" );

		local $@;
		unless( eval { $self->$method() } )
			{
			my $at = $@;
			$logger->error( "Error from [$method]: $at" );
			if( $die_on_error ) # only if failure is fatal
				{
				$self->set_run_info( 'fatal_error', $error_msg );
				$logger->error( "Fatal error, stopping: $error_msg" );
				return;
				}
			elsif( $at =~ /Alarm rang/i )
				{
				$logger->error( $at );
				$self->set_run_info( 'alarm_error', $error_msg );
				return;
				}
			elsif( $at )
				{
				$logger->error( "Program error! stopping: $at" );
				return;
				}
			else
				{
				$logger->error( $error_msg . " [" . $self->dist_info( 'dist_basename' ) . "]" );
				}
			}
		}

	$self->set_run_info( 'examine_end_time', time );
	$self->set_run_info( 'examine_time',
		$self->run_info('examine_end_time') - $self->run_info('examine_start_time')
		);

	return 1;
	}

sub examine_modules
	{
	my( $self ) = @_;

	my @file_info = map {
		$logger->debug( "Processing module $_" );
		$self->get_module_info( $_ );
		} @{ $self->dist_info( 'modules' ) || [] };

	$self->set_dist_info( 'module_info', \@file_info );
	}

sub examine_tests
	{
	my( $self ) = @_;

	my @file_info = map {
		$logger->debug( "Processing test $_" );
		$self->get_test_info( $_ );
		} @{ $self->dist_info( 'tests' ) || [] };

	$self->set_dist_info( 'test_info', \@file_info );
	}

=item clear_run_info

Clear anything recorded about the run.

=cut

sub clear_run_info
	{
	$logger->trace( sub { get_caller_info } );
	$logger->debug( "Clearing run_info\n" );
	$_[0]->{run_info} = {};
	}

=item setup_run_info( DISTPATH )

Given a distribution path, record various data about it, such as its size,
mtime, and so on.

Sets these items in dist_info:
	dist_file
	dist_size
	dist_basename
	dist_basename
	dist_author

=cut

sub setup_run_info
	{
	$logger->trace( sub { get_caller_info } );

	require Config;

	my $perl = Probe::Perl->new;

	$_[0]->set_run_info( 'root_working_dir', cwd()   );
	$_[0]->set_run_info( 'run_start_time',   time    );
	$_[0]->set_run_info( 'completed',        0       );
	$_[0]->set_run_info( 'pid',              $$      );
	$_[0]->set_run_info( 'ppid',             $_[0]->getppid );

	$_[0]->set_run_info( 'indexer',          ref $_[0] );
	$_[0]->set_run_info( 'indexer_versions', $_[0]->VERSION );

	$_[0]->set_run_info( 'perl_version',     $perl->perl_version );
	$_[0]->set_run_info( 'perl_path',        $perl->find_perl_interpreter );
	$_[0]->set_run_info( 'perl_config',      \%Config::Config );

	$_[0]->set_run_info( 'operating_system', $^O );
	$_[0]->set_run_info( 'operating_system_type', $perl->os_type );

	return 1;
	}

=item set_run_info( KEY, VALUE )

Set something to record about the run. This should only be information
specific to the run. See C<set_dist_info> to record dist info.

=cut

sub set_run_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $key, $value ) = @_;

	$logger->debug( "Setting run_info key [$key] to [$value]\n" );
	$self->{run_info}{$key} = $value;
	}

=item run_info( KEY )

Fetch some run info.

=cut

sub run_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $key ) = @_;

	$logger->debug( "Run info for $key is " . $self->{run_info}{$key} );
	$self->{run_info}{$key};
	}

=item clear_dist_info

Clear anything recorded about the distribution.

=cut

sub clear_dist_info
	{
	$logger->trace( sub { get_caller_info } );
	$logger->debug( "Clearing dist_info\n" );
	$_[0]->{dist_info} = {};
	}

=item setup_dist_info( DISTPATH )

Given a distribution path, record various data about it, such as its size,
mtime, and so on.

Sets these items in dist_info:
	dist_file
	dist_size
	dist_basename
	dist_basename
	dist_author

=cut

sub setup_dist_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $dist ) = @_;

	$logger->debug( "Setting dist [$dist]\n" );
	$self->set_dist_info( 'dist_file',     $dist                   );
	$self->set_dist_info( 'dist_size',     -s $dist                );
	$self->set_dist_info( 'dist_basename', basename($dist)         );
	$self->set_dist_info( 'dist_date',    (stat($dist))[9]         );
	$self->set_dist_info( 'dist_md5',     $self->get_md5_of_file_contents( $dist )  );
	$logger->debug( "dist size " . $self->dist_info( 'dist_size' ) .
		" dist date " . $self->dist_info( 'dist_date' )
		);

	my $c = '[A-Z0-9-]';
	my( undef, undef, $author ) = $dist =~ m|/($c)/\1($c)/(\1\2$c*)/|;
	$self->set_dist_info( 'dist_author', $author );
	$logger->debug( "dist author [$author]" );

	return unless $self->check_dist_size;

	return 1;
	}

=item check_dist_size

Some indexers might want to stop if the dist size is 0 (or some other value).
In particular, you can't unpack zero byte dists, so if you are expecting to
look at the dist files, a 0 sized dist is a problem.

=cut

sub check_dist_size
	{
	my( $self ) = @_;

        unless( $self->dist_info( 'dist_size' ) )
                {
                $logger->error( "Dist size was 0!" );
                $self->set_run_info( 'fatal_error', "Dist size was 0!" );
                return;
                }

	1;
	}

=item set_dist_info( KEY, VALUE )

Set something to record about the distribution. This should only be information
specific to the distribution. See C<set_run_info> to record run info.

=cut

sub set_dist_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $key, $value ) = @_;

	my $display = $self->_display_value( $value );
	$logger->debug( "Setting dist_info key [$key] to [$display]\n" );
	$self->{dist_info}{$key} = $value;
	}

sub _display_value
	{
	local $Data::Dumper::Terse = 1;
	chomp( my $v = Data::Dumper::Dumper( $_[1] ) );
	$v;
	}


=item dist_info( KEY )

Fetch some distribution info.

=cut

sub dist_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $key ) = @_;

	$logger->warn( "There is $key in dist_info"  )
		unless exists $self->{dist_info}{$key};

	$logger->debug(
		"dist info for $key is " .
		$self->_display_value ( $self->{dist_info}{$key} )
		);
	$self->{dist_info}{$key};
	}

=item unpack_dist( DISTPATH )

Given a distribution path, this determines the archive type, unpacks
it into a temporary directory, and records what it did.

Sets these items in dist_info:

	dist_archive_type
	dist_extract_path

Sets these items in run_info, when appropriate:

	unpack_dist_archive_zip_error
	extraction_error

This method returns false if any of these steps fail:

=over 4

=item * The distribution file is not there

=item * The distribution file does not uncompress

=item * The archive does not unpack

=item * The archive unpacks, but there are no files in the extraction directory

=back

=cut

sub unpack_dist
	{
	my $self = shift;
	$logger->trace( sub { get_caller_info } );

	$self->_patch_extractors;

	my $dist = $self->dist_info( 'dist_file' );
	$logger->debug( "Unpacking dist $dist" );

	return unless $self->get_unpack_dir;

	my $extractor = $self->_create_extractor( $dist );
	return unless $extractor;

	my $result = $self->_extract( $extractor );
	return unless $result;

	$self->_unpatch_extractors;

	$self->set_dist_info( 'dist_extract_path', $extractor->extract_path );

	1;
	}

BEGIN {
# This little bit gets around the limits of dynamic scope and refactoring.
# I move this all out of the unpack_dist
my %stash;
require Archive::Tar;
require Archive::Extract;
require Archive::Zip;

my @refs = (
	\ $Archive::Extract::DEBUG,
	\ $Archive::Extract::PREFER_BIN,
	\ $Archive::Extract::WARN,
	\ $Archive::TAR::WARN,
	);

sub _archive_extract_subclass {
	my $class = 'Archive::Extract::Libarchive';
	eval "use $class; 1";
	$class;
	}

sub _patch_extractors
	{
	$logger->trace( sub { get_caller_info } );

	my( $self ) = @_;

	return;
	}

sub _unpatch_extractors
	{
	$logger->trace( sub { get_caller_info } );

	foreach my $key ( keys %stash ) {
		my( $value, $variable_ref ) = @{ $stash{ $key } };
		$$variable_ref = $value;
		}
	}

sub _set_stash
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $variable_ref, $value ) = @_;

	$stash{ $variable_ref } = [
		@_ == 3 ? $value : $$variable_ref,
		$variable_ref
		];
	}

}

sub _create_extractor
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $dist ) = @_;

	my $subclass = $self->_archive_extract_subclass;

	my $extractor = eval { $subclass->new( archive => $dist ) };
	my $error = $@;

	unless( ref $extractor )
		{
		$logger->error( "Could not create Archive::Extract object for $dist [$error]" );
		$self->set_dist_info( 'dist_archive_type', 'unknown' );
		return;
		}

	my $type = $dist =~ s/.*\.//r;

	$self->set_dist_info( 'dist_archive_type', $type );

	$extractor;
	}

sub _extract
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $extractor ) = @_;

	my $dist = basename( $extractor->archive );

	$logger->debug( "About to extract $dist" );
	my $rc = $extractor->extract( to => scalar $self->dist_info( 'unpack_dir' ) );
	$logger->debug( "Archive::Extract returns [$rc] for $dist" );

	# I should fail here, but Archive::Extract 0.26 on Windows fails
	# even when it succeeds, so just log the error and keep going
	# if Windows reports a failure
	unless( $rc )
		{
		$self->set_dist_info( 'extraction_error', $extractor->error );
		$logger->error( "Archive::Extract could not extract $dist" );
		return;
		}

	$rc;
	}

=item get_unpack_dir

Get a directory where you can unpack the archive.

Sets these items in dist_info:

	unpack_dir

=cut

sub get_unpack_dir
	{
	$logger->trace( sub { get_caller_info } );

	require File::Temp;

	my $self = shift;

	( my $prefix = __PACKAGE__ ) =~ s/::/-/g;

	$logger->debug( "Preparing temp dir\n" );
	my $unpack_dir = eval { File::Temp::tempdir(
		$prefix . "-$$.XXXX",
		DIR     => $self->run_info( 'root_working_dir' ),
		CLEANUP => 1,
		) };

	if( $@ )
		{
		$logger->error( "Temp dir error: $@" );
		return;
		}

	$self->set_dist_info( 'unpack_dir', $unpack_dir );


	$logger->debug( "Unpacking into directory [$unpack_dir]" );

	1;
	}

=item find_dist_dir

Looks at dist_info's unpack_dir and guesses where the module distribution
is. This accounts for odd archiving people may have used, like putting all
the good stuff in a subdirectory.

Sets these items in dist_info:
	dist_dir

=cut

sub find_dist_dir {
	my( $self ) = @_;

	$logger->trace( sub { get_caller_info } );

	$logger->debug( "find_dist_dir cwd is " . $_[0]->dist_info( "unpack_dir" ) );

	my $dist_dir;
	foreach my $technique ( @{ $self->find_dist_dir_techniques } ) {
		$dist_dir = $self->$technique();
		$logger->debug( "find_dist_dir technique [$technique] returned [$dist_dir]" );
		last if defined $dist_dir;
		}

	unless( defined $dist_dir ) {
		$logger->debug( "find_dist_dir didn't find anything that looks like a module directory!" );
		return;
		}

	$self->set_dist_info( 'dist_dir', $dist_dir );

	return 1;
	}

sub find_dist_dir_techniques {
	[ qw(
		_try_unpack_dir
		_try_lower_dirs
		_try_module_at_top
		)
	];
	}

sub _try_unpack_dir {
	my( $self ) = @_;

	my @files = qw( MANIFEST Makefile.PL Build.PL META.yml );

	if( grep { -e } @files ) {
		$logger->debug( "Found dist dir with _try_unpack_dir" );
		return $self->dist_info( "unpack_dir" );
		}

	return;
	}

sub _try_lower_dirs {
	my( $self ) = @_;

	require File::Find::Closures;
	require File::Find;

	my @files = qw( MANIFEST Makefile.PL Build.PL META.yml );

	my( $wanted, $reporter ) =
		File::Find::Closures::find_by_directory_contains( @files );

	File::Find::find( $wanted, $self->dist_info( "unpack_dir" ) );

	# we want the shortest path
	my @found = sort { length $a <=> length $b } $reporter->();
	$logger->debug( "_try_lower_dirs found files [@found]" );

	$logger->debug( "_try_lower_dirs found dist file at [$found[0]]" );

	unless( $found[0] ) {
		$logger->debug( "_try_lower_dirs didn't find anything that looks like a module directory!" );
		return;
		}

	if( chdir $found[0] ) {
		$logger->debug( "_try_lower_dirs found module directory at $found[0]" );
		return $found[0];
		}

	return;
	}

sub _try_module_at_top {
	my( $self ) = @_;

	require File::Find::Closures;
	require File::Find;
	use File::Basename;

	$logger->debug( "Did not find dist directory at top level" );
	my( $wanted, $reporter ) =
		File::Find::Closures::find_by_regex( qr/\.p[ml]\z/ );

	File::Find::find( $wanted, $self->dist_info( "unpack_dir" ) );

	# we want the shortest path
	my @found = map { dirname($_) } sort { length $a <=> length $b } $reporter->();

	if( $found[0] ) {
		$logger->debug( "_try_module_at_top found $found[0]" );
		return $found[0];
		}
	else {
		$logger->debug( "_try_module_at_top did not find anything" );
		return;
		}

	}

=item get_file_list

Returns as an array reference the list of files in MANIFEST.

Sets these items in dist_info:
	manifest

=cut

sub get_file_list {
	$logger->trace( sub { get_caller_info } );

	$logger->debug( "Cwd is " . cwd() );

=pod

	unless( -e 'MANIFEST' or -e 'MANIFEST.SKIP' ) {
		$logger->error( "No Makefile.PL or Build.PL" );
		$_[0]->set_dist_info( 'manifest', [] );

		return;
		}

=cut

	require ExtUtils::Manifest;

	my $manifest = [ sort keys %{ ExtUtils::Manifest::manifind() } ];
	$logger->debug( "manifest is [ ", join( "|", @$manifest ), " ]" );
	$_[0]->set_dist_info( 'manifest', [ @$manifest ] );

	my @file_info = map {
		$logger->debug( "Getting file info for $_" );
		$_[0]->get_file_info( $_ )
		} @$manifest;

	$_[0]->set_dist_info( 'manifest_file_info', [ @file_info ] );

	$manifest;
	}

=item get_file_info( FILE )

Collect various meta-information about a file and store it in a
hash. Returns the hash reference.

=cut

sub get_file_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $file ) = @_;

	# get file name as key
	my $hash = { name => $file };

	# file digest
	$hash->{md5} = $self->get_md5_of_file_contents( $file );

	# mtime
	$hash->{mtime} = ( stat $file )[9];

	# file size
	$hash->{bytesize} = -s _;

	# file magic
	$hash->{file_mime_type} = $self->file_magic( $file );

	# line count signature
	$hash->{line_count} = $self->count_lines( $file );

	$hash;
	}

=item get_blib_file_list

Returns as an array reference the list of files in blib. You need to call
something like C<run_build_file> first.

Sets these items in dist_info:
	blib

=cut

sub get_blib_file_list
	{
	$logger->trace( sub { get_caller_info } );

	unless( -d catfile( qw(blib lib) ) )
		{
		$logger->info( "No blib/lib found for " . $_[0]->dist_info( 'dist_basename' ) );
		$_[0]->set_dist_info( 'blib', [] );

		return;
		}

	require ExtUtils::Manifest;

	my $blib = [ grep { m|^blib/| and ! m|.exists$| }
		sort keys %{ ExtUtils::Manifest::manifind() } ];

	$_[0]->set_dist_info( 'blib', $blib );
	}

=item look_in_lib

Look in the lib/ directory for .pm files.

=cut

sub look_in_lib  { $_[0]->_look_in_dirs( 'lib' );  }
sub look_in_blib { $_[0]->_look_in_dirs( 'blib' ); }

sub _look_in_dirs
	{
	my( $self, @directories ) = @_;

	$logger->trace( sub { get_caller_info } );

	require File::Find::Closures;
	require File::Find;

	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.pm\z/ );
	File::Find::find( $wanted, @directories );

	my @modules = $reporter->();
	unless( @modules )
		{
		$logger->debug( "Did not find any modules in @directories" );
		return;
		}

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}

=item look_in_cwd

Look for .pm files in the current workign directory (and not
in sub-directories). This is more common in older Perl modules.

=cut

sub look_in_cwd
	{
	$logger->trace( sub { get_caller_info } );

	my @modules = glob( "*.pm" );

	unless( @modules )
		{
		$logger->debug( "Did not find any modules in cwd" );
		return;
		}

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}

=item look_in_cwd_and_lib

This is instantly deprecated. It's glue until I can figure out a
better solution.

=cut

sub look_in_cwd_and_lib
	{
	$logger->trace( sub { get_caller_info } );

	$_[0]->_look_in_dirs( 'lib' );

	my $lib_modules = $_[0]->dist_info( 'modules' ) || [];

	my @modules = glob( "*.pm" );

	unless( @modules )
		{
		$logger->debug( "Did not find any modules in cwd" );
		}

	push @modules, @$lib_modules;
	unless( @modules )
		{
		$logger->debug( "Did not find any modules in cwd and lib" );
		return;
		}

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}


=item look_in_meta_yml_provides

As an almost-last-ditch effort, decide to beleive META.yml if it
has a provides entry. There's no reason to trust that the
module author has told the truth since he is only interested in
advertising the parts he wants you to use.

=cut

sub look_in_meta_yml_provides
	{
	$logger->trace( sub { get_caller_info } );

	unless( -e 'META.yml' )
		{
		$logger->debug( "Did not find a META.yml, so can't check provides" );
		return;
		}

	my $yaml = $_[0]->_load_meta_yml( 'META.yml' );

	return unless exists $yaml->{provides};

	my $provides = $yaml->{provides};

	my @modules = ();
	foreach my $key ( keys %$provides )
		{
		my( $namespace, $file, $version ) =
			( $key, @{$provides->{$key}}{qw(file version)} );

		push @modules, $file;
		}

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}

=item look_for_pm

This is a last ditch effort to find modules by looking everywhere, starting
in the current working directory.

=cut

sub look_for_pm
	{
	$logger->trace( sub { get_caller_info } );

	require File::Find::Closures;
	require File::Find;

	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.pm\z/ );
	File::Find::find( $wanted, cwd() );

	my @modules = $reporter->();
	unless( @modules )
		{
		$logger->debug( "Did not find any modules in lib" );
		return;
		}

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}

=item parse_meta_files

Parses the META.yml and returns the YAML object.

Sets these items in dist_info:
	META.yml

=cut

sub parse_meta_files
	{
	$logger->trace( sub { get_caller_info } );

	my $self = shift;

	$logger->debug( 'Parsing META.yml for ' . $self->dist_info( 'dist_basename' ) );
	$logger->debug( 'Working directory is ' . cwd() );

	my $generated_meta_file = eval{ $self->make_meta_file };
	$logger->error( $@ ) if $@;
	$logger->debug( "generated META is file $generated_meta_file" );

	my( $meta_file ) = grep { -e } ( 'META.yml', $generated_meta_file );
	$logger->info( "Using META file $meta_file for " . $self->dist_info( 'dist_basename' ) );
	$self->set_dist_info( 'meta_file', $meta_file );
	$self->set_dist_info( 'generated_meta_file', $generated_meta_file );

	if( defined $meta_file )
		{
		my $yaml = $self->_load_meta_yml( $meta_file );
		unless( ref $yaml->{author} ) {
			$yaml->{author} = [ $yaml->{author} ];
			}
		$logger->debug( "YAML author is $yaml->{author}[0]" );
		$self->set_dist_info( 'META.yml', $yaml ) if $yaml;
		return $yaml;
		}
	else
		{
		$logger->info( "Did not find a META.yml for " . $self->dist_info( 'dist_basename' ) );
		}

	return;
	}

sub _path_yaml_base { # We might not need this anymore
	my $self = shift;

	local *YAML::Base::die = sub {
		my $yaml = shift;
		require YAML::Error;

		my $code  = shift || 'unknown error';
		my $error = YAML::Error->new(code => $code);
		$error->line($yaml->line) if $yaml->can('line');
		$error->document($yaml->document) if $yaml->can('document');
		$error->arguments([@_]);
		$error->type('Error');

		my $warning = $error->format_message;

		$logger->warn( $warning );
		$self->set_run_info( 'parse_meta_files_yaml_error', $warning );
		};
}

sub _load_meta_yml { $_[0]->_try_utf8( $_[1] ) || $_[0]->_try_latin1( $_[1] ) }

sub _try_utf8 {
	$_[0]->_load_yaml( $_[0]->_load_file( 'utf8', $_[1] ) ) }

sub _try_latin1 {
	require Encode;
	Encode::from_to( my $utf8 = $_[0]->_load_file( 'bytes', $_[1] ), 'latin1', 'utf8' );
	$_[0]->_load_yaml( $utf8 );
	}

sub _load_file {
	require Encoding::FixLatin;
	$logger->debug( "Trying to load $_[2] as $_[1]" );
	local $/; open my $f, "<:$_[1]", $_[2];
	my $content = scalar <$f>;
	}

sub _load_yaml {
	require YAML::XS;
	my( $caller ) = ( caller(1) )[3];
	my $yaml = eval { YAML::Syck::Load( $_[1] ) } or
		$logger->error( "$caller: $@" );
	$yaml;
	}

=item find_module_techniques

Returns a list of 2-element anonymous arrays that lists method names
and string descriptions of the way that the C<find_modules>
should look for module files.

If you don't like the techniques, such as C<run_build_file>, you can
overload this and return a different set of techniques.

=cut

sub find_module_techniques
	{
	my @methods = (
		[ 'run_build_file', "Got from running build file"  ],
		[ 'look_in_blib',   "Guessed from looking in blib/"  ],
		[ 'look_in_lib',    "Guessed from looking in lib/" ],
		[ 'look_in_cwd',    "Guessed from looking in cwd"  ],
		[ 'look_in_meta_yml_provides',    "Guessed from looking in META.yml"  ],
		[ 'look_for_pm',    "Guessed from looking in cwd"  ],
		);
	}

=item find_modules

Find the module files. First, look in C<blib/>. If there are no files in
C<blib/>, look in C<lib/>. If there are still none, look in the current
working directory.

=cut

sub find_modules
	{
	$logger->trace( sub { get_caller_info } );

	my @methods = $_[0]->find_module_techniques;

	foreach my $tuple ( @methods )
		{
		my( $method, $message ) = @$tuple;
		next unless $_[0]->$method();
		$logger->debug( $message );
		return 1;
		}

	return;
	}

=item find_tests

Find the test files. Look for C<test.pl> or C<.t> files under C<t/>.

=cut

sub find_tests
	{
	$logger->trace( sub { get_caller_info } );

	require File::Find::Closures;
	require File::Find;

	my @tests;

	push @tests, 'test.pl' if -e 'test.pl';

	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.t$/ );
	File::Find::find( $wanted, "t" );

	push @tests, $reporter->();
	$logger->debug( "Found tests [@tests]" );

	$_[0]->set_dist_info( 'tests', [ @tests ] );

	return scalar @tests;
	}

=item run_build_file

This method is one stop shopping for calls to C<choose_build_file>,
C<setup_build>, C<run_build>.

=cut

sub run_build_file
	{
	$logger->trace( sub { get_caller_info } );

	foreach my $method ( qw(
		choose_build_file setup_build run_build get_blib_file_list ) )
		{
		$logger->debug( "Running $method for " . $_[0]->dist_info( 'dist_basename' ) );
		$_[0]->$method() or return;
		}

	my @modules = grep /\.pm$/, @{ $_[0]->dist_info( 'blib' ) };
	$logger->debug( "Modules are @modules\n" );

	$_[0]->set_dist_info( 'modules', [ @modules ] );

	return 1;
	}

=item choose_build_file

Guess what the build file for the distribution is, using
C<Distribution::Guess::BuildSystem>.

Sets these items in dist_info:

	build_file         - the build file to use
	build_system_guess - the Distribution::Guess::BuildSystem object

=cut

sub choose_build_file
	{
	$logger->trace( sub { get_caller_info } );

	require Distribution::Guess::BuildSystem;

	my $guesser = Distribution::Guess::BuildSystem->new(
		dist_dir => $_[0]->dist_info( 'dist_dir' )
		);

	$_[0]->set_dist_info(
		'build_system_guess',
		$guesser
		);

	my $file = eval { $guesser->preferred_build_file };
	$logger->debug( "Build file is $file" );
	$logger->debug( "At is $@" ) if $@;
	unless( defined $file )
		{
		$logger->error( "Did not find a build file" );
		return;
		}

	$_[0]->set_dist_info( 'build_file', $file );

	return 1;
	}

=item setup_build

Runs the build setup file (Build.PL, Makefile.PL) to prepare for the
build. You need to run C<choose_build_file> first.

Sets these items in dist_info:

	build_file_output

=cut

sub setup_build
	{
	$logger->trace( sub { get_caller_info } );

	my $program = $_[0]->dist_info( 'build_file' );

	$_[0]->run_perl_program( $program, 'build_file_output' );
	}

=item run_build

Run the build file (Build.PL, Makefile). Run C<setup_build> first.

Sets these items in dist_info:

	build_output

=cut

sub run_build
	{
	$logger->trace( sub { get_caller_info } );

	my $guesser = $_[0]->dist_info( 'build_system_guess' );

	$logger->debug( "Guesser is [" . Dumper( $guesser ) . "]" );
	my $build_command = $guesser->preferred_build_command;

	$logger->debug( "preferred build command is [$build_command]" );

	$_[0]->run_something( $build_command, 'build_output' );

=pod

# Why is this here and how is it different from what I just did?

	my( $runner ) = grep { -e } qw( ./Build Makefile );
	$logger->debug( "runner is [$runner]" );

	$_[0]->run_something( $runner, 'build_modules_output' ) if $runner;

=cut

	return 1;
	}

=item make_meta_file

Run the build file (Build.PL, Makefile) to create the META.yml file.
Run C<setup_build> first.

Sets these items in dist_info:
	build_meta_output
	make_meta_file_output

=cut

sub make_meta_file
	{
	$logger->trace( sub { get_caller_info } );

	my $file = $_[0]->dist_info( 'build_file' );
	$logger->debug( "build file in make_meta_file is $file" );
	unless( $file )
		{
		$logger->error( "There's nothing in build_file! Can't try to make the meta files" );
		return;
		}

	$_[0]->run_build_target( 'distdir' );

	my @meta_files = glob( "*/META.yml" );
	$logger->debug( "Found META.ymls at [@meta_files]" );

	return $meta_files[0];
	}

=item run_something( COMMAND, KEY )

Run the shell command and record the output in the dist_info for KEY. This
merges the outputs into stdout and closes stdin by redirecting /dev/null into
COMMAND.

=cut

sub run_something
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $command, $info_key ) = @_;

	$self->set_dist_info( "${info_key}_command", $command );

	require IPC::Open3;
	my $pid = IPC::Open3::open3( my( $in_fh, $out_fh, $err_fh ), $command );
	$logger->debug( "command [$command] starts as pid $pid" );

	close $in_fh;

	$logger->debug( "err_fh is defined before reading out_fh" )
		if defined $err_fh;

	$logger->debug( "Getting standard output" );
	my $output = $self->_get_output( $out_fh, 1024 );
	$logger->debug( "command [$command] outputs [$$output]" );

	$logger->debug( "err_fh is defined after reading out_fh" )
		if defined $err_fh;

	$logger->debug( "Getting standard error" );
	my $error  = $self->_get_output( $err_fh, 1024 );
	$logger->debug( "command [$command] outputs error [$$error]" );

	$self->set_dist_info( $info_key, $$output );
	$self->set_dist_info( "${info_key}_error", $$error );
	waitpid $pid, 0;
	}

sub _get_output
	{
	my( $self, $fh, $byte_limit ) = @_;
	return \ '' unless defined $fh; # why is stderr undef?

	$byte_limit ||= 2048;
	$logger->warn( "filehandle is not defined!" ) unless defined $fh;

	my $output;
	while( ! eof( $fh ) and length $output < $byte_limit )
		{
		my $bytes_read = read $fh, my $buffer, 4096;
		$output .= $buffer;
		}

	if( ! eof $fh )
		{
		$logger->warn( "Output exceeded [$byte_limit] bytes. Truncating and closing" );
		close $fh;
		$output .= "[truncated to $byte_limit]";
		}

	return \$output;
	}

=item run_build_target( TARGET )

Run the shell command and record the output in the dist_info for KEY. This
merges the outputs into stdout and closes stdin by redirecting /dev/null into
COMMAND.

=cut

sub run_build_target
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $target ) = @_;

	$self->run_build;

	my $guesser = $self->dist_info( 'build_system_guess' );

	my $command = join ' ',
		$guesser->preferred_build_command,
		$target;

	$self->run_something( $command, "build_target_${target}_output"  );

	return 1;
	}

=item run_perl_program( PROGRAM, KEY )

Run the shell command and record the output in the dist_info for KEY. This
merges the outputs into stdout and closes stdin by redirecting /dev/null into
COMMAND.

=cut

sub run_perl_program
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $program, $key ) = @_;

	my $coordinator = $self->get_coordinator;
	my $config      = $coordinator->get_config;

	my $perl = $config->perl || $^X;

	$self->run_something( "$perl $program", $key );

	return 1;
	}

=item get_module_info_tasks

Returns a list of anonymous arrays that tell C<get_module_info> what
to do. Each anonymous array holds:

	0. method to call
	1. description of technique

The default list includes C<extract_module_namespaces>, C<extract_module_version>,
and C<extract_module_dependencies>. If you don't like that list, you can prune
or expand it in a subclass.

=cut

sub get_module_info_tasks
	{
	(
	[ 'extract_module_namespaces',   'Extract the namespaces a file declares' ],
	[ 'extract_module_version',      'Extract the version of the module'      ],
	[ 'extract_module_dependencies', 'Extract module dependencies'            ],
	)
	}

=item get_module_info( FILE )

Collect meta informantion and package information about a module
file. It starts by calling C<get_file_info>, then adds more to
the hash, including the version and package information.

=cut

sub get_modules_info
	{
    my $self = shift;
	my @file_info = ();
	foreach my $file ( @{ $self->dist_info( 'modules' ) } )
		{
		$logger->debug( "Processing module $file" );
		my $hash = $self->get_module_info( $file );
		push @file_info, $hash;
		}

	$self->set_dist_info( 'module_info', [ @file_info ] );
	}

sub get_module_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $file ) = @_;

	my $hash = $self->get_file_info( $file );

	$logger->debug( "get_module_info called with [$file]" );

	my @tasks = $self->get_module_info_tasks;

	foreach my $task ( @tasks )
		{
		my( $method, $description ) = @$task;
		$logger->debug( "get_module_info calling [$method]" );

		my $result = $self->$method( $file, $hash );

		unless( $result )
			{
			$logger->debug( "Problem with $method and $file" );
			$hash->{"${method}_error"} = "Problem with $method and $file";
			}
		}

	$hash;
	}

sub extract_module_namespaces
	{
	my( $self, $file, $hash ) = @_;

	require Module::Extract::Namespaces;

	my @packages = Module::Extract::Namespaces->from_file( $file );

	$logger->warn( "Didn't find any packages in $file" ) unless @packages;

	$hash->{packages} = [ @packages ];

	$hash->{module_name_from_file_guess} = $self->get_package_name_from_filename( $file );

	$hash->{primary_package} = $self->guess_primary_package( $hash->{packages}, $file );

	1;
	}

sub get_package_name_from_filename
	{
	my( $self, $file ) = @_;

	# some people do odd things in their distributions, like fork
	# modules. I'll try to guess the primary package by seeing if
	# there is a package that matches the file name.
	#
	# See, for instance, Module::Info and it's B::BUtil fork.
	( my $module = $file ) =~ s|.*(?:blib\b.)?lib\b.||g;
	$module =~ s/\.pm\z//;
	$module =~ s|[\\/]|::|g;

	$module;
	}

sub guess_primary_package
	{
	my( $self, $packages, $file ) = @_;

	# ignore packages that start with an underscore
	@$packages = grep { ! /\b_/ } @$packages;

	my $module = $self->get_package_name_from_filename( $file );

	my @matches = grep { $_ eq $module } @$packages;

	my $primary_package = $matches[0] || $packages->[0];

	return $primary_package;
	}

sub extract_module_version
	{
	my( $self, $file, $hash ) = @_;

	require Module::Extract::VERSION;

	my @keys = qw( sigil identifier value filename line_number );

	my @version_info = eval {
		local $SIG{__WARN__} = sub { die @_ };
		my @v = Module::Extract::VERSION->parse_version_safely( $file );
		};

	# I don't have a better way to know if nothing was found. I need
	# to fix that in Module::Extract::VERSION
	my $defined_count = grep defined, @version_info;

	my %v = ! $defined_count ? () :
		map  { $keys[$_] => $version_info[$_] } 0 .. $#keys;

	$v{error} = $@ if $@;

	$hash->{version_info} = \%v;

	return 0 if $@;

	1;
	}

sub extract_module_dependencies
	{
	my( $self, $file, $hash ) = @_;

	require Module::Extract::Use;

	my $use_extractor = Module::Extract::Use->new;

	my @uses = $use_extractor->get_modules( $file );
	if( $use_extractor->error )
		{
		$logger->error( "Could not extract uses for [$file]: " . $use_extractor->error );
		}

	$hash->{uses} = [ @uses ];

	1;
	}

=item get_test_info( FILE )

Collect meta informantion and package information about a test
file. It starts by calling C<get_file_info>, then adds more to
the hash, including the version and package information.

=cut

sub get_test_info
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $file ) = @_;

	my $hash = $self->get_file_info( $file );

	require Module::Extract::Use;
	my $extractor = Module::Extract::Use->new;
	my @uses = $extractor->get_modules( $file );

	$hash->{uses} = [ @uses ];

	$hash;
	}

=item count_lines( FILE )

Counts the lines in a file and categorizes them as code, comment, documentation, or blank.

This returns a hash:

	{
	total         => ...,
	code          => ...,
	comment       => ...,
	documentation => ...,
	blank         => ...,
	}

=cut

sub count_lines
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $file ) = @_;

	my $class = 'SourceCode::LineCounter::Perl';

	eval { eval "require $class" } or return;

	$self->set_run_info( 'line_counter_class', $class );
	$self->set_run_info( 'line_counter_version', $class->VERSION );

	$logger->debug( "Counting lines in $file" );
	$logger->error( "File [$file] does not exist" ) unless -e $file;

	my $counter = $class->new;
	$counter->count( $file );

	my $hash = {
		map { $_ => $counter->$_() }
		qw( total code comment documentation blank )
		};

	return $hash;
	}

=item file_magic( FILE )

Guesses and returns the MIME type for the file, using File::MMagic if
it's available. If that module is not available, it returns nothing.

=cut

sub file_magic
	{
	$logger->trace( sub { get_caller_info } );

	my( $self, $file ) = @_;

	my $class = "File::MMagic";

	eval { eval "require $class" } or return;

	$self->set_run_info( 'file_magic_class',   $class );
	$self->set_run_info( 'file_magic_version', $class->VERSION );

	$class->new->checktype_filename( $file );
	}

=back

=head2 Utility functions

These functions aren't related to examining a distribution
directly.

=over 4

=item cleanup

Removes the unpack_dir. You probably don't need this if C<File::Temp>
cleans up its own files.

=cut

sub cleanup
	{
	$logger->trace( sub { get_caller_info } );

	return 1;

	File::Path::rmtree(
		[
		$_[0]->run_info( 'unpack_dir' )
		],
		0, 0
		);

	return 1;
	}

=item report_dist_info

Write a nice report. This isn't anything useful yet. From your program,
take the object and dump it in some way.

=cut

sub report_dist_info
	{
	$logger->trace( sub { get_caller_info } );

	no warnings 'uninitialized';

	my $module_hash = $_[0]->dist_info( 'module_versions' );

	while( my( $k, $v ) = each %$module_hash )
		{
		print "$k => $v\n\t";
		}

	print "\n";
	}

=item get_caller_info

This method is mostly for the $logger->trace method in Log4perl. It figures out
which information to report in the log message, acconting for all the
levels or magic in between.

=cut

sub get_caller_info
	{
	require File::Basename;

	my(
		$package, $filename, $line, $subroutine, $hasargs,
		$wantarray, $evaltext, $is_require, $hints, $bitmask
		) = caller(4);

	$filename = File::Basename::basename( $filename );

	return join " : ", $package, $filename, $line, $subroutine;
	}

=item get_md5_of_file_contents

=cut

sub get_md5_of_file_contents
	{
	my( $self, $file ) = @_;

	require Digest::MD5;

	my $context = Digest::MD5->new;

	open my $fh, '<', $file or return;

	$context->addfile( $fh );
	lc $context->hexdigest;
	}

=item getppid

Get the parent process ID. This is a method because I have to do
special things for Windows. For Windows, just return -1 for now.

=cut

sub getppid
	{
	unless( $^O =~ /Win32/ ) { return CORE::getppid }
	-1;
	}

=back

=head1 TO DO

=over 4

=item Count the lines in the files. I think this is currently broken.

=item Code stats? Lines of code, lines of pod, lines of comments

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
