use 5.008;
use ExtUtils::MakeMaker ();
use Config;

require 'copy_dlls.PL';

$ExtUtils::MakeMaker::Verbose = 0;

%os_supported = ( 'linux' => 1, 'MSWin32' => 1, 'darwin' => 1 );

our $TERM_RED			= "\033[31;1m";
our $TERM_GREEN			= "\033[32;1m";
our $TERM_YELLOW		= "\033[33;1m";
our $TERM_BLUE			= "\033[34;1m";
our $TERM_MAGENTA		= "\033[35;1m";
our $TERM_CYAN			= "\033[36;1m";
our $TERM_WHITE			= "\033[37;1m";
our $TERM_RESET			= "\033[m";

my $_useit = !$PAB || ($PAB && $PAB_OPT{'with_pgsql'});

%_LIBREQ = %_LIBS = ( 'pq' => 1 );
@_LIB_PATH = qw(/usr/local/lib64 /usr/local/lib /usr/lib64 /usr/lib);
@_INC_PATH = qw(/usr/local/include/pgsql /usr/include/pgsql);
@_LIB_PATH_MY = qw(/usr/local/pgsql/lib);
@_INC_PATH_MY = qw(/usr/local/pgsql/include);
@_EXT = ( '.so', '.a', '.dll', '.dylib' );
$_LIBPREFIX = 'lib';
$_BIN_DIR = '';

if( !$os_supported{$^O} ) {
	if( $PAB && $PAB_OPT{'with_pgsql'} eq '_auto_' ) {
		$_useit = 0;
	}
	elsif( $_useit ) {
		print <<EOF1;
************* WARNING *************
* Your operation system is not    *
* supported.                      *
* The installation may fail!      *
***********************************
EOF1
	}
}

%_MAKEOPTS = (
    NAME => 'PAB3::DB::Driver::Postgres',
    VERSION_FROM => 'Postgres.pm',
    ABSTRACT => 'Perl5 wrapper to libpgsql',
    XSPROTOARG => '-prototypes',
    PREREQ_PM => {},
    DEFINE => '',
    OBJECT => '$(O_FILES)',
    XS => { 'Postgres.xs' => 'Postgres.c' },
    C => [ 'my_postgres.c', 'Postgres.c' ],
    PL_FILES => { 'copy_dlls.PL' => $PAB ? 'pab' : 'self' },
);

if( ! $_useit ) {
	&donotuse();
	ExtUtils::MakeMaker::WriteMakefile( %_MAKEOPTS );
	$PAB ? return 1 : exit 0;
}

$mc = 'pg_config';

if( $^O eq 'MSWin32' ) {
	print "*****************************************************************\n";
	print "***         Tested with MS-VC 7.10 and Postgres 8.2.4         ***\n";
	print "*****************************************************************\n";
	$mc = undef;
	@_LIB_PATH_MY = @_LIB_PATH = ();
	@_INC_PATH_MY = @_INC_PATH = ();
	%_LIBREQ = %_LIBS = ( 'libpq' => 1 );
	@_EXT = ( '.dll' );
	#@_OBJECT = ( 'libpq.lib' );
	$_LIBPREFIX = '';
	require Win32::TieRegistry;
	import Win32::TieRegistry;
	$Registry->Delimiter( '/' );
	$keys = $Registry->{'HKEY_LOCAL_MACHINE/Software/PostgreSQL/Installations'};
	if( $keys ) {
		foreach( sort keys %$keys ) {
			next if ! ref( $keys->{$_} ) || ! $keys->{$_}->{'Base Directory'};
			my $path = $keys->{$_}->{'Base Directory'};
			$path =~ s!\\!\\\\!g;
			my $inc = $path . 'include\\libpq-fe.h';
			if( -f $inc ) {
				$_BIN_DIR = $path . 'bin';
				unshift( @_INC_PATH_MY, $path . 'include' );
				unshift( @_LIB_PATH_MY, $path . 'bin', $path . 'lib', $path . 'lib\\ms' );
				&copy_dlls( $path . 'bin/', '' );
			}
			if( -x $path . 'bin/pg_config.exe' ) {
				$mc = $path . 'bin/pg_config.exe';
			}
		}
	}
}

