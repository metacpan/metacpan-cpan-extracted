Name:           perl-MooseX-Types-EmailAddress
Summary:        Valid email address type constraints for Moose
Version:        1.1.2
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Utilities
Source:         MooseX-Types-EmailAddress-1.1.2.tar.gz
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(MooseX::Types), perl(Email::Valid), perl(Email::Address)

%description
A perl class which provides type constraints for valid email addresses
which can be used in Moose based classes.

%prep
%setup -q -n MooseX-Types-EmailAddress-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%files
%defattr(-,root,root)
%doc ChangeLog
%{perl_vendorlib}/MooseX/Types/*.pm
%{_mandir}/man3/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Apr 03 2013 SVN: new release
- Release: 1.1.2

* Wed Apr 03 2013 13:35 squinney@INF.ED.AC.UK
- MooseX-Types-EmailAddress.spec, lcfg.yml: Added pod to specfile
  files list

* Wed Apr 03 2013 13:34 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: MooseX-Types-EmailAddress release: 1.1.1

* Wed Apr 03 2013 13:34 squinney@INF.ED.AC.UK
- lib/MooseX/Types/EmailAddress.pm.in: Added perl docs

* Wed Aug 22 2012 13:36 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: MooseX-Types-EmailAddress release: 1.1.0

* Wed Aug 22 2012 13:35 squinney@INF.ED.AC.UK
- MooseX-Types-EmailAddress.spec, lcfg.yml: Commented out docs for
  now as there aren't any

* Wed Aug 22 2012 13:35 squinney@INF.ED.AC.UK
- t/00use.t: Added basic compilation test

* Wed Aug 22 2012 13:27 squinney@INF.ED.AC.UK
- ., Build.PL.in, ChangeLog, MANIFEST, MANIFEST.SKIP, META.yml.in,
  Makefile.PL, MooseX-Types-EmailAddress.spec, lcfg.yml, lib,
  lib/MooseX, lib/MooseX/Types,
  lib/MooseX/Types/EmailAddress.pm.in, t: first packaging


