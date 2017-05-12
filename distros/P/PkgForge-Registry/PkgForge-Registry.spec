Name:           PkgForge-Registry
Summary:        Package Forge job registry
Version:        1.3.0
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Utilities
Source:         PkgForge-Registry-1.3.0.tar.gz
BuildArch:	noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Module::Build), perl(Test::More) >= 0.87
BuildRequires:  perl(Moose), perl(MooseX::Types)
BuildRequires:  perl(Text::Abbrev)
BuildRequires:  perl(DBIx::Class)
BuildRequires:  PkgForge >= 1.3.0
BuildRequires:  perl(DateTime)

Requires:       PkgForge >= 1.3.0

# These do not get picked up automagically

Requires:       perl(DBIx::Class)
Requires:       perl(DBD::Pg)
Requires:       perl(DateTime::Format::Pg)

%description
Package Forge job registry

%prep
%setup -q -n PkgForge-Registry-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%files
%defattr(-,root,root)
%doc ChangeLog README NOTES.txt
%doc %{_mandir}/man3/*
%doc /usr/share/pkgforge/doc/registry
%{perl_vendorlib}/PkgForge/*
%config /etc/pkgforge/*.yml
/usr/share/pkgforge/scripts/*

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Mon May 09 2011 SVN: new release
- Release: 1.3.0

* Mon May 09 2011 08:12 squinney@INF.ED.AC.UK
- doc/manage_builders.html, doc/manage_platforms.html: Add docs on
  how to manage platforms and builders

* Wed May 04 2011 10:34 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.2.1

* Wed May 04 2011 10:34 squinney@INF.ED.AC.UK
- doc/admin.html: Added note about required software

* Mon May 02 2011 14:59 squinney@INF.ED.AC.UK
- doc/admin.html: corrected tiny error

* Mon May 02 2011 14:55 squinney@INF.ED.AC.UK
- doc/client.html: tweaked client docs

* Mon May 02 2011 14:53 squinney@INF.ED.AC.UK
- doc/client.html: Added docs on client configuration

* Mon May 02 2011 12:53 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.2.0

* Mon May 02 2011 12:53 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Registry/Schema/Result/BuildLog.pm.in,
  lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  scripts/registry-setup.sql: Altered the build_log table so that
  it has fewer dependencies on other tables. This makes it possible
  to delete some things without losing the log info

* Mon May 02 2011 11:51 squinney@INF.ED.AC.UK
- doc/admin.html: more work on the admin docs

* Mon May 02 2011 10:42 squinney@INF.ED.AC.UK
- doc/admin.html: Added admin guide

* Mon May 02 2011 10:42 squinney@INF.ED.AC.UK
- scripts/registry-setup.sql: Removed the 'create user' calls, now
  done separately in the registry-init script

* Mon May 02 2011 10:41 squinney@INF.ED.AC.UK
- scripts/registry-init.sh: Added the creation of all roles

* Mon May 02 2011 08:59 squinney@INF.ED.AC.UK
- doc/index.html: Small improvements to the introductory docs

* Fri Apr 01 2011 04:52 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.1.1

* Fri Apr 01 2011 04:52 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Registry.pm.in: small tweak to roles
  consumed

* Wed Mar 02 2011 09:01 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App/Platform.pm.in: Also display the new
  'auto' field for each platform in the list command

* Wed Mar 02 2011 09:01 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Builder.pm.in: permit the adding of builders for
  inactive platforms. This is useful when preparing new build
  platforms

* Tue Mar 01 2011 08:43 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.1.0

* Tue Mar 01 2011 08:42 squinney@INF.ED.AC.UK
- PkgForge-Registry.spec, lcfg.yml,
  lib/PkgForge/App/Platform.pm.in, lib/PkgForge/Registry.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  scripts/registry-setup.sql: Added support for new 'auto' field in
  the platform table

* Tue Mar 01 2011 06:03 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Do more to ensure that tasks are
  only registered for active platforms

* Wed Feb 16 2011 13:59 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.0.3

* Wed Feb 16 2011 13:58 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Only register tasks for active
  platforms

* Wed Jan 26 2011 15:05 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.0.2

* Wed Jan 26 2011 15:04 squinney@INF.ED.AC.UK
- PkgForge-Registry.spec: Added missing build-requires

* Wed Jan 26 2011 14:40 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.0.1

* Wed Jan 26 2011 14:40 squinney@INF.ED.AC.UK
- PkgForge-Registry.spec: Added build-requires on PkgForge

* Wed Jan 26 2011 14:40 squinney@INF.ED.AC.UK
- scripts/registry-setup.sql: fixed access to the job status table
  for pkgforge builders

* Sat Jan 22 2011 18:32 squinney@INF.ED.AC.UK
- scripts/registry-setup.sql: handle the builder current task field
  being null

* Sat Jan 22 2011 18:25 squinney@INF.ED.AC.UK
- scripts/registry-setup.sql: allow the builder user to update the
  job status and modtime

* Sat Jan 22 2011 18:25 squinney@INF.ED.AC.UK
- scripts/registry-init.sh: Set --no-createdb and --no-superuser
  for the pkgforge admin user

* Mon Jan 10 2011 13:15 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 1.0.0

* Mon Jan 10 2011 13:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: renamed some attributes to make them
  more consistent

* Mon Dec 20 2010 07:39 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 0.8.9

* Mon Dec 20 2010 07:38 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in: Added support for
  mapping in the new PkgForge::Job size attribute

* Thu Dec 16 2010 15:41 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 0.8.8

* Thu Dec 16 2010 15:21 squinney@INF.ED.AC.UK
- doc/index.html: made a start on the registry docs

* Thu Dec 16 2010 13:55 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Registry.spec: Added some documentation of
  the DB schema

* Wed Dec 15 2010 12:30 squinney@INF.ED.AC.UK
- doc/pkgforge.png: Added png as well for web page display

* Wed Dec 15 2010 12:03 squinney@INF.ED.AC.UK
- NOTES.txt, doc/pkgforge.dia, doc/pkgforge.dot, doc/pkgforge.html,
  doc/pkgforge.neato, doc/pkgforge.ps, doc/pkgforge.xml,
  doc/pkgforge.zigzag.dia: added some diagrams of the sql schema

* Wed Dec 15 2010 11:59 squinney@INF.ED.AC.UK
- doc: added doc dir

* Wed Dec 15 2010 11:27 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Builder.pm.in, lib/PkgForge/App/Platform.pm.in:
  Added more documentation

* Wed Dec 15 2010 10:55 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: clean namespace earlier for safety

* Wed Dec 15 2010 10:36 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in, lib/PkgForge/Registry/Role.pm.in:
  Added more documentation

* Wed Dec 15 2010 09:21 squinney@INF.ED.AC.UK
- NOTES.txt: Added some notes on how the schema classes were
  generated

* Wed Dec 15 2010 09:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/Builder.pm.in: Added a
  has_many relationship between builder and build_logs

* Wed Dec 15 2010 09:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/BuildLog.pm.in: Added schema
  result class for the new build_log table

* Mon Dec 13 2010 18:38 squinney@INF.ED.AC.UK
- scripts/registry-setup.sql: Added trigger to update job status
  when task status changes

* Mon Dec 13 2010 14:59 squinney@INF.ED.AC.UK
- README: Added README

* Mon Dec 13 2010 12:20 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 0.8.7

* Mon Dec 13 2010 12:20 squinney@INF.ED.AC.UK
- PkgForge-Registry.spec: Added missing dependencies which are not
  picked up automagically

* Mon Dec 13 2010 12:19 squinney@INF.ED.AC.UK
- MANIFEST: fixed manifest for State to TaskStatus switchover

* Mon Dec 13 2010 12:16 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 0.8.6

* Mon Dec 13 2010 12:16 squinney@INF.ED.AC.UK
- PkgForge-Registry.spec: Marked config files so they do not get
  overwritten

* Mon Dec 13 2010 12:05 squinney@INF.ED.AC.UK
- lib/PkgForge/App, lib/PkgForge/App/Builder.pm.in,
  lib/PkgForge/App/Platform.pm.in: Moved over the two registry apps

* Mon Dec 13 2010 11:40 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in,
  lib/PkgForge/Registry/Schema/Result/State.pm.in,
  lib/PkgForge/Registry/Schema/Result/Task.pm.in,
  lib/PkgForge/Registry/Schema/Result/TaskStatus.pm.in: The state
  table is now known as task_status. This results in a switch from
  the State module to TaskStatus

* Mon Dec 13 2010 10:55 squinney@INF.ED.AC.UK
- META.yml.in, Makefile.PL: Added some more Perl module meta-data
  files

* Mon Dec 13 2010 10:24 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Registry release: 0.8.5

* Mon Dec 13 2010 10:24 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Registry.spec, conf,
  conf/registry-builder.yml, conf/registry-incoming.yml,
  conf/registry-web.yml, conf/registry.yml, lcfg.yml: Added
  standard config files for DB access

* Mon Dec 13 2010 10:23 squinney@INF.ED.AC.UK
- MANIFEST, MANIFEST.SKIP: Added manifest

* Mon Dec 13 2010 10:01 squinney@INF.ED.AC.UK
- registry-init.sh, scripts/registry-init.sh: Moved to the scripts
  directory and made executable

* Mon Dec 13 2010 09:59 squinney@INF.ED.AC.UK
- lcfg.yml, registry-init.sh, registry-init.txt, registry-wipe.txt,
  registry.txt, scripts, scripts/registry-setup.sql,
  scripts/registry-wipe.sql: Added lots of documentation to the
  registry setup scripts

* Mon Dec 13 2010 06:54 squinney@INF.ED.AC.UK
- t, t/00_load.t: Added basic load tests

* Mon Dec 13 2010 06:42 squinney@INF.ED.AC.UK
- registry-init.txt, registry-wipe.txt, registry.txt: Added
  registry sql files

* Mon Dec 13 2010 06:41 squinney@INF.ED.AC.UK
- README: Added README

* Mon Dec 13 2010 06:40 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: Added changelog

* Mon Dec 13 2010 06:38 squinney@INF.ED.AC.UK
- lcfg.yml: Added build tools file

* Mon Dec 13 2010 06:36 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Registry.spec: Added specfile and build
  script

* Mon Dec 13 2010 06:25 squinney@INF.ED.AC.UK
- lib, lib/PkgForge, lib/PkgForge/Registry,
  lib/PkgForge/Registry.pm.in, lib/PkgForge/Registry/App.pm.in,
  lib/PkgForge/Registry/Role.pm.in, lib/PkgForge/Registry/Schema,
  lib/PkgForge/Registry/Schema.pm.in,
  lib/PkgForge/Registry/Schema/Result: Imported PkgForge::Registry
  code from the PkgForge project directory

* Mon Dec 13 2010 06:19 squinney@INF.ED.AC.UK
- .: Added separate project directory for the Package Forge
  registry code


