package Module::Build::Functions;

#<<<
use     strict;
use     5.00503;
use     vars                  qw( $VERSION @EXPORT $AUTOLOAD %ARGS);
use     Carp                  qw( croak carp confess              );
use     File::Spec::Functions qw( catdir catfile                  );
use     Exporter              qw();
use     Cwd                   qw();
use     File::Find            qw();
use     File::Path            qw();
use     FindBin;
use     Config;

# The equivalent of "use warnings" pre-5.006.
local $^W                 = 1;
my    $object             = undef;
my    $class              = 'Module::Build';
my    $mb_required        = 0;
my    $object_created     = 0;
my    $export_to          = undef;
my    $sharemod_used      = 1;
my    (%FLAGS, %ALIASES, %ARRAY, %HASH, @AUTOLOADED, @DEFINED);
my    @install_types;
my    %config;
#>>>

# Whether or not inc::Module::Build::Functions is actually loaded, the
# $INC{inc/Module/Build/Functions.pm} is what will still get set as long as
# the caller loaded this module in the documented manner.
# If not set, the caller may NOT have loaded the bundled version, and thus
# they may not have a MBF version that works with the Build.PL. This would
# result in false errors or unexpected behaviour. And we don't want that.
my $file = join( '/', 'inc', split /::/, __PACKAGE__ ) . '.pm';
unless ( $INC{$file} ) {
	die <<"END_DIE" }

Please invoke ${\__PACKAGE__} with:

    use inc::${\__PACKAGE__};

not:

    use ${\__PACKAGE__};

END_DIE

# To save some more typing in Module::Build::Functions installers, every...
# use inc::Module::Build::Functions
# ...also acts as an implicit use strict.
$^H |= strict::bits(qw(refs subs vars));

# import which will also perform self-bundling
sub import {
	$export_to = caller;
	
	my $class = shift;

	%config = @_;

	$config{prefix} ||= 'inc';
	$config{author} ||= ( $^O eq 'VMS' ? '_author' : '.author' );
	$config{base}   ||= Cwd::abs_path($FindBin::Bin);

  # Stripping leading prefix, if this import was called
  # from loader (inc::Module::Build::Functions)
	$class =~ s/^\Q$config{prefix}\E:://;

	$config{name} ||= $class;
	$config{version} ||= $class->VERSION;

	unless ( $config{path} ) {
		$config{path} = $config{name};
		$config{path} =~ s!::!/!g;
	}
	$config{file} ||= "$config{base}/$config{prefix}/$config{path}.pm";

	unless ( -f $config{file} || $0 ne 'Build.PL' && $0 ne 'Makefile.PL' ) {
		File::Path::mkpath("$config{prefix}/$config{author}");

		# Bundling its own copy to ./inc
		_copy( $INC{"$config{path}.pm"} => $config{file} );

		unless ( grep { $_ eq $config{prefix} } @INC ) {
			unshift @INC, $config{prefix};
		}
	}
	
	if (defined $config{build_class}) {
	    $DB::single = 1;
	    
	    build_class($config{build_class});
	}

	{
		# The export should be performed 1 level up, since we call 
		# Exporter's 'import' from our 'import'
		local $Exporter::ExportLevel = 1;

		# Delegating back to Exporter's import
		&Exporter::import($class);
	}
} ## end sub import


# Copy a single package to inc/, with its @ISA tree (note, dependencies are skipped)
sub copy_package {
	my ( $pkg, $skip_isa ) = @_;

	my $file = $pkg;
	$file =~ s!::!/!g;

	my $pathname = "$file.pm";

	# Do not re-require packages
	eval "require $pkg" unless $INC{$pathname};
	die "The package [$pkg] not found and cannot be added to ./inc" if $@;

	$file = "$config{prefix}/$file.pm";
	return if -f $file;                # prevents infinite recursion

	_copy( $INC{$pathname} => $file );

	unless ($skip_isa) {
		my @isa = eval '@' . $pkg . '::ISA';

		copy_package($_) foreach (@isa);
	}
} ## end sub copy_package

