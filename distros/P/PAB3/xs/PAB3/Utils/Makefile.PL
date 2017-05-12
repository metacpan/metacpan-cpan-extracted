package PAB3::Utils::Install;
use 5.008;
use ExtUtils::MakeMaker;
use Config;

$Verbose = 0;

%MAKEOPTS = (
    NAME => 'PAB3::Utils',
    VERSION_FROM => 'Utils.pm',
    LIBS => [''],
    DEFINE => '',
    INC => '-I../../',
    XSPROTOARG => '-noprototypes',
    PREREQ_PM => {
    },
    OBJECT => '$(O_FILES)',
    XS => { 'Utils.xs' => 'Utils.c' },
    C => ['my_utils.c', 'Utils.c'],
    H => ['my_utils.h'],
);

if( $^O eq 'MSWin32' ) {
	$MAKEOPTS{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
	# help makemaker removing not existing libs, eg. bufferoverflowU.lib
	push @{$MAKEOPTS{'LIBS'}}, '-lkernel32';
}
elsif( $^O eq 'cygwin' ) {
	push @{$MAKEOPTS{'LIBS'}}, '-L/lib/w32api -lole32 -lversion';
}

WriteMakefile( %MAKEOPTS );

1;

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
