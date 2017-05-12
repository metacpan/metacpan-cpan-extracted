package Perl::Dist::WiX::Mixin::Support;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::Support - Provides support routines for building a Win32 perl distribution.

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::Support version 1.500002.

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.
  

=head1 DESCRIPTION

This module provides support methods for copying, extracting, and executing 
files, directories, and programs for L<Perl::Dist::WiX|Perl::Dist::WiX>.

=cut

#<<<
use 5.010;
use Moose;
use English                    qw( -no_match_vars );
use Archive::Tar          1.42 qw();
use Archive::Zip               qw( AZ_OK );
use Devel::StackTrace          qw();
use LWP::UserAgent             qw();
use File::Basename             qw();
use File::Find::Rule           qw();
use File::Path            2.08 qw();
use File::pushd                qw();
use File::Spec::Functions      qw( catdir catfile rel2abs catpath );
use File::Slurp                qw(read_file);
use IO::Compress::Bzip2  2.025 qw();
use IO::Compress::Gzip   2.025 qw();
#>>>

# IO::Uncompress::Xz is tested for later, as it's an 'optional'.

our $VERSION = '1.500002';



=head1 METHODS

=head2 dir

	my $dir = $dist->dir(qw(perl bin));

Returns the subdirectory of the image directory with these components in 
order. 

=cut

sub dir {
	return catdir( shift->image_dir(), @_ );
}



=head2 file

	my $file = $dist->file(qw(perl bin perl.exe));

Returns the filename contained in the image directory with these components 
in order. 

=cut

sub file {
	return catfile( shift->image_dir(), @_ );
}



=head2 mirror_url

	my $file = $dist->mirror_url(
		'http://www.strawberryperl.com/strawberry-perl.zip',
		'C:\strawberry\',
	);
	
Downloads a file from the url in the first parameter to the directory in 
the second parameter.

Returns where the file was downloaded, including filename.

=cut

sub mirror_url {
	my ( $self, $url, $dir ) = @_;

	# If our caller was install_par, don't display anything.
	my $no_display_trace = 0;
	my (undef, undef, undef, $sub,  undef,
		undef, undef, undef, undef, undef
	) = caller 0;
	if ( $sub eq 'install_par' ) { $no_display_trace = 1; }

	# Check if the file already is downloaded.
	my $file = $url;
	$file =~ s{.+\/} # Delete anything before the last forward slash.
			  {}msx; ## (leaves only the filename.)
	my $target = catfile( $dir, $file );

	if ( $self->offline() and -f $target ) {
		return $target;
	}

	# Error out - we can't download.
	if ( $self->offline() and not $url =~ m{\Afile://}msx ) {
		PDWiX->throw("Currently offline, cannot download $url.\n");
	}

	# Create the directory to download to if required.
	File::Path::mkpath($dir);

	# Now download the file.
	$self->trace_line( 2, "Downloading file $url...\n", $no_display_trace );
	if ( $url =~ m{\Afile://}msx ) {

		# Don't use WithCache for files (it generates warnings)
		my $ua = LWP::UserAgent->new();
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} else {

		my $ua = $self->user_agent();
		my $r = $ua->mirror( $url, $target );
		if ( $r->is_error ) {
			$self->trace_line( 0,
				"    Error getting $url:\n" . $r->as_string . "\n" );
		} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
			$self->trace_line( 2, "(already up to date)\n",
				$no_display_trace );
		}
	} ## end else [ if ( $url =~ m{\Afile://}msx)]

	# Return the location downloaded to.
	return $target;
} ## end sub mirror_url



=head2 copy_file

	# Copy a file to a directory.
	$dist->copy_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\'
	);

	# Copy a file to a file.
	$dist->copy_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\perl.exe'
	);
	
	# Copy a directory to a directory.
	$dist->copy_file(
		'C:\strawberry\license\',
		'C:\strawberry\text\'
	);
	
Copies a file or directory into a directory, or a file to another file.

If you are copying a file, the destination file already exists, and the 
destination file is not writable, the destination is temporarily set 
to be writable, the copy is performed, and the destination is set to 
read-only.

=cut

