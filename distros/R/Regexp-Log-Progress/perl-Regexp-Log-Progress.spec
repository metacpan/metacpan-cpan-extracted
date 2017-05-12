Name:           perl-Regexp-Log-Progress
Version:        0.03
Release:        1%{?dist}
Summary:        A set of modules to parse Progress database logs
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://wsipc-scm-01/repos/Regexp-Log-Progress/trunk/
Source0:        Regexp-Log-Progress-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Regexp::Log) >= 0.06
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
Requires:       perl(Regexp::Log) >= 0.06
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
A set of modules to parse Progress Softwares OpenEdge log files.

%prep
%setup -q -n Regexp-Log-Progress-%{version}

%build
%{__perl} Build.PL installdirs=site
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_sitelib}/*
/usr/local/share/man/*

%changelog
* Wed Mar 07 2014 "kesteb <kevin@kesteb.us>" 0.01-1
- Created for the v0.01 release.
