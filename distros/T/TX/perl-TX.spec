Name:         perl-TX
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      TX
Version:      0.09
Release:      1
Source:       TX-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
TX a simple text template engine based on Text::Template and
Text::Template::Library

Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n TX-%{version}
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
%{perl_vendorlib}
%{perl_vendorarch}/auto
%doc %{_mandir}/man3/TX.3pm.gz
%doc %{_mandir}/man3/TX::Escape.3pm.gz
/var/adm/perl-modules/perl-TX
%doc MANIFEST
