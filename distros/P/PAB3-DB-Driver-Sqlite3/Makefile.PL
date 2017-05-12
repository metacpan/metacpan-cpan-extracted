#package PAB3::DB::Driver::Sqlite3::Makefile;

use 5.008;
use ExtUtils::MakeMaker ();
use Config;

$ExtUtils::MakeMaker::Verbose = 0;

my %MY_MAKEOPTS = ();

my %os_supported = ( 'linux' => 1, 'darwin' => 1 );

my $TERM_RED			= "\033[31;1m";
my $TERM_GREEN			= "\033[32;1m";
my $TERM_YELLOW			= "\033[33;1m";
my $TERM_BLUE			= "\033[34;1m";
my $TERM_MAGENTA		= "\033[35;1m";
my $TERM_CYAN			= "\033[36;1m";
my $TERM_WHITE			= "\033[37;1m";
my $TERM_RESET			= "\033[m";

my $_useit = ! $PAB || ( $PAB && $PAB_OPT{'with_sqlite3'} );

my( @_INC, %_LIBREQ, %_LIBS, @_LIB_PATH, @_INC_PATH, @_EXT, $lb, $ic );
@_INC = qw(sqlite3.h);
%_LIBREQ = %_LIBS = ( 'sqlite3' => 1 );
@_LIB_PATH = qw(/usr/local/lib64 /usr/local/lib /usr/lib64 /usr/lib);
@_INC_PATH = (split( ' ', $Config{'incpath'} ), split( ' ', $Config{'locincpth'} ));

@_EXT = ( '.so', '.a', '.dll', '.dylib' );

