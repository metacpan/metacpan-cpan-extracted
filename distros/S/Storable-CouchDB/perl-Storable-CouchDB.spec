Name:           perl-Storable-CouchDB
Version:        0.05
Release:        1%{?dist}
Summary:        Persistences for Perl data structures in Apache CouchDB
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Storable-CouchDB/
Source0:        http://www.cpan.org/modules/by-module/Storable/Storable-CouchDB-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(IO::Socket::INET)
buildRequires:  perl(CouchDB::Client)
Requires:       perl(CouchDB::Client)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
The Storable::CouchDB package brings persistence to your Perl data
structures containing SCALAR, ARRAY, HASH or anything that can be
serialized into JSON.

%prep
%setup -q -n Storable-CouchDB-%{version}

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
