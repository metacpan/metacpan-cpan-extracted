%define real_name NetAthlon2-RAW

Summary: Perl extensions to parse NetAthlon2 RAW performance data files
Name: perl-NetAthlon2-RAW
Version: 0.31
Release: 1%{?dist}
License: Artistic/GPL
Group: Applications/CPAN
URL: http://search.cpan.org/dist/%{real_name}/

Source: http://www.cpan.org/modules/by-module/NetAthlon2/%{real_name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: perl >= 5.8.0
BuildRequires: perl(GD::Graph)
Requires:perl >= 5.8.0
Requires: perl(GD::Graph)

%description
A perl module to parse the NetAthlon2 RAW file format.  parse() will
return a hash reference to the resultant data structure.

%prep
%setup -n %{real_name}-%{version}

%build
%{__perl} Build.PL installdirs=site
./Build

%install
%{__rm} -rf %{buildroot}

./Build install destdir=%{buildroot} create_packlist=0
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} %{buildroot}/*

%check
./Build test

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%doc Changes MANIFEST META.yml README
%doc %{_mandir}/man3/NetAthlon2::RAW.3pm*
%dir %{perl_sitelib}/NetAthlon2/
%{perl_sitelib}/NetAthlon2/RAW.pm
%{_bindir}/na2png

%changelog
* Tue Aug 24 2010 Jim Pirzyk <jim+rpm@pirzyk.org> - 0.31-1
- Software Update

* Tue Aug 24 2010 Jim Pirzyk <jim+rpm@pirzyk.org> - 0.30-1
- Initial package.
