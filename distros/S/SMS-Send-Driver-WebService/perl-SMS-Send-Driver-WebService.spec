Name:           perl-SMS-Send-Driver-WebService
Version:        0.08
Release:        1%{?dist}
Summary:        SMS::Send driver base class for web services
License:        mit
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/SMS-Send-Driver-WebService/
Source0:        http://www.cpan.org/modules/by-module/SMS/SMS-Send-Driver-WebService-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(Config::IniFiles)
BuildRequires:  perl(LWP::UserAgent)
BuildRequires:  perl(HTTP::Tiny)
BuildRequires:  perl(Path::Class)
BuildRequires:  perl(SMS::Send)
BuildRequires:  perl(URI)
Requires:       perl(Config::IniFiles)
Requires:       perl(LWP::UserAgent)
Requires:       perl(HTTP::Tiny)
Requires:       perl(Path::Class)
Requires:       perl(SMS::Send)
Requires:       perl(URI)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
The SMS::Send::Driver::WebService package provides an SMS::Send driver base class to support two common needs.  The first need is a base class that provides HTTP:Tiny as a simple method. The second need is a way to configure various setting for multiple SMS providers without having to rebuild the SMS::Send driver concept.

%prep
%setup -q -n SMS-Send-Driver-WebService-%{version}

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
%doc Changes LICENSE README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Thu Jan 02 2025 Michael R. Davis <mrdvt92@yahoo.com> 0.08-1
- Update to move to GitHub
