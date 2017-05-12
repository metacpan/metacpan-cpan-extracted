package Socket::Class::Const::Install;
use 5.006;
use ExtUtils::MakeMaker;
#use Config;

use strict;

my %makeopts = (
	'NAME' => 'Socket::Class::Const',
	'VERSION_FROM' => 'Const.pm',
	'ABSTRACT' => 'Socket Class Constants',
	'LIBS' => [],
	'DEFINE' => '',
	'INC' => '-I../../',
	'XSPROTOARG' => '-noprototypes',
	'PREREQ_PM' => {
	},
	'OBJECT' => '$(O_FILES)',
	'XS' => { 'Const.xs' => 'Const.c' },
	'C' => [ 'Const.c' ],
	'H' => [],
);

if( $^O eq 'MSWin32' ) {
	$makeopts{'DEFINE'} .= ' -D_CRT_SECURE_NO_DEPRECATE -D_CRT_SECURE_NO_WARNINGS';
	$makeopts{'LIBS'}[0] = '-lws2_32';
	# cpan bug #37639
	$ExtUtils::MM_Win32::Config{'ccversion'} = 13;
}
elsif( $^O eq 'cygwin' ) {
	$makeopts{'LIBS'}[0] = '-L/lib/w32api -lole32 -lversion -lws2_32';
}

WriteMakefile( %makeopts );

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
