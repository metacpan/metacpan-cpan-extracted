Name:           PkgForge
Summary:        Tools for building packages from source
Version:        1.4.8
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Utilities
Source:         PkgForge-1.4.8.tar.gz
BuildArch:	noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Module::Build), perl(Test::More) >= 0.87
BuildRequires:  perl(Test::File) >= 1.24, perl(Test::Exception)

BuildRequires:  perl(Data::UUID::Base64URLSafe)
BuildRequires:  perl(Digest::SHA1)
BuildRequires:  perl(Email::Address), perl(Email::Valid)
BuildRequires:  perl(File::Find::Rule), perl(File::HomeDir)
BuildRequires:  perl(Module::Find)
BuildRequires:  perl(Moose)
BuildRequires:  perl(MooseX::Getopt), perl(MooseX::App::Cmd) >= 0.09
BuildRequires:  perl(MooseX::ConfigFromFile)
BuildRequires:  perl(MooseX::Types)
BuildRequires:  perl(Readonly)
BuildRequires:  perl(UNIVERSAL::require)
BuildRequires:  perl(YAML::Syck), perl(RPM2)

# These are loaded via Moose 'with' or 'extends' so do not get picked
# up automatically.

Requires:       perl(MooseX::Getopt), perl(MooseX::App::Cmd) >= 0.09
Requires:       perl(MooseX::ConfigFromFile)

%description
Tools for building packages from source

%prep
%setup -q -n PkgForge-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build
pod2man --section=1 lib/PkgForge/App/Submit.pm pkgforge-submit.1

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

mkdir -p $RPM_BUILD_ROOT/var/lib/pkgforge
mkdir -p $RPM_BUILD_ROOT/var/log/pkgforge
mkdir -p $RPM_BUILD_ROOT/var/run/pkgforge

mkdir -p $RPM_BUILD_ROOT/%{_mandir}/man1
cp pkgforge-submit.1 $RPM_BUILD_ROOT/%{_mandir}/man1

%check
./Build test