sub copy_file {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	if ( not -e $basedir ) {
		File::Path::mkpath($basedir);
	}
	$self->trace_line( 2, "Copying $from to $to\n" );

	if ( -f $to and not -w $to ) {
		require Win32::File::Object;

		# Make sure it isn't readonly
		my $file = Win32::File::Object->new( $to, 1 );
		my $readonly = $file->readonly();
		$file->readonly(0);

		# Do the actual copy
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");

		# Set it back to what it was
		$file->readonly($readonly);
	} else {
		File::Copy::Recursive::rcopy( $from, $to )
		  or PDWiX->throw("Copy error: $OS_ERROR");
	}
	return 1;
} ## end sub copy_file



=head2 move_file

	# Move a file into a directory.
	$dist->move_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\'
	);

	# Move a file to a file.
	$dist->move_file(
		'C:\strawberry\perl\bin\perl.exe',
		'C:\strawberry\perl\lib\perl.exe'
	);
	
	# Move a directory to a directory.
	$dist->move_file(
		'C:\strawberry\license\',
		'C:\strawberry\text\'
	);

Moves a file or directory into a directory, or a file to another file.

=cut

sub move_file {
	my ( $self, $from, $to ) = @_;
	my $basedir = File::Basename::dirname($to);
	if ( not -e $basedir ) {
		File::Path::mkpath($basedir);
	}
	$self->trace_line( 2, "Moving $from to $to\n" );
	File::Copy::Recursive::rmove( $from, $to )
	  or PDWiX->throw("Move error: $OS_ERROR");

	return;
} ## end sub move_file



=head2 push_dir

	my $dir = $dist->push_dir($dist->image_dir(), qw(perl bin));

Changes the current directory to the location specified by the
components passed in.

When the object that is returned (a L<File::pushd|File::pushd> 
object) is destroyed, the current directory is changed back to
the previous value.

=cut 

sub push_dir {
	my $self = shift;
	my $dir  = catdir(@_);
	$self->trace_line( 2, "Lexically changing directory to $dir...\n" );
	return File::pushd::pushd($dir);
}



=head2 execute_build

	$dist->execute_build('install');

Executes a Module::Build script with the options given (which can be
empty).

=cut 

sub execute_build {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', 'Build.bat', @params ) . qq{\n} );
	$self->execute_any( 'Build.bat', @params )
	  or PDWiX->throw('build failed');

	if ( $CHILD_ERROR >> 8 ) {
		PDWiX->throw('build failed (OS error)');
	}
	return 1;
} ## end sub execute_build



=head2 execute_make

	$dist->execute_make('install');

Executes a ExtUtils::MakeMaker-generated makefile with the options given 
(which can be empty) using the C<dmake> being installed.

=cut 

sub execute_make {
	my $self   = shift;
	my @params = @_;
	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_make(), @params ) . qq{\n} );
	$self->execute_any( $self->bin_make(), @params )
	  or PDWiX->throw('make failed');

	if ( $CHILD_ERROR >> 8 ) {
		PDWiX->throw('make failed (OS error)');
	}
	return 1;
} ## end sub execute_make



=head2 execute_perl

	$self->execute_perl('Build.PL', 'INSTALLDIR=vendor');

Executes a perl script (given in the first parameter) with the 
options given using the perl being installed.

=cut 

