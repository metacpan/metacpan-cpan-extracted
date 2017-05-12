Name:           PkgForge-Server
Summary:        Package Forge servers
Version:        1.1.10
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Utilities
Source:         PkgForge-Server-1.1.10.tar.gz
BuildArch:	noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Module::Build), perl(Test::More) >= 0.87
BuildRequires:  perl(Test::File) >= 1.24, perl(Test::Exception)
BuildRequires:  perl(Moose)
BuildRequires:  PkgForge >= 1.4.6, PkgForge-Registry
BuildRequires:  perl(MIME::Lite::TT), perl(Template)
BuildRequires:  perl(RPM2)

# These are loaded via Moose 'with' or 'extends' so do not get picked
# up automatically.

BuildRequires:  perl(MooseX::Getopt), perl(MooseX::LogDispatch)
Requires:       perl(MooseX::Getopt)
Requires:       perl(MooseX::LogDispatch), perl(Log::Dispatch) >= 2.21
Requires:       perl(File::Temp) >= 0.22
Requires:       PkgForge >= 1.4.6, PkgForge-Registry

%description
Package Forge servers

%prep
%setup -q -n PkgForge-Server-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

mkdir -p $RPM_BUILD_ROOT/var/lib/pkgforge
mkdir -p $RPM_BUILD_ROOT/var/log/pkgforge
mkdir -p $RPM_BUILD_ROOT/var/run/pkgforge
mkdir -p $RPM_BUILD_ROOT/var/tmp/pkgforge

%check
./Build test

