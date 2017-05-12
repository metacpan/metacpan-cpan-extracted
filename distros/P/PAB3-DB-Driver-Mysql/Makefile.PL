use 5.008;
use ExtUtils::MakeMaker ();
use Config;

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

my $_useit = ! $PAB || ( $PAB && $PAB_OPT{'with_mysql'} );

%_LIBREQ = %_LIBS = ( 'mysqlclient' => 1, 'z' => 1 );
@_LIB_PATH = qw(/usr/local/lib64 /usr/local/lib /usr/lib64 /usr/lib);
@_INC_PATH = qw(/usr/local/include/mysql /usr/include/mysql);
@_LIB_PATH_MY = qw(/usr/local/mysql/lib);
@_INC_PATH_MY = qw(/usr/local/mysql/include);
@_OBJECT = ();
@_EXT = ( '.so', '.a', '.dll', '.dylib' );

if( ! $os_supported{$^O} ) {
	if( $PAB && $PAB_OPT{'with_mysql'} eq '_auto_' ) {
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
    NAME => 'PAB3::DB::Driver::Mysql',
    VERSION_FROM => 'Mysql.pm',
    ABSTRACT => 'A Perl5 wrapper for MySQL and a driver for the PAB3::DB class',
    XSPROTOARG => '-prototypes',
    PREREQ_PM => {},
    OBJECT => '$(O_FILES)',
    XS => { 'Mysql.xs' => 'Mysql.c' },
    C => [ 'my_mysql.c', 'Mysql.c' ],
    DEFINE => '',
    PL_FILES => { 'install_files.PL' => $PAB ? 'pab' : 'self' },
);

if( ! $_useit ) {
	&donotuse();
	ExtUtils::MakeMaker::WriteMakefile( %_MAKEOPTS );
	$PAB ? return 1 : exit 0;
}

my $mc = 'mysql_config';

if( $^O eq 'MSWin32' ) {
	print "*****************************************************************\n";
	print "***       Tested with MS-VC 7.10 and MySQL 5.0.37 Dll         ***\n";
	print "*****************************************************************\n";
	$mc = undef;
	@_LIB_PATH_MY = @_LIB_PATH = ();
	@_INC_PATH_MY = @_INC_PATH = ();
	%_LIBREQ = %_LIBS = ( 'mysql' => 'inst' );
	@_EXT = ( '.dll' );
	#@_OBJECT = ( 'mysqlclient.lib' );
	require Win32::TieRegistry;
	import Win32::TieRegistry;
	$Registry->Delimiter( '/' );
	$keys = $Registry->{'HKEY_LOCAL_MACHINE/Software/MySQL AB'};
	if( $keys ) {
		foreach( keys %$keys ) {
			next if ! ref( $keys->{$_} ) || ! $keys->{$_}->{'Location'};
			my $path = $keys->{$_}->{'Location'};
			$path =~ s!\\!\\\\!g;
			my $inc = $path . 'include/mysql.h';
			if( -f $inc ) {
				push( @_INC_PATH_MY, $path . 'include' );
				push( @_LIB_PATH_MY, $path . 'bin', $path . 'lib', $path . 'lib\\opt' );
			}
		}
	}
    my $path = 'c:\\program files\\mysql\\';
	if( ! @_INC_PATH_MY && -d $path ) {
	    my( $dir, @items, $cp );
	    opendir( $dir, $path );
	    @items = grep{ ! /^\./ && -d $path . $_ } readdir( $dir );
	    closedir( $dir );
	    foreach( @items ) {
	        $cp = $path . $_ . '\\';
	        if( -f $cp . 'include/mysql.h' ) {
				push( @_INC_PATH_MY, $cp . 'include' );
				push( @_LIB_PATH_MY, $cp . 'bin', $cp . 'lib', $cp . 'lib\\opt' );
	        }
	    }
	}
	$_MAKEOPTS{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
}

if( $PAB_OPT{'with_mysql'} ) {
	if( -d $PAB_OPT{'with_mysql'} ) {
		@_INC_PATH_MY = ( $PAB_OPT{'with_mysql'} . '/include' );
		@_LIB_PATH_MY = ( $PAB_OPT{'with_mysql'} . '/lib' );
		if( $^O eq 'MSWin32' ) {
			unshift @_LIB_PATH_MY, $PAB_OPT{'with_mysql'} . '/lib/opt';
			unshift @_LIB_PATH_MY, $PAB_OPT{'with_mysql'} . '/bin';
		}
		$mc = 0;
	}
	elsif( -x $PAB_OPT{'with_mysql'} ) {
		$mc = $PAB_OPT{'with_mysql'};
	}
}

if( $Config{'usethreads'} ) {
	$_MAKEOPTS{'DEFINE'} .= ' -DUSE_THREADS';
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
	if( /--mysql_config=(.+)/ ) {
		$mc = $1;
	}
	elsif( /--mysql_dir=(.+)/ ) {
		@_INC_PATH_MY = ( $1 . '/include' );
		@_LIB_PATH_MY = ( $1 . '/bin', $1 . '/lib', $1 . '/lib/opt' );
		$lb = $ic = 1;
	}
	elsif( /--libs=(.+)/ ) {
		&parse_lib( $lb = $1 );
	}
	elsif( /--include=(.+)/ ) {
		&parse_inc( $ic = $1 );
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
		&parse_inc( $ic = `$mc --include` );
	}
	if( ! $lb ) {
		&parse_lib( $lb = `$mc --libs` );
	}
}
unshift @_LIB_PATH, @_LIB_PATH_MY;
unshift @_INC_PATH, @_INC_PATH_MY;
print $TERM_BLUE, "Preparing ", $TERM_YELLOW, $_MAKEOPTS{'NAME'}, $TERM_RESET, "\n";
foreach $lib( keys %_LIBS ) {
	print $TERM_WHITE, "Looking for ", $TERM_GREEN, "lib$lib", $TERM_RESET, " ...";
	$found = 0;
	foreach $path( @_LIB_PATH ) {
		foreach $ext( @_EXT ) {
			my $file = $path . '/lib' . $lib . $ext;
			if( -f $file ) {
				print $TERM_WHITE, "\n  found at ", $TERM_MAGENTA, $file, $TERM_RESET;
				$found = 1;
				if( $_LIBS{$lib} eq 'inst' ) {
					&file_copy( $file, 'lib' . $lib . $ext );
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
	if( $PAB && $PAB_OPT{'with_mysql'} eq '_auto_' ) {
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
    --mysql_dir=DIR        DIR is the path to the MySQL base directory
    --mysql_config=FILE    FILE is the pathname to mysql_config
    --libs=LIBS            Use LIBS for running the linker; defaults to the value of "mysql_config --libs" or a guessed value
    --include=INCLUDE      Use INCLUDE for running the comiler; defaults to the value of "mysql_config --include" or a guessed value
EOTH
	exit( 256 );
}

sub donotuse {
	$_MAKEOPTS{'XS'} = {};
	$_MAKEOPTS{'C'} = [];
	$_MAKEOPTS{'OBJECT'} = '';
	$_MAKEOPTS{'PM'} = {};
    $_MAKEOPTS{'PL_FILES'} = {};
	rename 't', '_t' if -d 't';
}

sub parse_inc {
	my $ic = shift;
	@_INC_PATH_MY = ();
	foreach( split( /\"*(.+?)\"*\s+/, $ic ) ) {
		chomp;
		next unless $_;
		if( substr( $_, 0, 2 ) eq '-I' ) {
			push @_INC_PATH_MY, substr( $_, 2 );
		}
	}
}

sub parse_lib {
	$lb = shift;
	@_LIB_PATH_MY = ();
	foreach( split( /\"*(.+?)\"*\s+/, $lb ) ) {
		chomp;
		next unless $_;
		if( substr( $_, 0, 2 ) eq '-L' ) {
			push @_LIB_PATH_MY, substr( $_, 2 );
		}
		elsif( substr( $_, 0, 2 ) eq '-l' ) {
			$_LIBS{ substr( $_, 2 ) } = 2;
			$_LIBREQ{ substr( $_, 2 ) } = 2;
		}
	}
}

sub file_copy {
	my( $src, $dst ) = @_;
	my( $sfh, $dfh, $buf );
	return if ! -f $src;
	open( $sfh, '<', $src ) or warn "Can not open $src: $!";
	binmode( $sfh );
	open( $dfh, '>', $dst ) or warn "Can not open $dst: $!";
	binmode( $dfh );
	while( read( $sfh, $buf, 8192 ) ) {
		print $dfh $buf;
	}
	close( $dfh );
	close( $sfh );
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