sub execute_perl {
	my $self   = shift;
	my @params = @_;

	if ( not -x $self->bin_perl() ) {
		PDWiX->throw( q{Can't execute } . $self->bin_perl() );
	}

	$self->trace_line( 2,
		join( q{ }, '>', $self->bin_perl(), @params ) . qq{\n} );
	$self->execute_any( $self->bin_perl(), @params )
	  or PDWiX->throw('perl failed');
	if ( $CHILD_ERROR >> 8 ) {
		PDWiX->throw('perl failed (OS error)');
	}
	return 1;
} ## end sub execute_perl



=head2 execute_any

	$self->execute_any('dmake');
	
Executes a program, saving the STDOUT and STDERR in the files specified by
C<debug_stdout()> and C<debug_stderr()>.

=cut 

sub execute_any {
	my $self = shift;

	# Remove any Perl installs from PATH to prevent
	# "which" discovering stuff it shouldn't.
	my @path = split /;/ms, $ENV{PATH};
	my @keep = ();
	foreach my $p (@path) {

		# Strip any path that doesn't exist
		next if not -d $p;

		# Strip any path that contains either dmake or perl.exe.
		# This should remove both the ...\c\bin and ...\perl\bin
		# parts of the paths that Vanilla/Strawberry added.
		next if -f catfile( $p, 'dmake.exe' );
		next if -f catfile( $p, 'perl.exe' );

		# Strip any path that contains either unzip or gzip.exe.
		# These two programs cause perl to fail its own tests.
		next if -f catfile( $p, 'unzip.exe' );
		next if -f catfile( $p, 'gzip.exe' );

		push @keep, $p;
	} ## end foreach my $p (@path)

	# Reset the environment
	local $ENV{'LIB'}               = undef;
	local $ENV{'INCLUDE'}           = undef;
	local $ENV{'PERL5LIB'}          = undef;
	local $ENV{'PERL_YAML_BACKEND'} = undef;
	local $ENV{'PERL_JSON_BACKEND'} = undef;
	local $ENV{'PATH'} = $self->get_path_string() . q{;} . join q{;}, @keep;

	$self->trace_line( 3, "Path during execute_any: $ENV{PATH}\n" );

	my $output_dir = $self->output_dir()->stringify();
	if ( not -d $output_dir ) {
		$self->make_path($output_dir);
	}

	# TODO: Look into IPC::Run::Fused.
	# Execute the child process
	return IPC::Run3::run3(
		[@_], \undef,
		$self->debug_stdout()->stringify(),
		$self->debug_stderr()->stringify(),
	);
} ## end sub execute_any



=head2 extract_archive

	$dist->extract_archive($archive, $to);

Extracts an archive file (set in the first parameter) to a specified 
directory (set in the second parameter).

The archive file must be a .tar.gz, .tar.bz2, .tar.xz, or .zip file.

=cut 

sub extract_archive {
	my ( $self, $from, $to ) = @_;
	File::Path::mkpath($to);
	my $wd = $self->push_dir($to);

	my @filelist;

	$self->trace_line( 2, "Extracting $from...\n" );
	if ( $from =~ m{[.] zip\z}msx ) {
		my $zip = Archive::Zip->new($from);

		if ( not defined $zip ) {
			PDWiX->throw("Could not open archive $from for extraction");
		}

# I can't just do an extractTree here, as I'm trying to
# keep track of what got extracted.
		my @members = $zip->members();

		foreach my $member (@members) {
			my $filename = $member->fileName();
			$filename = _convert_name($filename)
			  ;                        # Converts filename to Windows format.
			my $status = $member->extractToFileNamed($filename);
			if ( $status != AZ_OK ) {
				PDWiX->throw('Error in archive extraction');
			}
			push @filelist, $filename;
		}

	} elsif ( $from =~
		m{ [.] tar [.] gz | [.] tgz [.] | tar [.] bz2 | [.] tbz }msx )
	{
		local $Archive::Tar::CHMOD = 0;
		my @fl = @filelist = Archive::Tar->extract_archive( $from, 1 );
		@filelist = map { catfile( $to, $_ ) } @fl;
		if ( !@filelist ) {
			PDWiX->throw('Error in archive extraction');
		}

	} elsif ( $from =~ m{ [.] tar [.] xz | [.] txz}msx ) {

		# First attempt at trying to use .xz files. TODO: Improve.
		eval {
			require IO::Uncompress::UnXz;
			IO::Uncompress::UnXz->VERSION(2.025);
			1;
		}
		  or PDWiX->throw(
"Tried to extract the file $from without the xz libraries installed."
		  );

		local $Archive::Tar::CHMOD = 0;
		my $xz = IO::Uncompress::UnXz->new( $from, BlockSize => 16_384 );
		my @fl = @filelist = Archive::Tar->extract_archive($xz);
		@filelist = map { catfile( $to, $_ ) } @fl;
		if ( !@filelist ) {
			PDWiX->throw('Error in archive extraction');
		}

	} else {
		PDWiX->throw("Didn't recognize archive type for $from");
	}

	return @filelist;
} ## end sub extract_archive

sub _convert_name {
	my $name     = shift;
	my @paths    = split m{\/}ms, $name;
	my $filename = pop @paths;
	if ( not defined $filename ) {
		$filename = q{};
	}
	my $local_dirs = @paths ? catdir(@paths) : q{};
	my $local_name = catpath( q{}, $local_dirs, $filename );
	$local_name = rel2abs($local_name);
	return $local_name;
} ## end sub _convert_name

sub _extract_filemap { ## no critic(ProhibitUnusedPrivateSubroutines)
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	my @files;

	if ( $archive =~ m{[.] zip\z}msx ) {

		@files =
		  $self->_extract_filemap_zip( $archive, $filemap, $basedir,
			$file_only );

	} elsif ( $archive =~
		m{[.] tar [.] gz | [.] tgz | [.] tar [.] bz2 | [.] tbz }msx )
	{
		local $Archive::Tar::CHMOD = 0;
		my $tar = Archive::Tar->new($archive);
		for my $file ( $tar->get_files() ) {
			my $f       = $file->full_path();
			my $canon_f = File::Spec::Unix->canonpath($f);
			for my $tgt ( keys %{$filemap} ) {
				my $canon_tgt = File::Spec::Unix->canonpath($tgt);
				my $t;

#<<<
				if ($file_only) {
					next if
					  $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E\z}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
										  {$filemap->{$tgt}}imsx;
				} else {
					next if
					  $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
										  {$filemap->{$tgt}}imsx;
				}
#>>>
				my $full_t = catfile( $basedir, $t );
				$self->trace_line( 2, "Extracting $f to $full_t\n" );
				$tar->extract_file( $f, $full_t );
				push @files, $full_t;
			} ## end for my $tgt ( keys %{$filemap...})
		} ## end for my $file ( $tar->get_files...)

	} elsif ( $archive =~ m{ [.] tar [.] xz | [.] txz}msx ) {

		# First attempt at trying to use .xz files. TODO: Improve.
		eval {
			require IO::Uncompress::UnXz;
			IO::Uncompress::UnXz->VERSION(2.025);
			1;
		}
		  or PDWiX->throw( "Tried to extract the file $archive "
			  . 'without the xz libraries installed.' );

		local $Archive::Tar::CHMOD = 0;
		my $xz = IO::Uncompress::UnXz->new( $archive, BlockSize => 16_384 );
		my $tar = Archive::Tar->new($xz);
		for my $file ( $tar->get_files() ) {
			my $f       = $file->full_path();
			my $canon_f = File::Spec::Unix->canonpath($f);
			for my $tgt ( keys %{$filemap} ) {
				my $canon_tgt = File::Spec::Unix->canonpath($tgt);
				my $t;

#<<<
				if ($file_only) {
					next if
					  $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E\z}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
										  {$filemap->{$tgt}}imsx;
				} else {
					next if
					  $canon_f !~ m{\A(?:[^/]+[/])?\Q$canon_tgt\E}imsx;
					( $t = $canon_f ) =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
										  {$filemap->{$tgt}}imsx;
				}
#>>>
				my $full_t = catfile( $basedir, $t );
				$self->trace_line( 2, "Extracting $f to $full_t\n" );
				$tar->extract_file( $f, $full_t );
				push @files, $full_t;
			} ## end for my $tgt ( keys %{$filemap...})
		} ## end for my $file ( $tar->get_files...)



	} else {
		PDWiX->throw("Didn't recognize archive type for $archive");
	}

	return @files;
} ## end sub _extract_filemap



