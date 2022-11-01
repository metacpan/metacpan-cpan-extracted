Name:           perl-SMS-Send-NANP-Twilio
Version:        0.06
Release:        1%{?dist}
Summary:        SMS::Send driver for Twilio
License:        Mit
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/SMS-Send-NANP-Twilio/
Source0:        http://www.cpan.org/modules/by-module/SMS/SMS-Send-NANP-Twilio-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(DateTime)
BuildRequires:  perl(JSON::XS)
BuildRequires:  perl(SMS::Send)
BuildRequires:  perl(SMS::Send::Driver::WebService) >= 0.06
BuildRequires:  perl(URI)
Requires:       perl(JSON::XS)
Requires:       perl(SMS::Send::Driver::WebService) >= 0.06
Requires:       perl(URI)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
SMS::Send driver for Twilio

%prep
%setup -q -n SMS-Send-NANP-Twilio-%{version}

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
%doc Changes README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