if( $PAB_OPT{'with_pgsql'} ) {
	if( -d $PAB_OPT{'with_pgsql'} ) {
		@_INC_PATH_MY = ( $PAB_OPT{'with_pgsql'} . '/include' );
		@_LIB_PATH_MY = ( $PAB_OPT{'with_pgsql'} . '/lib' );
		$_BIN_DIR = $PAB_OPT{'with_pgsql'} . '/bin';
		&copy_dlls( $_BIN_DIR . '/', '' );
		$mc = 0;
	}
	elsif( -x $PAB_OPT{'with_pgsql'} ) {
		$mc = $PAB_OPT{'with_pgsql'};
	}
}

if( $Config{'usethreads'} ) {
	$_MAKEOPTS{'DEFINE'} .= ' -DUSE_THREADS';
}
if( $^O eq 'MSWin32' ) {
	$_MAKEOPTS{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
}

if( $^O ne 'linux' ) {
	$TERM_RED = $TERM_GREEN = $TERM_YELLOW = $TERM_BLUE = $TERM_MAGENTA =
		$TERM_CYAN = $TERM_WHITE = $TERM_RESET = '';
}

@argv = ();
foreach( @ARGV ) {
	if( /--help/ ) {
		print_usage();
	}
	if( /--pg_config=(.+)/ ) {
		$mc = $1;
	}
	elsif( /--pg_base=(.+)/ ) {
		@_INC_PATH_MY = ( $1 . '/include' );
		@_LIB_PATH_MY = ( $1 . '/lib' );
		$_BIN_DIR = $1 . '/bin';
		&copy_dlls( $_BIN_DIR . '/', '' );
		$bd = $lb = $ic = 1;
	}
	elsif( /--libdir=(.+)/ ) {
		@_LIB_PATH_MY = ( $1 );
		$lb = 1;
	}
	elsif( /--bindir=(.+)/ ) {
		$_BIN_DIR = $1;
		&copy_dlls( $_BIN_DIR . '/', '' );
		$bd = 1;
	}
	elsif( /--incdir=(.+)/ ) {
		@_INC_PATH_MY = ( $1 );
		$ic = 1;
	}
	else {
		push @argv, $_;
	}
}
@ARGV = @argv;

$out = select( STDOUT );
$| = 1;
select( $out );

$res = $mc ? `$mc --version` : 0;
if( $res ) {
	if( ! $ic ) {
		$ic = `$mc --includedir`;
		$ic =~ s![\n\r]+$!!;
		@_INC_PATH_MY = ( $ic );
	}
	if( ! $lb ) {
		$lb = `$mc --libdir`;
		$lb =~ s![\n\r]+$!!;
		@_LIB_PATH_MY = ( $lb );
		if( $^O eq 'MSWin32' ) {
			unshift @_LIB_PATH_MY, $lb . '/ms';
			$lb = `$mc --bindir`;
			$lb =~ s![\n\r]+$!!;
			unshift @_LIB_PATH_MY, $lb;
			&copy_dlls( $lb . '/', '' );
		}
	}
	if( ! $bd ) {
		$bd = `$mc --bindir`;
		$bd =~ s![\n\r]+$!!;
		$_BIN_DIR = $bd;
	}
}

unshift @_LIB_PATH, @_LIB_PATH_MY;
unshift @_INC_PATH, @_INC_PATH_MY;
print $TERM_BLUE, "Preparing ", $TERM_YELLOW, $_MAKEOPTS{'NAME'}, $TERM_RESET, "\n";
foreach $lib( keys %_LIBS ) {
	print $TERM_WHITE, "Looking for ", $TERM_GREEN, $_LIBPREFIX . "$lib", $TERM_RESET, " ...";
	$found = 0;
	foreach $path( @_LIB_PATH ) {
		foreach $ext( @_EXT ) {
			my $file = $path . '/' . $_LIBPREFIX . $lib . $ext;
			if( -f $file ) {
				print $TERM_WHITE, "\n  found at ", $TERM_MAGENTA, $file, $TERM_RESET;
				$found = 1;
				if( $_LIBS{$lib} eq 'inst' ) {
					&file_copy( $file, $_LIBPREFIX . $lib . $ext );
				}
			}
		}
	}
	if( ! $found ) {
		print $TERM_RED, " not found", $TERM_RESET;
		delete $_LIBS{$lib};
	}
	print "\n";
}
if( $^O eq 'MSWin32' ) {
	$_MAKEOPTS{'LIBS'} = [
		join( ' ', map{ '"-L' . $_ . '"' } @_LIB_PATH ) . ' '
		. join( ' ', map{ '-l' . $_ } keys %_LIBS )
		. ' ' . join( ' ', @_OBJECT )
	];
	$_MAKEOPTS{'INC'} = join( ' ', map{ '"-I' . $_ . '"' } @_INC_PATH );
}
else {
	$_MAKEOPTS{'LIBS'} = [
		join( ' ', map{ '-L' . $_ } @_LIB_PATH ) . ' '
		. join( ' ', map{ '-l' . $_ } keys %_LIBS )
		. ' ' . join( ' ', @_OBJECT )
	];
	$_MAKEOPTS{'INC'} = join( ' ', map{ '-I' . $_ } @_INC_PATH );
}
$found = 1;
foreach( keys %_LIBREQ ) {
	if( ! $_LIBS{$_} ) {
		$found = 0;
		last;
	}
}
if( ! $found ) {
	if( $PAB && $PAB_OPT{'with_pgsql'} eq '_auto_' ) {
		&donotuse();
	}
	else {
		print <<EOF1;
************* WARNING *************
* Some required libraries has not *
* been found.                     *
* The installation may fail!      *
***********************************
EOF1
	}
}
else {
	rename '_t', 't' if -d '_t';
}
ExtUtils::MakeMaker::WriteMakefile( %_MAKEOPTS );

1;

sub print_usage {
	print <<EOTH;
Usage: perl $0 [options]
Options:
    --help                 print this message
    --pg_base=DIR          DIR is the PostgreSQL base directory
    --pg_config=FILE       FILE is the pathname to pg_config
    --libdir=DIR           Use DIR for running the linker; defaults to the value of "pg_config --libdir" or a guessed value
    --incdir=DIR           Use DIR for running the comiler; defaults to the value of "pg_config --includedir" or a guessed value
    --bindir=DIR           Use DIR for copying dlls on MSWin32; defaults to the value of "pg_config --bindir" or a guessed value
EOTH
	exit( 256 );
}

sub donotuse {
	$_MAKEOPTS{'XS'} = {};
	$_MAKEOPTS{'C'} = [];
	$_MAKEOPTS{'OBJECT'} = '';
	$_MAKEOPTS{'PM'} = {};
    $_MAKEOPTS{'PL_FILES'} => {};
	rename 't', '_t' if -d 't';
}

package MY;

sub cflags {
    my $inherited = shift->SUPER::cflags( @_ );
    if( $^O eq 'MSWin32' ) {
	    $inherited =~ s/-O1/-O2/sg;
    	# set static linking to crt
	    $inherited =~ s/-MD/-MT/sg;
	}
    $inherited;
}

sub const_loadlibs {
    my $inherited = shift->SUPER::const_loadlibs( @_ );
    if( $^O eq 'MSWin32' ) {
    	# set static linking to crt
	    $inherited =~ s/msvcrt\.lib/libcmt\.lib/sgi;
	}
    $inherited;
}