sub _extract_filemap_zip {
	my ( $self, $archive, $filemap, $basedir, $file_only ) = @_;

	my @files;

	my $zip = Archive::Zip->new($archive);
	my $wd  = $self->push_dir($basedir);
	while ( my ( $f, $t ) = each %{$filemap} ) {
		$self->trace_line( 2, "Extracting $f to $t\n" );
		my $dest = catfile( $basedir, $t );

		my @members = $zip->membersMatching("^\Q$f");

		foreach my $member (@members) {
			my $filename = $member->fileName();
#<<<
			$filename =~
			  s{\A\Q$f}    # At the beginning of the string, change $f 
			   {$dest}msx; # to $dest.
#>>>
			$filename = _convert_name($filename);
			my $status = $member->extractToFileNamed($filename);

			if ( $status != AZ_OK ) {
				PDWiX->throw('Error in archive extraction');
			}
			push @files, $filename;
		} ## end foreach my $member (@members)
	} ## end while ( my ( $f, $t ) = each...)

	return @files;
} ## end sub _extract_filemap_zip


=head2 make_path

	$dist->make_path('perl\bin');

Creates a path if it does not already exist.
	
The path passed in is converted to an absolute path using 
L<File::Spec::Functions|File::Spec::Functions>::L<rel2abs()|File::Spec/rel2abs>
before creation occurs.

