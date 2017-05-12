package Module::Starter::CSJEWELL;

use 5.008001;
use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use parent 'Module::Starter::Simple';

our $VERSION = '0.200';
$VERSION =~ s/_//sm;

sub module_guts {
	my $self    = shift;
	my %context = (
		'MODULE NAME' => shift,
		'RT NAME'     => shift,
		'DATE'        => scalar localtime,
		'YEAR'        => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Module.pm', \%context );
}

sub create_Makefile_PL {
	my $self = shift;

	# We don't create a Makefile.PL.

	return;
}

sub Build_PL_guts {
	my $self    = shift;
	my %context = (
		'MAIN MODULE'  => shift,
		'MAIN PM FILE' => shift,
		'DATE'         => scalar localtime,
		'YEAR'         => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Build.PL', \%context );
}

sub Changes_guts {
	my $self = shift;

	my %context = (
		'DATE' => scalar localtime,
		'YEAR' => $self->_thisyear(),
	);

	return $self->_load_and_expand_template( 'Changes', \%context );
}

sub create_README {
	my $self = shift;

	# We don't create a readme as such.

	return;
}

sub t_guts { ## no critic (RequireArgUnpacking)
	my $self    = shift;
	my @modules = @_;
	my %context = (
		'DATE' => scalar localtime,
		'YEAR' => $self->_thisyear(),
	);

	my %t_files;
	my @template_files;
	push @template_files, glob "$self->{template_dir}/t/*.t";
	push @template_files, glob "$self->{template_dir}/xt/author/*.t";
	push @template_files, glob "$self->{template_dir}/xt/settings/*.txt";
	for my $test_file (
		map {
			my $x = $_;
			$x = File::Spec->abs2rel( $_, $self->{template_dir} );
			$x;
		} @template_files
	  )
	{
		$t_files{$test_file} =
		  $self->_load_and_expand_template( $test_file, \%context );
	}

	my $nmodules = @modules;
	$nmodules++;
	my $main_module = $modules[0];
	my $use_lines = join "\n", map {"    use_ok( '$_' );"} @modules;

	$t_files{'t/compile.t'} = <<"END_LOAD";
use Test::More tests => $nmodules;

BEGIN {
	use strict;
	\$^W = 1;
	\$| = 1;

    ok((\$] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
$use_lines
    diag( "Testing $main_module \$${main_module}::VERSION" );
}

END_LOAD

	return %t_files;
} ## end sub t_guts

sub _create_t {
	my $self     = shift;
	my $filename = shift;
	my $content  = shift;

	my @dirparts = ( $self->{basedir}, 't' );
	foreach my $tdir (
		File::Spec->catdir( $self->{basedir}, 't' ),
		File::Spec->catdir( $self->{basedir}, 'xt' ),
		File::Spec->catdir( $self->{basedir}, 'xt', 'settings' ),
		File::Spec->catdir( $self->{basedir}, 'xt', 'author' ),
	  )
	{

		if ( not -d $tdir ) {
			local @ARGV = $tdir;
			mkpath();
			$self->progress("Created $tdir");
		}
	} ## end foreach my $tdir ( File::Spec...)

	my $fname = File::Spec->catfile( $self->{basedir}, $filename );
	$self->create_file( $fname, $content );
	$self->progress("Created $fname");

	return "$filename";
} ## end sub _create_t

sub MANIFEST_guts { ## no critic (RequireArgUnpacking)
	my $self  = shift;
	my @files = sort @_;

	my $mskip = $self->_load_and_expand_template( 'MANIFEST.SKIP', {} );
	my $fname = File::Spec->catfile( $self->{basedir}, 'MANIFEST.SKIP' );
	$self->create_file( $fname, $mskip );
	$self->progress("Created $fname");

	return join "\n", @files, q{};
}


sub _load_and_expand_template {
	my ( $self, $rel_file_path, $context_ref ) = @_;

	@{$context_ref}{ map {uc} keys %{$self} } = values %{$self};

	die
"Can't find directory that holds Module::Starter::CSJEWELL templates\n",
	  "(no 'template_dir: <directory path>' in config file)\n"
	  if not defined $self->{template_dir};

	die "Can't access Module::Starter::CSJEWELL template directory\n",
"(perhaps 'template_dir: $self->{template_dir}' is wrong in config file?)\n"
	  if not -d $self->{template_dir};

	my $abs_file_path = "$self->{template_dir}/$rel_file_path";

	die "The Module::Starter::CSJEWELL template: $rel_file_path\n",
	  "isn't in the template directory ($self->{template_dir})\n\n"
	  if not -e $abs_file_path;

	die "The Module::Starter::CSJEWELL template: $rel_file_path\n",
	  "isn't readable in the template directory ($self->{template_dir})\n\n"
	  if not -r $abs_file_path;

	open my $fh, '<', $abs_file_path or croak $ERRNO;
	local $INPUT_RECORD_SEPARATOR = undef;
	my $text = <$fh>;
	close $fh or croak $ERRNO;

	$text =~ s{<([[:upper:] ]+)>}
              { $context_ref->{$1}
                || die "Unknown placeholder <$1> in $rel_file_path\n"
              }xmseg;

	return $text;
} ## end sub _load_and_expand_template

sub import { ## no critic (RequireArgUnpacking ProhibitExcessComplexity)
	my $class = shift;
	my ( $setup, @other_args ) = @_;

	# If this is not a setup request,
	# refer the import request up the hierarchy...
	if ( @other_args || !$setup || $setup ne 'setup' ) {
		return $class->SUPER::import(@_);
	}

	## no critic (RequireLocalizedPunctuationVars ProhibitLocalVars)

	# Otherwise, gather the necessary tools...
	use ExtUtils::Command qw( mkpath );
	use File::Spec;
	local $OUTPUT_AUTOFLUSH = 1;

	local $ENV{HOME} = $ENV{HOME};

	if ( $OSNAME eq 'MSWin32' ) {
		if ( defined $ENV{HOME} ) {
			$ENV{HOME} = Win32::GetShortPathName( $ENV{HOME} );
		} else {
			$ENV{HOME} = Win32::GetShortPathName(
				File::Spec->catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, q{} )
			);
		}
	}

	# Locate the home directory...
	if ( !defined $ENV{HOME} ) {
		print 'Please enter the full path of your home directory: ';
		$ENV{HOME} = <>;
		chomp $ENV{HOME};
		croak 'Not a valid directory. Aborting.'
		  if !-d $ENV{HOME};
	}

	# Create the directories...
	my $template_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL' );
	if ( not -d $template_dir ) {
		print {*STDERR} "Creating $template_dir...";
		local @ARGV = $template_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_test_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 't' );
	if ( not -d $template_test_dir ) {
		print {*STDERR} "Creating $template_test_dir...";
		local @ARGV = $template_test_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_xtest_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 'xt' );
	if ( not -d $template_xtest_dir ) {
		print {*STDERR} "Creating $template_xtest_dir...";
		local @ARGV = $template_xtest_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_authortest_dir =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 'xt',
		'author' );
	if ( not -d $template_authortest_dir ) {
		print {*STDERR} "Creating $template_authortest_dir...";
		local @ARGV = $template_authortest_dir;
		mkpath;
		print {*STDERR} "done.\n";
	}

	my $template_authortest_settings =
	  File::Spec->catdir( $ENV{HOME}, '.module-starter', 'CSJEWELL', 'xt',
		'settings' );
	if ( not -d $template_authortest_settings ) {
		print {*STDERR} "Creating $template_authortest_settings...";
		local @ARGV = $template_authortest_settings;
		mkpath;
		print {*STDERR} "done.\n";
	}

	# Create or update the config file (making a backup, of course)...
	my $config_file =
	  File::Spec->catfile( $ENV{HOME}, '.module-starter', 'config' );

	my @config_info;

	if ( -e $config_file ) {
		print {*STDERR} "Backing up $config_file...";
		my $backup =
		  File::Spec->catfile( $ENV{HOME}, '.module-starter',
			'config.bak' );
		rename $config_file, $backup or croak $ERRNO;
		print {*STDERR} "done.\n";

		print {*STDERR} "Updating $config_file...";
		open my $fh, '<', $backup or die "$config_file: $OS_ERROR\n";
		@config_info =
		  grep { not /\A (?: template_dir | plugins ) : /xms } <$fh>;
		close $fh or die "$config_file: $OS_ERROR\n";
	} else {
		print {*STDERR} "Creating $config_file...\n";

		my $author = _prompt_for('your full name');
		my $email  = _prompt_for('an email address');

		@config_info = (
			"author:  $author\n",
			"email:   $email\n",
			"builder: Module::Build\n",
		);

		print {*STDERR} "Writing $config_file...\n";
	} ## end else [ if ( -e $config_file )]

	push @config_info,
	  ( "plugins: Module::Starter::CSJEWELL\n",
		"template_dir: $template_dir\n",
	  );

	open my $fh, '>', $config_file or die "$config_file: $OS_ERROR\n";
	print {$fh} @config_info or die "$config_file: $OS_ERROR\n";
	close $fh or die "$config_file: $OS_ERROR\n";
	print {*STDERR} "done.\n";

	print {*STDERR} "Installing templates...\n";

	# Then install the various files...
	my @files = (
		['Build.PL'],
		['Changes'],
		['Module.pm'],
		['MANIFEST.SKIP'],
		[ 't', '000_report_versions.t' ],
		[ 'xt', 'settings', 'perltidy.txt' ],
		[ 'xt', 'settings', 'perlcritic.txt' ],
		[ 'xt', 'author',   'prereq.t' ],
		[ 'xt', 'author',   'portability.t' ],
		[ 'xt', 'author',   'meta.t' ],
		[ 'xt', 'author',   'manifest.t' ],
		[ 'xt', 'author',   'minimumversion.t' ],
		[ 'xt', 'author',   'pod_coverage.t' ],
		[ 'xt', 'author',   'pod.t' ],
		[ 'xt', 'author',   'perlcritic.t' ],
		[ 'xt', 'author',   'fixme.t' ],
		[ 'xt', 'author',   'common_mistakes.t' ],
		[ 'xt', 'author',   'changes.t' ],
		[ 'xt', 'author',   'version.t' ],
	);

	my %contents_of = do {
		local $INPUT_RECORD_SEPARATOR = undef;
		( q{}, split m{_____\[ [ ] (\S+) [ ] \]_+\n}smx, <DATA> );
	};

	for ( values %contents_of ) {
		s/^!=([[:lower:]])/=$1/gxms;
	}

	for my $ref_path (@files) {
		my $abs_path =
		  File::Spec->catfile( $ENV{HOME}, '.module-starter', 'CSJEWELL',
			@{$ref_path} );
		print {*STDERR} "\t$abs_path...";
		open my $fh, '>', $abs_path or die "$abs_path: $OS_ERROR\n";
		print {$fh} $contents_of{ $ref_path->[-1] }
		  or die "$abs_path: $OS_ERROR\n";
		close $fh or die "$abs_path: $OS_ERROR\n";
		print {*STDERR} "done\n";
	}
	print {*STDERR} "Installation complete.\n";

	exit;
} ## end sub import

sub _prompt_for {
	my ($requested_info) = @_;
	my $response;
  RESPONSE: while (1) {
		print "Please enter $requested_info: ";
		$response = <>;
		if ( not defined $response ) {
			warn "\n[Installation cancelled]\n";
			exit;
		}
		$response =~ s/\A \s+ | \s+ \Z//gxms;
		last RESPONSE if $response =~ m{\S}sm;
	}
	return $response;
} ## end sub _prompt_for


1;                                     # Magic true value required at end of module

__DATA__
_____[ Build.PL ]________________________________________________
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',

sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt/author ) );
    $self->depends_on('test');

    return;
}



