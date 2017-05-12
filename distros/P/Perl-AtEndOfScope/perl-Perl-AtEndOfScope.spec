Name:         perl-Perl-AtEndOfScope
License:      Artistic License
Group:        Development/Libraries/Perl
Provides:     p_Perl_AtEndOfScope
Obsoletes:    p_Perl_AtEndOfScope
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Perl::AtEndOfScope
Version:      0.02
Release:      1
Source:       Perl-AtEndOfScope-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Perl::AtEndOfScope

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Perl-AtEndOfScope-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/Perl::AtEndOfScope.3pm || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorlib}/Perl
%{perl_vendorarch}/auto/Perl
%doc %{_mandir}/man3/Perl::AtEndOfScope.3pm.gz
/var/adm/perl-modules/perl-Perl-AtEndOfScope
%doc MANIFEST README