=cut 

sub make_path {
	my $class = shift;
	my $dir   = rel2abs(shift);
	my $err;
	if ( not -d $dir ) {
		File::Path::make_path( "$dir", { error => \$err, } );
		if ( @{$err} ) {
			my $errors = q{};
			for my $diag ( @{$err} ) {
				my ( $file, $message ) = %{$diag};
				if ( $file eq q{} ) {
					$errors .= "General error: $message\n";
				} else {
					$errors .= "Problem remaking $file: $message\n";
				}
			}
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to create directory, errors:\n$errors"
			);
		} ## end if ( @{$err} )
	} ## end if ( not -d $dir )
	if ( not -d $dir ) {
		PDWiX::Directory->throw(
			directory => $dir,
			message   => 'Failed to create directory, no information why'
		);
	}
	return $dir;
} ## end sub make_path



=head2 remake_path

	$dist->remake_path('perl\bin');

Creates a path, removing all the files in it if the path already exists.
	
The path passed in is converted to an absolute path using 
L<File::Spec::Functions|File::Spec::Functions>::L<rel2abs()|File::Spec/rel2abs>
before creation occurs.

=cut 

sub remake_path {
	my $class = shift;
	my $dir   = rel2abs(shift);
	my $err;
	if ( -d "$dir" ) {
		File::Path::remove_tree(
			"$dir",
			{   keep_root => 1,
				error     => \$err,
			} );
		my $e = $EVAL_ERROR;
		if ($e) {
			PDWiX::Directory->throw(
				dir => $dir,
				message =>
"Failed to remove directory during recreation, critical error:\n$e"
			);
		}
		if ( @{$err} ) {
			my $errors = q{};
			for my $diag ( @{$err} ) {
				my ( $file, $message ) = %{$diag};
				if ( $file eq q{} ) {
					$errors .= "General error: $message\n";
				} else {
					$errors .= "Problem removing $file: $message\n";
				}
			}
			PDWiX::Directory->throw(
				dir => $dir,
				message =>
"Failed to remove directory during recreation, errors:\n$errors"
			);
		} ## end if ( @{$err} )
	} ## end if ( -d "$dir" )
	if ( not -d "$dir" ) {
		File::Path::make_path( "$dir", { error => \$err, } );
		if ( @{$err} ) {
			my $errors = q{};
			for my $diag ( @{$err} ) {
				my ( $file, $message ) = %{$diag};
				if ( $file eq q{} ) {
					$errors .= "General error: $message\n";
				} else {
					$errors .= "Problem remaking $file: $message\n";
				}
			}
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to recreate directory, errors:\n$errors"
			);
		} ## end if ( @{$err} )
	} ## end if ( not -d "$dir" )
	if ( not -d "$dir" ) {
		PDWiX::Directory->throw(
			dir     => $dir,
			message => 'Failed to recreate directory, no information why'
		);
	}
	return $dir;
} ## end sub remake_path



=head2 remove_path

	$dist->remove_path('perl\bin');

Removes a path, removing all the files in it if the path already exists.

The path passed in is converted to an absolute path using 
L<File::Spec::Functions|File::Spec::Functions>::L<rel2abs()|File::Spec/rel2abs>
before deletion occurs.

=cut

sub remove_path {
	my $class = shift;
	my $dir   = rel2abs(shift);
	my $err;
	if ( -d "$dir" ) {
		File::Path::remove_tree(
			"$dir",
			{   keep_root => 0,
				error     => \$err,
			} );
		my $e = $EVAL_ERROR;
		if ($e) {
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to remove directory, critical error:\n$e"
			);
		}
		if ( @{$err} ) {
			my $errors = q{};
			for my $diag ( @{$err} ) {
				my ( $file, $message ) = %{$diag};
				if ( $file eq q{} ) {
					$errors .= "General error: $message\n";
				} else {
					$errors .= "Problem removing $file: $message\n";
				}
			}
			PDWiX::Directory->throw(
				dir     => $dir,
				message => "Failed to remove directory, errors:\n$errors"
			);
		} ## end if ( @{$err} )
	} ## end if ( -d "$dir" )

	return;
} ## end sub remove_path



