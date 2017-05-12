Summary: Perl module for loading SGML, XML, and HTML
Name: SGML-SPGroveBuilder
Version: 2.01
Release: 1
Source: ftp://ftp.uu.net/vendor/bitsko/gdo/SGML-SPGroveBuilder-2.01.tar.gz
Copyright: distributable
Group: Applications/Publishing/SGML
URL: http://www.bitsko.slc.ut.us/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/SGML-SPGroveBuilder

#
# $Id: SGML-SPGroveBuilder.spec,v 1.3 1998/01/29 23:48:36 ken Exp $
#

%description
A Perl 5 module for loading SGML, XML, and HTML document instances
using James Clark's SGML Parser (SP).

%prep
%setup

if test x"$SPLIBDIR" != x; then
  perl Makefile.PL LIBS="-L$SPLIBDIR/lib -lsp" \
    INC="-I$SPLIBDIR/lib -I$SPLIBDIR/generic -I$SPLIBDIR/include" \
    INSTALLDIRS=perl
else
  perl Makefile.PL INSTALLDIRS=perl
fi

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

%files

%doc README COPYING Changes test.pl

%dir /usr/lib/perl5/i386-linux/*/auto/SGML/SPGroveBuilder
/usr/lib/perl5/i386-linux/*/auto/SGML/SPGroveBuilder/SPGroveBuilder.so
/usr/lib/perl5/i386-linux/*/auto/SGML/SPGroveBuilder/SPGroveBuilder.bs
/usr/lib/perl5/SGML/SPGroveBuilder.pm
/usr/lib/perl5/man/man3/SGML::SPGroveBuilder.3