%files
%defattr(-,root,root)
%doc ChangeLog README
%doc %{_mandir}/man3/*
%doc /usr/share/pkgforge/doc/server
%{perl_vendorlib}/PkgForge/*
%config(noreplace) /etc/pkgforge/*.cfg
/etc/init.d/*
/usr/sbin/*
%{_bindir}/mock_config_query
%attr(755, pkgforge, pkgforge) /var/lib/pkgforge
%attr(755, pkgforge, pkgforge) /var/log/pkgforge
%attr(755, pkgforge, pkgforge) /var/run/pkgforge
%attr(750, pkgforge, pkgforge) /var/tmp/pkgforge

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Jul 03 2012 SVN: new release
- Release: 1.1.10

* Tue Jul 03 2012 14:26 squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in, PkgForge-Server.spec, lcfg.yml,
  lib/PkgForge/Handler.pm.in: Reverted most of the previous change.
  Took a different approach and patched MooseX::App::Cmd instead

* Tue Jul 03 2012 13:17 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.9

* Tue Jul 03 2012 13:17 squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in, PkgForge-Server.spec,
  lib/PkgForge/Handler.pm.in: Reworked the way we handle the
  default configfile attribute for an application to work with
  MooseX::App::Cmd >= 0.09. Also bumped the minimum required
  version of the core PkgForge module

* Fri Aug 05 2011 08:51 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Reporter/Email.pm.in: minor tweak to
  the default email report template

* Mon Jul 18 2011 15:15 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.8

* Mon Jul 18 2011 15:14 squinney@INF.ED.AC.UK
- conf/log-default.cfg,
  lib/PkgForge/BuildCommand/Reporter/Email.pm.in: Only display the
  package basename not the full path

* Mon Jul 18 2011 14:32 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.7

* Mon Jul 18 2011 14:28 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Reporter/Email.pm.in: Further tweaks to
  the email template

* Mon Jul 18 2011 14:09 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Reporter/Email.pm.in: Added list of
  success/fail packages to the email report

* Thu Jun 30 2011 04:46 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Made load_queue more robust

* Wed Jun 01 2011 13:07 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.6

* Wed Jun 01 2011 13:07 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Buildd2.pm.in, lib/PkgForge/Daemon/Buildd.pm.in,
  lib/PkgForge/Daemon/Buildd2.pm.in, sbin/pkgforge-buildd.in:
  Removed the rest of the Buildd2 stuff which is now in the main
  modules

* Wed Jun 01 2011 12:39 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.5

* Wed Jun 01 2011 12:38 squinney@INF.ED.AC.UK
- lcfg.yml, t/00_load.t: Buildd2 is now considered stable so it
  replaces Buildd

* Wed Jun 01 2011 12:36 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in,
  lib/PkgForge/Handler/Buildd2.pm.in: Switched new Buildd to being
  the default (and only) version

* Mon May 09 2011 08:21 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.4

* Mon May 09 2011 08:20 squinney@INF.ED.AC.UK
- doc/admin/builder.html, doc/admin/incoming.html,
  doc/admin/mock.html: docs updates

* Wed May 04 2011 11:54 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.3

* Wed May 04 2011 11:54 squinney@INF.ED.AC.UK
- Build.PL.in, lcfg.yml: Fixed the inclusion of admin docs

* Wed May 04 2011 11:25 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.2

* Wed May 04 2011 11:25 squinney@INF.ED.AC.UK
- PkgForge-Server.spec: Added build-dependency on RPM2 perl module

* Wed May 04 2011 10:28 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.1

* Wed May 04 2011 10:27 squinney@INF.ED.AC.UK
- Build.PL.in: Added various missing deps

* Wed May 04 2011 10:27 squinney@INF.ED.AC.UK
- doc/admin, doc/admin/filesystem.html, doc/admin/incoming.html:
  Added docs on how to configure the filesystem and how to configue
  the incoming queue processor

* Mon Apr 25 2011 13:34 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Reporter/Email.pm.in: tweaked the email
  report subject to be more useful

* Fri Apr 22 2011 14:44 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.1.0

* Fri Apr 22 2011 14:44 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildInfo.pm.in: Added methods to make it easier to
  find out how many packages were attempted/succeeded/failed

* Fri Apr 22 2011 14:43 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: More thorough testing of the
  writability of the accepted jobs directory. Altered load_queue to
  handle the filesystem disappearing for short periods of time

* Fri Apr 22 2011 12:16 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.0.4

* Fri Apr 22 2011 12:16 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Builder/RPM.pm.in: Fixed the logic
  which decides when it is necessary to rebuild SRPMs to handle the
  rpmlib API change

* Fri Apr 22 2011 11:53 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.0.3

* Fri Apr 22 2011 11:52 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Submitter/PkgSubmit.pm.in: Do not bomb
  out if pkgsubmit fails for normal reasons, just log it and return
  zero

* Fri Apr 22 2011 11:50 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Check/RPMLint.pm.in: Fixed logging of
  error message if rpmlint has failed

* Fri Apr 22 2011 11:25 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.0.2

* Fri Apr 22 2011 11:25 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Check/RPMLint.pm.in: Fixed the handling
  of the exit code for rpmlint

* Fri Apr 22 2011 10:57 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.0.1

* Fri Apr 22 2011 10:57 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Handle build errors correctly

* Fri Apr 22 2011 09:44 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 1.0.0

* Fri Apr 22 2011 09:43 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand.pm.in: Merged the handling of the build
  command module names and standardised the stringification

* Fri Apr 22 2011 09:43 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Added support for digitally
  signing packages

* Fri Apr 22 2011 09:42 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd2.pm.in: Improved logging of which task
  is being started and finished

* Fri Apr 22 2011 09:41 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Builder.pm.in,
  lib/PkgForge/BuildCommand/Check.pm.in,
  lib/PkgForge/BuildCommand/Reporter/Email.pm.in,
  lib/PkgForge/BuildCommand/Signer,
  lib/PkgForge/BuildCommand/Submitter.pm.in: Merged the handling of
  the build command module names and standardised the
  stringification

* Fri Apr 22 2011 08:17 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App/Buildd2.pm.in,
  lib/PkgForge/BuildCommand/Signer.pm.in,
  lib/PkgForge/Daemon/Buildd2.pm.in, sbin/pkgforge-buildd.in,
  t/00_load.t: Added a build command role for the digital-signing
  phase

* Fri Apr 22 2011 08:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Do not block the submission of
  SRPMs

* Fri Apr 22 2011 07:08 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Ensure temporary directory
  permissions are always correct on startup

* Fri Apr 22 2011 06:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Added missing 'use' of
  File::Temp module

* Fri Apr 22 2011 06:48 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: added missing semi-colon

* Fri Apr 22 2011 06:47 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Improved test for results
  directory writability

* Fri Apr 22 2011 05:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Fixed more typos

* Fri Apr 22 2011 05:29 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Fixed various small bugs

* Fri Apr 22 2011 05:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Added start of docs

* Fri Apr 22 2011 05:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Docs tweak

* Fri Apr 22 2011 05:10 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Added in the new build method
  and all the DB handling code which is the same as in the previous
  generation build daemon

* Fri Apr 22 2011 05:07 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Check/RPMLint.pm.in: Do not enforce
  errors from rpmlint for now

* Tue Apr 05 2011 19:31 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: fixed role name for reporter
  list

* Tue Apr 05 2011 19:28 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: fixed checks and reports
  builder methods

* Tue Apr 05 2011 19:18 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: fixed variable names

* Tue Apr 05 2011 19:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: fixed typo

* Tue Apr 05 2011 19:07 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd2.pm.in: Added build methods for the
  rest of the commands

* Tue Apr 05 2011 19:05 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Submitter.pm.in: tidied

* Tue Apr 05 2011 16:02 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Buildd2.pm.in: made a start on the
  new build daemon

* Tue Apr 05 2011 16:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: Add MooseX::Getopt role for now

* Tue Apr 05 2011 11:02 squinney@INF.ED.AC.UK
- t/00_load.t: test tweaks

* Tue Apr 05 2011 11:02 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Check.pm.in: oops, stringify method was
  after the END

* Tue Apr 05 2011 10:42 squinney@INF.ED.AC.UK
- PkgForge-Server.spec, lcfg.yml, lib/PkgForge/Builder.pm.in,
  lib/PkgForge/Handler.pm.in, lib/PkgForge/Handler/Buildd.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in: Added new pkgforge temporary
  directory. Should be more secure and avoid potential clashes
  between build daemons

* Tue Apr 05 2011 10:35 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Set svn:keywords

* Tue Apr 05 2011 10:35 squinney@INF.ED.AC.UK
- t/01_builder.t: Switched to new Builder module

* Tue Apr 05 2011 10:33 squinney@INF.ED.AC.UK
- t/00_load.t: Module load tests added for new build command
  modules

* Tue Apr 05 2011 10:32 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildInfo.pm.in: More work on the new BuildInfo
  class

* Tue Apr 05 2011 10:09 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildLog.pm.in: Added new module to provide an
  object which can handle the per-job logging

* Tue Apr 05 2011 10:09 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Builder.pm.in,
  lib/PkgForge/BuildCommand/Builder/RPM.pm.in: Added new builder
  build command modules

* Tue Apr 05 2011 10:05 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: Set svn:keywords

* Tue Apr 05 2011 10:04 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Builder: Added builder command tree

* Tue Apr 05 2011 10:03 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildTopic.pm.in: Added close_on_write option for
  logging. Set svn:keywords

* Tue Apr 05 2011 10:02 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Check,
  lib/PkgForge/BuildCommand/Check.pm.in,
  lib/PkgForge/BuildCommand/Check/RPMLint.pm.in,
  lib/PkgForge/Check, lib/PkgForge/Check.pm.in: Moved check modules
  to new build command tree

* Tue Apr 05 2011 09:59 squinney@INF.ED.AC.UK
- lib/PkgForge/Check, lib/PkgForge/Check.pm.in,
  lib/PkgForge/Check/RPMLint.pm.in: Added check modules

* Tue Apr 05 2011 09:58 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Reporter,
  lib/PkgForge/BuildCommand/Reporter.pm.in,
  lib/PkgForge/BuildCommand/Reporter/Email.pm.in,
  lib/PkgForge/Reporter, lib/PkgForge/Reporter.pm.in: moved
  reporter modules to new build command tree

* Tue Apr 05 2011 09:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Reporter, lib/PkgForge/Reporter.pm.in,
  lib/PkgForge/Reporter/Email.pm.in: added report modules

* Tue Apr 05 2011 09:53 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand/Submitter,
  lib/PkgForge/BuildCommand/Submitter.pm.in,
  lib/PkgForge/BuildCommand/Submitter/PkgSubmit.pm.in,
  lib/PkgForge/Submitter, lib/PkgForge/Submitter.pm.in: Moved
  submitter modules to new tree

* Tue Apr 05 2011 09:45 squinney@INF.ED.AC.UK
- lib/PkgForge/Submitter, lib/PkgForge/Submitter.pm.in,
  lib/PkgForge/Submitter/PkgSubmit.pm.in: Added package submission
  command

* Tue Apr 05 2011 09:44 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand.pm.in: set svn:keywords

* Tue Apr 05 2011 09:43 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand.pm.in: Added base role for build
  commands

* Tue Apr 05 2011 09:36 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildCommand: Added directory for build command
  modules

* Mon Apr 04 2011 07:36 squinney@INF.ED.AC.UK
- doc/incoming.html, lib/PkgForge/BuildInfo.pm.in: Added new
  BuildInfo class for managing information related to building a
  job

* Thu Mar 31 2011 16:47 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.6

* Thu Mar 31 2011 16:44 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Filter out any SRPMs, we already
  have them stored elsewhere as part of the originally submitted
  job

* Mon Feb 28 2011 20:13 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: pass thru error message for
  logging

* Mon Feb 28 2011 19:52 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.5

* Mon Feb 28 2011 19:51 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: progname needed to be lazy

* Fri Feb 18 2011 16:22 squinney@INF.ED.AC.UK
- PkgForge-Server.spec: Set a new minimum required version of
  PkgForge

* Fri Feb 18 2011 16:08 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.4

* Fri Feb 18 2011 16:07 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/BuildTopic.pm.in: fixed missing import of
  SourcePackageList Moose type

* Fri Feb 18 2011 13:54 squinney@INF.ED.AC.UK
- doc/incoming.html: added some internal links

* Fri Feb 18 2011 13:43 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.3

* Fri Feb 18 2011 12:53 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: The temp directory should be
  removed when the object goes out of scope, not when the program
  exits

* Fri Feb 18 2011 12:45 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: The path was being put onto the
  failure/retry list instead of the source package object, this
  prevented the builder from retrying sources later

* Fri Feb 18 2011 10:43 squinney@INF.ED.AC.UK
- doc/incoming.html: Added description of incoming queue processing

* Tue Feb 01 2011 13:43 squinney@INF.ED.AC.UK
- conf/log-buildd.cfg, conf/log-incoming.cfg: set the
  close_on_write option to true so that logrotate 'just works'

* Fri Jan 28 2011 09:59 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.2

* Fri Jan 28 2011 09:58 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Buildd.pm.in: Actually send a
  report when the job is finished

* Thu Jan 27 2011 14:48 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.1

* Thu Jan 27 2011 14:48 squinney@INF.ED.AC.UK
- PkgForge-Server.spec: Added missing build-requires

* Thu Jan 27 2011 14:04 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.12.0

* Thu Jan 27 2011 14:03 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Buildd.pm.in, templates: added
  support for sending reports by email

* Thu Jan 27 2011 14:02 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: added another error message
  to make it more obvious what is happening

* Thu Jan 27 2011 13:57 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: overload double-quote context so
  that the builder object stringifies to the name

* Thu Jan 27 2011 13:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: Added a stringify method which
  returns the builder name, note that the overload has to be done
  in the individual classes which implement this role

* Thu Jan 27 2011 13:55 squinney@INF.ED.AC.UK
- PkgForge-Server.spec: updated requires and buildrequires lists

* Wed Jan 19 2011 14:24 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.11.0

* Wed Jan 19 2011 14:23 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/BuildTopic.pm.in,
  lib/PkgForge/Builder.pm.in, lib/PkgForge/Handler/Buildd.pm.in,
  t/01_builder.t: Restructured how the per-task logs are written
  and stored.

* Wed Jan 19 2011 12:13 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: More logging improvements

* Wed Jan 19 2011 09:22 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.5

* Wed Jan 19 2011 05:42 squinney@INF.ED.AC.UK
- init/pkgforge-buildd, init/pkgforge-incoming, lcfg.yml: Reworked
  how pagsh is used for starting daemons

* Wed Jan 19 2011 05:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Return true if tests are
  passed

* Wed Jan 19 2011 05:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Added a preflight test for
  writability of the accepted jobs directory

* Wed Jan 19 2011 05:38 squinney@INF.ED.AC.UK
- conf/log-buildd.cfg: added logging configuration for build
  daemons

* Tue Jan 18 2011 14:26 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.4

* Tue Jan 18 2011 14:10 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Server.spec: We need a version of
  File::Temp which is better than 0.16, only tested 0.22 so make
  that the minimum required version

* Tue Jan 18 2011 12:33 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.3

* Tue Jan 18 2011 12:33 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Builder/RPM.pm.in: improved error
  reporting

* Tue Jan 18 2011 12:32 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: use File::Temp to ensure we
  can write into the results directory

* Tue Jan 18 2011 12:32 squinney@INF.ED.AC.UK
- sbin/createrepo_hack: needed to quote the createrepo file glob to
  avoid the possibility of the shell expansion

* Tue Jan 18 2011 10:03 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Added support for building source
  packages created with recent rpmlib versions on older platforms

* Tue Jan 18 2011 09:34 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildTopic.pm.in: Made the sources attribute rw so
  the list can be replaced when necessary

* Tue Jan 18 2011 09:33 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Support a timeout option which
  can be passed on to the package builder object

* Mon Jan 17 2011 19:11 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.2

* Mon Jan 17 2011 19:11 squinney@INF.ED.AC.UK
- Build.PL.in: added missing comma

* Mon Jan 17 2011 19:09 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.1

* Mon Jan 17 2011 19:07 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: kill k5start if the daemon fails to start

* Mon Jan 17 2011 19:07 squinney@INF.ED.AC.UK
- init/pkgforge-buildd: Run k5start inside pagsh

* Mon Jan 17 2011 19:01 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: Run k5start within pagsh to get AFS
  access working correctly

* Mon Jan 17 2011 14:21 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Server.spec: The code requires at least
  version 2.21 for Log::Dispatch

* Mon Jan 17 2011 12:53 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.10.0

* Mon Jan 17 2011 10:19 squinney@INF.ED.AC.UK
- init/pkgforge-buildd, init/pkgforge-incoming: explicitly set
  KRB5CCNAME after running k5start

* Mon Jan 17 2011 10:11 squinney@INF.ED.AC.UK
- init/pkgforge-buildd: Reworked init script for build daemons to
  use standard functions

* Mon Jan 17 2011 10:11 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: removed some stuff which is now
  unnecessary

* Mon Jan 17 2011 09:59 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: Added stop message for k5start

* Mon Jan 17 2011 09:55 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: Reworked the incoming daemon init script
  to use the common functions

* Fri Jan 14 2011 15:16 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.9.2

* Fri Jan 14 2011 15:16 squinney@INF.ED.AC.UK
- sbin/createrepo_hack: added hacky workaround script for
  createrepo leaving files not group-writable

* Fri Jan 14 2011 13:57 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.9.1

* Fri Jan 14 2011 13:57 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: return false when the build fails

* Fri Jan 14 2011 13:50 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.9.0

* Fri Jan 14 2011 11:59 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in, lib/PkgForge/Daemon/Buildd.pm.in: Made
  the daemon status message overridable and do so for the build
  daemons so that the name gets embedded

* Fri Jan 14 2011 11:49 squinney@INF.ED.AC.UK
- init/pkgforge-buildd, init/pkgforge-incoming: Reworked the
  checking of the start methods

* Fri Jan 14 2011 11:36 squinney@INF.ED.AC.UK
- init/pkgforge-buildd: Set as executable

* Fri Jan 14 2011 11:33 squinney@INF.ED.AC.UK
- init/pkgforge-buildd: Added basic support for managing all build
  daemons on a host

* Fri Jan 14 2011 11:20 squinney@INF.ED.AC.UK
- init/pkgforge-buildd: Added init script for build daemons

* Fri Jan 14 2011 11:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in: Set the default pid file name
  differently based on the name of the build daemon

* Fri Jan 14 2011 11:12 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: Improved output. Fixed runuser/su call by
  using a better env variable name

* Fri Jan 14 2011 10:18 squinney@INF.ED.AC.UK
- init/pkgforge-incoming: fixed shell

* Fri Jan 14 2011 10:18 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Fixed status method

* Fri Jan 14 2011 10:09 squinney@INF.ED.AC.UK
- init/pkgforge-incoming, sbin/pkgforge-buildd.in,
  sbin/pkgforge-incoming.in: mark scripts as executable

* Fri Jan 14 2011 10:08 squinney@INF.ED.AC.UK
- Build.PL.in, lcfg.yml: fixed copy/paste error

* Fri Jan 14 2011 10:01 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Server.spec, init, init/pkgforge-incoming:
  Added a basic init script for the pkgforge incoming queue
  processor

* Wed Jan 12 2011 17:25 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in, lib/PkgForge/Handler/Initialise.pm.in,
  lib/PkgForge/Queue.pm.in: A few little code improvements based on
  feedback from perlcritic

* Wed Jan 12 2011 17:10 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildTopic.pm.in: Added missing 'use'

* Wed Jan 12 2011 17:03 squinney@INF.ED.AC.UK
- lib/PkgForge/Server.pm.in: Added top-level Server package just as
  a documentation holder

* Wed Jan 12 2011 16:39 squinney@INF.ED.AC.UK
- PkgForge-Server.spec: never replace pkgforge config files

* Wed Jan 12 2011 16:39 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Use the new BuildTopic methods
  for storing logs and generated packages

* Wed Jan 12 2011 16:38 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: Pass through the debug attribute
  value to the build topic

* Wed Jan 12 2011 16:38 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildTopic.pm.in: Added full API docs. Added methods
  for storing log files and generated packages

* Wed Jan 12 2011 16:15 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Builder/RPM.pm.in: Switched to using the
  new BuildTopic

* Wed Jan 12 2011 16:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: Now using the new BuildTopic object.
  Created a generic build() method which calls a run() method in
  the specific class

* Wed Jan 12 2011 16:13 squinney@INF.ED.AC.UK
- lib/PkgForge/BuildTopic.pm.in: Added a simple class to hold all
  the info on the current build task

* Tue Jan 11 2011 15:18 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Removed the configfile
  attribute overrides, this all now works fine from the
  parent-class. Slightly modified the call to the build method for
  the builder class. Also now pass in the setting of the debug
  parameter.

* Tue Jan 11 2011 15:17 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: removed the configfile
  attribute overrides, this all now works fine from the
  parent-class

* Tue Jan 11 2011 15:17 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Moved the setting of the umask and
  working directory outside of the daemonize routine so that they
  are done earlier. Removed the unused 'user' attribute.

* Tue Jan 11 2011 15:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in, t/02_incoming.t: Modified the list of
  standard configuration files for handlers

* Tue Jan 11 2011 15:15 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Server.spec: Updated list of requirements

* Fri Dec 17 2010 09:44 squinney@INF.ED.AC.UK
- t/01_builder.t, t/01_daemon.t, t/01_pidfile.t, t/01_queue.t,
  t/02_incoming.t: Added the tests which were previously in the
  PkgForge project directory

* Fri Dec 17 2010 09:40 squinney@INF.ED.AC.UK
- t/00_load.t: Added basic module tests

* Fri Dec 17 2010 09:31 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.8.10

* Fri Dec 17 2010 09:30 squinney@INF.ED.AC.UK
- MANIFEST, MANIFEST.SKIP, META.yml.in: Added standard
  Module::Build metadata files

* Fri Dec 17 2010 09:24 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.8.9

* Fri Dec 17 2010 09:23 squinney@INF.ED.AC.UK
- PkgForge-Server.spec, lcfg.yml: Added mock_config_query script
  and some pkgforge directories

* Fri Dec 17 2010 09:22 squinney@INF.ED.AC.UK
- bin, bin/mock_config_query: Added the mock_config_query script
  for the RPM builder

* Fri Dec 17 2010 09:19 squinney@INF.ED.AC.UK
- doc/index.html: Added the first documentation html page

* Fri Dec 17 2010 09:18 squinney@INF.ED.AC.UK
- README: added the missing README file

* Fri Dec 17 2010 09:18 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge-Server release: 0.8.8

* Fri Dec 17 2010 09:17 squinney@INF.ED.AC.UK
- doc, lcfg.yml, t: First import of all server related modules

* Fri Dec 17 2010 09:17 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge-Server.spec: Added deps

* Fri Dec 17 2010 09:11 squinney@INF.ED.AC.UK
- ChangeLog: added empty changelog to make reltool happy

* Fri Dec 17 2010 09:10 squinney@INF.ED.AC.UK
- lib/PkgForge/App, lib/PkgForge/App/Buildd.pm.in,
  lib/PkgForge/App/Incoming.pm.in,
  lib/PkgForge/App/InitServer.pm.in: Moved server related apps

* Fri Dec 17 2010 09:08 squinney@INF.ED.AC.UK
- sbin, sbin/pkgforge-buildd.in, sbin/pkgforge-incoming.in: Moved
  pkgforge daemons

* Fri Dec 17 2010 09:08 squinney@INF.ED.AC.UK
- conf, conf/log-default.cfg, conf/log-incoming.cfg: Moved logging
  config files

* Fri Dec 17 2010 09:00 squinney@INF.ED.AC.UK
- ., lib, lib/PkgForge, lib/PkgForge/Builder,
  lib/PkgForge/Builder.pm.in, lib/PkgForge/Daemon,
  lib/PkgForge/Daemon.pm.in, lib/PkgForge/Handler,
  lib/PkgForge/Handler.pm.in, lib/PkgForge/PidFile.pm.in,
  lib/PkgForge/Queue, lib/PkgForge/Queue.pm.in: Moved all the
  server related modules into a separate project directory