# POD-stripping enabled copy function
sub _copy {
	my ( $from, $to ) = @_;

	my @parts = split( '/', $to );
	File::Path::mkpath( [ join( '/', @parts[ 0 .. $#parts - 1 ] ) ] );

	chomp $to;

	local ( *FROM, *TO, $_ );
	open FROM, "< $from" or die "Can't open $from for input:\n$!";
	open TO,   "> $to"   or die "Can't open $to for output:\n$!";
	print TO "#line 1\n";

	my $content;
	my $in_pod;

	while (<FROM>) {
		if (/^=(?:b(?:egin|ack)|head\d|(?:po|en)d|item|(?:ove|fo)r)/) {
			$in_pod = 1;
		} elsif ( /^=cut\s*\z/ and $in_pod ) {
			$in_pod = 0;
			print TO "#line $.\n";
		} elsif ( !$in_pod ) {
			print TO $_;
		}
	}

	close FROM;
	close TO;

	print "include $to\n";
} ## end sub _copy

BEGIN {
	$VERSION = '0.04';

	*inc::Module::Build::Functions::VERSION = *VERSION;

  # Very important line which turns a loader (inc::Module::Build::Functions)
  # into our subclass, thus provides an 'import' function to it
	@inc::Module::Build::Functions::ISA = __PACKAGE__;

	require Module::Build;

	# Module implementation here

	# Set defaults.
	if ( $Module::Build::VERSION >= 0.28 ) {
		$ARGS{create_packlist} = 1;
		$mb_required = '0.28';
	}

	%FLAGS = (
		'create_makefile_pl'          => [ '0.19', 0 ],
		'c_source'                    => [ '0.04', 0 ],
		'dist_abstract'               => [ '0.20', 0 ],
		'dist_name'                   => [ '0.11', 0 ],
		'dist_version'                => [ '0.11', 0 ],
		'dist_version_from'           => [ '0.11', 0 ],
		'installdirs'                 => [ '0.19', 0 ],
		'license'                     => [ '0.11', 0 ],
		'create_packlist'             => [ '0.28', 1 ],
		'create_readme'               => [ '0.22', 1 ],
		'create_license'              => [ '0.31', 1 ],
		'dynamic_config'              => [ '0.07', 1 ],
		'use_tap_harness'             => [ '0.30', 1 ],
		'sign'                        => [ '0.16', 1 ],
		'recursive_test_files'        => [ '0.28', 1 ],
		'auto_configure_requires'     => [ '0.34', 1 ],
	);

	%ALIASES = (
		'test_requires'       => 'build_requires',
		'abstract'            => 'dist_abstract',
		'name'                => 'module_name',
		'author'              => 'dist_author',
		'version'             => 'dist_version',
		'version_from'        => 'dist_version_from',
		'extra_compiler_flag' => 'extra_compiler_flags',
		'extra_linker_flag'   => 'extra_linker_flags',
		'include_dir'         => 'include_dirs',
		'pl_file'             => 'PL_files',
		'pl_files'            => 'PL_files',
		'PL_file'             => 'PL_files',
		'pm_file'             => 'pm_files',
		'pod_file'            => 'pod_files',
		'xs_file'             => 'xs_files',
		'test_file'           => 'test_files',
		'script_file'         => 'script_files',
	);

	%ARRAY = (
		'autosplit'      => '0.04',
		'add_to_cleanup' => '0.19',
		'include_dirs'   => '0.24',
		'dist_author'    => '0.20',
	);

	%HASH = (
		'configure_requires' => [ '0.30', 1 ],
		'build_requires'     => [ '0.07', 1 ],
		'conflicts'          => [ '0.07', 1 ],
		'recommends'         => [ '0.08', 1 ],
		'requires'           => [ '0.07', 1 ],
		'get_options'        => [ '0.26', 0 ],
		'meta_add'           => [ '0.28', 0 ],
		'pm_files'           => [ '0.19', 0 ],
		'pod_files'          => [ '0.19', 0 ],
		'xs_files'           => [ '0.19', 0 ],
		'install_path'       => [ '0.19', 0 ],
	);

	@AUTOLOADED = ( keys %HASH, keys %ARRAY, keys %ALIASES, keys %FLAGS );

	@DEFINED = qw(
	  all_from abstract_from author_from license_from perl_version
	  perl_version_from install_script install_as_core install_as_cpan
	  install_as_site install_as_vendor WriteAll auto_install auto_bundle
	  bundle bundle_deps auto_bundle_deps can_use can_run can_cc
	  requires_external_bin requires_external_cc get_file check_nmake
	  interactive release_testing automated_testing win32 winlike
	  author_context install_share auto_features extra_compiler_flags
	  extra_linker_flags module_name no_index PL_files script_files test_files
	  tap_harness_args subclass create_build_script get_builder build_class
	  repository bugtracker meta_merge cygwin
	);
	@EXPORT = ( 'AUTOLOAD', @DEFINED, @AUTOLOADED );
	
	$DB::single = 1;

} ## end BEGIN

# The autoload handles 4 types of "similar" routines, for 45 names.
sub AUTOLOAD {
	my $full_sub = $AUTOLOAD;
	my ($sub) = $AUTOLOAD =~ m{\A.*::([^:]*)\z}x;

	if ( exists $ALIASES{$sub} ) {
		my $alias = $ALIASES{$sub};
		eval <<"END_OF_CODE";
sub $full_sub {
	$alias(\@_);
	return;
}
END_OF_CODE
		goto &{$full_sub};
	}

	if ( exists $FLAGS{$sub} ) {
		my $boolean_version = $FLAGS{$sub}[0];
		my $boolean_default = $FLAGS{$sub}[1] ? ' || 1' : q{};
		my $boolean_normal  = $FLAGS{$sub}[1] ? q{!!} : q{};
		eval <<"END_OF_CODE";
sub $full_sub {	
	my \$argument = shift$boolean_default;
	\$ARGS{$sub} = $boolean_normal \$argument;
	_mb_required('$boolean_version');
	return;
}
END_OF_CODE
		goto &{$full_sub};
	} ## end if ( exists $FLAGS{$sub...})

	if ( exists $ARRAY{$sub} ) {

		my $array_version = $ARRAY{$sub};
		my $code_array    = <<"END_OF_CODE";
sub $full_sub {
	my \$argument = shift;
	if ( 'ARRAY' eq ref \$argument ) {
		foreach my \$f ( \@{\$argument} ) {
			$sub(\$f);
		}
		return;
	}
	
	my \@array;
	if (exists \$ARGS{$sub}) {
		\$ARGS{$sub} = [ \@{ \$ARGS{$sub} }, \$argument ];
	} else {
		\$ARGS{$sub} = [ \$argument ];
	}
	_mb_required('$array_version');
	return;
}
END_OF_CODE
		eval $code_array;
		goto &{$full_sub};
	} ## end if ( exists $ARRAY{$sub...})

	if ( exists $HASH{$sub} ) {
		_create_hashref($sub);
		my $hash_version = $HASH{$sub}[0];
		my $hash_default = $HASH{$sub}[1] ? ' || 0' : q{};
		my $code_hash    = <<"END_OF_CODE";
sub $full_sub {
	my \$argument1 = shift;
	my \$argument2 = shift$hash_default;
	if ( 'HASH' eq ref \$argument1 ) {
		my ( \$k, \$v );
		while ( ( \$k, \$v ) = each \%{\$argument1} ) {
			$sub( \$k, \$v );
		}
		return;
	}

	\$ARGS{$sub}{\$argument1} = \$argument2;
	_mb_required('$hash_version');
	return;
}
END_OF_CODE
		eval $code_hash;
		goto &{$full_sub};
	} ## end if ( exists $HASH{$sub...})

	croak "$sub cannot be found";
} ## end sub AUTOLOAD

sub _mb_required {
	my $version = shift;
	if ( $version > $mb_required ) {
		$mb_required = $version;
	}
	return;
}

sub _installdir {
	return $Config{'sitelibexp'} unless ( defined $ARGS{install_type} );
	return $Config{'sitelibexp'}   if ( 'site'   eq $ARGS{install_type} );
	return $Config{'privlibexp'}   if ( 'perl'   eq $ARGS{install_type} );
	return $Config{'vendorlibexp'} if ( 'vendor' eq $ARGS{install_type} );
	croak 'Invalid install type';
}

sub _create_arrayref {
    my $name = shift;
    unless ( exists $ARGS{$name} ) {
        $ARGS{$name} = [];
    }
    return;
}


sub _create_hashref {
	my $name = shift;
	unless ( exists $ARGS{$name} ) {
		$ARGS{$name} = {};
	}
	return;
}

sub _create_hashref_arrayref {
	my $name1 = shift;
	my $name2 = shift;
	unless ( exists $ARGS{$name1}{$name2} ) {
		$ARGS{$name1}{$name2} = [];
	}
	return;
}

sub _slurp_file {
	my $name = shift;
	my $file_handle;

	if ( $] < 5.006 ) {
		require Symbol;
		$file_handle = Symbol::gensym();
		open $file_handle, "<$name"
		  or croak $!;
	} else {
		open $file_handle, '<', $name
		  or croak $!;
	}

	local $/ = undef;                  # enable localized slurp mode
	my $content = <$file_handle>;

	close $file_handle;
	return $content;
} ## end sub _slurp_file

# Module::Install syntax below.

sub all_from {
	my $file = shift;

	abstract_from($file);
	author_from($file);
	version_from($file);
	license_from($file);
	perl_version_from($file);
	return;
}

sub abstract_from {
	my $file = shift;

	require ExtUtils::MM_Unix;
	abstract(
		bless( { DISTNAME => $ARGS{module_name} }, 'ExtUtils::MM_Unix' )
		  ->parse_abstract($file) );

	return;
}

# Borrowed from Module::Install::Metadata->author_from
sub author_from {
	my $file    = shift;
	my $content = _slurp_file($file);
	my $author;

	if ($content =~ m{
		=head \d \s+ (?:authors?)\b \s*
		(.*?)
		=head \d
	}ixms
	  )
	{

		# Grab all author lines.
		my $authors = $1;

		# Now break up each line.
		while ( $authors =~ m{\G([^\n]+) \s*}gcixms ) {
			$author = $1;

			# Convert E<lt> and E<gt> into the right characters.
			$author =~ s{E<lt>}{<}g;
			$author =~ s{E<gt>}{>}g;

			# Remove new-style C<< >> markers.
			if ( $author =~ m{\A(.*?) \s* C<< \s* (.*?) \s* >>}msx ) {
				$author = "$1 $2";
			}
			dist_author($author);
		} ## end while ( $authors =~ m{\G([^\n]+) \s*}gcixms)
	} elsif (
		$content =~ m{
		=head \d \s+ (?:licen[cs]e|licensing|copyright|legal)\b \s*
		.*? copyright .*? \d\d\d[\d.]+ \s* (?:\bby\b)? \s*
		([^\n]*)
	}ixms
	  )
	{
		$author = $1;

		# Convert E<lt> and E<gt> into the right characters.
		$author =~ s{E<lt>}{<}g;
		$author =~ s{E<gt>}{>}g;

		# Remove new-style C<< >> markers.
		if ( $author =~ m{\A(.*?) \s* C<< \s* (.*?) \s* >>}msx ) {
			$author = "$1 $2";
		}
		dist_author($author);
	} else {
		carp "Cannot determine author info from $file";
	}

	return;
} ## end sub author_from

# Borrowed from Module::Install::Metadata->license_from
sub license_from {
	my $file    = shift;
	my $content = _slurp_file($file);
	if ($content =~ m{
		(
			=head \d \s+
			(?:licen[cs]e|licensing|copyright|legal)\b
			.*?
		)
		(=head\\d.*|=cut.*|)
		\z
	}ixms
	  )
	{
		my $license_text = $1;
#<<<
		my @phrases      = (
			'under the same (?:terms|license) as perl itself' => 'perl',        1,
			'GNU general public license'                      => 'gpl',         1,
			'GNU public license'                              => 'gpl',         1,
			'GNU lesser general public license'               => 'lgpl',        1,
			'GNU lesser public license'                       => 'lgpl',        1,
			'GNU library general public license'              => 'lgpl',        1,
			'GNU library public license'                      => 'lgpl',        1,
			'BSD license'                                     => 'bsd',         1,
			'Artistic license'                                => 'artistic',    1,
			'GPL'                                             => 'gpl',         1,
			'LGPL'                                            => 'lgpl',        1,
			'BSD'                                             => 'bsd',         1,
			'Artistic'                                        => 'artistic',    1,
			'MIT'                                             => 'mit',         1,
			'proprietary'                                     => 'restrictive', 0,
		);
#>>>
		while ( my ( $pattern, $license, $osi ) = splice @phrases, 0, 3 ) {
			$pattern =~ s{\s+}{\\s+}g;
			if ( $license_text =~ /\b$pattern\b/ix ) {
				license($license);
				return;
			}
		}
	} ## end if ( $content =~ m{ ) (})

	carp "Cannot determine license info from $file";
	license('unknown');
	return;
} ## end sub license_from

sub perl_version {
	requires( 'perl', @_ );
	return;
}

# Borrowed from Module::Install::Metadata->license_from
sub perl_version_from {
	my $file    = shift;
	my $content = _slurp_file($file);
	if ($content =~ m{
		^  # Start of LINE, not start of STRING.
		(?:use|require) \s*
		v?
		([\d_\.]+)
		\s* ;
		}ixms
	  )
	{
		my $perl_version = $1;
		$perl_version =~ s{_}{}g;
		perl_version($perl_version);
	} else {
		carp "Cannot determine perl version info from $file";
	}

	return;
} ## end sub perl_version_from

sub install_script {
	my @scripts = @_;
	foreach my $script (@scripts) {
		if ( -f $script ) {
			script_files($_);
		} elsif ( -d 'script' and -f "script/$script" ) {
			script_files("script/$script");
		} else {
			croak "Cannot find script '$script'";
		}
	}

	return;
} ## end sub install_script

sub install_as_core {
	return installdirs('perl');
}

sub install_as_cpan {
	return installdirs('site');
}

sub install_as_site {
	return installdirs('site');
}

sub install_as_vendor {
	return installdirs('vendor');
}

sub WriteAll { ## no critic(Capitalization)
	my $answer = create_build_script();
	return $answer;
}

# Module::Install::AutoInstall

sub auto_install {
	croak 'auto_install is deprecated';
}

# Module::Install::Bundle

sub auto_bundle {
	croak 'auto_bundle is deprecated';
}

sub bundle {
	croak 'bundle is deprecated';
}

sub bundle_deps {
	croak 'bundle_deps is deprecated';
}

sub auto_bundle_deps {
	croak 'auto_bundle_deps is deprecated';
}

# Module::Install::Can

sub can_use {
	my ( $mod, $ver ) = @_;

	my $file = $mod;
	$file =~ s{::|\\}{/}g;
	$file .= '.pm' unless $file =~ /\.pm$/i;

	local $@ = undef;
	return eval { require $file; $mod->VERSION( $ver || 0 ); 1 };
}

sub can_run {
	my $cmd = shift;
	require ExtUtils::MakeMaker;
	if ( $^O eq 'cygwin' ) {

		# MM->maybe_command is fixed in 6.51_01 for Cygwin.
		ExtUtils::MakeMaker->import(6.52);
	}

	my $_cmd = $cmd;
	return $_cmd if ( -x $_cmd or $_cmd = MM->maybe_command($_cmd) );

	for my $dir ( ( split /$Config::Config{path_sep}/x, $ENV{PATH} ), q{.} )
	{
		next if $dir eq q{};
		my $abs = File::Spec->catfile( $dir, $cmd );
		return $abs if ( -x $abs or $abs = MM->maybe_command($abs) );
	}

	return;
} ## end sub can_run

sub can_cc {
	return eval {
		require ExtUtils::CBuilder;
		ExtUtils::CBuilder->new()->have_compiler();
	};
}

# Module::Install::External

sub requires_external_bin {
	my ( $bin, $version ) = @_;
	if ($version) {
		croak 'requires_external_bin does not support versions yet';
	}

	# Locate the bin
	print "Locating required external dependency bin: $bin...";
	my $found_bin = can_run($bin);
	if ($found_bin) {
		print " found at $found_bin.\n";
	} else {
		print " missing.\n";
		print "Unresolvable missing external dependency.\n";
		print "Please install '$bin' seperately and try again.\n";
		print {*STDERR}
		  "NA: Unable to build distribution on this platform.\n";
		exit 0;
	}

	return 1;
} ## end sub requires_external_bin

sub requires_external_cc {
	unless ( can_cc() ) {
		print "Unresolvable missing external dependency.\n";
		print "This package requires a C compiler.\n";
		print {*STDERR}
		  "NA: Unable to build distribution on this platform.\n";
		exit 0;
	}

	return 1;
}

# Module::Install::Fetch

sub get_file {
	croak
'get_file is not supported - replace by code in a Module::Build subclass.';
}

# Module::Install::Win32

sub check_nmake {
	croak
'check_nmake is not supported - replace by code in a Module::Build subclass.';
}

# Module::Install::With

sub release_testing {
	return !!$ENV{RELEASE_TESTING};
}

sub automated_testing {
	return !!$ENV{AUTOMATED_TESTING};
}

# Mostly borrowed from Scalar::Util::openhandle, since I should
# not use modules that were non-core in 5.005.
sub _openhandle {
	my $fh = shift;
	my $rt = reftype($fh) || q{};

	return ( ( defined fileno $fh ) ? $fh : undef )
	  if $rt eq 'IO';

	if ( $rt ne 'GLOB' ) {
		return;
	}

	return ( tied *{$fh} or defined fileno $fh ) ? $fh : undef;
} ## end sub _openhandle

# Mostly borrowed from IO::Interactive::is_interactive, since I should
# not use modules that were non-core in 5.005.
sub interactive {

	# If we're doing automated testing, we assume that we don't have
	# a terminal, even if we otherwise would.
	return 0 if automated_testing();

	# Not interactive if output is not to terminal...
	return 0 if not -t *STDOUT;

	# If *ARGV is opened, we're interactive if...
	if ( _openhandle(*ARGV) ) {

		# ...it's currently opened to the magic '-' file
		return -t *STDIN if defined $ARGV && $ARGV eq q{-};

		# ...it's at end-of-file and the next file is the magic '-' file
		return @ARGV > 0 && $ARGV[0] eq q{-} && -t *STDIN if eof *ARGV;

		# ...it's directly attached to the terminal
		return -t *ARGV;
	}

	# If *ARGV isn't opened, it will be interactive if *STDIN is attached
	# to a terminal.
	else {
		return -t *STDIN;
	}
} ## end sub interactive

sub win32 {
	return !!( $^O eq 'MSWin32' );
}

sub cygwin {
	return !!( $^O eq 'cygwin' );
}

sub winlike {
	return !!( $^O eq 'MSWin32' or $^O eq 'cygwin' );
}

sub author_context {
	return 1 if -d 'inc/.author';
	return 1 if -d 'inc/_author';
	return 1 if -d '.svn';
	return 1 if -f '.cvsignore';
	return 1 if -f '.gitignore';
	return 1 if -f 'MANIFEST.SKIP';
	return 0;
}

# Module::Install::Share

sub _scan_dir {
	my ( $srcdir, $destdir, $unixdir, $type, $files ) = @_;

	my $type_files = $type . '_files';

	$ARGS{$type_files} = {} unless exists $ARGS{"$type_files"};

	my $dir_handle;

	if ( $] < 5.006 ) {
		require Symbol;
		$dir_handle = Symbol::gensym();
	}

	opendir $dir_handle, $srcdir or croak $!;

  FILE:
	foreach my $direntry ( readdir $dir_handle ) {
		if ( -d catdir( $srcdir, $direntry ) ) {
			next FILE if ( $direntry eq q{.} );
			next FILE if ( $direntry eq q{..} );
			_scan_dir(
				catdir( $srcdir,  $direntry ),
				catdir( $destdir, $direntry ),
				File::Spec::Unix->catdir( $unixdir, $direntry ),
				$type,
				$files
			);
		} else {
			my $sourcefile = catfile( $srcdir, $direntry );
			my $unixfile = File::Spec::Unix->catfile( $unixdir, $direntry );
			if ( exists $files->{$unixfile} ) {
				$ARGS{$type_files}{$sourcefile} =
				  catfile( $destdir, $direntry );
			}
		}
	} ## end foreach my $direntry ( readdir...)

	closedir $dir_handle;

	return;
} ## end sub _scan_dir

sub install_share {
	my $dir  = @_ ? pop   : 'share';
	my $type = @_ ? shift : 'dist';

	unless ( defined $type
		and ( ( $type eq 'module' ) or ( $type eq 'dist' ) ) )
	{
		croak "Illegal or invalid share dir type '$type'";
	}
	unless ( defined $dir and -d $dir ) {
		croak 'Illegal or missing directory install_share param';
	}

	require File::Spec::Unix;
	require ExtUtils::Manifest;
	my $files = ExtUtils::Manifest::maniread();
	if ( 0 == scalar(%$files) ) {
		croak 'Empty or no MANIFEST file';
	}
	my $installation_path;
	my $sharecode;

	if ( $type eq 'dist' ) {
		croak 'Too many parameters to install_share' if @_;

		my $dist = $ARGS{'dist_name'};

		$installation_path =
		  catdir( _installdir(), qw(auto share dist), $dist );
		_scan_dir( $dir, 'share', $dir, 'share', $files );
		push @install_types, 'share';
		$sharecode = 'share';
	} else {
		my $module = shift;

		unless ( defined $module ) {
			croak "Missing or invalid module name '$module'";
		}

		$module =~ s/::/-/g;
		$installation_path =
		  catdir( _installdir(), qw(auto share module), $module );
		$sharecode = 'share_d' . $sharemod_used;
		_scan_dir( $dir, $sharecode, $dir, $sharecode, $files );
		push @install_types, $sharecode;
		$sharemod_used++;
	} ## end else [ if ( $type eq 'dist' )]

	# Set the path to install to.
	install_path( $sharecode, $installation_path );

	# This helps for testing purposes...
	if ( $Module::Build::VERSION >= 0.31 ) {
		Module::Build->add_property( $sharecode . '_files',
			default => sub { return {} } );
	}

	# 99% of the time we don't want to index a shared dir
	no_index($dir);

	# This construction requires 0.26.
	_mb_required('0.26');
	return;
} ## end sub install_share

# Module::Build syntax

sub _af_hashref {
	my $feature = shift;
	unless ( exists $ARGS{auto_features} ) {
		$ARGS{auto_features} = {};
	}
	unless ( exists $ARGS{auto_features}{$feature} ) {
		$ARGS{auto_features}{$feature} = {};
		$ARGS{auto_features}{$feature}{requires} = {};
	}
	return;
}

sub auto_features {
	my $feature = shift;
	my $type    = shift;
	my $param1  = shift;
	my $param2  = shift;
	_af_hashref($type);

	if ( 'description' eq $type ) {
		$ARGS{auto_features}{$feature}{description} = $param1;
	} elsif ( 'requires' eq $type ) {
		$ARGS{auto_features}{$feature}{requires}{$param1} = $param2;
	} else {
		croak "Invalid type $type for auto_features";
	}
	_mb_required('0.26');
	return;
} ## end sub auto_features

sub extra_compiler_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_compiler_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_compiler_flags($f);
		}
	} else {
		_create_arrayref('extra_compiler_flags');
		push @{ $ARGS{'extra_compiler_flags'} }, $flag;
	}
	_mb_required('0.19');
	return;
} ## end sub extra_compiler_flags

