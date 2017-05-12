#!/usr/bin/perl -w
#*************************************************************************
#
#  $RCSfile$
#
#  $Revision$
#
#  last change: $Author$ $Date$
#
#  The Contents of this file are made available subject to the terms of
#  either of the following licenses
#
#         - GNU Lesser General Public License Version 2.1
#         - Sun Industry Standards Source License Version 1.1
#
#  Sun Microsystems Inc., October, 2000
#
#  GNU Lesser General Public License Version 2.1
#  =============================================
#  Copyright 2000 by Sun Microsystems, Inc.
#  901 San Antonio Road, Palo Alto, CA 94303, USA
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License version 2.1, as published by the Free Software Foundation.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#  MA  02111-1307  USA
#
#
#  Sun Industry Standards Source License Version 1.1
#  =================================================
#  The contents of this file are subject to the Sun Industry Standards
#  Source License Version 1.1 (the "License"); You may not use this file
#  except in compliance with the License. You may obtain a copy of the
#  License at http://www.openoffice.org/license.html.
#
#  Software provided under this License is provided on an "AS IS" basis,
#  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
#  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
#  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
#  See the License for the specific provisions governing your rights and
#  obligations concerning the Software.
#
#  The Initial Developer of the Original Code is: Ralph Thomas
#
#   Copyright: 2000 by Sun Microsystems, Inc.
#
#   All Rights Reserved.
#
#   Contributor(s): Bustamam Harun
#
#
#***********************************************************************

use warnings;

use ExtUtils::MakeMaker;
use File::Find;
use File::Basename;
use File::Path;
use Config;
use Cwd;

unless ($ENV{'OO_SDK_HOME'}) {
    print STDERR <<EOT;

**************************************************

The environment variable OO_SDK_HOME is not set,
please set up the OpenOffice.org SDK enviornemnt
by using the setsdkenv_unix.sh script or similar.

**************************************************

EOT
    exit 0;
}

$cwd = cwd();
$sdk_dir = $ENV{'OO_SDK_HOME'};
$cc = $ENV{'CXX'} || $Config{'cc'};
$ld = $ENV{'CXX'} || $Config{'ld'};
$cc_flags = '';
$uno_lib = $ENV{'OO_SDK_URE_LIB_DIR'};
$uno_libpath = "-L$uno_lib";
if( $^O eq 'MSWin32' ) {
    $psep = '\\';
    $sdk_platf = 'windows';
    $uno_def   = '-DCPPU_ENV=msci -DWIN32 -DWNT';
    $uno_lib   = $sdk_dir . "\\windows\\lib";
    $uno_libpath = "-libpath:$uno_lib";
    $ld = 'link';
    $cc_flags = ' /TP /EHsc ';
} else {
    $psep = '/';
    @config = split '-', qx[$sdk_dir/config.guess];
    $cc = $ld = $ENV{'CXX'} || 'g++';
    if( $config[2] eq 'linux' ) {
        $sdk_platf = 'linux';
        $uno_def   = '-DCPPU_ENV=gcc3 -DGCC -DLINUX -DUNX';
        $uno_libpath = "$uno_libpath -L$cwd/blib/uno/lib";
    } elsif( $config[2] =~ /^darwin/ ) {
        $sdk_platf = 'macosx';
        $uno_def   = '-DCPPU_ENV=gcc3 -DGCC -DMACOSX -DUNX';
        $uno_libpath = "$uno_libpath -L$cwd/blib/uno/lib";
    } elsif( $config[2] eq 'solaris' ) {
        if( $config[0] eq 'sparc' ) {
            $sdk_platf = 'solsparc';
            $uno_def   = '-DUNX -DSOLARIS -DSPARC -DCPPU_ENV=sunpro5';
        } else {
            $sdk_platf = 'solintel';
            $uno_def   = '-DUNX -DSOLARIS -DX86 -DCPPU_ENV=sunpro5';
        }
        $cc = $ld = $ENV{'CXX'} || 'CC';
    } else {
        die "Please add a case for your sdk platform: ", join '-', @config;
    }
}
($sdk_bin_dir) = grep -d $_, "$sdk_dir$psep$sdk_platf${psep}bin",
                             "$sdk_dir${psep}bin";
($sdk_ure_lib) = grep -f "$_/types.rdb", "$ENV{'OO_SDK_URE_BIN_DIR'}",
                                         "$ENV{'OO_SDK_URE_HOME'}/share/misc";

@ReqLibs = ("cppuhelper", "cppu", "salhelper", "sal", "stlport", "gcc_s");
@LPath = ($uno_lib);

$LibsOK = 0;
%FLib = ();
%SLib = ();
# Check all required libs
for $lib (@ReqLibs) {
    for $lpath (@LPath) {
	$flib = &getReqLib($lpath, $lib);
	if ( $flib ne "" ) {
	    $LibsOK = 1;
	    last;
	}
    }

    if ( $LibsOK == 0 ) {
	print "Library: $lib could not be found\n";
	exit(-1);
    }
}

$LinkLibs = "";
for $ky (keys(%SLib)) {
    $LinkLibs .= "-l" . $SLib{$ky} . " ";
}