=head2 make_relocation_file

	$dist->make_relocation_file('strawberry_merge_module.reloc.txt');
	
	$dist->make_relocation_file('strawberry_ui.reloc.txt', 
		'strawberry_merge_module.reloc.txt');
	
Creates a file to be input to relocation.pl.

The first file is created, and it includes all files in the .source file 
that actually exist, and adds all .packlist files that are not already
being processed for relocation in files after the first.

If there is no second parameter, the first file will include all
.packlist files existing to that point.

=cut 

sub make_relocation_file {
	my $self                      = shift;
	my $file                      = shift;
	my (@files_already_processed) = @_;

	## no critic(ProhibitComplexMappings ProhibitMutatingListFunctions)
	## no critic(ProhibitCaptureWithoutTest RequireBriefOpen)
	# TODO: Calm down on the no critics.

	# Get the input and output filenames.
	my $file_in  = $self->patch_pathlist()->find_file( $file . '.source' );
	my $file_out = $self->image_dir()->file($file);

	# Find files we're already assigned for relocation.
	my @filelist;
	my %files_already_relocating;
	foreach my $file_already_processed (@files_already_processed) {
		@filelist = read_file(
			$self->image_dir()->file($file_already_processed)->stringify()
		);
		shift @filelist;
		%files_already_relocating = (
			%files_already_relocating,
			map { m/\A([^:]*):.*\z/msx; $1 => 1 } @filelist
		);
	}

	# Find all the .packlist files.
	my @packlists_list =
	  File::Find::Rule->file()->name('.packlist')->relative()
	  ->in( $self->image_dir()->stringify() );
	my %packlists = map { s{/}{\\}msg; $_ => 1 } @packlists_list;

	# Find all the .bat files.
	my @batch_files_list =
	  File::Find::Rule->file()->name('*.bat')->relative()
	  ->in( $self->image_dir()->stringify() );
	my %batch_files = map { s{/}{\\}msg; $_ => 1 } @batch_files_list;

	# Get rid of the .packlist and *.bat files we're already relocating.
	delete @packlists{ keys %files_already_relocating };
	delete @batch_files{ keys %files_already_relocating };

	# Print the first line of the relocation file.
	my $file_out_handle;
	open $file_out_handle, '>', $file_out
	  or PDWiX::File->throw(
		file    => $file_out,
		message => 'Could not open.'
	  );
	print {$file_out_handle} $self->image_dir()->stringify();
	print {$file_out_handle} "\\\n";

	# Read the source file, writing out the files that actually exist.
	@filelist = read_file($file_in);
	foreach my $filelist_entry (@filelist) {
		$filelist_entry =~ m/\A([^:]*):.*\z/msx;
		if ( defined $1 and -f $self->image_dir()->file($1)->stringify() ) {
			print {$file_out_handle} $filelist_entry;
		}
	}

	# Print out the rest of the .packlist files.
	foreach my $pl ( sort { $a cmp $b } keys %packlists ) {
		print {$file_out_handle} "$pl:backslash\n";
	}

	# Print out the batch files that need relocated.
	my $batch_contents;
	my $match_string =
	  q(eval [ ] 'exec [ ] )
	  . quotemeta $self->image_dir()->file('perl\\bin\\perl.exe')
	  ->stringify();
	foreach my $batch_file ( sort { $a cmp $b } keys %batch_files ) {
		$self->trace_line( 5,
			"Checking to see if $batch_file needs relocated.\n" );
		$batch_contents =
		  read_file( $self->image_dir()->file($batch_file)->stringify() );
		if ( $batch_contents =~ m/$match_string/msgx ) {
			print {$file_out_handle} "$batch_file:backslash\n";
		}
	}

	# Finish up by closing the handle.
	close $file_out_handle or PDWiX->throw('Ouch!');

	return 1;
} ## end sub make_relocation_file

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
