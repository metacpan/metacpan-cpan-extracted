package PAB3::Install;
use 5.008;
use ExtUtils::MakeMaker;

%os_supported = ( 'linux' => 1, 'MSWin32' => 1, 'darwin' => 1 );

if( ! $os_supported{$^O} ) {
print <<EOF1;
************* WARNING *************
* Your operation system has not   *
* been tested.                    *
* The installation may fail!      *
***********************************
EOF1
}

$PAB = 1;

@argv = ();
foreach( @ARGV ) {
	if( /--help/ ) {
		print_usage();
	}
	if( /--verbose/ ) {
		$Verbose = 1;
	}
	else {
		push @argv, $_;
	}
}
@ARGV = @argv;

WriteMakefile(
    NAME => 'PAB3',
    VERSION_FROM => 'xs/PAB3/PAB3.pm',
    ABSTRACT => 'PAB - Perl Application Builder',
    PREREQ_PM => {
        'Time::HiRes' => 0,
        'Digest::MD5' => 0,
        'Storable' => 0,
    },
    XSPROTOARG => '-prototypes',
    OPTIMIZE => '-O3',
	OBJECT => '',
	XS => {},
	C => [],
	H => [],
    DIR => [ 'xs' ],
);

1;

sub print_usage {
	print <<USAGE;
Usage: perl $0 [options]
Options:
    --help               print this message
    --verbose            enable MakeMaker's verbosity
USAGE
	exit;
}