WriteMakefile (       
    'NAME'	=> 'OpenOffice::UNO',
    'CC'	=> $cc,
    'LD'	=> $ld,
    'CCFLAGS'	=> $uno_def . " " . $cc_flags,
#    'CCCDLFLAGS' => ' ' . $Config{'cccdlflags'},
    'LDDLFLAGS'	=> $uno_libpath . ' ' . $Config{'lddlflags'}  . ' ',
    'LIBS'	=> [ $uno_libpath . ' ' . $LinkLibs ],
    'INC'	=> " -Iblib/uno -I$sdk_dir/include ",
    'depend'	=> { '$(OBJECT)' => 'blib/uno/headers perluno',
		     },
    'clean'	=> { 'FILES'     => 'test2_export.pdf test2_save.sxw perluno',
		     },
    'XSOPT'	=> '-C++',
    'AUTHOR'	=> join( ', ', 'Bustamam Harun <bustamam@gmail.com>',
			       'Mattia Barbon <mbarbon@cpan.org>' ),
    'VERSION_FROM'=> 'UNO.pm',
    'ABSTRACT_FROM'=> 'UNO.pm',
    'LICENSE'	=> 'open_source',
    'META_MERGE' => { 'resources' =>
                      { 'homepage' => 'http://perluno.sourceforge.net/',
                        'repository' => 'https://sourceforge.net/scm/?type=hg&group_id=88004',
                        },
                      },
);

exit(0);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }

sub MY::postamble {
    my $cwd = cwd();
    my $out = "blib${psep}uno";
    my $abs_out = File::Spec->rel2abs( $out );
    my $interfaces = join ' ', map '-T' . $_,
      qw(com.sun.star.lang.IllegalArgumentException
         com.sun.star.uno.RuntimeException
         com.sun.star.uno.TypeClass
         com.sun.star.uno.XAggregation
         com.sun.star.uno.XComponentContext
         com.sun.star.lang.XInitialization
         com.sun.star.lang.XMultiComponentFactory
         com.sun.star.lang.XMultiServiceFactory
         com.sun.star.registry.XRegistryKey
         com.sun.star.lang.XServiceInfo
         com.sun.star.lang.XSingleComponentFactory
         com.sun.star.lang.XSingleServiceFactory
         com.sun.star.lang.XTypeProvider
         com.sun.star.uno.XWeak
         com.sun.star.lang.XComponent
         com.sun.star.bridge.XUnoUrlResolver
         com.sun.star.container.XHierarchicalNameAccess
         com.sun.star.uno.DeploymentException
         com.sun.star.registry.XSimpleRegistry
         com.sun.star.reflection.XIdlClass
         com.sun.star.reflection.XIdlReflection
         com.sun.star.beans.XMaterialHolder
         com.sun.star.script.XTypeConverter
         com.sun.star.beans.XIntrospection
         com.sun.star.script.XInvocation2
         com.sun.star.lang.WrappedTargetRuntimeException
         );

# for OOo 2.x
# com.sun.star.frame.XComponentLoader

    return <<EOT;
#$out/some.urd : $out some.idl
#	$sdk_dir/$sdk_platf/bin/idlc -I. -I$sdk_dir/idl -O$abs_out some.idl

#$out/moo.uno.rdb : $out $out/some.urd
#	$sdk_dir/$sdk_platf/bin/regmerge $out/moo.uno.rdb /UCR $out/some.urd

$out/headers : $out
	$sdk_bin_dir${psep}cppumaker -Gc -BUCR -O$abs_out $interfaces "$sdk_ure_lib${psep}types.rdb"
	\$(TOUCH) $out/headers

uno_stuff: $out/headers perluno

$out :
	\$(MKPATH) $out

perluno : perluno.tmpl
	\$(PERL) -pe "s<UNO_PATH><$sdk_ure_lib>" -- perluno.tmpl > perluno

EOT
}

sub getReqLib {
    $cdir = $_[0];
    $clib = $_[1];

    push(@dirs, $cdir);
    find( { wanted => \&getlib }, @dirs, );
    if ( defined($FLib{$clib}) ) {
	return($FLib{$clib});
    } else {
	return("");
    }
}

sub getlib {
    return if defined($FLib{$clib});
    if ( ($File::Find::name =~ m/${clib}/) ) {
	($libname, $libdir) = fileparse($File::Find::name);
        if ( $^O eq 'MSWin32' ) {
            getlib_win32();
        } elsif ( $^O eq 'darwin' ) {
            getlib_osx();
        } else {
            getlib_unix();
        }
    }
}

sub getlib_win32 {
    return unless ($libname =~ m/${clib}/) && ($libname =~ m/\.lib$/);
    $FLib{$clib} = $libname;
    $SLib{$clib} = $libname;
    $SLib{$clib} =~ s/\.lib$//;
}

sub getlib_unix {
    return unless ($libname =~ m/^lib/) && ($libname =~ m/\.so(\.\d+)?$/);
    $FLib{$clib} = $libname;
    $SLib{$clib} = $libname;
    $SLib{$clib} =~ s/^lib//;
    $SLib{$clib} =~ s/\.so(\.\d+)?$//;

    # as insane as this seems, that's what OOo SDK does
    mkpath("$cwd/blib/uno/lib");
    symlink("$libdir$libname", "$cwd/blib/uno/lib/lib$SLib{$clib}.so");
}

sub getlib_osx {
    return unless ($libname =~ m/^lib/) && ($libname =~ m/\.dylib(\.\d+)?$/);
    $FLib{$clib} = $libname;
    $SLib{$clib} = $libname;
    $SLib{$clib} =~ s/^lib//;
    $SLib{$clib} =~ s/\.dylib(\.\d+)?$//;

    # as insane as this seems, that's what OOo SDK does
    mkpath("$cwd/blib/uno/lib");
    symlink("$libdir$libname", "$cwd/blib/uno/lib/lib$SLib{$clib}.dylib");
}