sub ACTION_releasetest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt/author xt/release ) );
    $self->depends_on('test');

    return;
}



sub ACTION_manifest {
    my ($self, @arguments) = @_;

    if (-e 'MANIFEST') {
        unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
    }

    return $self->SUPER::ACTION_manifest(@arguments);
}
END_CODE
);


my $builder = $class->new(
    module_name              => '<MAIN MODULE>',
    license                  => '<LICENSE>',
    dist_author              => '<AUTHOR> <<EMAIL>>',
    dist_version_from        => '<MAIN PM FILE>',
	create_readme            => 1,
	create_license           => 1,
	create_makefile_pl       => 'small',
	configure_requires       => {
        'Module::Build'      => '0.33',
	},
    requires => {
        'perl'                => '5.008001',	
#        'parent'              => '0.221',
#        'Exception::Class'    => '1.29',
    },
	build_requires => {
        'Test::More'          => '0.88',
	},
    meta_merge     => {
        resources => {
            homepage    => 'http://www.no-home-page.invalid/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=<DISTRO>',
            repository  => 'http://www.no-source-code-repository.invalid/'
        },
    },
    add_to_cleanup      => [ '<DISTRO>-*', ],
);

$builder->create_build_script();
_____[ Changes ]_________________________________________________
Revision history for <DISTRO>

