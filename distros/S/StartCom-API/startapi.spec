# $Id$

%define rname StartCom-API
Name: perl-%{rname}
Version: 0.2
Release: 1%{?dist}
Summary: an api connector module for startcom
License: LGPL
Group: Development/Libraries
URL: http://search.cpan.org/dist/%{rname}/
Source0: http://search.cpan.org/CPAN/authors/id/P/PH/PHILIPPE/%{rname}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires: perl(LWP::UserAgent)
Requires: perl(IO::Socket::SSL)
Requires: perl(JSON)
Requires: perl(MIME::Base64)
BuildRequires: perl(ExtUtils::MakeMaker) perl(Module::Build) perl(Test::Simple)
BuildRequires: perl(LWP::UserAgent)
BuildRequires: perl(IO::Socket::SSL)
BuildRequires: perl(JSON)
BuildRequires: perl(MIME::Base64)


%description
This module allows to connect to the api of StartCom.

Please see https://startssl.com/StartAPI/Docs for a catalog of api methods.


%prep
%setup -q -n %{rname}-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}
make pure_install PERL_INSTALL_ROOT=%{buildroot}

find %{buildroot} -type f -name .packlist -delete
find %{buildroot} -depth -type d -empty -delete

%{_fixperms} %{buildroot}/*


%clean
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc README StartAPI.pl
%{perl_vendorlib}/StartCom/API.pm
%{_mandir}/man3/StartCom::API.3pm*
