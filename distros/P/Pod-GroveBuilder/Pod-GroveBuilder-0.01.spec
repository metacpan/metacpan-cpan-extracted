Summary: Perl module for creating SGML::Grove objects from POD documents
Name: Pod-GroveBuilder
Version: 0.01
Release: 1
Source: ftp://ftp.uu.net/vendor/bitsko/gdo/Pod-GroveBuilder-0.01.tar.gz
Copyright: distributable
Group: Applications/Publishing/SGML
URL: http://www.bitsko.slc.ut.us/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/Pod-GroveBuilder

#
# $Id: Pod-GroveBuilder.spec,v 1.1 1998/01/02 21:44:48 ken Exp $
#

%description
A Perl 5 module for creating SGML::Grove objects from POD documents.
The grove can then be used with Grove modules to format, index, and
perform other functions.

%prep
%setup

perl Makefile.PL INSTALLDIRS=perl

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

%files

%doc README COPYING Changes test.pl

/usr/lib/perl5/Pod/GroveBuilder.pm
/usr/lib/perl5/man/man3/Pod::GroveBuilder.3
