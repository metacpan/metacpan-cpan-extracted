% my $p = shift;

#  Copyright (C) <%= $p->{year} %> <%= $p->{fullName} %>

AC_INIT([<%= $p->{name} %>],m4_esyscmd([tr -d '\n' < VERSION]),[<%= $p->{email} %>])
AC_PREREQ([2.59])
AC_CONFIG_AUX_DIR(conftools)


# need this to allow long path names
AM_INIT_AUTOMAKE([1.9 tar-ustar foreign])
AM_MAINTAINER_MODE

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREFIX_DEFAULT(/opt/$PACKAGE_NAME-$PACKAGE_VERSION)

AC_ARG_VAR(PERL,   [Path to local perl binary])
AC_PATH_PROG(PERL, perl, no)

ac_perl_version="5.10.1"

if test "x$PERL" != "x"; then
  AC_MSG_CHECKING(for perl version greater than or equal to $ac_perl_version)
  $PERL -e "use $ac_perl_version;" >/dev/null 2>&1
  if test $? -ne 0; then
    AC_MSG_RESULT(no);
    AC_MSG_ERROR(at least version 5.10.1 is required to run mojolicious)
  else
    AC_MSG_RESULT(ok);
  fi
else
  AC_MSG_ERROR(could not find perl)
fi

AC_PROG_GREP

AC_ARG_VAR(GMAKE,   [Path to local GNU Make binary])
AC_PATH_PROGS(GMAKE, [gnumake gmake make])

AC_MSG_CHECKING([checking for gnu make availablility])
if  ( $GMAKE --version 2> /dev/null | $GREP GNU  > /dev/null 2>&1 );  then
    AC_MSG_RESULT([$GMAKE is GNU make])
else
    AC_MSG_ERROR([GNU make not found. Try setting the GMAKE environment variable.])
fi

AC_ARG_ENABLE(pkgonly,
        AC_HELP_STRING([--enable-pkgonly],
                        [Skip all checking]))
AC_SUBST(enable_pkgonly)

actual_prefix=$prefix
if test x$actual_prefix = xNONE; then
    actual_prefix=$ac_default_prefix
fi

HTDOCSDIR=${actual_prefix}/htdocs
AC_ARG_WITH(htdocs-dir,AC_HELP_STRING([--with-htdocs-dir=DIR],[Where to install htdocs [PREFIX/htdocs]]), [HTDOCSDIR=$withval])
AC_SUBST(HTDOCSDIR)

QOOXDOO_PATH=
AC_ARG_WITH(qooxdoo-sdk,AC_HELP_STRING([--with-qooxdoo-sdk=DIR],[Where can we find the qooxdoo sdk (required to rebuild the web ui)]), [
        if test -d $withval/framework; then
             QOOXDOO_PATH=$withval
        else
        cat <<NOTES

** Aborting Configure *************************************

You specified --with-qooxdoo-sdk=DIR without pointing it
to a copy of the qooxdoo sdk. If you specify the option,
make sure there is a copy of the qooxdoo sdk present.
get your copy form www.qooxdoo.org.

NOTES
          exit 1
        fi
])

AC_SUBST(QOOXDOO_PATH)

AM_CONDITIONAL(BUILD_QOOXDOO_APP,[test x$QOOXDOO_PATH != x])

AC_ARG_VAR(PERL5LIB,   [Colon separated list of perl library directories])
AC_SUBST(PERL5LIB)

# Check the necessary Perl modules

mod_ok=1
if test "$enable_pkgonly" != yes; then
   for module in m4_esyscmd([tr '\n' ' ' < PERL_MODULES | sed 's/\@[^ ]*//g']); do
     AC_MSG_CHECKING([checking for perl module '$module'])
     if ${PERL} -I$actual_prefix/thirdparty/lib/perl5 -e 'use '$module 2>/dev/null ; then
         AC_MSG_RESULT([Ok])
     else
         AC_MSG_RESULT([Failed])
         mod_ok=0
     fi
   done
fi


AC_CONFIG_FILES([
    Makefile
    backend/Makefile
    frontend/Makefile
])

AC_SUBST(VERSION)

AC_OUTPUT

if test x$QOOXDOO_PATH = x; then

    cat <<NOTES

** QOOXDOO SDK NOT INSTALLED **********************************

You did NOT specify the --with-qooxdoo-sdk configuration
option. This is fine if you got a packed version of this
application. If you are developping, you must have a copy
of the qooxdoo sdk installed or you will not be able to
build the javascript parts of your application.

NOTES
fi

if test x$mod_ok = x0; then
    cat <<NOTES

** SOME PERL MODULES ARE MISSING ******************************

If you know where perl can find the missing modules, set
the PERL5LIB environment variable accordingly.

You can also install a local copy of the Perl modules by running

   $GMAKE get-thirdparty-modules
   
You can append additional Perl modules used in your application to
the file PERL_MODULES to have them downloaded and build automatically.

NOTES
fi

cat <<NOTES

** CONFIGURE DONE **********************************************

Settings:

  PERL5LIB = ${PERL5LIB:-"not set"}
  PERL = $PERL

The Makefiles use GNU make functionality.
Continue installation with

  $GMAKE install

NOTES

