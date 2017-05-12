#!/usr/bin/perl -w
################################################################################
#
# Copyright (C) 2000, Ashley Winters <jql@accessone.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This is the Makefile.PL for PerlKDE
#
# Usage:
# perl Makefile.PL
# make
# make install
#
# This is a Unix-only Makefile.PL as far as I know...
#

$MAKE = 'KDE-1.1.1';
$LINK = 'Qt-1.4';

$ENV{QTDIR} = '/usr/lib/qt' unless $ENV{QTDIR};
$ENV{KDEDIR} = '/opt/kde' unless $ENV{KDEDIR};

##########
# Please modify these arguments as needed
%Args = (
    CC => 'g++',
    CCFLAGS => '',
    DEFINE => '',
    INC => '-I$(KDEDIR)/include -I$(QTDIR)/include ' .
           '-I/usr/X11R6/include -I/usr/include/kde -I/usr/include/qt',
    LIBS => "-L$ENV{QTDIR}/lib -L$ENV{KDEDIR}/lib -L/usr/X11R6/lib " .
	    "-lkdecore -lkdeui -lkfm -lqt -lX11",
    OPTIMIZE => '-O'
);
##########

use ExtUtils::MakeMaker;
use Config;
use File::Copy;
use Pig;

my $filelist;

unless(@ARGV && $ARGV[0] =~ /^-f/) {
    GenerateSource(
	DIR => [ $MAKE ],
	LINK => [ $LINK ],
	TYPEMAPS => [ "$LINK/typemap", "$MAKE/typemap" ],
	INCLUDE => [ "pigmodule_KDE.h" ],
	VIRTUALHEADER => 'pigvirtual.h',
	SOURCEDIR => '.',
	Source => \$filelist
    );
}

$debug = 0;

if($Config{bincompat3} && $Config{bincompat3} =~ /y/) {
    $pl = 3;
} else {
    $pl = $Config{PATCHLEVEL};
}

$sv = $Config{SUBVERSION};

sub configurate {
    my $object = qq{
	pigboot\$(OBJ_EXT)
	pigsymbol\$(OBJ_EXT)
	pigsymbol_KDE\$(OBJ_EXT)
	pigtype_kde\$(OBJ_EXT)
	@$filelist
    };

    my $define = "-DPIGDEBUG=$debug -DPIG_QT " .
	"-DPIGPERL_PL=$pl -DPIGPERL_SV=$sv $Args{DEFINE}";

    my $libs = $Args{LIBS};

    eval {
	open(SAVEERR, ">&STDERR") || die "Cannot redirect stderr";
#	open(STDERR, ">&STDOUT") || die "Cannot >&";   # doesn't work
	open(STDERR, ">/dev/null") || die "Cannot redirect stderr";
	my $filename = `$Args{CC} -print-libgcc-file-name`;
	$libs .= " -L$1 -lgcc" if $filename =~ /(.*)\/libgcc\.a/;
	open(STDERR, ">&SAVEERR") || die "Cannot restore stderr";
	close(SAVEERR);
    };

    return { OBJECT => $object, DEFINE => $define, LIBS => $libs };
}

$Args{INC} .= ' -I. -I./include';

WriteMakefile(
# These arguments should remain unchanged.
    %Args,
    NAME => 'KDE',
    DISTNAME => 'PerlKDE',
    VERSION_FROM => 'KDE.pm',
    PM => { 'KDE.pm', '$(INST_LIBDIR)/KDE.pm' },
    PREREQ_PM => { 'Qt' => '2.104' },
    CONFIGURE => \&configurate,
    realclean => { FILES => 'pig_* _pig*' }
);