0.001  <DATE>
       - Initial release.

_____[ 000_report_versions.t ]____________________________________________
#!perl
use warnings;
use strict;
use Test::More 0.88;
use Config;

# Include a cut-down version of YAML::Tiny so we don't introduce unnecessary
# dependencies ourselves.

package Local::YAML::Tiny;

use strict;
use Carp 'croak';

# UTF Support?
sub HAVE_UTF8 () { $] >= 5.007003 }

BEGIN {
	if (HAVE_UTF8) {

		# The string eval helps hide this from Test::MinimumVersion
		eval "require utf8;";
		die "Failed to load UTF-8 support" if $@;
	}

	# Class structure
	require 5.004;
	$YAML::Tiny::VERSION = '1.40';

	# Error storage
	$YAML::Tiny::errstr = '';
} ## end BEGIN

# Printable characters for escapes
my %UNESCAPES = (
	z    => "\x00",
	a    => "\x07",
	t    => "\x09",
	n    => "\x0a",
	v    => "\x0b",
	f    => "\x0c",
	r    => "\x0d",
	e    => "\x1b",
	'\\' => '\\',
);


#####################################################################
# Implementation

# Create an empty YAML::Tiny object
sub new {
	my $class = shift;
	bless [@_], $class;
}

# Create an object from a file
sub read {
	my $class = ref $_[0] ? ref shift : shift;

	# Check the file
	my $file = shift
	  or return $class->_error('You did not specify a file name');
	return $class->_error("File '$file' does not exist") unless -e $file;
	return $class->_error("'$file' is a directory, not a file") unless -f _;
	return $class->_error("Insufficient permissions to read '$file'")
	  unless -r _;

	# Slurp in the file
	local $/ = undef;
	local *CFG;
	unless ( open( CFG, $file ) ) {
		return $class->_error("Failed to open file '$file': $!");
	}
	my $contents = readline(*CFG);
	unless ( close(CFG) ) {
		return $class->_error("Failed to close file '$file': $!");
	}

	$class->read_string($contents);
} ## end sub read

