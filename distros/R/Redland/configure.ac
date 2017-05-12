dnl -*- Mode: autoconf -*-
dnl
dnl configure.in - top level autoconf file for Redland Perl binding
dnl (Process this file with autoconf to produce a configure script.)
dnl
dnl $Id: configure.ac 11661 2006-11-30 18:34:27Z dajobe $
dnl
dnl Copyright (C) 2000-2006, David Beckett http://purl.org/net/dajobe/
dnl Copyright (C) 2000-2005 Copyright (C) 2000-2005, University of Bristol, UK http://www.bristol.ac.uk/
dnl 
dnl This package is Free Software and part of Redland http://librdf.org/
dnl 
dnl It is licensed under the following three licenses as alternatives:
dnl   1. GNU Lesser General Public License (LGPL) V2.1 or any newer version
dnl   2. GNU General Public License (GPL) V2 or any newer version
dnl   3. Apache License, V2.0 or any newer version
dnl 
dnl You may not use this file except in compliance with at least one of
dnl the above three licenses.
dnl 
dnl See LICENSE.html or LICENSE.txt at the top of this package for the
dnl complete terms and further detail along with the license texts for
dnl the licenses in COPYING.LIB, COPYING and LICENSE-2.0.txt respectively.
dnl 
dnl 


AC_INIT([Redland Perl binding], 1.0.5.4, http://bugs.librdf.org/, redland-perl)
AC_PREREQ(2.53)
AC_CONFIG_SRCDIR(perl/example.pl)
AC_REVISION($Revision: 11661 $)dnl

AM_INIT_AUTOMAKE([1.7 check-news tar-ustar])
AM_MAINTAINER_MODE

dnl Checks for programs.
AM_PROG_CC_STDC
AM_SANITY_CHECK
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET

m4_undefine([AC_PROG_CXX])
m4_defun([AC_PROG_CXX],[])
m4_undefine([AC_PROG_F77])
m4_defun([AC_PROG_F77],[])
AC_PROG_LIBTOOL

# Find a tar command for 'make dist'
AC_CHECK_PROGS(TAR, gnutar gtar tar)

AC_CHECK_PROGS(PERL, perl)
AC_CHECK_PROGS(SWIG, swig)
# Gnome
AC_CHECK_PROGS(PKG_CONFIG, pkg-config)

if test "X$PERL" != "X"; then
  PERLINSTALLSITEARCH=`$PERL -MConfig -e 'print $Config{installsitearch};'`
  PERLMAN3DIR=`$PERL -MConfig -e 'print $Config{man3dir};'`
else
  PERLINSTALLSITEARCH=none
  PERLMAN3DIR=none
fi
AC_SUBST(PERLINSTALLSITEARCH)
AC_SUBST(PERLMAN3DIR)

SWIG_MIN_VERSION=1.3.26

AC_MSG_CHECKING(SWIG support)
if test "X$SWIG" != "X"; then
  SWIG_VERSION=`$SWIG -version 2>&1 |sed -ne 's/^SWIG Version //p'`
  SWIG_VERSION_DEC=`echo $SWIG_VERSION | $AWK -F. '{printf("%d\n", 10000*$1 + 100*$2 + $3)};'`

  SWIG_MIN_VERSION_DEC=`echo $SWIG_MIN_VERSION | $AWK -F. '{printf("%d\n", 10000*$1 + 100*$2 + $3)};'`

  if test $SWIG_VERSION_DEC -ge $SWIG_MIN_VERSION_DEC; then
    AC_MSG_RESULT($SWIG_VERSION - OK)
  else
    AC_MSG_RESULT($SWIG_VERSION - too old to generate language interfaces)
    if test -r $srcdir/perl/CORE_wrap.c ; then
      AC_MSG_WARN(Pre-generated language interface files are present)
      AC_MSG_WARN(If you want to change the interfaces you will need)
      AC_MSG_WARN(SWIG version $SWIG_MIN_VERSION from http://www.swig.org/)
    else
      AC_MSG_WARN(There are no pre-generated language interface files)
      AC_MSG_WARN(Redland language interfaces will NOT build.)
      AC_MSG_WARN(If you want to build them you will need)
      AC_MSG_WARN(SWIG version $SWIG_MIN_VERSION from http://www.swig.org/)
      AC_MSG_WARN(Alternatively copy the pre-generated interface)
      AC_MSG_WARN(files from a released version)
    fi
  fi
else
  AC_MSG_RESULT(not present - using pre-generated interface files)
fi


languages=
languages_available=


AC_ARG_WITH(perl, [  --with-perl(=PERL)      Set the Perl interpreter], with_perl="$withval", with_perl="auto")
if test "X$with_perl" != Xauto ; then
  if test "X$with_perl" != Xyes; then
    PERL=$with_perl
  fi
fi

PERL_VERSION=`$PERL -MConfig -e 'print $Config{version}' 2>/dev/null`
if test "X$PERL_VERSION" = X; then
  AC_MSG_ERROR(No perl available - please install perl first.)
fi

AC_SUBST(PERL_VERSION)


AM_MISSING_PROG(ACLOCAL, aclocal, $missing_dir)
AM_MISSING_PROG(AUTOCONF, autoconf, $missing_dir)
AM_MISSING_PROG(AUTOMAKE, automake, $missing_dir)
AM_MISSING_PROG(AUTOHEADER, autoheader, $missing_dir)


release_version=no
AC_ARG_ENABLE(release, [  --enable-release        Turn on optimizations (for maintainer).  ], \
 if test "$enableval" = "yes"; then \
	  release_version=yes
fi;)	

if test "$USE_MAINTAINER_MODE" = yes -a $release_version = no; then 
  CFLAGS=`echo $CFLAGS | sed s/-O2//`
  CXXFLAGS=`echo $CXXFLAGS | sed s/-O2//`
  CPPFLAGS=`echo $CPPFLAGS | sed s/-O2//`
fi



dnl compiler checks
# if using gcc...
if test "$ac_cv_prog_gcc" = yes; then
  STANDARD_CFLAGS=
  MAINTAINER_CFLAGS="-Wall -Wshadow -Wstrict-prototypes -Wmissing-prototypes -Wmissing-declarations -Wredundant-decls"
else
  STANDARD_CFLAGS=
  MAINTAINER_CFLAGS=
fi


# Externally linked libraries - appear in redland-config
# -Dfoo -Idir
LIBRDF_CPPFLAGS=$CPPFLAGS
# -Ldir
LIBRDF_LDFLAGS=$LDFLAGS
# -llib
LIBRDF_LIBS=$LIBS




# redland is REQUIRED
AC_CHECK_PROG(REDLAND_CONFIG, redland-config, redland-config)
AC_ARG_WITH(redland, [  --with-redland=SOURCE   Pick redland source - system/internal (default auto)], with_redland="$withval", with_redland="auto")

changequote(<<, >>)dnl
OUR_REDLAND_VERSION=`echo $PACKAGE_VERSION | sed -e 's,\.[0-9]$,,'`
changequote([, ])dnl

AC_SUBST(REDLAND_MIN_VERSION)
if test "X$REDLAND_CONFIG" = X; then
  with_redland=internal
else
  REDLAND_VERSION=`$REDLAND_CONFIG --version 2>/dev/null`

  if test "X$with_redland" = Xauto; then
    if test "X$REDLAND_VERSION" = X; then
      with_redland=internal
    elif test $REDLAND_VERSION = $OUR_REDLAND_VERSION; then
      with_redland=system
    else
      AC_MSG_WARN(System redland $REDLAND_VERSION does not match - need $OUR_REDLAND_VERSION)
      with_redland=internal
    fi
  elif test $with_redland = system; then
    if test $REDLAND_VERSION != $OUR_REDLAND_VERSION; then
      AC_MSG_WARN(System redland $REDLAND_VERSION does not match - need $OUR_REDLAND_VERSION)
      AC_MSG_WARN(Proceeding anyway since --with-redland=system was given)
      AC_MSG_WARN(To use the internal redland use --with-redland=internal)
      AC_MSG_WARN(or omit any --with-redland argument.)
    fi
  fi
fi

AC_MSG_CHECKING(redland library source)
redland_dir=
if test $with_redland = system; then
  REDLAND_VERSION_VERBOSE="system $REDLAND_VERSION"
  REDLAND_RUN=
else
  dir=
  redland_source_dirs="redland"
  for testdir in $redland_source_dirs; do 
    if test -r $testdir/redland-src-config.in; then
      dir=`cd $testdir; pwd`
      break
    fi
  done
  if test "X$dir" = X; then
    AC_MSG_ERROR(Installed redland and sources not found - please install Redland first.)
  fi
  redland_dir=$dir

  REDLAND_VERSION_VERBOSE="internal redland in $redland_dir"
  REDLAND_CONFIG=$redland_dir/redland-src-config
  REDLAND_RUN="$REDLAND_CONFIG --run "
  with_redland=internal
fi
AC_MSG_RESULT($REDLAND_VERSION_VERBOSE)

AC_SUBST(REDLAND_CONFIG)
AC_SUBST(REDLAND_RUN)

if test "X$with_redland" = Xinternal -o "$USE_MAINTAINER_MODE" = yes; then 
  AC_CONFIG_SUBDIRS(redland)
fi

if test "$USE_MAINTAINER_MODE" = yes; then 
  LOCAL_SUBDIRS="redland"
else
  LOCAL_SUBDIRS="$redland_dir"
fi

AC_SUBST(LOCAL_SUBDIRS)


# Make final changes to cflags
STANDARD_CFLAGS="$STANDARD_CFLAGS $CFLAGS"
if test "$USE_MAINTAINER_MODE" = yes; then
  CFLAGS="$MAINTAINER_CFLAGS $CFLAGS"
fi

LIBS=
CPPFLAGS=
LDFLAGS=

AC_SUBST(STANDARD_CFLAGS)

abs_top_srcdir=`cd $srcdir; pwd`
AC_SUBST(abs_top_srcdir)
abs_top_builddir=`pwd`
AC_SUBST(abs_top_builddir)

AC_CONFIG_FILES([Makefile
redland-perl.rdf
docs/Makefile
perl/Makefile
perl/t/Makefile
perl/lib/Makefile
perl/lib/RDF/Makefile
perl/lib/RDF/Redland/Makefile
demos/Makefile
data/Makefile
])
AC_CONFIG_FILES([redland-perl.spec])
AC_CONFIG_FILES([perl/lib/RDF/Redland.pm])

AC_OUTPUT

AC_MSG_RESULT([
Redland Perl build summary:
  Redland: $REDLAND_VERSION_VERBOSE
  Perl:    $PERL_VERSION in $PERL
])