sub extra_linker_flags {
	my $flag = shift;
	if ( 'ARRAY' eq ref $flag ) {
		foreach my $f ( @{$flag} ) {
			extra_linker_flags($f);
		}
	}

	if ( $flag =~ m{\s} ) {
		my @flags = split m{\s+}, $flag;
		foreach my $f (@flags) {
			extra_linker_flags($f);
		}
	} else {
		_create_arrayref('extra_linker_flags');
		push @{ $ARGS{'extra_linker_flags'} }, $flag;
	}
	_mb_required('0.19');
	return;
} ## end sub extra_linker_flags

sub module_name {
	my ($name) = shift;
	$ARGS{'module_name'} = $name;
	unless ( exists $ARGS{'dist_name'} ) {
		my $dist_name = $name;
		$dist_name =~ s/::/-/g;
		dist_name($dist_name);
	}
	_mb_required('0.03');
	return;
}

sub no_index {
	my $name = pop;
	my $type = shift || 'directory';

	# TODO: compatibility code.

	_create_hashref('no_index');
	_create_hashref_arrayref( 'no_index', $type );
	push @{ $ARGS{'no_index'}{$type} }, $name;
	_mb_required('0.28');
	return;
} ## end sub no_index

sub PL_files { ## no critic(Capitalization)
	my $pl_file = shift;
	my $pm_file = shift || [];
	if ( 'HASH' eq ref $pl_file ) {
		my ( $k, $v );
		while ( ( $k, $v ) = each %{$pl_file} ) {
			PL_files( $k, $v );
		}
	}

	_create_hashref('PL_files');
	$ARGS{PL_files}{$pl_file} = $pm_file;
	_mb_required('0.06');
	return;
} ## end sub PL_files