# Create an object from a string
sub read_string {
	my $class = ref $_[0] ? ref shift : shift;
	my $self = bless [], $class;
	my $string = $_[0];
	unless ( defined $string ) {
		return $self->_error("Did not provide a string to load");
	}

	# Byte order marks
	# NOTE: Keeping this here to educate maintainers
	# my %BOM = (
	#     "\357\273\277" => 'UTF-8',
	#     "\376\377"     => 'UTF-16BE',
	#     "\377\376"     => 'UTF-16LE',
	#     "\377\376\0\0" => 'UTF-32LE'
	#     "\0\0\376\377" => 'UTF-32BE',
	# );
	if ( $string =~ /^(?:\376\377|\377\376|\377\376\0\0|\0\0\376\377)/ ) {
		return $self->_error("Stream has a non UTF-8 BOM");
	} else {

		# Strip UTF-8 bom if found, we'll just ignore it
		$string =~ s/^\357\273\277//;
	}

	# Try to decode as utf8
	utf8::decode($string) if HAVE_UTF8;

	# Check for some special cases
	return $self unless length $string;
	unless ( $string =~ /[\012\015]+\z/ ) {
		return $self->_error("Stream does not end with newline character");
	}

	# Split the file into lines
	my @lines = grep { !/^\s*(?:\#.*)?\z/ }
	  split /(?:\015{1,2}\012|\015|\012)/, $string;

	# Strip the initial YAML header
	@lines and $lines[0] =~ /^\%YAML[: ][\d\.]+.*\z/ and shift @lines;

	# A nibbling parser
	while (@lines) {

		# Do we have a document header?
		if ( $lines[0] =~ /^---\s*(?:(.+)\s*)?\z/ ) {

			# Handle scalar documents
			shift @lines;
			if ( defined $1 and $1 !~ /^(?:\#.+|\%YAML[: ][\d\.]+)\z/ ) {
				push @$self, $self->_read_scalar( "$1", [undef], \@lines );
				next;
			}
		}

		if ( !@lines or $lines[0] =~ /^(?:---|\.\.\.)/ ) {

			# A naked document
			push @$self, undef;
			while ( @lines and $lines[0] !~ /^---/ ) {
				shift @lines;
			}

		} elsif ( $lines[0] =~ /^\s*\-/ ) {

			# An array at the root
			my $document = [];
			push @$self, $document;
			$self->_read_array( $document, [0], \@lines );

		} elsif ( $lines[0] =~ /^(\s*)\S/ ) {

			# A hash at the root
			my $document = {};
			push @$self, $document;
			$self->_read_hash( $document, [ length($1) ], \@lines );

		} else {
			croak("YAML::Tiny failed to classify the line '$lines[0]'");
		}
	} ## end while (@lines)

	$self;
} ## end sub read_string

# Deparse a scalar string to the actual scalar
sub _read_scalar {
	my ( $self, $string, $indent, $lines ) = @_;

	# Trim trailing whitespace
	$string =~ s/\s*\z//;

	# Explitic null/undef
	return undef if $string eq '~';

	# Quotes
	if ( $string =~ /^\'(.*?)\'\z/ ) {
		return '' unless defined $1;
		$string = $1;
		$string =~ s/\'\'/\'/g;
		return $string;
	}
	if ( $string =~ /^\"((?:\\.|[^\"])*)\"\z/ ) {

		# Reusing the variable is a little ugly,
		# but avoids a new variable and a string copy.
		$string = $1;
		$string =~ s/\\"/"/g;
		$string =~
s/\\([never\\fartz]|x([0-9a-fA-F]{2}))/(length($1)>1)?pack("H2",$2):$UNESCAPES{$1}/gex;
		return $string;
	}

	# Special cases
	if ( $string =~ /^[\'\"!&]/ ) {
		croak(
			"YAML::Tiny does not support a feature in line '$lines->[0]'");
	}
	return {} if $string eq '{}';
	return [] if $string eq '[]';

	# Regular unquoted string
	return $string unless $string =~ /^[>|]/;

	# Error
	croak("YAML::Tiny failed to find multi-line scalar content")
	  unless @$lines;

	# Check the indent depth
	$lines->[0] =~ /^(\s*)/;
	$indent->[-1] = length("$1");
	if ( defined $indent->[-2] and $indent->[-1] <= $indent->[-2] ) {
		croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
	}

	# Pull the lines
	my @multiline = ();
	while (@$lines) {
		$lines->[0] =~ /^(\s*)/;
		last unless length($1) >= $indent->[-1];
		push @multiline, substr( shift(@$lines), length($1) );
	}

	my $j = ( substr( $string, 0, 1 ) eq '>' ) ? ' ' : "\n";
	my $t = ( substr( $string, 1, 1 ) eq '-' ) ? ''  : "\n";
	return join( $j, @multiline ) . $t;
} ## end sub _read_scalar

# Parse an array
sub _read_array {
	my ( $self, $array, $indent, $lines ) = @_;

	while (@$lines) {

		# Check for a new document
		if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
			while ( @$lines and $lines->[0] !~ /^---/ ) {
				shift @$lines;
			}
			return 1;
		}

		# Check the indent level
		$lines->[0] =~ /^(\s*)/;
		if ( length($1) < $indent->[-1] ) {
			return 1;
		} elsif ( length($1) > $indent->[-1] ) {
			croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
		}

		if ( $lines->[0] =~ /^(\s*\-\s+)[^\'\"]\S*\s*:(?:\s+|$)/ ) {

			# Inline nested hash
			my $indent2 = length("$1");
			$lines->[0] =~ s/-/ /;
			push @$array, {};
			$self->_read_hash( $array->[-1], [ @$indent, $indent2 ],
				$lines );

		} elsif ( $lines->[0] =~ /^\s*\-(\s*)(.+?)\s*\z/ ) {

			# Array entry with a value
			shift @$lines;
			push @$array,
			  $self->_read_scalar( "$2", [ @$indent, undef ], $lines );

		} elsif ( $lines->[0] =~ /^\s*\-\s*\z/ ) {
			shift @$lines;
			unless (@$lines) {
				push @$array, undef;
				return 1;
			}
			if ( $lines->[0] =~ /^(\s*)\-/ ) {
				my $indent2 = length("$1");
				if ( $indent->[-1] == $indent2 ) {

					# Null array entry
					push @$array, undef;
				} else {

					# Naked indenter
					push @$array, [];
					$self->_read_array( $array->[-1],
						[ @$indent, $indent2 ], $lines );
				}

			} elsif ( $lines->[0] =~ /^(\s*)\S/ ) {
				push @$array, {};
				$self->_read_hash( $array->[-1], [ @$indent, length("$1") ],
					$lines );

			} else {
				croak("YAML::Tiny failed to classify line '$lines->[0]'");
			}

		} elsif ( defined $indent->[-2] and $indent->[-1] == $indent->[-2] )
		{

			# This is probably a structure like the following...
			# ---
			# foo:
			# - list
			# bar: value
			#
			# ... so lets return and let the hash parser handle it
			return 1;

		} else {
			croak("YAML::Tiny failed to classify line '$lines->[0]'");
		}
	} ## end while (@$lines)

	return 1;
} ## end sub _read_array

# Parse an array
sub _read_hash {
	my ( $self, $hash, $indent, $lines ) = @_;

	while (@$lines) {

		# Check for a new document
		if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
			while ( @$lines and $lines->[0] !~ /^---/ ) {
				shift @$lines;
			}
			return 1;
		}

		# Check the indent level
		$lines->[0] =~ /^(\s*)/;
		if ( length($1) < $indent->[-1] ) {
			return 1;
		} elsif ( length($1) > $indent->[-1] ) {
			croak("YAML::Tiny found bad indenting in line '$lines->[0]'");
		}

		# Get the key
		unless ( $lines->[0] =~ s/^\s*([^\'\" ][^\n]*?)\s*:(\s+|$)// ) {
			if ( $lines->[0] =~ /^\s*[?\'\"]/ ) {
				croak(
"YAML::Tiny does not support a feature in line '$lines->[0]'"
				);
			}
			croak("YAML::Tiny failed to classify line '$lines->[0]'");
		}
		my $key = $1;

		# Do we have a value?
		if ( length $lines->[0] ) {

			# Yes
			$hash->{$key} =
			  $self->_read_scalar( shift(@$lines), [ @$indent, undef ],
				$lines );
		} else {

			# An indent
			shift @$lines;
			unless (@$lines) {
				$hash->{$key} = undef;
				return 1;
			}
			if ( $lines->[0] =~ /^(\s*)-/ ) {
				$hash->{$key} = [];
				$self->_read_array( $hash->{$key}, [ @$indent, length($1) ],
					$lines );
			} elsif ( $lines->[0] =~ /^(\s*)./ ) {
				my $indent2 = length("$1");
				if ( $indent->[-1] >= $indent2 ) {

					# Null hash entry
					$hash->{$key} = undef;
				} else {
					$hash->{$key} = {};
					$self->_read_hash( $hash->{$key},
						[ @$indent, length($1) ], $lines );
				}
			} ## end elsif ( $lines->[0] =~ /^(\s*)./)
		} ## end else [ if ( length $lines->[0...])]
	} ## end while (@$lines)

	return 1;
} ## end sub _read_hash

# Set error
sub _error {
	$YAML::Tiny::errstr = $_[1];
	undef;
}

# Retrieve error
sub errstr {
	$YAML::Tiny::errstr;
}



#####################################################################
# Use Scalar::Util if possible, otherwise emulate it

BEGIN {
	eval { require Scalar::Util; };
	if ($@) {

		# Failed to load Scalar::Util
		eval <<'END_PERL';
sub refaddr {
	my $pkg = ref($_[0]) or return undef;
	if (!!UNIVERSAL::can($_[0], 'can')) {
		bless $_[0], 'Scalar::Util::Fake';
	} else {
		$pkg = undef;
	}
	"$_[0]" =~ /0x(\w+)/;
	my $i = do { local $^W; hex $1 };
	bless $_[0], $pkg if defined $pkg;
	$i;
}
END_PERL
	} else {
		Scalar::Util->import('refaddr');
	}
} ## end BEGIN


#####################################################################
# main test
#####################################################################

package main;

BEGIN {

   # Skip modules that either don't want to be loaded directly, such as
   # Module::Install, or that mess with the test count, such as the Test::*
   # modules listed here.
   #
   # Moose::Role conflicts if Moose is loaded as well, but Moose::Role is in
   # the Moose distribution and it's certain that someone who uses
   # Moose::Role also uses Moose somewhere, so if we disallow Moose::Role,
   # we'll still get the relevant version number.

	my %skip = map { $_ => 1 } qw(
	  App::FatPacker
	  Class::Accessor::Classy
	  Module::Install
	  Moose::Role
	  Test::YAML::Meta
	  Test::Pod::Coverage
	  Test::Portability::Files
	  Test::Perl::Dist
	);

	my $Test = Test::Builder->new;

	$Test->plan( skip_all => "META.yml could not be found" )
	  unless -f 'META.yml' and -r _;

	my $meta = ( Local::YAML::Tiny->read('META.yml') )->[0];
	my %requires;
	for my $require_key ( grep {/requires/} keys %$meta ) {
		my %h = %{ $meta->{$require_key} };
		$requires{$_}++ for keys %h;
	}
	delete $requires{perl};

	diag("Testing with Perl $], $Config{archname}, $^X");
	for my $module ( sort keys %requires ) {
		if ( $skip{$module} ) {
			note "$module doesn't want to be loaded directly, skipping";
			next;
		}
		local $SIG{__WARN__} = sub { note "$module: $_[0]" };
		use_ok $module or BAIL_OUT("can't load $module");
		my $version = $module->VERSION;
		$version = 'undefined' unless defined $version;
		diag("    $module version is $version");
	}
	done_testing;
} ## end BEGIN

_____[ prereq.t ]____________________________________________
#!perl

# Test that all our prerequisites are defined in the Build.PL.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Prereq::Build 1.037',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

local $ENV{PERL_MM_USE_DEFAULT} = 1;

diag('Takes a few minutes...');

my @modules_skip = (
# Modules needed for prerequisites, not for this module
    # List here if needed.
# Needed only for AUTHOR_TEST tests
	'Parse::CPAN::Meta',
	'Perl::Critic',
	'Perl::Critic::More',
	'Perl::Critic::Utils::Constants',
	'Perl::MinimumVersion',
	'Perl::Tidy',
	'Pod::Coverage::Moose',
	'Pod::Coverage',
	'Pod::Simple',
	'Test::CPAN::Meta',
	'Test::DistManifest',
	'Test::MinimumVersion',
	'Test::Perl::Critic',
	'Test::Pod',
	'Test::Pod::Coverage',
	'Test::Portability::Files',
	'Test::Prereq::Build',
);

prereq_ok(5.008001, 'Check prerequisites', \@modules_skip);

_____[ portability.t ]_______________________________________
#!perl

# Test that our files are portable across systems.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Portability::Files 0.05',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

run_tests();

_____[ meta.t ]______________________________________________
#!perl

# Test that our META.yml file matches the specification

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
    'Parse::CPAN::Meta 1.40',
	'Test::CPAN::Meta 0.17',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

meta_yaml_ok();

_____[ manifest.t ]__________________________________________
#!perl

# Test that our MANIFEST describes the distribution

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::DistManifest 1.009',
);

# Load the testing modules
use Test::More;
unless ( -e 'MANIFEST.SKIP' ) {
	plan( skip_all => "MANIFEST.SKIP does not exist, so cannot test this." );
}
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

manifest_ok();

_____[ minimumversion.t ]____________________________________
#!perl

# Test that our declared minimum Perl version matches our syntax

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::MinimumVersion 1.26',
	'Test::MinimumVersion 0.101080',
);


# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

all_minimum_version_from_metayml_ok();

_____[ pod_coverage.t ]______________________________________
#!perl

# Test that modules are documented by their pod.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

# If using Moose, uncomment the appropriate lines below.
my @MODULES = (
#	'Pod::Coverage::Moose 0.01',
	'Pod::Coverage 0.21',
	'Test::Pod::Coverage 1.08',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

my @modules = all_modules();
my @modules_to_test = sort { $a cmp $b } @modules;
my $test_count = scalar @modules_to_test;
plan tests => $test_count;

foreach my $module (@modules_to_test) {
	pod_coverage_ok($module, { 
#		coverage_class => 'Pod::Coverage::Moose', 
		also_private => [ qr/^[A-Z_]+$/ ],
	});
}

_____[ pod.t ]_______________________________________________
#!perl

# Test that the syntax of our POD documentation is valid

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Simple 3.14',
	'Test::Pod 1.44',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

my @files = sort { $a cmp $b } all_pod_files();

all_pod_files_ok( @files );

_____[ fixme.t ]_____________________________________________
#!/usr/bin/perl

# Test that all modules have nothing marked to do.

use strict;

BEGIN {
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::Fixme 0.04',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

# To make this a todo test, remove the comments below, and the spaces
# between TO and DO in the next two lines.
#TO DO: {
#	local $TO DO = 'All modules are going to be fixed.';

	run_tests(
		match    => 'TO' . 'DO',                # what to check for
	);
#}

_____[ common_mistakes.t ]___________________________________
#!/usr/bin/perl

# Test that all modules have no common misspellings.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Pod::Spell::CommonMistakes 0.01',
	'Test::Pod::Spelling::CommonMistakes 0.01',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

all_pod_files_ok();

_____[ changes.t ]___________________________________________
#!/usr/bin/perl

# Test that the distribution's Changes file has been updated.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::CheckChanges 0.14',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

ok_changes(base => '..');

_____[ version.t ]___________________________________________

#!/usr/bin/perl

# Test that all modules have a version number.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Test::HasVersion 0.012',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" );
	}
}

all_pm_version_ok();

_____[ perlcritic.t ]________________________________________
#!perl

# Test that modules pass perlcritic and perltidy.

use strict;

BEGIN {
	BAIL_OUT ('Perl version unacceptably old.') if ($] < 5.008001);
	use English qw(-no_match_vars);
	$OUTPUT_AUTOFLUSH = 1;
	$WARNING = 1;
}

my @MODULES = (
	'Perl::Tidy',
	'Perl::Critic',
	'PPIx::Regexp',
	'PPIx::Utilities::Statement',
	'Email::Address',
	'Perl::Critic::Utils::Constants',
	'Perl::Critic::More',
	'Test::Perl::Critic',
);

# Load the testing modules
use Test::More;
foreach my $MODULE ( @MODULES ) {
	eval "require $MODULE"; # Has to be require because we pass options to import.
	if ( $EVAL_ERROR ) {
		BAIL_OUT( "Failed to load required release-testing module $MODULE" )
	}
}

$Perl::Critic::VERSION =~ s/_//;
if ( 1.108 > eval { $Perl::Critic::VERSION } ) {
	plan( skip_all => 'Perl::Critic needs updated to 1.108' );
}

if ( 20090616 > eval { $Perl::Tidy::VERSION } ) {
	plan( skip_all => "Perl::Tidy needs updated to 20090616" );
}

use File::Spec::Functions qw(catfile);
Perl::Critic::Utils::Constants->import(':profile_strictness');
my $dummy = $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET;

local $ENV{PERLTIDY} = catfile( 'xt', 'settings', 'perltidy.txt' );

my $rcfile = catfile( 'xt', 'settings', 'perlcritic.txt' );
Test::Perl::Critic->import( 
	-profile            => $rcfile, 
	-severity           => 1, 
	-profile-strictness => $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_QUIET
);
all_critic_ok();

_____[ perlcritic.txt ]__________________________________________
verbose = %f:%l:%c:\n %p: %m\n
theme = (core || more)

[ControlStructures::ProhibitPostfixControls]
flowcontrol = warn die carp croak cluck confess goto exit throw return next

[RegularExpressions::RequireExtendedFormatting]
minimum_regex_length_to_complain_about = 7

[InputOutput::RequireCheckedSyscalls]
functions = :builtins
exclude_functions = print

[Modules::PerlMinimumVersion]
version = 5.008001

[ValuesAndExpressions::ProhibitMagicNumbers]
allowed_values = -1 0 1 2

# Excluded because Moose builder subroutines get hit by this.
[Subroutines::ProhibitUnusedPrivateSubroutines]
private_name_regex = _(?!build_)\w+

# Exclusions
# This one can be removed if keywords are used.
[-Miscellanea::RequireRcsKeywords]

# Excluded because we filter out development versions.
[-ValuesAndExpressions::RequireConstantVersion]

# I like to set up my own pod.
[-Documentation::RequirePodAtEnd]
[-Documentation::RequirePodSections]

# No Emacs!
[-Editor::RequireEmacsFileVariables]

_____[ perltidy.txt ]____________________________________________
--backup-and-modify-in-place
--warning-output
--maximum-line-length=76
--indent-columns=4
--entab-leading-whitespace=4
# --check-syntax
# -perl-syntax-check-flags=-c
--continuation-indentation=2
--outdent-long-quotes
--outdent-long-lines
--outdent-labels
--paren-tightness=1
--square-bracket-tightness=1
--block-brace-tightness=1
--space-for-semicolon
--add-semicolons
--delete-semicolons
--indent-spaced-block-comments
--minimum-space-to-comment=3
--fixed-position-side-comment=40
--closing-side-comments
--closing-side-comment-interval=12
--static-block-comments
# --static-block-comment-prefix=^#{2,}[^\s#]
--static-side-comments
--format-skipping
--cuddled-else
--no-opening-brace-on-new-line
--vertical-tightness=1
--stack-opening-tokens
--stack-closing-tokens
--maximum-fields-per-table=8
--comma-arrow-breakpoints=0
--blanks-before-comments
--blanks-before-subs
--blanks-before-blocks
--long-block-line-count=4
--maximum-consecutive-blank-lines=5

_____[ MANIFEST.SKIP ]___________________________________________

# Avoid version control files.
\bRCS\b
\bCVS\b
\bSCCS\b
,v$
\B\.svn\b
\B\.git\b
\B\.gitignore\b
\B\.hg\b
\B\.hgignore\b
\B\.hgtags\b
\b_darcs\b

# Avoid Makemaker generated and utility files.
\bMANIFEST\.bak
\bMakefile$
\bblib/
\bMakeMaker-\d
\bpm_to_blib\.ts$
\bpm_to_blib$
\bblibdirs\.ts$         # 6.18 through 6.25 generated this

# Avoid temp and backup files.
~$
\.old$
\#$
\b\.#
\.bak$

# Avoid Devel::Cover files.
\bcover_db\b

# Avoid Module::Build generated and utility files.
\bBuild$
\bBuild.bat$
\b_build
\bBuild.COM$
\bBUILD.COM$
\bbuild.com$

# Avoid release automation.
\breleaserc$
\bMANIFEST\.SKIP$

# Avoid MYMETA.yml
^MYMETA.yml$
^MYMETA.json$

# Avoid archives of this distribution
\b<DISTRO>-[\d\.\_]+

_____[ Module.pm ]_______________________________________________
package <MODULE NAME>;

use 5.008001;
use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use parent 'Parent::Class';
#  use Exception::Class 1.29 {
#    ...
#  };
#  use Moose;

our $VERSION = '0.001';
$VERSION =~ s/_//sm;


# Module implementation here


1; # Magic true value required at end of module
__END__

=pod

!=begin readme text

<MODULE NAME> version 0.001

!=end readme

!=for readme stop

!=head1 NAME

<MODULE NAME> - [One line description of module's purpose here]

!=head1 VERSION

This document describes <MODULE NAME> version 0.001

!=begin readme

!=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

!=end readme

!=for readme stop

!=head1 SYNOPSIS

    use <MODULE NAME>;

!=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exemplary as possible.

!=head1 DESCRIPTION

!=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

!=head1 INTERFACE 

!=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

!=head1 DIAGNOSTICS

!=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

!=over

!=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

!=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

!=back

!=head1 CONFIGURATION AND ENVIRONMENT

!=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
<MODULE NAME> requires no configuration files or environment variables.

!=for readme continue

!=head1 DEPENDENCIES

!=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

!=for readme stop

!=head1 INCOMPATIBILITIES

!=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

!=head1 BUGS AND LIMITATIONS

!=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=<DISTRO>>
if you have an account there.

2) Email to E<lt>bug-<DISTRO>@rt.cpan.orgE<gt> if you do not.

!=head1 AUTHOR

<AUTHOR>  C<< <<EMAIL>> >>

!=for readme continue

!=head1 LICENSE AND COPYRIGHT

Copyright (c) <YEAR>, <AUTHOR> C<< <<EMAIL>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

!=for readme stop

!=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
