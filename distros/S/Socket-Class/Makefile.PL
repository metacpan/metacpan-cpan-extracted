package Socket::Class::Install;
use 5.006;
use ExtUtils::MakeMaker;
use Config;

my %os_supported = (
	'linux' => 1, 'MSWin32' => 1, 'darwin' => 1, 'cygwin' => 1, 'aix' => 1,
	'solaris' => 1, 'os390' => 1, 'hpux' => 1, 'freebsd' => 1,
);

if( ! $os_supported{$^O} ) {
print <<EOF1;
************* WARNING *************
* Your operation system has NOT   *
* been tested.                    *
***********************************
EOF1
}

my @argv = ();
foreach my $p( @ARGV ) {
	$_ = lc( $p );
	if( /--debug/ ) {
		if( /--debug=(\d+)/ ) {
			$_DEBUG = $1;
		}
		else {
			$_DEBUG = 1;
		}
	}
	elsif( /--verbose/ ) {
		$Verbose = 1;
	}
	elsif( /--help/ ) {
		&print_usage();
	}
	else {
		push @argv, $p;
	}
}
@ARGV = @argv;

%_MAKEOPTS = (
	'NAME' => 'Socket::Class',
	'VERSION_FROM' => 'Class.pm',
	'LIBS' => [ '' ],
	'DEFINE' => '',
	'INC' => '',
	'XSPROTOARG' => '-noprototypes',
	'PREREQ_PM' => {
	},
	'OBJECT' => '$(O_FILES)',
	'XS' => {'Class.xs' => 'Class.c'},
	'C' => ['sc_mod_def.c', 'socket_class.c', 'Class.c'],
	'H' => ['mod_sc.h', 'sc_mod_def.h', 'socket_class.h'],
	'DIR' => [ 'xs' ],
);

if( $_DEBUG ) {
	$ENV{'SC_DEBUG'} = $_DEBUG;
	print "Enable debug messages in Socket::Class level($_DEBUG)\n";
	$_MAKEOPTS{'DEFINE'} .= ' -DSC_DEBUG=' . $_DEBUG;
	if( $^O eq 'linux' ) {
		$_MAKEOPTS{'DEFINE'} .= ' -Wall';
	}
}
if( $^O eq 'MSWin32' ) {
	$_MAKEOPTS{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
	# help makemaker removing not existing libs, eg. bufferoverflowU.lib
	push @{$_MAKEOPTS{'LIBS'}}, '-lws2_32';
}
elsif( $^O eq 'cygwin' ) {
	push @{$_MAKEOPTS{'LIBS'}}, '-L/lib/w32api -lole32 -lversion -lws2_32';
}

if( $^O eq 'MSWin32' ) {
	if( $Config{'cc'} !~ /gcc/ ) {
		@_IP = split( ';', $ENV{'INCLUDE'} );
		$r = find_header_item( \@_IP, 'winsock2.h', 'getaddrinfo' );
		$r += find_header_item( \@_IP, 'winsock2.h', 'freeaddrinfo' );
		$r += find_header_item( \@_IP, 'winsock2.h', 'getnameinfo' );
		if( $r < 3 ) {
			$_MAKEOPTS{'DEFINE'} .= ' -DSC_OLDNET';
		}
		# bug #37639
		$ExtUtils::MM_Win32::Config{'ccversion'} = 13;
	}
}
else {
	@_IP = qw(/usr/local/include /usr/include /opt/include);
	$r = find_header_item( \@_IP, 'netdb.h', 'getaddrinfo' );
	$r += find_header_item( \@_IP, 'netdb.h', 'freeaddrinfo' );
	$r += find_header_item( \@_IP, 'netdb.h', 'getnameinfo' );
	if( $r < 3 ) {
		$_MAKEOPTS{'DEFINE'} .= ' -DSC_OLDNET';
	}
	$r = find_header_item( \@_IP, 'time.h', 'nanosleep' );
	if( $r ) {
		$_MAKEOPTS{'DEFINE'} .= ' -DSC_HAS_NANOSLEEP';
		if( $^O eq 'solaris' ) {
			$_MAKEOPTS{'LIBS'}->[0] .= ' -lrt';
		}
	}
}

if( $^O eq 'linux' && 0 ) {
	unshift @{$_MAKEOPTS{'C'}}, 'sc_bluez.c';
	unshift @{$_MAKEOPTS{'H'}}, 'sc_bluez.h';
	push @{$_MAKEOPTS{'LIBS'}}, '-lbluetooth';
	$_MAKEOPTS{'DEFINE'} .= ' -DSC_USE_BLUEZ -DSC_HAS_BLUETOOTH';
	$_MAKEOPTS{'XS'}->{'Bluetooth.xs'} = 'Bluetooth.c';
	push @{$_MAKEOPTS{'C'}}, 'Bluetooth.c';
}
elsif( $^O eq 'MSWin32' && 0 ) {
	unshift @{$_MAKEOPTS{'C'}}, 'sc_ws2bth.c';
	unshift @{$_MAKEOPTS{'H'}}, 'sc_ws2bth.h';
	$_MAKEOPTS{'DEFINE'} .= ' -DSC_USE_WS2BTH -DSC_HAS_BLUETOOTH';
	$_MAKEOPTS{'XS'}->{'Bluetooth.xs'} = 'Bluetooth.c';
	push @{$_MAKEOPTS{'C'}}, 'Bluetooth.c';
}

WriteMakefile( %_MAKEOPTS );

1;

sub find_header_item {
	my( $inc, $file, $item, $level, $reflist ) = @_;
	my( $fh, @ct, $p );
	$reflist ||= {};
	$reflist->{$file} = 1;
	$level ||= 0;
	$level or print "Looking for '$item' ... ";
	foreach $p( @$inc ) {
		$p =~ s/^\"(.+)\"$/$1/;
		$_ = $p . '/' . $file;
		-f or next;
		open $fh, '<' . $_;
		@ct = <$fh>;
		close $fh;
		foreach( @ct ) {
			if( m!^\#include\s+[\<\"]([\w\.\_\/\\]+?\.h\w*)[\"\>]! ) {
				next if $reflist->{$1};
				find_header_item( $inc, $1, $item, $level + 1, $reflist )
					and return 1;
			}
			if( index( $_, $item ) >= 0 ) {
				print "found\n";
				return 1;
			}
		}
	}
	$level or print "NOT found\n";
	return 0;
}

sub print_usage {
	print <<EOTH;

Usage: perl $0 [options]
Options:
    --help                 print this message
    --debug[=LEVEL]        compile with debug messages enabled (level 1-2)
    --verbose              enable MakeMakers verbosity
    --openssl-dir=DIR      path to the OpenSSL Toolkit

EOTH
	exit 256;
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
	    #$inherited =~ s/\/GS//sg;
	}
    $inherited;
}