sub meta_merge {
	my $key   = shift;
	my $value = shift;
	if ( 'HASH' eq ref $key ) {
		my ( $k, $v );
		while ( ( $k, $v ) = each %{$key} ) {
			meta_merge( $k, $v );
		}
		return;
	}

	# Allow omitting hashrefs, if there's one more parameter.
	if ( 1 == scalar @_ ) {
		meta_merge( $key, { $value => shift } );
		return;
	} elsif ( 0 != scalar @_ ) {
		confess 'Too many parameters to meta_merge';
	}

	if (    ( defined $ARGS{meta_merge}{$key} )
		and ( ref $value ne ref $ARGS{meta_merge}{$key} ) )
	{
		confess
'Mismatch between value to merge into meta information and value already there';
	}

	if ( 'HASH' eq ref $ARGS{meta_merge}{$key} ) {
		$ARGS{meta_merge}{$key} =
		  { ( %{ $ARGS{meta_merge}{$key} } ), ( %{$value} ) };
	} elsif ( 'ARRAY' eq ref $ARGS{meta_merge}{$key} ) {
		$ARGS{meta_merge}{$key} =
		  \( @{ $ARGS{meta_merge}{$key} }, @{$value} );
	} else {
		$ARGS{meta_merge}{$key} = $value;
	}

	_mb_required('0.28');
	return;
} ## end sub meta_merge


