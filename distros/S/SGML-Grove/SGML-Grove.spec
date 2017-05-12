Summary: Perl module for iterating SGML, XML, and HTML
Name: SGML-Grove
Version: @VERSION@
Release: 1
Source: ftp://ftp.uu.net/vendor/bitsko/gdo/SGML-Grove-@VERSION@.tar.gz
Copyright: distributable
Group: Applications/Publishing/SGML
URL: http://www.bitsko.slc.ut.us/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/SGML-Grove

#
# $Id: SGML-Grove.spec,v 1.3 1998/01/30 04:00:24 ken Exp $
#

%description

A Perl 5 module for working with SGML, XML, and HTML document
instances after they've been built by a parsing or grove building
module like SGML::SPGroveBuilder, Pod::GroveBuilder, etc.

%prep
%setup

perl Makefile.PL INSTALLDIRS=perl

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

DOCDIR="${RPM_ROOT_DIR}/usr/doc/SGML-Grove-@VERSION@-1"
mkdir -p "$DOCDIR/examples"
for ii in README COPYING Changes DOM test.pl examples/*; do
  cp $ii "$DOCDIR/$ii"
  chmod 644 "$DOCDIR/$ii"
done

ENTDIR="${RPM_ROOT_DIR}/usr/lib/sgml/SGML-Grove-@VERSION@-1"
mkdir -p "$ENTDIR"
for ii in catalog simple-spec.dtd; do
  cp entities/$ii "$ENTDIR/$ii"
  chmod 644 "$ENTDIR/$ii"
done

%files

/usr/doc/SGML-Grove-@VERSION@-1
/usr/lib/sgml/SGML-Grove-@VERSION@-1

/usr/lib/perl5/SGML/SData.pm
/usr/lib/perl5/SGML/Grove.pm
/usr/lib/perl5/SGML/PI.pm
/usr/lib/perl5/SGML/Element.pm
/usr/lib/perl5/SGML/Entity.pm
/usr/lib/perl5/SGML/ExtEntity.pm
/usr/lib/perl5/SGML/Notation.pm
/usr/lib/perl5/SGML/SubDocEntity.pm
/usr/lib/perl5/SGML/Writer.pm
/usr/lib/perl5/SGML/Simple/BuilderBuilder.pm
/usr/lib/perl5/SGML/Simple/SpecBuilder.pm
/usr/lib/perl5/SGML/Simple/Spec.pm
/usr/lib/perl5/man/man3/SGML::SData.3
/usr/lib/perl5/man/man3/SGML::Grove.3
/usr/lib/perl5/man/man3/SGML::PI.3
/usr/lib/perl5/man/man3/SGML::Element.3
/usr/lib/perl5/man/man3/SGML::Entity.3
/usr/lib/perl5/man/man3/SGML::ExtEntity.3
/usr/lib/perl5/man/man3/SGML::Notation.3
/usr/lib/perl5/man/man3/SGML::SubDocEntity.3
/usr/lib/perl5/man/man3/SGML::Writer.3
/usr/lib/perl5/man/man3/SGML::Simple::BuilderBuilder.3
/usr/lib/perl5/man/man3/SGML::Simple::SpecBuilder.3
/usr/lib/perl5/man/man3/SGML::Simple::Spec.3
