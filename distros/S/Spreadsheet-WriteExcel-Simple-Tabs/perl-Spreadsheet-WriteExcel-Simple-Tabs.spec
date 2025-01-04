Name:           perl-Spreadsheet-WriteExcel-Simple-Tabs
Version:        0.11
Release:        1%{?dist}
Summary:        Simple Interface to the Spreadsheet::WriteExcel Package
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Spreadsheet-WriteExcel-Simple-Tabs/
Source0:        http://www.cpan.org/modules/by-module/Spreadsheet/Spreadsheet-WriteExcel-Simple-Tabs-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(IO::Scalar)
BuildRequires:  perl(Spreadsheet::WriteExcel)
Requires:       perl(IO::Scalar)
Requires:       perl(Spreadsheet::WriteExcel)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This is a simple wrapper around Spreadsheet::WriteExcel that creates tabs
for data. It is meant to be simple not full featured. I use this package to
export data from the DBIx::Array sqlarrayarrayname method which is an array
of array references where the first array is the column headings.

%prep
%setup -q -n Spreadsheet-WriteExcel-Simple-Tabs-%{version}

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
* Fri Jan 03 2025 Michael R. Davis (mrdvt92@yahoo.com) 0.11-1
- Updated for version 0.11
