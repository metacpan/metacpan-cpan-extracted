# -*- rpm-spec -*-
# Copyright (C) 2004-2015 Daniel Berrange <dan@berrange.com>
#

use strict;

die unless (scalar @ARGV == 1);

open SRC, "lib/Net/DBus.pm"
    or die "lib/Net/DBus.pm: $!";

our $VERSION;
while (<SRC>) {
    if (/\$VERSION\s*=\s*'(.*)'/) {
       $VERSION=$1;
    }
}
close SRC;

local $/ = undef;
$_ = <DATA>;
s/\@VERSION\@/$VERSION/g;

open SPEC, ">$ARGV[0]" or die "$!";
print SPEC $_;
close SPEC;
__DATA__

Name:           perl-Net-DBus
Version:        @VERSION@
Release:        1%{?dist}
Summary:        Use and provide DBus services
License:        GPLv2+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Net-DBus/
Source0:        http://search.cpan.org/CPAN/authors/id/D/DA/DANBERR/Net-DBus-%{version}.tar.gz
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  dbus-devel  >= 1.00, pkgconfig
BuildRequires:  perl(Exporter)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Time::HiRes)
BuildRequires:  perl(XML::Parser)
BuildRequires:  perl(XML::Twig)
BuildRequires:  perl(XSLoader)
# test
BuildRequires:  perl(Carp)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Pod) >= 1.00
BuildRequires:  perl(Test::Pod::Coverage) >= 1.00
BuildRequires:  perl(Test::CPAN::Changes)
Requires:       perl(XSLoader)

%{?perl_default_filter}

%description
Net::DBus provides a Perl API for the DBus message system. The DBus Perl
interface is currently operating against the 0.33 development version of
DBus, but should work with later versions too, providing the API changes
have not been too drastic.

%prep
%setup -q -n Net-DBus-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}"
make %{?_smp_mflags}

%install
make pure_install PERL_INSTALL_ROOT=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} +
find %{buildroot} -type f -name '*.bs' -size 0 -exec rm -f {} +
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} %{buildroot}/*

%check
make test

%files
%doc AUTHORS Changes README LICENSE examples/
%{perl_vendorarch}/auto/*
%{perl_vendorarch}/Net*
%{_mandir}/man3/*

%changelog