sub repository {
	my $url = shift;
	meta_merge( 'resources', 'repository' => $url );
	return;
}

sub bugtracker {
	my $url = shift;
	meta_merge( 'resources', 'bugtracker' => $url );
	return;
}

sub script_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			script_files($f);
		}
	}

	if ( -d $file ) {
		if ( exists $ARGS{'script_files'} ) {
			if ( 'ARRAY' eq ref $ARGS{'script_files'} ) {
				croak
				  "cannot add directory $file to a list of script_files";
			} else {
				croak
"attempt to overwrite string script_files with $file failed";
			}
		} else {
			$ARGS{'script_files'} = $file;
		}
	} else {
		_create_arrayref('script_files');
		push @{ $ARGS{'script_files'} }, $file;
	}
	_mb_required('0.18');
	return;
} ## end sub script_files

sub test_files {
	my $file = shift;
	if ( 'ARRAY' eq ref $file ) {
		foreach my $f ( @{$file} ) {
			test_files($f);
		}
	}

	if ( $file =~ /[*?]/ ) {
		if ( exists $ARGS{'test_files'} ) {
			if ( 'ARRAY' eq ref $ARGS{'test_files'} ) {
				croak 'cannot add a glob to a list of test_files';
			} else {
				croak 'attempt to overwrite string test_files failed';
			}
		} else {
			$ARGS{'test_files'} = $file;
		}
	} else {
		_create_arrayref('test_files');
		push @{ $ARGS{'test_files'} }, $file;
	}
	_mb_required('0.23');
	return;
} ## end sub test_files

