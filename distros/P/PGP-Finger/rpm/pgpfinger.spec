%define module_name PGP-Finger

Name: pgpfinger
Version: 1.1
Release: %(date +%Y%m%d)%{dist}
Summary: retrieve PGP keys from different sources

Group: Applications/CPAN
License: restricted
Vendor: Markus Benning
Packager: Markus Benning

BuildArch: noarch
BuildRoot: /var/tmp/buildroot-%{name}-%{version}

Source0: %{module_name}-%{version}.tar.gz

#AutoProv: 0
# AutoReq: 0

%description
retrieve PGP keys from different sources

%prep
rm -rf $RPM_BUILD_ROOT
%setup -q -n %{module_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
if [ -d "$RPM_BUILD_ROOT" ] ; then
        rm -rf $RPM_BUILD_ROOT
fi
make install DESTDIR=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -type f -name perllocal.pod -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
if [ "$RPM_BUILD_ROOT" = "" -o "$RPM_BUILD_ROOT" = "/" ]; then
  RPM_BUILD_ROOT=/var/tmp/rpm-build-root
  export RPM_BUILD_ROOT
fi
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README README.md
%attr(755,root,root) %{_bindir}/pgpfinger
%{perl_vendorlib}
%{_mandir}/man1/*
%{_mandir}/man3/*

