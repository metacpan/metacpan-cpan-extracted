Name:         perl-ModPerl2-Tools
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version} perl(Apache2::RequestRec)
Requires:     perl(ModPerl::MM) perl(Apache::TestMM)
Autoreqprov:  on
Summary:      ModPerl2::Tools
Version:      0.06
Release:      1
Source:       ModPerl2-Tools-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
A few useful methods to work with modperl2

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n ModPerl2-Tools-%{version}
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
%{perl_vendorlib}/ModPerl2
%{perl_vendorarch}/auto/ModPerl2
%doc %{_mandir}/man3
/var/adm/perl-modules/%{name}
%doc MANIFEST README