%files
%defattr(-,root,root)
%doc ChangeLog README
%doc %{_mandir}/man1/*
%doc %{_mandir}/man3/*
%doc /usr/share/pkgforge/doc/*
%config(noreplace) /etc/pkgforge/*
%{_bindir}/pkgforge
%{perl_vendorlib}/PkgForge/*
%{perl_vendorlib}/PkgForge.pm

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Jul 03 2012 SVN: new release
- Release: 1.4.8

* Tue Jul 03 2012 14:28 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App.pm.in: Reverted most of the previous
  change. Took a different approach and patched MooseX::App::Cmd
  instead

* Tue Jul 03 2012 13:13 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.7

* Tue Jul 03 2012 13:13 squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in, Makefile.PL: Bumped minimum required
  version for MooseX::App::Cmd

* Tue Jul 03 2012 13:12 squinney@INF.ED.AC.UK
- PkgForge.spec, lcfg.yml, lib/PkgForge/App.pm.in: Reworked the way
  we handle the default configfile attribute for an application to
  work with MooseX::App::Cmd >= 0.09

* Thu Jun 30 2011 05:21 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.6

* Thu Jun 30 2011 05:10 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Process platforms and architectures lists
  in a case-insensitive way

* Tue May 10 2011 08:24 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.5

* Tue May 10 2011 08:24 squinney@INF.ED.AC.UK
- Build.PL.in, doc/index.html, doc/submitting.html: Added user
  guide on how to submit packages

* Mon May 09 2011 08:53 squinney@INF.ED.AC.UK
- doc/user: Added directory for user docs

* Mon May 09 2011 08:45 squinney@INF.ED.AC.UK
- doc/index.html: Added a link to builder config docs

* Mon May 09 2011 08:15 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.4

* Mon May 09 2011 08:15 squinney@INF.ED.AC.UK
- doc/index.html: Added new entries to the docs index

* Wed May 04 2011 11:46 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.3

* Wed May 04 2011 11:46 squinney@INF.ED.AC.UK
- doc/index.html: corrected some links

* Wed May 04 2011 11:33 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.2

* Wed May 04 2011 11:33 squinney@INF.ED.AC.UK
- doc/index.html: Added links to new docs

* Wed May 04 2011 11:32 squinney@INF.ED.AC.UK
- notes.txt: updated paths

* Wed May 04 2011 11:32 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: Permit a period in a job ID string

* Mon May 02 2011 08:30 squinney@INF.ED.AC.UK
- doc/intro.html: Small improvements to the introductory docs

* Mon May 02 2011 07:36 squinney@INF.ED.AC.UK
- doc/job.html: fixed formatting of verbatim sections

* Thu Mar 31 2011 16:28 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.1

* Thu Mar 31 2011 16:25 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Job.pm.in,
  lib/PkgForge/Types.pm.in: Changed the pkgforge job ID type to
  only allow certain characters

* Fri Mar 25 2011 15:52 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.4.0

* Fri Mar 25 2011 15:50 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in, lib/PkgForge/Job.pm.in,
  lib/PkgForge/Meta/Attribute/Trait/Serialise.pm.in,
  lib/PkgForge/SourceUtils.pm.in, lib/PkgForge/YAMLStorage.pm.in:
  Reworked how the serialisation and storage as YAML files works.
  It is all still compatible with the previous version but it gains
  some new functionality to work with code-refs as well as method
  names. This should make it more flexible and useful for classes
  other than just PkgForge::Job

* Fri Mar 25 2011 15:48 squinney@INF.ED.AC.UK
- doc/intro.html: Docs tweaks

* Fri Mar 25 2011 15:47 squinney@INF.ED.AC.UK
- t/01_configfile.t, t/01_source.t, t/01_sourceutils.t: Fixed the
  tests, also made it possible to run the test suite without having
  RPM2 installed

* Tue Mar 01 2011 08:25 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.3.0

* Tue Mar 01 2011 08:25 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Job.pm.in, t/process_platforms.t: Added
  support for differentiating between all active platforms and
  those which should be added automatically when a user does not
  express any preference

* Mon Feb 28 2011 20:41 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.2.1

* Mon Feb 28 2011 20:38 squinney@INF.ED.AC.UK
- lib/PkgForge/Source.pm.in: source basedir should be lazy and not
  required

* Mon Feb 28 2011 19:20 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.2.0

* Mon Feb 28 2011 19:19 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Job.pm.in,
  lib/PkgForge/YAMLStorage.pm.in, notes.txt: minor doc tweaks

* Mon Feb 28 2011 19:07 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Switched to using the YAMLStorage role

* Mon Feb 28 2011 18:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Meta/Attribute/Trait/Serialise.pm.in,
  lib/PkgForge/YAMLStorage.pm.in: Added yaml storage

* Fri Feb 18 2011 13:41 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.9

* Fri Feb 18 2011 13:41 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Job.pm.in, lib/PkgForge/Types.pm.in:
  Reworked the pkgforge source moose type to make it easier to use
  elsewhere

* Fri Feb 18 2011 13:41 squinney@INF.ED.AC.UK
- doc/index.html: updated link to perldoc. Added link to incoming
  processor docs

* Wed Feb 16 2011 16:05 squinney@INF.ED.AC.UK
- lib/PkgForge/Source/SRPM.pm.in: Updated notes about package
  validation

* Wed Feb 16 2011 15:54 squinney@INF.ED.AC.UK
- lib/PkgForge/Source/SRPM.pm.in: Added a check that the SRPM
  contains a specfile with a .spec suffix

* Wed Feb 16 2011 08:52 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.8

* Wed Feb 16 2011 08:51 squinney@INF.ED.AC.UK
- doc/index.html: Added documentation index page

* Mon Feb 14 2011 11:54 squinney@INF.ED.AC.UK
- doc/job.html: more build job docs

* Mon Feb 14 2011 10:41 squinney@INF.ED.AC.UK
- doc/job.html: Add docs on build jobs

* Fri Feb 11 2011 14:49 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.7

* Fri Feb 11 2011 14:49 squinney@INF.ED.AC.UK
- doc/intro.html: tweaked the intro docs

* Fri Feb 11 2011 14:34 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.6

* Fri Feb 11 2011 14:34 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge.spec, lcfg.yml: Install the doc files

* Fri Feb 11 2011 14:30 squinney@INF.ED.AC.UK
- Build.PL.in, doc, doc/intro.html: Added intro docs for pkgforge

* Tue Jan 25 2011 09:42 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.5

* Tue Jan 25 2011 09:41 squinney@INF.ED.AC.UK
- Build.PL.in, Makefile.PL, PkgForge.spec: forgot to add
  Email::Valid back to the deps list

* Tue Jan 25 2011 09:37 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.4

* Tue Jan 25 2011 09:36 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Types.pm.in, t/01_job.t: reworked the
  emailaddress types and added some tests for the improved handling
  of the Job report attribute

* Mon Jan 24 2011 16:51 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.3

* Mon Jan 24 2011 16:50 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge.spec, lcfg.yml, lib/PkgForge/Job.pm.in,
  lib/PkgForge/Types.pm.in, t/01_job.t: Switched to using
  Email::Address for the Job report attribute

* Wed Jan 19 2011 08:38 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.2

* Wed Jan 19 2011 08:38 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Handle attempts to submit
  unsupported source package types

* Wed Jan 19 2011 08:37 squinney@INF.ED.AC.UK
- lib/PkgForge/Utils.pm.in: Handle the top-directory not existing

* Mon Jan 10 2011 12:38 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.1

* Mon Jan 10 2011 12:38 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/ConfigFile.pm.in: Need to set a default
  value of an empty list for the configfile attribute now that it
  has an Array trait

* Mon Jan 10 2011 12:28 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.1.0

* Mon Jan 10 2011 12:27 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/ConfigFile.pm.in: Exclude the
  new_with_config method as we will provide our own (compatible)
  extended version. This allows us to append config files to the
  list (prefixed with a plus-sign) as well as replace the list

* Fri Jan 07 2011 11:34 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: do not set a default for the
  target, forces it to be specified

* Fri Jan 07 2011 11:04 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 1.0.0

* Fri Jan 07 2011 10:59 squinney@INF.ED.AC.UK
- bin/pkgforge.in, lib/PkgForge/App.pm.in,
  lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Job.pm.in,
  lib/PkgForge/Source/SRPM.pm.in, lib/PkgForge/SourceUtils.pm.in:
  small tweaks to satisfy perl-critic

* Fri Jan 07 2011 10:32 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Added some more docs on what a
  build job is

* Fri Jan 07 2011 09:36 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Avoid using magic punctuation
  variables

* Fri Jan 07 2011 09:29 squinney@INF.ED.AC.UK
- PkgForge.spec: Generate a pkgforge-submit.1 man page

* Wed Jan 05 2011 16:55 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.9.4

* Wed Jan 05 2011 16:51 squinney@INF.ED.AC.UK
- PkgForge.spec: Added the new top-level PkgForge module

* Wed Jan 05 2011 16:50 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: copyright update

* Wed Jan 05 2011 16:50 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: Added a short command-line flag
  for the configfile attribute

* Wed Jan 05 2011 16:49 squinney@INF.ED.AC.UK
- lib/PkgForge/App.pm.in: Tidied the configfile default sub.
  Updated some docs

* Wed Jan 05 2011 16:49 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: improved the docs

* Wed Jan 05 2011 16:48 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added support for verbose output. Added
  short command-line option flags for some attributes

* Wed Jan 05 2011 16:47 squinney@INF.ED.AC.UK
- lib/PkgForge/SourceUtils.pm.in, lib/PkgForge/Tool.pm.in,
  lib/PkgForge/Utils.pm.in: Documentation tweaks

* Wed Jan 05 2011 14:52 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in, lib/PkgForge/Types.pm.in: Switched to new
  PkgForgeList types which allow the user to specify lists of
  platforms or architectures as comma-separated strings. This makes
  the command-line applications much nicer and more intuitive to
  use

* Wed Jan 05 2011 12:46 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Source.pm.in,
  t/01_source.t: Added support for Source modules to just take a
  fullpath to the package as a string

* Wed Jan 05 2011 12:03 squinney@INF.ED.AC.UK
- lib/PkgForge.pm.in: added links to other pod

* Wed Jan 05 2011 11:59 squinney@INF.ED.AC.UK
- lib/PkgForge.pm.in: Added empty top-level module just to provide
  POD

* Wed Jan 05 2011 11:59 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: corrected copyright

* Sun Dec 19 2010 08:35 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.9.3

* Sun Dec 19 2010 08:35 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Job.pm.in: Trying to do the automatic
  updating of the job size using an 'after' method modifier instead

* Sun Dec 19 2010 08:13 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Triggers only fire when an attribute
  value is set, not when modified. Changed how the job size is
  measured

* Sun Dec 19 2010 08:08 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in, lib/PkgForge/Source.pm.in: Set source
  size and sha1sum attributes to be lazy. Switch to just grabbing
  the value of the attribute when serialising. do not need to do a
  has_value() check

* Sun Dec 19 2010 07:31 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Job.pm.in: set
  NoGetopt in the correct place

* Sun Dec 19 2010 07:00 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in, lib/PkgForge/Source.pm.in: Added support
  for examining the job size

* Fri Dec 17 2010 14:31 squinney@INF.ED.AC.UK
- lib/PkgForge/App.pm.in: Added docs for new module

* Fri Dec 17 2010 14:31 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: fixed handling of the default
  values which are sub-refs

* Fri Dec 17 2010 13:46 squinney@INF.ED.AC.UK
- PkgForge.spec, lcfg.yml: Re-enabled the tests now everything has
  been split into separate packages

* Fri Dec 17 2010 13:44 squinney@INF.ED.AC.UK
- lib/PkgForge/App.pm.in, lib/PkgForge/App/Submit.pm.in: Extracted
  some of the user-end app stuff out of the submit app so that it
  can be used elsewhere

* Fri Dec 17 2010 13:42 squinney@INF.ED.AC.UK
- PkgForge.spec, conf/pkgforge.yml: Added a basic config file

* Fri Dec 17 2010 12:22 squinney@INF.ED.AC.UK
- PkgForge.spec, lcfg.yml: Simplified the files list in the
  specfile

* Fri Dec 17 2010 12:21 squinney@INF.ED.AC.UK
- bin/pkgforge.in, lib/PkgForge/App.pm.in,
  lib/PkgForge/App/Submit.pm.in, lib/PkgForge/Tool.pm.in,
  lib/PkgForge/Utils.pm.in: Renamed PkgForge::App to PkgForge::Tool
  to clear the way for re-using that module name for something else

* Fri Dec 17 2010 10:02 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.9.2

* Fri Dec 17 2010 10:00 squinney@INF.ED.AC.UK
- META.yml, META.yml.in, Makefile.PL: updated the Module::Build
  metadata files

* Fri Dec 17 2010 09:57 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.9.1

* Fri Dec 17 2010 09:57 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge.spec: Updated the list of dependencies

* Fri Dec 17 2010 09:51 squinney@INF.ED.AC.UK
- MANIFEST, MANIFEST.SKIP, lcfg.yml: Updated MANIFEST

* Fri Dec 17 2010 09:42 squinney@INF.ED.AC.UK
- t/00_load.t, t/01_builder.t, t/01_daemon.t, t/01_pidfile.t,
  t/01_queue.t, t/02_incoming.t: moved all the server related tests

* Fri Dec 17 2010 09:37 squinney@INF.ED.AC.UK
- PkgForge.spec, bin/mock_config_query, bin/pkgforge-buildd.in,
  bin/pkgforge-incoming.in, conf/log-default.cfg,
  conf/log-incoming.cfg, lib/PkgForge/App/Buildd.pm.in,
  lib/PkgForge/App/Incoming.pm.in,
  lib/PkgForge/App/InitServer.pm.in, registry-init.txt,
  registry-wipe.txt, registry.txt: More stuff moved to separate
  packages

* Fri Dec 17 2010 09:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder, lib/PkgForge/Builder.pm.in,
  lib/PkgForge/Daemon, lib/PkgForge/Daemon.pm.in,
  lib/PkgForge/Handler, lib/PkgForge/Handler.pm.in,
  lib/PkgForge/PidFile.pm.in, lib/PkgForge/Queue,
  lib/PkgForge/Queue.pm.in: Moved all the server related modules
  into a separate project directory

* Mon Dec 13 2010 12:14 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.9.0

* Mon Dec 13 2010 12:13 squinney@INF.ED.AC.UK
- PkgForge.spec, lcfg.yml: Temporarily not running tests whilst the
  package is split into various bits

* Mon Dec 13 2010 12:12 squinney@INF.ED.AC.UK
- PkgForge.spec: No longer build depend on DBIx::Class

* Mon Dec 13 2010 12:11 squinney@INF.ED.AC.UK
- t/00_load.t: Removed a couple more tests related to registry
  stuff

* Mon Dec 13 2010 12:09 squinney@INF.ED.AC.UK
- PkgForge.spec, lib/PkgForge/App/Builder.pm.in,
  lib/PkgForge/App/Platform.pm.in, lib/PkgForge/Registry,
  lib/PkgForge/Registry.pm.in, t/00_load.t: Moved all the registry
  stuff to a separate project

* Mon Dec 13 2010 12:09 squinney@INF.ED.AC.UK
- Build.PL.in: added missing build_requires and set the Test::More
  minimum version

* Sat Dec 11 2010 07:48 squinney@INF.ED.AC.UK
- registry-wipe.txt: cascade everything

* Sat Dec 11 2010 07:45 squinney@INF.ED.AC.UK
- registry-wipe.txt: updated wipe list

* Sat Dec 11 2010 07:39 squinney@INF.ED.AC.UK
- registry.txt: Added integrity constraints on what task can be set
  for a builder. Added logging of build attempts

* Fri Dec 03 2010 15:41 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.8.4

* Fri Dec 03 2010 12:25 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Job.pm.in, lib/PkgForge/SourceUtils.pm.in:
  Added a new method to load a source package module given the
  type. This attempts to validate (and thus untaint) the value
  given before passing it to require()

* Thu Dec 02 2010 15:09 squinney@INF.ED.AC.UK
- lib/PkgForge/Utils.pm.in: Added a useful kinit method so that
  things like CGI scripts can get kerberos creds

* Wed Dec 01 2010 17:06 squinney@INF.ED.AC.UK
- notes.txt: updated afs notes

* Wed Dec 01 2010 13:08 squinney@INF.ED.AC.UK
- registry.txt: allowed db access for web frontend

* Wed Dec 01 2010 09:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in,
  lib/PkgForge/Daemon/Incoming.pm.in: Improved logging of daemons
  starting and stopping

* Wed Dec 01 2010 09:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in, lib/PkgForge/Builder/RPM.pm.in: Added
  support for an error_policy so that the builder can keep working
  on a job even if some packages failed first time due to missing
  build-deps

* Tue Nov 30 2010 17:36 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.8.3

* Tue Nov 30 2010 17:36 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Builder/RPM.pm.in: reworked
  submit_packages to use IPC::Run and capture the pkgsubmit logs
  for later examination

* Tue Nov 30 2010 16:40 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.8.2

* Tue Nov 30 2010 16:40 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Buildd.pm.in: Fixed typo

* Tue Nov 30 2010 16:39 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.8.1

* Tue Nov 30 2010 16:39 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in: Added logging of startup so
  it's easier to find in the log files

* Tue Nov 30 2010 16:39 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: job_resultsdir needed the job
  object passed in. Also replaced some calls to die() with
  log_and_die()

* Tue Nov 30 2010 16:37 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: moved logging in case it tampers
  with eval error message

* Tue Nov 30 2010 15:59 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.8.0

* Tue Nov 30 2010 15:59 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App/Buildd.pm.in: Override the execute
  method so it doesn't get handed all the stuff from App::Cmd

* Tue Nov 30 2010 15:58 squinney@INF.ED.AC.UK
- PkgForge.spec: Added PkgForge::Builder docs to the server package

* Tue Nov 30 2010 15:58 squinney@INF.ED.AC.UK
- notes.txt: Added AFS ACLs for the results directory

* Tue Nov 30 2010 15:57 squinney@INF.ED.AC.UK
- lib/PkgForge/SourceUtils.pm.in: Added a list_source_types method.
  Updated the API docs to be more complete

* Tue Nov 30 2010 15:57 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Now calls the builder object
  to do the work. Also added a lot more documentation of the API

* Tue Nov 30 2010 15:02 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in, lib/PkgForge/Builder/RPM.pm.in,
  t/01_builder.t: completed the basic RPM building infrastructure

* Tue Nov 30 2010 11:44 squinney@INF.ED.AC.UK
- PkgForge.spec: fixed build requires list

* Fri Nov 26 2010 10:39 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Finally got the setpgrp() working,
  turns out it has to be done before the call to setsid(). Improved
  the daemonisation process and remembered to cleanly exit the
  parent

* Fri Nov 26 2010 10:38 squinney@INF.ED.AC.UK
- lib/PkgForge/PidFile.pm.in, t/01_pidfile.t: Renamed the write()
  method as store() to avoid some confusion

* Thu Nov 25 2010 17:26 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Looks like cannot change process group

* Thu Nov 25 2010 17:10 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Improved the daemonize method. Added
  setting of the process group to see if that will be usefully for
  hunting down rogue mock processes

* Thu Nov 25 2010 16:00 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: stop method was getting confused when
  the daemon wasn't running

* Thu Nov 25 2010 13:57 squinney@INF.ED.AC.UK
- lib/PkgForge/SourceUtils.pm.in: hack around Moose enum being dumb

* Thu Nov 25 2010 13:52 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in,
  lib/PkgForge/SourceUtils.pm.in: Find and load the builder module
  dynamically

* Wed Nov 24 2010 19:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: Use PkgForge::Utils::remove_tree
  to empty the mock resultdir

* Wed Nov 24 2010 19:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: attribute is named 'architecture'
  not 'arch'

* Wed Nov 24 2010 19:00 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: fixed dumb thinko

* Wed Nov 24 2010 18:59 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: added more logging for when a
  build fails

* Wed Nov 24 2010 18:57 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Builder/RPM.pm.in,
  lib/PkgForge/Handler/Buildd.pm.in, t/00_load.t: various small bug
  fixes

* Wed Nov 24 2010 18:57 squinney@INF.ED.AC.UK
- PkgForge.spec: include the new Builder modules in the server
  package

* Wed Nov 24 2010 18:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Use the new builder module

* Wed Nov 24 2010 18:29 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in: reset any unfinished tasks at a
  better point in the process

* Wed Nov 24 2010 18:28 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder/RPM.pm.in: reworked so we could support
  tools other than mock

* Wed Nov 24 2010 18:26 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: The builder role now also requires a
  verify_environment() method

* Wed Nov 24 2010 18:12 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added a filter_packages() method to
  simplify grepping out particular types of packages

* Wed Nov 24 2010 18:11 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: get_builder is now a public method

* Wed Nov 24 2010 18:10 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder, lib/PkgForge/Builder/RPM.pm.in: Added RPM
  builder module, currently only supports using mock

* Wed Nov 24 2010 15:58 squinney@INF.ED.AC.UK
- PkgForge.spec, bin/mock_config_query: Added slightly hacky python
  script to query mock configurations

* Wed Nov 24 2010 14:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Builder.pm.in: Added basic Builder role which just
  requires the existence of a build() method

* Wed Nov 24 2010 13:49 squinney@INF.ED.AC.UK
- notes.txt: Updated ACLs

* Wed Nov 24 2010 13:49 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in: Added attempt to reset any
  unfinished tasks when the daemon is stopping

* Wed Nov 24 2010 13:48 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: Added a wrapper for the new
  reset_unfinished_tasks() method

* Wed Nov 24 2010 13:47 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Added reset_unfinished_tasks()
  method to put unfinished tasks back on the queue

* Wed Nov 24 2010 13:43 squinney@INF.ED.AC.UK
- PkgForge.spec, bin/pkgforge-buildd.in: Added a basic builder
  daemon tool

* Tue Nov 23 2010 20:27 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: next_new_task should return a task
  not a job

* Tue Nov 23 2010 20:26 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Buildd.pm.in,
  lib/PkgForge/Handler/Buildd.pm.in: refactored the buildd handler
  and daemon

* Tue Nov 23 2010 15:20 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.7.0

* Tue Nov 23 2010 15:04 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Split the execute method so
  it is in multiple smaller methods which are easier to understand,
  document and test

* Tue Nov 23 2010 14:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Added get_job_status() method to
  retrieve the name of the current status for a job

* Tue Nov 23 2010 14:54 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added scrub() method

* Tue Nov 23 2010 14:53 squinney@INF.ED.AC.UK
- lib/PkgForge/Queue/Entry.pm.in: Improved docs for scrub()

* Mon Nov 22 2010 15:25 squinney@INF.ED.AC.UK
- registry.txt: Added permissions for the pkgforge_incoming user to
  update the job status

* Mon Nov 22 2010 15:24 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Fixed calls to
  update_job_status()

* Mon Nov 22 2010 15:23 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Added missing calls to update()

* Mon Nov 22 2010 14:50 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.6.2

* Mon Nov 22 2010 14:50 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Incoming.pm.in: split apart the
  registering of jobs and tasks. Regularly update the job status to
  indicate what stage of the pipeline it has reached

* Mon Nov 22 2010 14:47 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Split register_job into two separate
  methods, one to register the job and the other to register tasks.
  Also added a method to simplify updating a job status.

* Mon Nov 22 2010 14:46 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: Added a new log_problem method to
  work around an issue with the logger eating the contents of eval
  errors

* Mon Nov 22 2010 13:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/JobStatus.pm.in: Added
  JobStatus class for job_status table

* Mon Nov 22 2010 13:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/Job.pm.in: fixed missing
  comma

* Mon Nov 22 2010 13:12 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  lib/PkgForge/Registry/Schema/Result/State.pm.in,
  lib/PkgForge/Registry/Schema/Result/Task.pm.in: Added job_status
  table support. Fixed up places which still referred to 'builds'
  instead of 'tasks'

* Mon Nov 22 2010 12:13 squinney@INF.ED.AC.UK
- registry.txt: Added new job_status table

* Fri Nov 19 2010 16:03 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: check for anything with same name as
  transferred job dir, not just directories

* Fri Nov 19 2010 15:51 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: added some debugging

* Fri Nov 19 2010 15:22 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Set the package basedir attribute when
  loading with new_from_metafile

* Fri Nov 19 2010 14:40 squinney@INF.ED.AC.UK
- PkgForge.spec, lcfg.yml, lib/PkgForge/Daemon.pm.in: Switched to
  storing PID files in /var/run/pkgforge so that necessary write
  permissions are available

* Fri Nov 19 2010 12:31 squinney@INF.ED.AC.UK
- PkgForge.spec: Added a couple of directories with the correct
  owner/group. Marked config files appropriately so they are not
  overwritten

* Fri Nov 19 2010 12:31 squinney@INF.ED.AC.UK
- bin/pkgforge-incoming.in: Added basic script for running the
  incoming handler as a daemon

* Thu Nov 18 2010 17:45 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in, lib/PkgForge/Daemon/Incoming.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in: Finished daemonising the
  incoming queue handler

* Thu Nov 18 2010 14:43 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Incoming.pm.in: added more logging

* Thu Nov 18 2010 14:43 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: Set stop timeout to something sensible
  and change code so we wait for each kill level separately

* Thu Nov 18 2010 14:29 squinney@INF.ED.AC.UK
- t/01_daemon.t: Fixed test now PkgForge::Daemon is not a role

* Thu Nov 18 2010 14:27 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in, lib/PkgForge/Daemon/Incoming.pm.in,
  t/00_load.t: Switched PkgForge::Daemon from a role to a class.
  Added some compile tests

* Thu Nov 18 2010 14:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Incoming.pm.in: Added Moose::Types

* Thu Nov 18 2010 14:14 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Incoming.pm.in: Fixed main loop

* Thu Nov 18 2010 14:12 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Incoming.pm.in: Trying out how to gracefully
  stop

* Thu Nov 18 2010 13:32 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: tweaked start method

* Thu Nov 18 2010 13:15 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon/Incoming.pm.in: Working on incoming
  processing daemon

* Wed Nov 17 2010 09:04 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.6.1

* Wed Nov 17 2010 09:04 squinney@INF.ED.AC.UK
- design.txt, notes.txt, registry-init.txt, registry-wipe.txt,
  registry.txt: Added more notes about how to setup the system

* Mon Nov 15 2010 14:58 squinney@INF.ED.AC.UK
- PkgForge.spec: Added group field to satisfy sl5 version of
  rpmbuild

* Mon Nov 15 2010 14:57 squinney@INF.ED.AC.UK
- PkgForge.spec: Split the package to allow easier client installs

* Mon Nov 15 2010 13:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Allow username and password to be
  undefined

* Wed Nov 10 2010 09:45 squinney@INF.ED.AC.UK
- registry-wipe.txt: Added sql script to completely wipe (drop all
  the tables) in the registry DB

* Wed Nov 10 2010 09:45 squinney@INF.ED.AC.UK
- PkgForge.spec, lib/PkgForge/Registry.pm.in,
  lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Task.pm.in, registry.txt:
  Added modification time (modtime) columns for builder, job and
  task tables. Use the new modtime to sort the build tasks queue.

* Wed Nov 10 2010 08:26 squinney@INF.ED.AC.UK
- registry.txt: Added db schema

* Mon Nov 08 2010 10:27 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.6.0

* Mon Nov 08 2010 10:26 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/App/Builder.pm.in,
  lib/PkgForge/App/Platform.pm.in: Improved the usage of the
  DBIx::Class code

* Mon Nov 08 2010 10:24 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema.pm.in,
  lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  lib/PkgForge/Registry/Schema/Result/State.pm.in,
  lib/PkgForge/Registry/Schema/Result/Task.pm.in: Added
  documentation

* Mon Nov 08 2010 09:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/App.pm.in: Added documentation

* Wed Nov 03 2010 12:24 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Registry.pm.in: Tweaked some bits of code
  to make perlcritic happier. Tidied some sections based on
  knowledge of the DB schema. Add documentation

* Wed Nov 03 2010 07:43 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Buildd.pm.in, lib/PkgForge/App/Incoming.pm.in,
  lib/PkgForge/App/InitServer.pm.in,
  lib/PkgForge/Daemon/Incoming.pm.in,
  lib/PkgForge/Handler/Initialise.pm.in,
  lib/PkgForge/Registry/Schema.pm.in,
  lib/PkgForge/Source/SRPM.pm.in, lib/PkgForge/Types.pm.in: Tidying

* Wed Nov 03 2010 07:42 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Split out building the DB DSN into a
  separate method

* Wed Nov 03 2010 07:42 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Builder.pm.in, lib/PkgForge/App/Platform.pm.in,
  lib/PkgForge/Handler/Buildd.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in,
  lib/PkgForge/Registry/App.pm.in,
  lib/PkgForge/Registry/Role.pm.in: Extracted registry attribute
  handling into a role. Standardised the access to the DBIx::Class
  schema object

* Tue Nov 02 2010 08:55 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in: made the Moose immutable

* Tue Nov 02 2010 07:56 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Builder.pm.in,
  lib/PkgForge/Handler/Buildd.pm.in, lib/PkgForge/Registry.pm.in:
  added for modules

* Tue Nov 02 2010 07:49 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Fixed syntax error

* Tue Nov 02 2010 07:48 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Some code tidying

* Tue Nov 02 2010 07:41 squinney@INF.ED.AC.UK
- t/00_load.t: Added compile tests for a few more modules

* Mon Nov 01 2010 12:01 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Buildd.pm.in: completed the basic
  generic framework for running a build job

* Mon Nov 01 2010 12:00 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Added a method for finding the next
  task for a builder. Also added methods for finalising and failing
  tasks

* Mon Nov 01 2010 11:58 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Separated out the
  environment checks which must be done at startup time into a
  preflight() method

* Mon Nov 01 2010 11:57 squinney@INF.ED.AC.UK
- t/00_load.t: check more modules compile

* Mon Nov 01 2010 10:21 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Buildd.pm.in: Added a very basic buildd command
  line app

* Mon Nov 01 2010 10:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added a -B flag for the bucket (same as
  pkgsubmit). Added a count_packages method

* Mon Nov 01 2010 10:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  lib/PkgForge/Registry/Schema/Result/State.pm.in: Updated so that
  references to 'build' are now 'task'. Also removed a load of
  unnecessary DBIx::Class::Schema::Loader boilerplate

* Mon Nov 01 2010 10:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema/Result/Build.pm.in,
  lib/PkgForge/Registry/Schema/Result/Task.pm.in: 'Build' table is
  now 'Task'

* Mon Nov 01 2010 08:24 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Buildd.pm.in,
  lib/PkgForge/Handler/Builder.pm: renamed to avoid confusion with
  the registry builder class when running as a command line app

* Thu Oct 28 2010 16:00 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Builder.pm.in: Added an app for managing the
  builders info in the registry

* Thu Oct 28 2010 16:00 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Builder.pm: Added the beginnings of a
  handler for process the accepted build jobs

* Thu Oct 28 2010 13:24 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Handler/Incoming.pm.in: some logging
  tweaks

* Wed Oct 27 2010 18:43 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: tweak the job registration
  process

* Wed Oct 27 2010 16:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Call the correct method to
  get the queue entries list. Also added some debugging.

* Wed Oct 27 2010 15:46 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Incoming.pm.in: Added incoming queue processor
  app

* Wed Oct 27 2010 15:33 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.5.0

* Wed Oct 27 2010 15:24 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: fixed another wrong accessor name

* Wed Oct 27 2010 15:23 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: fixed wrong accessor name

* Wed Oct 27 2010 15:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: removed troublesome semicolon

* Wed Oct 27 2010 15:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: removed some unnecessary error
  handling which caused problems

* Wed Oct 27 2010 15:18 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: fixed typos

* Wed Oct 27 2010 15:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: use the new register_job
  method to add jobs to the DB

* Wed Oct 27 2010 15:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry.pm.in: Added first pass at a register_job
  method

* Wed Oct 27 2010 15:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added new process_build_targets method
  for convenience

* Wed Oct 27 2010 13:52 squinney@INF.ED.AC.UK
- PkgForge.spec: Added requirement on DBIx::Cklass as the autoreq
  script does not notice it

* Wed Oct 27 2010 13:50 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Platform.pm.in: Added proper error handling

* Wed Oct 27 2010 13:40 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: PkgForgeRegistry type no longer
  required

* Wed Oct 27 2010 13:39 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Schema.pm,
  lib/PkgForge/Registry/Schema.pm.in,
  lib/PkgForge/Registry/Schema/Result/Build.pm,
  lib/PkgForge/Registry/Schema/Result/Build.pm.in,
  lib/PkgForge/Registry/Schema/Result/Builder.pm,
  lib/PkgForge/Registry/Schema/Result/Builder.pm.in,
  lib/PkgForge/Registry/Schema/Result/Job.pm,
  lib/PkgForge/Registry/Schema/Result/Job.pm.in,
  lib/PkgForge/Registry/Schema/Result/Platform.pm,
  lib/PkgForge/Registry/Schema/Result/Platform.pm.in,
  lib/PkgForge/Registry/Schema/Result/State.pm,
  lib/PkgForge/Registry/Schema/Result/State.pm.in: renamed perl
  modules to have correct suffixes

* Wed Oct 27 2010 13:36 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Platform.pm.in, lib/PkgForge/Registry.pm.in,
  lib/PkgForge/Registry/App.pm.in,
  lib/PkgForge/Registry/Connection.pm.in,
  lib/PkgForge/Registry/Platform.pm.in,
  lib/PkgForge/Registry/Schema, lib/PkgForge/Registry/Schema.pm,
  lib/PkgForge/Registry/Schema/Result,
  lib/PkgForge/Registry/Schema/Result/Build.pm,
  lib/PkgForge/Registry/Schema/Result/Builder.pm,
  lib/PkgForge/Registry/Schema/Result/Job.pm,
  lib/PkgForge/Registry/Schema/Result/Platform.pm,
  lib/PkgForge/Registry/Schema/Result/State.pm,
  lib/PkgForge/Registry/Table.pm.in: Reworked the registry to use
  DBIx::Class

* Wed Oct 27 2010 08:44 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.4.0

* Wed Oct 27 2010 08:44 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Registry.pm.in: removed old registry
  module, now split into multiple parts for ease of usage

* Wed Oct 27 2010 08:43 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Platform.pm.in: Moose class which provides a
  commandline app for manipulating the build platform register

* Wed Oct 27 2010 08:42 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/App.pm.in: Moose role to hold the common
  parts of a commandline registry app

* Wed Oct 27 2010 08:42 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Platform.pm.in: Moose class to represent
  the platform table in the registry DB. Provides a number of
  wrappers functions to do common operations

* Wed Oct 27 2010 08:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Table.pm.in: Moose role to represent a
  table in the registry DB

* Wed Oct 27 2010 08:40 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: added moose type for the registry
  connection so we can coerce from a filename to load a new
  connection object

* Wed Oct 27 2010 08:40 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry/Connection.pm.in: Added support for a
  configuration file for storing the DB parameters

* Wed Oct 27 2010 08:40 squinney@INF.ED.AC.UK
- lib/PkgForge/Registry: New PkgForge::Registry namespace

* Mon Sep 13 2010 08:47 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.3.0

* Wed Sep 01 2010 15:38 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: fixed log_dispatch_conf spec so that
  it will take either a file name or a hash-ref

* Wed Sep 01 2010 14:51 squinney@INF.ED.AC.UK
- Build.PL.in, PkgForge.spec, conf/log-default.cfg,
  conf/log-incoming.cfg, lcfg.yml,
  lib/PkgForge/App/InitServer.pm.in, lib/PkgForge/Handler.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in,
  lib/PkgForge/Handler/Initialise.pm.in, t/02_incoming.t: Reworked
  the logging system so that it uses configuration files

* Wed Sep 01 2010 13:55 squinney@INF.ED.AC.UK
- conf: Added dir to hold config files

* Wed Sep 01 2010 11:47 squinney@INF.ED.AC.UK
- bin/pkgforge.in, lib/PkgForge/App.pm.in,
  lib/PkgForge/App/InitServer.pm.in,
  lib/PkgForge/Daemon/Incoming.pm.in, lib/PkgForge/Registry.pm.in:
  Set svn:keywords

* Wed Sep 01 2010 11:45 squinney@INF.ED.AC.UK
- t/00_load.t: Added compile tests for more modules

* Wed Sep 01 2010 11:45 squinney@INF.ED.AC.UK
- lib/PkgForge/App/InitServer.pm.in: added an command-line app
  wrapper for the server initialisation handler

* Wed Sep 01 2010 11:37 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Initialise.pm.in: Ensure we have a directory
  for logs before anything else (otherwise we cannot log
  success/fail/anything). Improved error checking on directory
  creation

* Wed Sep 01 2010 11:36 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: Marked some more attributes as not
  being command line options. Altered log format to include a
  timestamp. Altered docs to reflect that this is now a class not a
  role

* Tue Aug 31 2010 17:44 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Fixed access of package list

* Tue Aug 31 2010 17:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: Fixed coercion of email address list
  from string

* Tue Aug 31 2010 16:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in, lib/PkgForge/Types.pm.in: Allow the
  report attribute to be a string or list of strings

* Tue Aug 31 2010 16:13 squinney@INF.ED.AC.UK
- bin/pkgforge.in, lib/PkgForge/App.pm.in,
  lib/PkgForge/App/Submit.pm.in: More improvements to the
  documentation of the new pkgforge app (and command modules)

* Tue Aug 31 2010 15:48 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Documentation updates

* Tue Aug 31 2010 15:44 squinney@INF.ED.AC.UK
- bin/pkgforge-submit, lib/PkgForge/Submit,
  lib/PkgForge/Submit.pm.in: Removed old Submit class and tool now
  it is merged into the standard pkgforge app

* Tue Aug 31 2010 15:43 squinney@INF.ED.AC.UK
- lcfg.yml, lib/PkgForge/Daemon,
  lib/PkgForge/Daemon/Incoming.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in, lib/PkgForge/Registry.pm.in:
  Fixed missing '+' in override of configfile attribute

* Tue Aug 31 2010 15:41 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in, lib/PkgForge/Handler/Incoming.pm.in,
  lib/PkgForge/Handler/Initialise.pm.in: Switch handler from a role
  to a real class to avoid problems with needing to override
  attributes in previously applied roles

* Tue Aug 31 2010 15:34 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in, lib/PkgForge/ConfigFile.pm.in,
  lib/PkgForge/Handler.pm.in: To work with MooseX::App::Cmd the
  configfile attribute must be done with a 'default' not a
  'builder'

* Tue Aug 31 2010 15:08 squinney@INF.ED.AC.UK
- t/00_load.t: Test the new Submit module

* Tue Aug 31 2010 15:04 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in, lib/PkgForge/ConfigFile.pm.in:
  Added an abstract for the Submit method. Added a documentation
  string for the configfile attribute. Both improve the help output
  from the pkgforge command

* Tue Aug 31 2010 14:51 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Submit.pm.in: Copy the Submit module and rework
  to use the new command line app infrastructure

* Tue Aug 31 2010 14:50 squinney@INF.ED.AC.UK
- bin/pkgforge.in, lib/PkgForge/App.pm.in: Added a new
  infrastructure for command line apps

* Tue Aug 31 2010 14:50 squinney@INF.ED.AC.UK
- lib/PkgForge/App/Cmd: removed a directory we don't need

* Tue Aug 31 2010 14:27 squinney@INF.ED.AC.UK
- lib/PkgForge/App, lib/PkgForge/App/Cmd: Added App::Cmd hierarchy

* Tue Aug 31 2010 08:49 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: tweaked the formatting of the some
  examples in the docs

* Thu Aug 26 2010 08:51 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in, lib/PkgForge/Types.pm.in: Improved
  Types docs

* Thu Aug 26 2010 08:34 squinney@INF.ED.AC.UK
- bin/pkgforge-submit, lib/PkgForge/ConfigFile.pm.in,
  lib/PkgForge/Daemon.pm.in, lib/PkgForge/Handler.pm.in,
  lib/PkgForge/Handler/Incoming.pm.in,
  lib/PkgForge/Handler/Initialise.pm.in, lib/PkgForge/Job.pm.in,
  lib/PkgForge/Meta/Attribute/Trait/Directory.pm.in,
  lib/PkgForge/Meta/Attribute/Trait/Serialise.pm.in,
  lib/PkgForge/PidFile.pm.in, lib/PkgForge/Queue.pm.in,
  lib/PkgForge/Queue/Entry.pm.in, lib/PkgForge/Source.pm.in,
  lib/PkgForge/Source/SRPM.pm.in, lib/PkgForge/SourceUtils.pm.in,
  lib/PkgForge/Submit.pm.in, lib/PkgForge/Types.pm.in,
  lib/PkgForge/Utils.pm.in: Properly set svn keywords

* Wed Aug 25 2010 15:35 squinney@INF.ED.AC.UK
- lib/PkgForge/Queue.pm.in, lib/PkgForge/SourceUtils.pm.in,
  lib/PkgForge/Types.pm.in, lib/PkgForge/Utils.pm.in: perltidy

* Wed Aug 25 2010 14:20 squinney@INF.ED.AC.UK
- t/00_load.t, t/01_configfile.t, t/01_daemon.t, t/01_queue.t,
  t/02_incoming.t: Added tests for new classes

* Wed Aug 25 2010 14:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Incoming.pm.in: Added handler for the
  incoming queue

* Wed Aug 25 2010 14:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler/Initialise.pm.in: Added initialisation
  handler

* Wed Aug 25 2010 14:19 squinney@INF.ED.AC.UK
- lib/PkgForge/Meta/Attribute/Trait/Directory.pm.in: Added
  PkgForge::Directory trait to allow tagging of directories which
  should be created and maintained for the daemons to work

* Wed Aug 25 2010 14:18 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: use the new default_configfile
  method. Added a default_logfile method for settig the logfile
  path to make it easier to override from a class implementing this
  role

* Wed Aug 25 2010 14:17 squinney@INF.ED.AC.UK
- lib/PkgForge/Queue.pm.in: Added optional logger handling. Added
  erase_cruft method. Documented sorted_entries method

* Wed Aug 25 2010 14:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Daemon.pm.in: New Daemon role

* Wed Aug 25 2010 14:16 squinney@INF.ED.AC.UK
- lib/PkgForge/Submit.pm.in: Use the new default_configfile method
  with the PkgForge::ConfigFile role

* Wed Aug 25 2010 14:15 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: Reworked configfile attribute so
  that classes using this role can just implement a
  'default_configfile' method

* Wed Aug 25 2010 14:13 squinney@INF.ED.AC.UK
- lib/PkgForge/Types.pm.in: Added GUID and Octal types

* Wed Aug 25 2010 11:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: Improved the Handler role, added docs

* Wed Aug 25 2010 11:20 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler, lib/PkgForge/Handler/Incoming.pm.in:
  Improved the Handler role, added docs

* Mon Aug 23 2010 15:42 squinney@INF.ED.AC.UK
- lib/PkgForge/PidFile.pm.in: Added more docs.

* Mon Aug 23 2010 14:37 squinney@INF.ED.AC.UK
- t/01_pidfile.t: more pidfile tests

* Mon Aug 23 2010 14:37 squinney@INF.ED.AC.UK
- lib/PkgForge/PidFile.pm.in: Simplified the is_running test

* Mon Aug 23 2010 13:59 squinney@INF.ED.AC.UK
- lib/PkgForge/PidFile.pm.in, t/00_load.t, t/01_pidfile.t: Added
  class for managing a pid file. Also added tests

* Fri Aug 20 2010 17:51 squinney@INF.ED.AC.UK
- t/bar.yml, t/foo.yml: added some test content

* Fri Aug 20 2010 15:43 squinney@INF.ED.AC.UK
- t/01_configfile.t, t/bar.yml, t/foo.yml: Added basic tests for
  the ConfigFile role

* Fri Aug 20 2010 15:26 squinney@INF.ED.AC.UK
- t/00_load.t: forgot to bump test count

* Fri Aug 20 2010 15:24 squinney@INF.ED.AC.UK
- t/00_load.t, t/01_sourceutils.t: Added tests for
  PkgForge::SourceUtils

* Fri Aug 20 2010 11:29 squinney@INF.ED.AC.UK
- lib/PkgForge/Source/SRPM.pm.in: Test of the validate method
  showed that the RPM2 open_package method dies when presented with
  a file which is not really an RPM. Fixed by wrapping in an eval
  and catching

* Fri Aug 20 2010 11:27 squinney@INF.ED.AC.UK
- t/01_source.t: updated test count and fixed validation regexp

* Fri Aug 20 2010 11:25 squinney@INF.ED.AC.UK
- t/01_source.t: added more tests for PkgForge::Source::SRPM

* Fri Aug 20 2010 11:14 squinney@INF.ED.AC.UK
- t/01_source.t: Added tests for PkgForge::Source::can_handle()

* Fri Aug 20 2010 11:04 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: Added docs

* Thu Aug 19 2010 14:54 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: needed to 'use English'

* Thu Aug 19 2010 14:52 squinney@INF.ED.AC.UK
- lib/PkgForge/Submit.pm.in: fixed typo

* Thu Aug 19 2010 14:46 squinney@INF.ED.AC.UK
- bin/pkgforge-submit, lib/PkgForge/Submit.pm.in: Added support for
  configuration files for the job submission tools

* Thu Aug 19 2010 14:28 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in: Handle the file argument being a
  code-ref

* Thu Aug 19 2010 14:27 squinney@INF.ED.AC.UK
- lib/PkgForge/Handler.pm.in: fixed PkgForge::ConfigFile role usage

* Thu Aug 19 2010 14:27 squinney@INF.ED.AC.UK
- Build.PL.in: added Moose role deps

* Thu Aug 19 2010 14:26 squinney@INF.ED.AC.UK
- PkgForge.spec: Added dependencies on perl modules which are only
  used as Moose roles so don't get picked up by the automated
  perl-dep finding script

* Wed Aug 18 2010 14:06 squinney@INF.ED.AC.UK
- lib/PkgForge/Source.pm.in: Switch from lazy and default to
  specifying a builder method for the sha1sum attribute

* Wed Aug 18 2010 14:02 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.2.2

* Wed Aug 18 2010 14:01 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Added docs for new_from_metafile and
  save_metafile about attributes with the PkgForge::Serialise trait

* Wed Aug 18 2010 14:01 squinney@INF.ED.AC.UK
- MANIFEST: fixed MANIFEST

* Wed Aug 18 2010 13:56 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Only (de)serialise package attributes
  which have the PkgForge::Serialise trait

* Wed Aug 18 2010 13:55 squinney@INF.ED.AC.UK
- lib/PkgForge/Source.pm.in: Marked source package attributes which
  require serialisation

* Wed Aug 18 2010 13:34 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: A couple of tweaks so that the dump and
  restore hashes are keyed on the right thing

* Wed Aug 18 2010 13:28 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Use the new PkgForge::Serialise attribute
  to signify which Job attributes should be saved/restored to/from
  metafiles

* Wed Aug 18 2010 13:26 squinney@INF.ED.AC.UK
- lib/PkgForge/Meta/Attribute/Trait/Serialise.pm.in: removed
  unnecessary attribute

* Wed Aug 18 2010 11:30 squinney@INF.ED.AC.UK
- lib/PkgForge/Job.pm.in: Attempt to use new PkgForge::Serialise
  attribute

* Wed Aug 18 2010 11:24 squinney@INF.ED.AC.UK
- lib/PkgForge/Meta, lib/PkgForge/Meta/Attribute,
  lib/PkgForge/Meta/Attribute/Trait,
  lib/PkgForge/Meta/Attribute/Trait/Serialise.pm.in: Added Moose
  trait role that can be used to indicate that particular PkgForge
  attributes should be serialised

* Wed Aug 18 2010 11:16 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.2.1

* Wed Aug 18 2010 11:16 squinney@INF.ED.AC.UK
- MANIFEST, META.yml, Makefile.PL: updated meta files

* Wed Aug 18 2010 11:13 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: PkgForge release: 0.2.0

* Wed Aug 18 2010 11:10 squinney@INF.ED.AC.UK
- PkgForge.spec: fixed perl module path

* Wed Aug 18 2010 11:09 squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-PkgForge.spec, PkgForge.spec,
  bin/pkgforge-submit, lcfg.yml: LCFG::PkgForge to PkgForge
  renaming

* Wed Aug 18 2010 11:09 squinney@INF.ED.AC.UK
- t/00_load.t, t/01_queue.t, t/01_source.t: LCFG::PkgForge to
  PkgForge renaming

* Wed Aug 18 2010 11:08 squinney@INF.ED.AC.UK
- lib/PkgForge/ConfigFile.pm.in, lib/PkgForge/Handler.pm.in,
  lib/PkgForge/Job.pm.in, lib/PkgForge/Queue.pm.in,
  lib/PkgForge/Queue/Entry.pm.in, lib/PkgForge/Source.pm.in,
  lib/PkgForge/Source/SRPM.pm.in, lib/PkgForge/SourceUtils.pm.in,
  lib/PkgForge/Submit.pm.in, lib/PkgForge/Types.pm.in,
  lib/PkgForge/Utils.pm.in: More renaming

* Wed Aug 18 2010 11:06 squinney@INF.ED.AC.UK
- lib/LCFG, lib/PkgForge: Moved libs from LCFG/PkgForge to PkgForge
  directory

* Wed Aug 18 2010 11:02 squinney@INF.ED.AC.UK
- ., lcfg.yml: Renaming LCFG-PkgForge as PkgForge

* Wed Aug 18 2010 09:50 squinney@INF.ED.AC.UK
- Using the can_handle method now provided as part of the
  LCFG::PkgForge::Source role

* Wed Aug 18 2010 09:49 squinney@INF.ED.AC.UK
- Added a default can_handle() method. Improved the docs a bit

* Wed Aug 18 2010 09:27 squinney@INF.ED.AC.UK
- Added the build requirements. Included man1 files

* Wed Aug 18 2010 09:03 squinney@INF.ED.AC.UK
- Updated the list of dependencies

* Wed Aug 18 2010 08:57 squinney@INF.ED.AC.UK
- use the SOURCE_PACKAGE_BASE rather than hardwiring the name into
  the code

* Wed Aug 18 2010 08:56 squinney@INF.ED.AC.UK
- Make the SOURCE_PACKAGE_BASE exportable if requested

* Wed Aug 18 2010 08:55 squinney@INF.ED.AC.UK
- explicitly check that each package submitted is a file

* Wed Aug 18 2010 08:02 squinney@INF.ED.AC.UK
- Set svn keywords

* Mon May 03 2010 10:41 squinney@INF.ED.AC.UK
- Documented pkgforge-submit

* Mon May 03 2010 09:55 squinney@INF.ED.AC.UK
- Tweaked the docs

* Mon May 03 2010 09:49 squinney@INF.ED.AC.UK
- Fixed call to findsubmod, the sort needed to be done separately
  for some reason

* Mon May 03 2010 09:37 squinney@INF.ED.AC.UK
- Added a new module to handle looking up the handler for a source
  package. This makes the Submit code generic so it can handle any
  source types. The Source package modules are now required to
  implement a class method, named 'can_handle', which returns
  true/false based on whether it can handle a particular file.

* Mon May 03 2010 08:57 squinney@INF.ED.AC.UK
- Turns out that RPM4 is no longer maintained so switch to using
  RPM2

* Mon Mar 08 2010 14:22 squinney@INF.ED.AC.UK
- Added handler base class

* Mon Mar 08 2010 14:22 squinney@INF.ED.AC.UK
- Do not need Data::Structure::Util

* Mon Mar 08 2010 14:21 squinney@INF.ED.AC.UK
- Added role to represent configuration file

* Mon Mar 08 2010 11:56 squinney@INF.ED.AC.UK
- Apparently overriding a method which comes from the Array trait
  is not a good idea. Replaced the add_packages() override with a
  new method named include_packages()

* Mon Mar 08 2010 10:58 squinney@INF.ED.AC.UK
- Added override for add_packages which takes a list of file names.
  Also completed the module docs

* Fri Mar 05 2010 17:20 squinney@INF.ED.AC.UK
- LCFG-PkgForge release: 0.1.0

* Fri Mar 05 2010 17:20 squinney@INF.ED.AC.UK
- added a, basically empty, test package

* Fri Mar 05 2010 17:08 squinney@INF.ED.AC.UK
- submit not transfer

* Fri Mar 05 2010 17:08 squinney@INF.ED.AC.UK
- small tweak

* Fri Mar 05 2010 16:58 squinney@INF.ED.AC.UK
- Need to catch exceptions for transfer method

* Fri Mar 05 2010 16:51 squinney@INF.ED.AC.UK
- another attempt at having an ArrayRef which takes a role

* Fri Mar 05 2010 15:52 squinney@INF.ED.AC.UK
- PkgForge not PkgBuild

* Fri Mar 05 2010 15:48 squinney@INF.ED.AC.UK
- More fixes

* Fri Mar 05 2010 15:47 squinney@INF.ED.AC.UK
- Source not Package

* Fri Mar 05 2010 15:45 squinney@INF.ED.AC.UK
- fixed missing (

* Fri Mar 05 2010 15:45 squinney@INF.ED.AC.UK
- Added package handling

* Fri Mar 05 2010 15:44 squinney@INF.ED.AC.UK
- blocked another couple of options from getopt

* Fri Mar 05 2010 15:17 squinney@INF.ED.AC.UK
- fixes

* Fri Mar 05 2010 15:16 squinney@INF.ED.AC.UK
- fixed typo

* Fri Mar 05 2010 15:14 squinney@INF.ED.AC.UK
- updated plan

* Fri Mar 05 2010 15:14 squinney@INF.ED.AC.UK
- added tests for Source

* Fri Mar 05 2010 15:14 squinney@INF.ED.AC.UK
- Made sha1sum and file accessors read-only

* Fri Mar 05 2010 14:52 squinney@INF.ED.AC.UK
- Only load RPM4 when needed for validation

* Fri Mar 05 2010 14:44 squinney@INF.ED.AC.UK
- Updated plan

* Fri Mar 05 2010 14:38 squinney@INF.ED.AC.UK
- fixed tests, should use is_deeply not eq_hash

* Fri Mar 05 2010 14:28 squinney@INF.ED.AC.UK
- added more tests of the queue

* Fri Mar 05 2010 14:21 squinney@INF.ED.AC.UK
- fixed issue with sorting the queue entries

* Fri Mar 05 2010 13:58 squinney@INF.ED.AC.UK
- Wrong method name for the cruft clearer

* Fri Mar 05 2010 13:56 squinney@INF.ED.AC.UK
- Allow a single argument fo the queue directory name

* Fri Mar 05 2010 13:52 squinney@INF.ED.AC.UK
- started tests for queue object

* Fri Mar 05 2010 13:39 squinney@INF.ED.AC.UK
- Need to include pkgforge-submit script

* Fri Mar 05 2010 13:38 squinney@INF.ED.AC.UK
- Properly added load test for LCFG::PkgForge::Submit

* Fri Mar 05 2010 13:38 squinney@INF.ED.AC.UK
- Added load test for LCFG::PkgForge::Submit

* Fri Mar 05 2010 13:37 squinney@INF.ED.AC.UK
- Added basic script to do pkgforge submissions.

* Fri Mar 05 2010 13:31 squinney@INF.ED.AC.UK
- Added support for submitting build jobs

* Fri Mar 05 2010 13:19 squinney@INF.ED.AC.UK
- Added Queue and Queue::Entry classes

* Fri Mar 05 2010 13:18 squinney@INF.ED.AC.UK
- tweaked pod

* Fri Mar 05 2010 11:21 squinney@INF.ED.AC.UK
- Documentation updates

* Fri Mar 05 2010 09:06 squinney@INF.ED.AC.UK
- Fixed definition of source package list so that it can take any
  items which implement the Source role

* Thu Mar 04 2010 21:58 squinney@INF.ED.AC.UK
- missing a module

* Thu Mar 04 2010 21:58 squinney@INF.ED.AC.UK
- Updated for name change and some tweaks

* Thu Mar 04 2010 21:57 squinney@INF.ED.AC.UK
- updated

* Thu Mar 04 2010 21:57 squinney@INF.ED.AC.UK
- MooseX::Types needs to be at least 0.21

* Thu Mar 04 2010 21:54 squinney@INF.ED.AC.UK
- Fixed tests

* Thu Mar 04 2010 16:15 squinney@INF.ED.AC.UK
- Added basic test to load modules

* Thu Mar 04 2010 13:46 squinney@INF.ED.AC.UK
- started on Job class

* Thu Mar 04 2010 13:46 squinney@INF.ED.AC.UK
- added UserName and EmailAddress types

* Thu Mar 04 2010 12:31 squinney@INF.ED.AC.UK
- Added general utilities module

* Thu Mar 04 2010 12:13 squinney@INF.ED.AC.UK
- Added various meta files for Module::Build

* Thu Mar 04 2010 12:08 squinney@INF.ED.AC.UK
- Actually run the build script

* Thu Mar 04 2010 12:08 squinney@INF.ED.AC.UK
- switched from RPM2 to RPM4 so we only use one rpm module in the
  whole code base

* Thu Mar 04 2010 10:42 squinney@INF.ED.AC.UK
- renamed specfile to something more sensible

* Thu Mar 04 2010 10:41 squinney@INF.ED.AC.UK
- Added classes representing a source package

* Thu Mar 04 2010 10:40 squinney@INF.ED.AC.UK
- Translate templates before packing and removing any input files
  from the final product

* Thu Mar 04 2010 08:59 squinney@INF.ED.AC.UK
- Created with lcfg-skeleton