if( ! $os_supported{$^O} ) {
	if( $PAB && $PAB_OPT{'with_sqlite3'} eq '_auto_' ) {
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

%MY_MAKEOPTS = (
    NAME => 'PAB3::DB::Driver::Sqlite3',
    VERSION_FROM => 'Sqlite3.pm',
    ABSTRACT => 'Perl wrapper to Sqlite3',
    XSPROTOARG => '-prototypes',
    PREREQ_PM => {},
    OBJECT => '$(O_FILES)',
    XS => { 'Sqlite3.xs' => 'Sqlite3.c' },
    C => [ 'my_sqlite3.c', 'Sqlite3.c' ],
    DEFINE => '',
    PL_FILES => { 'install_files.PL' => $PAB ? 'pab' : 'self' },
);

if( ! $_useit ) {
	&donotuse();
	ExtUtils::MakeMaker::WriteMakefile( %MY_MAKEOPTS );
	$PAB ? return 1 : exit 0;
}

if( $PAB_OPT{'with_sqlite3'} ) {
	if( -d $PAB_OPT{'with_sqlite3'} ) {
		@_INC_PATH = ( $PAB_OPT{'with_sqlite3'} . '/include' );
		unshift @_LIB_PATH, $PAB_OPT{'with_sqlite3'} . '/lib';
		$lb = $ic = 1;
	}
}

if( $Config{'usethreads'} ) {
	$MY_MAKEOPTS{'DEFINE'} .= ' -DUSE_THREADS';
}
if( $PAB_OPT{'sqlite3_enable_metadata'} ) {
	$MY_MAKEOPTS{'DEFINE'} .= ' -DSQLITE_ENABLE_COLUMN_METADATA';
}
if( $^O eq 'darwin' ) {
	$MY_MAKEOPTS{'DEFINE'} .= ' -fnested-functions';
}
if( $^O eq 'MSWin32' ) {
	$MY_MAKEOPTS{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
}

if( $^O ne 'linux' ) {
	$TERM_RED = $TERM_GREEN = $TERM_YELLOW = $TERM_BLUE = $TERM_MAGENTA =
		$TERM_CYAN = $TERM_WHITE = $TERM_RESET = '';
}

my @argv = ();
foreach( @ARGV ) {
	if( /--help/ ) {
		print_usage();
	}
	elsif( /--libdir=(.+)/ ) {
		@_LIB_PATH = ( $lb = $1 );
	}
	elsif( /--incdir=(.+)/ ) {
		@_INC_PATH = ( $ic = $1 );
	}
	else {
		push @argv, $_;
	}
}
@ARGV = @argv;

my $out = select( STDOUT );
$| = 1;
select( $out );

print $TERM_BLUE, "Preparing ", $TERM_YELLOW, $MY_MAKEOPTS{'NAME'}, $TERM_RESET, "\n";
foreach my $lib( keys %_LIBS ) {
	print $TERM_WHITE, "Looking for ", $TERM_GREEN, "lib$lib", $TERM_RESET, " ...";
	my $found = 0;
	foreach my $path( @_LIB_PATH ) {

		foreach my $ext( @_EXT ) {
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
	$MY_MAKEOPTS{'LIBS'} = [
		join( ' ', map{ '"-L' . $_ . '"' } @_LIB_PATH ) . ' '
		. join( ' ', map{ '-l' . $_ } keys %_LIBS )
	];
	$MY_MAKEOPTS{'INC'} = join( ' ', map{ '"-I' . $_ . '"' } @_INC_PATH );
}
else {
	$MY_MAKEOPTS{'LIBS'} = [
		join( ' ', map{ '-L' . $_ } @_LIB_PATH ) . ' '
		. join( ' ', map{ '-l' . $_ } keys %_LIBS )
	];
	$MY_MAKEOPTS{'INC'} = join( ' ', map{ '-I' . $_ } @_INC_PATH );
}

my $found = 1;
foreach( keys %_LIBREQ ) {
	if( ! $_LIBS{$_} ) {
		$found = 0;
		last;
	}
}
if( $found ) {
	$found = find_header_item( \@_INC_PATH, 'sqlite3.h', 'sqlite3_prepare' );
}
if( $found ) {
	my $r = find_header_item( \@_INC_PATH, 'sqlite3.h', 'sqlite3_prepare_v2' );
	if( $r ) {
		$MY_MAKEOPTS{'DEFINE'} .= ' -DSQLITE_HAS_V2';
	}
}
if( ! $found ) {
	if( $PAB && $PAB_OPT{'with_sqlite3'} eq '_auto_' ) {
		&donotuse();
		WriteMakefile( %MY_MAKEOPTS );
		$PAB ? return 1 : exit 0;
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

rename '_t', 't' if -d '_t';
#use PAB3;
#PAB3::print_r( \%MY_MAKEOPTS );
ExtUtils::MakeMaker::WriteMakefile( %MY_MAKEOPTS );

1;

sub print_usage {
	print <<EOTH;
Usage: perl $0 [options]
Options:
    --help            print this message
    --libdir=DIR      Use DIR for running the linker; defaults to a guessed value
    --incdir=DIR      Use DIR for running the comiler; defaults to a guessed value
EOTH
	exit( 256 );
}

sub donotuse {
	$MY_MAKEOPTS{'XS'} = {};
	$MY_MAKEOPTS{'C'} = [];
	$MY_MAKEOPTS{'OBJECT'} = '';
	$MY_MAKEOPTS{'PM'} = {};
    $MY_MAKEOPTS{'PL_FILES'} = {};
	rename 't', '_t' if -d 't';
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

sub find_header_item {
	my( $inc, $file, $item, $level, $reflist ) = @_;
	my( $fh, @ct, $p );
	$reflist ||= {};
	$reflist->{$file} = 1;
	$level ||= 0;
	$level or print "Looking for '$item' ... ";
	foreach $p( @$inc ) {
		$_ = $p . '/' . $file;
		-f or next;
		open $fh, '<' . $_;
		@ct = <$fh>;
		close $fh;
		foreach( @ct ) {
			if( m!^\#include\s+[\<\"]([\w\.\_\/\\]+?\.h\w*)[\"\>]! ) {
			#if( m!^\#include! ) {
				next if $reflist->{$1};
				#print "include $1\n";
				return 1 if find_header_item( $inc, $1, $item, $level + 1, $reflist );
			}
			if( index( $_, $item ) >= 0 ) {
				print "found\n";
				return 1;
			}
		}
	}
	$level or print "not found\n";
	return 0;
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