sub tap_harness_args {
	my ($thargs) = shift;
	$ARGS{'tap_harness_args'} = $thargs;
	use_tap_harness(1);
	return;
}

sub build_class {
	my $further_class = $ARGS{build_class} = shift;
	
    eval "require $further_class;";
    die "Can't find custom build class '$further_class'" if $@;
    
    copy_package($further_class, 'true');
    
    sync_interface($further_class);
	
	_mb_required('0.28');
	return;
}

sub subclass {
    # '$class->' will enable the further subclassing of custom subclass
	sync_interface($class->subclass(@_));
	return;
}

sub create_build_script {
	get_builder();
	$object->create_build_script;
	return $object;
}

# Required to get a builder for later use.
sub get_builder {

	if ( $mb_required < 0.07 ) { $mb_required = '0.07'; }
	build_requires( 'Module::Build', $mb_required );

	if ( $mb_required > 0.2999 ) {
		configure_requires( 'Module::Build', $mb_required );
	}

	unless ( defined $object ) {
		$object = $class->new(%ARGS);
		$object_created = 1;
	}

	foreach my $type (@install_types) {
		$object->add_build_element($type);
	}

	return $object;
} ## end sub get_builder


sub sync_interface {
    # subclass needs be already 'required', as it will be introspected 
    my $subclass = shift;
    
    # Properties of current builder class
    my @current_all_properties      = $class->valid_properties;
    
    # Hashed variant for convenient checking of presense
    my %current_all_properties      = map { $_ => '' } @current_all_properties;
    
    
    # Properties of subclass
    my @all_properties      = $subclass->valid_properties;
    my %array_properties    = map { $_ => '' } $subclass->array_properties;
    my %hash_properties     = map { $_ => '' } $subclass->hash_properties;
    
    $class = $subclass;
    
    foreach my $property (@all_properties) {
        # Skipping already presented properties
        next if defined $current_all_properties{$property};
        
        if (defined $hash_properties{$property}) {
            additional_hash($property)
        } elsif (defined $array_properties{$property}) {
            additional_array($property)
        } else {
            additional_flag($property)
        }
    }
}


