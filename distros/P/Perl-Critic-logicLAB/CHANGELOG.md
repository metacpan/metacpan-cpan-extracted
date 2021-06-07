# Change log for Perl::Critic::logicLAB

## 0.11 2021-06-01, feature release, update not required

- Added [Perl::Critic::Policy::InputOutput::ProhibitHighPrecedentLogicalOperatorErrorHandling](https://metacpan.org/release/Perl-Critic-Policy-InputOutput-ProhibitHighPrecedentLogicalOperatorErrorHandling)

- Improvements to [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) config, only [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) supported via [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) now. [Module::Build](https://metacpan.org/pod/Module::Build) support having been removed

- See [the article by Neil Bowers](https://neilb.org/2015/05/18/two-build-files-considered-harmful.html) (NEILB) on the topic.

- Thanks to Karen Etheridge (ETHER) for information and link to the mentioned article

- Removed test of Changes file, since the change log has been ported to Markdown

## 0.10 2021-05-22, feature release, update not required

- Added [Perl::Critic::Policy::RegularExpressions::RequireDefault](https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireDefault)

- Migrated to Dist::Zilla as build system

## 0.09 2014-08-08, feature release, update not required

- Added [Perl::Critic::Policy::logicLAB::ModuleBlacklist](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::ModuleBlacklist)

- Added [Perl::Critic::Policy::logicLAB::RequireParamsValidate](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::RequireParamsValidate)
  This was wrongfully communicated as being a part of the 0.08 release
  which was wrong, so it is included in the following release instead

## 0.08 2014-02-27, feature release, update not required

- Added [Perl::Critic::Policy::logicLAB::RequirePackageNamePattern](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::RequirePackageNamePattern)

- Added warnings to make [CPANTS](https://cpants.cpanauthors.org/) happy

- Specified perl version to be 5.6.0

- Added `changes.t` automatic assertion of the integrity of the Changes file

## 0.07 2013-08-01, maintenance release, update recommended

- Fixing build system, 0.06 build system was broken

## 0.06 2013-07-27, maintenance release, update not required

- Adding a Changes file as part of my Questhub quest adhering to the standard
  described in: [CPAN::Changes::Spec](https://metacpan.org/module/CPAN::Changes::Spec)

- Added creation of traditional `Makefile.PL` to `Build.PL`

## 0.05 2011-05-03, feature release, update not required

- Added new policy: [Perl::Critic::Policy::logicLAB::RequireSheBang](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::RequireSheBang)

## 0.04 2011-04-16, feature release, update not required

- Added new policy: [Perl::Critic::Policy::logicLAB::ProhibitShellDispatch](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::ProhibitShellDispatch)

## 0.03 2010-11-24, Update recommended

- Implemented custom build system

## 0.02 2010-09-14 maintenance release, update not required

- Missing tests

## 0.01 2010-09-07, initial release

- Including: [Perl::Critic::Policy::logicLAB::ProhibitUseLib](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::ProhibitUseLib)

- Including: [Perl::Critic::Policy::logicLAB::RequireVersionFormat](https://metacpan.org/pod/Perl::Critic::Policy::logicLAB::RequireVersionFormat)

- Wrote documentation

- Implementation of `Build.PL` using the [Task](https://metacpan.org/pod/Task) scheme
