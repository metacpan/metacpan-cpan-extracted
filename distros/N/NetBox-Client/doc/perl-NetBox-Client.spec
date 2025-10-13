Name:           perl-NetBox-Client
Version:        0.1.5
Release:        1%{?dist}
Summary:        NetBox API perl client
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            https://github.com/kornix/perl-NetBox-Client
Source0:        NetBox-Client-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:	perl(Class::Load)
Requires:	perl(Class::XSAccessor)
Requires:	perl(Encode)
Requires:	perl(GraphQL::Client)
Requires:	perl(HTTP::Request)
Requires:	perl(JSON)
Requires:	perl(LWP::UserAgent)
Requires:	perl(URI::Escape)
Provides:	perl(NetBox::Client)

%description
NetBox DCIM/IPAM both REST and GraphQL API perl client

%prep
%setup -q -n NetBox-Client-%{version}

rm -f pm_to_blib

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes LICENSE MYMETA.json MYMETA.yml README.md doc/perl-NetBox-Client.spec
%dir %{perl_vendorlib}/NetBox
%{perl_vendorlib}/NetBox/*
%{_mandir}/man3/NetBox*

%changelog

* Wed Oct  8 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.1.5
- renamed module to NetBox::Client to match CPAN naming conventions.

* Fri Sep 26 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.1.4
- LICENSE added;
- automation issues fixed;
- README.md is now generated from module POD;
- RPM spec-file fixes.

* Fri Sep 26 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.1.3
- CPAN compatibility fixes.

* Thu Sep 25 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.1.0
- Initial public release.

* Thu Apr 17 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.4
- Response fields filtering added.

* Mon Mar 04 2024 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.1-1
- Initial release.