sub additional {
	my ($additional_type, $additional_name) = @_;
	if (not defined $additional_name) {
		croak 'additional requires a name.';
	}
	
	unless($class->valid_property($additional_name)) {
		croak "Property '$additional_name' not found in $class";
	}
	
	if ( 'array' eq lc $additional_type ) {
		$ARRAY{$additional_name} = 0.07;
	} elsif ( 'hash' eq lc $additional_type ) {
		$HASH{$additional_name} = [ 0.07, 0 ];	
	} elsif ( 'flag' eq lc $additional_type ) {
		$FLAGS{$additional_name} = [ 0.07, 0 ];
	} else {
		croak 'additional requires two parameters: a type (array, hash, or flag) and a name.';
	}
	
	no strict 'refs';
	
	my $symbol = "${export_to}::$additional_name";
	
	# Create a stub in the caller package
	\&{$symbol};
}

sub additional_array {
	my $additional_name = shift;
	croak 'additional_array needs a name to define' if not defined $additional_name;
	additional('array', $additional_name);
}

sub additional_flag {
	my $additional_name = shift;
	croak 'additional_flag needs a name to define' if not defined $additional_name;
	additional('flag', $additional_name);
}

sub additional_hash {
	my $additional_name = shift;
	croak 'additional_hash needs a name to define' if not defined $additional_name;
	additional('hash', $additional_name);
}

sub _debug_print {
	require Data::Dumper;
	my $d = Data::Dumper->new( [ \%ARGS, \$mb_required ],
		[qw(*ARGS *mb_required)] );
	print $d->Indent(1)->Dump();
	return;
}

1;
