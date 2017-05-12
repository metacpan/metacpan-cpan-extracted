Name:         perl-Sys-Proctitle
License:      Artistic License
Group:        Development/Libraries/Perl
Provides:     p_Sys_Proctitle
Obsoletes:    p_Sys_Proctitle
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Sys::Proctitle
Version:      0.04
Release:      1
Source:       Sys-Proctitle-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Sys::Proctitle

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Sys-Proctitle-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
find $RPM_BUILD_ROOT%{_mandir}/man* -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorarch}/Sys
%{perl_vendorarch}/auto/Sys
%doc %{_mandir}
/var/adm/perl-modules/perl-Sys-Proctitle
%doc MANIFEST README
