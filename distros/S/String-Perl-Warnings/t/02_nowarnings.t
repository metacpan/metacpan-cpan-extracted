use strict;
use warnings;
use Test::More tests => 627;
use_ok('String::Perl::Warnings', qw(not_warning));

while(<DATA>){
  chomp;
  ok( not_warning($_), "Not Warning: '$_'" );
}

exit 0;
__END__
[MSG] [Mon Feb  9 20:02:28 2009] Checksum matches for 'Module-Build-0.31_03.tar.gz'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/Build.PL'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/Makefile.PL'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/install.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/metadata2.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/test_file_exts.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/add_property.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/mbyaml.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/pod_parser.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/xs.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/tilde.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/basic.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/notes.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/extend.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/script_dist.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/metadata.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/compat/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/compat/exit.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/ppm.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/bundled/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/bundled/Tie/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/bundled/Tie/CPHash.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/par.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/moduleinfo.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/lib/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/lib/MBTest.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/lib/DistGen.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/ext.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/compat.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/runthrough.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/new_from_context.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/versions.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/destinations.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/use_tap_harness.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/test_types.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/files.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/parents.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/test_type.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/help.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/manifypods.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/t/signature.t'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/MANIFEST'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/scripts/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/scripts/bundle.pl'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/scripts/config_data'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/LICENSE'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/INSTALL'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/README'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Config.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/API.pod'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Compat.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Authoring.pod'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Version.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Notes.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Dumper.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/YAML.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/PPMMaker.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Cookbook.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/PodParser.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/ModuleInfo.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Base.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/darwin.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/Unix.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/Amiga.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/EBCDIC.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/Windows.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/aix.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/VOS.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/MacOS.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/VMS.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/Default.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/MPEiX.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/cygwin.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/os2.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/lib/Module/Build/Platform/RiscOS.pm'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/contrib/'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/contrib/bash_completion.module-build'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/Changes'
[MSG] [Mon Feb  9 20:02:38 2009] Extracted 'Module-Build-0.31_03/META.yml'
[MSG] [Mon Feb  9 20:02:39 2009] Extracted 'Module::Build' to '/home/chris/dev/perls/rel/conf/perl-5.10.0/.cpanplus/5.10.0/build/Module-Build-0.31_03'
[MSG] [Mon Feb  9 20:02:44 2009]  * Optional prerequisite Module::Signature is not installed
 * Optional prerequisite Pod::Readme is not installed

ERRORS/WARNINGS FOUND IN PREREQUISITES.  You may wish to install the versions
of the modules indicated above before proceeding with this installation

    - YAML is not installed

Checking whether your kit is complete...
Looks good

Checking prerequisites...
Checking features:
  manpage_support....enabled
  YAML_support.......disabled
  C_support..........enabled
  HTML_support.......enabled
Creating new 'Build' script for 'Module-Build' version '0.31_03'

[MSG] [Mon Feb  9 20:02:44 2009] DEFAULT 'filter_prereqs' HANDLER RETURNING 'sub return value'
[MSG] [Mon Feb  9 20:02:53 2009] Copying lib/Module/Build/Version.pm -> blib/lib/Module/Build/Version.pm
Copying lib/Module/Build/Platform/darwin.pm -> blib/lib/Module/Build/Platform/darwin.pm
Copying lib/Module/Build/Platform/MacOS.pm -> blib/lib/Module/Build/Platform/MacOS.pm
Copying lib/Module/Build/Dumper.pm -> blib/lib/Module/Build/Dumper.pm
Copying lib/Module/Build/Notes.pm -> blib/lib/Module/Build/Notes.pm
Copying lib/Module/Build/Compat.pm -> blib/lib/Module/Build/Compat.pm
Copying lib/Module/Build/Platform/RiscOS.pm -> blib/lib/Module/Build/Platform/RiscOS.pm
Copying lib/Module/Build/PodParser.pm -> blib/lib/Module/Build/PodParser.pm
Copying lib/Module/Build/Platform/VOS.pm -> blib/lib/Module/Build/Platform/VOS.pm
Copying lib/Module/Build/Platform/Windows.pm -> blib/lib/Module/Build/Platform/Windows.pm
Copying lib/Module/Build/Platform/Unix.pm -> blib/lib/Module/Build/Platform/Unix.pm
Copying lib/Module/Build/ModuleInfo.pm -> blib/lib/Module/Build/ModuleInfo.pm
Copying lib/Module/Build/Platform/Amiga.pm -> blib/lib/Module/Build/Platform/Amiga.pm
Copying lib/Module/Build/Config.pm -> blib/lib/Module/Build/Config.pm
Copying lib/Module/Build/Platform/os2.pm -> blib/lib/Module/Build/Platform/os2.pm
Copying lib/Module/Build/Base.pm -> blib/lib/Module/Build/Base.pm
Copying lib/Module/Build/Platform/cygwin.pm -> blib/lib/Module/Build/Platform/cygwin.pm
Copying lib/Module/Build/Platform/MPEiX.pm -> blib/lib/Module/Build/Platform/MPEiX.pm
Copying lib/Module/Build/Platform/VMS.pm -> blib/lib/Module/Build/Platform/VMS.pm
Copying lib/Module/Build/Platform/EBCDIC.pm -> blib/lib/Module/Build/Platform/EBCDIC.pm
Copying lib/Module/Build.pm -> blib/lib/Module/Build.pm
Copying lib/Module/Build/PPMMaker.pm -> blib/lib/Module/Build/PPMMaker.pm
Copying lib/Module/Build/Platform/aix.pm -> blib/lib/Module/Build/Platform/aix.pm
Copying lib/Module/Build/Cookbook.pm -> blib/lib/Module/Build/Cookbook.pm
Copying lib/Module/Build/Platform/Default.pm -> blib/lib/Module/Build/Platform/Default.pm
Copying lib/Module/Build/YAML.pm -> blib/lib/Module/Build/YAML.pm
Copying lib/Module/Build/Authoring.pod -> blib/lib/Module/Build/Authoring.pod
Copying lib/Module/Build/API.pod -> blib/lib/Module/Build/API.pod
Copying scripts/config_data -> blib/script/config_data
Deleting blib/script/config_data.bak
Writing config notes to blib/lib/Module/Build/ConfigData.pm
Manifying blib/script/config_data -> blib/bindoc/config_data.1
Manifying blib/lib/Module/Build/Platform/Unix.pm -> blib/libdoc/Module::Build::Platform::Unix.3
Manifying blib/lib/Module/Build/Platform/EBCDIC.pm -> blib/libdoc/Module::Build::Platform::EBCDIC.3
Manifying blib/lib/Module/Build/Platform/MacOS.pm -> blib/libdoc/Module::Build::Platform::MacOS.3
Manifying blib/lib/Module/Build.pm -> blib/libdoc/Module::Build.3
Manifying blib/lib/Module/Build/Platform/Amiga.pm -> blib/libdoc/Module::Build::Platform::Amiga.3
Manifying blib/lib/Module/Build/ConfigData.pm -> blib/libdoc/Module::Build::ConfigData.3
Manifying blib/lib/Module/Build/Platform/cygwin.pm -> blib/libdoc/Module::Build::Platform::cygwin.3
Manifying blib/lib/Module/Build/Notes.pm -> blib/libdoc/Module::Build::Notes.3
Manifying blib/lib/Module/Build/ModuleInfo.pm -> blib/libdoc/Module::Build::ModuleInfo.3
Manifying blib/lib/Module/Build/YAML.pm -> blib/libdoc/Module::Build::YAML.3
Manifying blib/lib/Module/Build/Platform/MPEiX.pm -> blib/libdoc/Module::Build::Platform::MPEiX.3
Manifying blib/lib/Module/Build/PPMMaker.pm -> blib/libdoc/Module::Build::PPMMaker.3
Manifying blib/lib/Module/Build/Platform/Windows.pm -> blib/libdoc/Module::Build::Platform::Windows.3
Manifying blib/lib/Module/Build/Platform/VOS.pm -> blib/libdoc/Module::Build::Platform::VOS.3
Manifying blib/lib/Module/Build/Platform/Default.pm -> blib/libdoc/Module::Build::Platform::Default.3
Manifying blib/lib/Module/Build/API.pod -> blib/libdoc/Module::Build::API.3
Manifying blib/lib/Module/Build/Platform/RiscOS.pm -> blib/libdoc/Module::Build::Platform::RiscOS.3
Manifying blib/lib/Module/Build/Cookbook.pm -> blib/libdoc/Module::Build::Cookbook.3
Manifying blib/lib/Module/Build/Platform/aix.pm -> blib/libdoc/Module::Build::Platform::aix.3
Manifying blib/lib/Module/Build/Platform/darwin.pm -> blib/libdoc/Module::Build::Platform::darwin.3
Manifying blib/lib/Module/Build/Platform/os2.pm -> blib/libdoc/Module::Build::Platform::os2.3
Manifying blib/lib/Module/Build/Platform/VMS.pm -> blib/libdoc/Module::Build::Platform::VMS.3
Manifying blib/lib/Module/Build/Base.pm -> blib/libdoc/Module::Build::Base.3
Manifying blib/lib/Module/Build/Authoring.pod -> blib/libdoc/Module::Build::Authoring.3
Manifying blib/lib/Module/Build/Compat.pm -> blib/libdoc/Module::Build::Compat.3

[MSG] [Mon Feb  9 20:07:07 2009] t/add_property........ok
t/basic...............ok
t/compat..............ok
t/destinations........ok
t/ext.................ok
t/extend..............ok
t/files...............ok
t/help................ok
t/install.............ok
t/manifypods..........ok
t/mbyaml..............ok
t/metadata............ok
t/metadata2...........ok
t/moduleinfo..........ok
t/new_from_context....ok
t/notes...............ok
t/par.................skipped: PAR::Dist 0.17 or up not installed to check .par's.
t/parents.............ok
t/pod_parser..........ok
t/ppm.................ok
t/runthrough..........ok
t/script_dist.........ok
t/signature...........skipped: $ENV{TEST_SIGNATURE} is not set
t/test_file_exts......ok
t/test_type...........ok
t/test_types..........ok
t/tilde...............ok
t/use_tap_harness.....ok
t/versions............ok
t/xs..................ok
All tests successful.
Files=30, Tests=1028, 250 wallclock secs ( 1.69 usr  0.35 sys + 91.45 cusr 18.35 csys = 111.84 CPU)
Result: PASS

[MSG] [Mon Feb  9 20:07:08 2009] Sending test report for 'Module-Build-0.31_03'
[MSG] [Mon Feb  9 20:07:09 2009] DEFAULT 'munge_test_report' HANDLER RETURNING 'sub return value'
[MSG] [Mon Feb  9 20:07:09 2009] Successfully sent 'pass' report for 'Module-Build-0.31_03'

[MSG] [Fri Feb  6 22:57:18 2009] Checksum matches for 'Package-Constants-0.02.tar.gz'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/CHANGES'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/lib/'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/lib/Package/'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/lib/Package/Constants.pm'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/Makefile.PL'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/MANIFEST'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/META.yml'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/README'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/t/'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package-Constants-0.02/t/01_list.t'
[MSG] [Fri Feb  6 22:57:18 2009] Extracted 'Package::Constants' to '/home/chris/dev/perls/rel/conf/perl-5.10.0/.cpanplus/5.10.0/build/Package-Constants-0.02'
[MSG] [Fri Feb  6 22:57:19 2009] Checking if your kit is complete...
Looks good
Writing Makefile for Package::Constants

[MSG] [Fri Feb  6 22:57:19 2009] DEFAULT 'filter_prereqs' HANDLER RETURNING 'sub return value'
[MSG] [Fri Feb  6 22:57:21 2009] cp lib/Package/Constants.pm blib/lib/Package/Constants.pm
Manifying blib/man3/Package::Constants.3

[MSG] [Fri Feb  6 22:57:21 2009] MAKE TEST passed: PERL_DL_NONLAZY=1 /home/chris/dev/perls/rel/perl-5.10.0/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/01_list....ok
All tests successful.
Files=1, Tests=4,  0 wallclock secs ( 0.12 cusr +  0.02 csys =  0.14 CPU)

[MSG] [Fri Feb  6 22:57:22 2009] Sending test report for 'Package-Constants-0.02'
[MSG] [Fri Feb  6 22:57:22 2009] DEFAULT 'munge_test_report' HANDLER RETURNING 'sub return value'
[MSG] [Fri Feb  6 22:57:22 2009] Successfully sent 'pass' report for 'Package-Constants-0.02'
[MSG] [Fri Feb  6 22:57:48 2009] Trying to get 'http://www.nic.funet.fi/pub/CPAN/authors/id/A/AN/ANDYA/Test-Harness-3.14.tar.gz'
[MSG] [Fri Feb  6 22:57:49 2009] Trying to get 'http://www.nic.funet.fi/pub/CPAN/authors/id/A/AN/ANDYA/CHECKSUMS'
[MSG] [Fri Feb  6 22:57:50 2009] Checksum matches for 'Test-Harness-3.14.tar.gz'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/Build.PL'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/Changes'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/Changes-2.64'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/HACKING.pod'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/MANIFEST'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/META.yml'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/Makefile.PL'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/README'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/bin/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/bin/prove'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/README'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/analyze_tests.pl'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/bin/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/bin/forked_tests.pl'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/bin/test_html.pl'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/bin/tprove_gtk'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/harness-hook/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/harness-hook/hook.pl'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/harness-hook/lib/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/harness-hook/lib/Harness/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/harness-hook/lib/Harness/Hook.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/my_exec'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/silent-harness.pl'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/t/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/t/10-stuff.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/t/ruby.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/examples/test_urls.txt'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/inc/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/inc/MyBuilder.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/State/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/State/Result/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/State/Result/Test.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/State/Result.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove/State.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/App/Prove.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Base.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/Color.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/Console/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/Console/ParallelSession.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/Console/Session.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Formatter/Console.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Harness.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Object.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Aggregator.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Grammar.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Iterator/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Iterator/Array.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Iterator/Process.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Iterator/Stream.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Iterator.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/IteratorFactory.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Multiplexer.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Bailout.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Comment.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Plan.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Pragma.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Test.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Unknown.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/Version.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result/YAML.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Result.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/ResultFactory.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Scheduler/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Scheduler/Job.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Scheduler/Spinner.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Scheduler.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Source/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Source/Perl.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Source.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/Utils.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/YAMLish/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/YAMLish/Reader.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser/YAMLish/Writer.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/TAP/Parser.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/Test/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/lib/Test/Harness.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/perlcriticrc'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/000-load.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/aggregator.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/bailout.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/base.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/callbacks.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/env.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/failure.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/inc-propagation.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/inc_taint.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/nonumbers.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/regression.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/test-harness-compat.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/compat/version.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/console.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/data/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/data/catme.1'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/data/proverc'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/data/sample.yml'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/errors.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/glob-to-regexp.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/grammar.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/harness-subclass.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/harness.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/iterators.t'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/App/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/App/Prove/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/App/Prove/Plugin/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/App/Prove/Plugin/Dummy.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/Dev/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/Dev/Null.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/EmptyParser.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/IO/'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/IO/c55Capture.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/MyCustom.pm'
[MSG] [Fri Feb  6 22:57:52 2009] Extracted 'Test-Harness-3.14/t/lib/MyGrammar.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MyIterator.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MyIteratorFactory.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MyPerlSource.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MyResult.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MyResultFactory.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/MySource.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/NOP.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/NoFork.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/TAP/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/TAP/Parser/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/TAP/Parser/SubclassTest.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/Builder/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/Builder/Module.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/Builder.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/More.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/Test/Simple.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/lib/if.pm'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/multiplexer.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/nofork-mux.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/nofork.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/object.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/parse.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/parser-config.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/parser-subclass.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/premature-bailout.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/process.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/prove.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/proveenv.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/proverc.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/proverun.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/regression.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/results.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/bailout'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/bignum'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/bignum_many'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/combined'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/combined_compat'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/delayed'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/descriptive'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/descriptive_trailing'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/die'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/die_head_end'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/die_last_minute'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/die_unfinished'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/duplicates'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/echo'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/empty'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/escape_eol'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/escape_hash'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/head_end'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/head_fail'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/inc_taint'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/junk_before_plan'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/lone_not_bug'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/no_nums'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/no_output'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/out_err_mix'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/out_of_order'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/schwern'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/schwern-todo-quiet'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/segfault'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/sequence_misparse'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/shbang_misparse'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/simple'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/simple_fail'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/simple_yaml'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/skip'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/skip_nomsg'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/skipall'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/skipall_nomsg'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/skipall_v13'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/space_after_plan'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/stdout_stderr'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/strict'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/switches'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/taint'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/taint_warn'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/todo'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/todo_inline'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/todo_misparse'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/too_many'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/version_good'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/version_late'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/version_old'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/vms_nit'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/sample-tests/with_comments'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/scheduler.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/harness'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/harness_badtap'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/harness_complain'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/harness_directives'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/harness_failure'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/source_tests/source'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/spool.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/state.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/state_results.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/streams.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/subclass_tests/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/subclass_tests/non_perl_source'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/subclass_tests/perl_source'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/taint.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/testargs.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/unicode.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/utils.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/yamlish-output.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/yamlish-writer.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/t/yamlish.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/author/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/author/pod-coverage.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/author/pod.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/author/stdin.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/perls/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/perls/harness_perl.t'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/perls/sample-tests/'
[MSG] [Fri Feb  6 22:57:53 2009] Extracted 'Test-Harness-3.14/xt/perls/sample-tests/perl_version'
[MSG] [Fri Feb  6 22:57:54 2009] Extracted 'Test::Harness' to '/home/chris/dev/perls/rel/conf/perl-5.10.0/.cpanplus/5.10.0/build/Test-Harness-3.14'
[MSG] [Fri Feb  6 22:57:54 2009] Checking if your kit is complete...
Looks good
Writing Makefile for Test::Harness

[MSG] [Fri Feb  6 22:57:54 2009] DEFAULT 'filter_prereqs' HANDLER RETURNING 'sub return value'
[MSG] [Fri Feb  6 22:58:01 2009] cp lib/TAP/Parser/Result/Pragma.pm blib/lib/TAP/Parser/Result/Pragma.pm
cp lib/App/Prove/State/Result.pm blib/lib/App/Prove/State/Result.pm
cp lib/TAP/Parser/Iterator/Array.pm blib/lib/TAP/Parser/Iterator/Array.pm
cp lib/TAP/Base.pm blib/lib/TAP/Base.pm
cp lib/TAP/Formatter/Console/ParallelSession.pm blib/lib/TAP/Formatter/Console/ParallelSession.pm
cp lib/TAP/Parser/Result.pm blib/lib/TAP/Parser/Result.pm
cp lib/TAP/Formatter/Console/Session.pm blib/lib/TAP/Formatter/Console/Session.pm
cp lib/TAP/Parser/Result/YAML.pm blib/lib/TAP/Parser/Result/YAML.pm
cp lib/TAP/Parser/Scheduler/Job.pm blib/lib/TAP/Parser/Scheduler/Job.pm
cp lib/TAP/Parser.pm blib/lib/TAP/Parser.pm
cp lib/TAP/Parser/IteratorFactory.pm blib/lib/TAP/Parser/IteratorFactory.pm
cp lib/TAP/Parser/Iterator.pm blib/lib/TAP/Parser/Iterator.pm
cp lib/TAP/Formatter/Color.pm blib/lib/TAP/Formatter/Color.pm
cp lib/TAP/Parser/Iterator/Process.pm blib/lib/TAP/Parser/Iterator/Process.pm
cp lib/TAP/Parser/Grammar.pm blib/lib/TAP/Parser/Grammar.pm
cp HACKING.pod blib/lib/Test/HACKING.pod
cp lib/Test/Harness.pm blib/lib/Test/Harness.pm
cp lib/TAP/Parser/ResultFactory.pm blib/lib/TAP/Parser/ResultFactory.pm
cp lib/TAP/Parser/Utils.pm blib/lib/TAP/Parser/Utils.pm
cp lib/TAP/Parser/Result/Bailout.pm blib/lib/TAP/Parser/Result/Bailout.pm
cp lib/TAP/Object.pm blib/lib/TAP/Object.pm
cp lib/TAP/Parser/Multiplexer.pm blib/lib/TAP/Parser/Multiplexer.pm
cp lib/TAP/Parser/Result/Version.pm blib/lib/TAP/Parser/Result/Version.pm
cp lib/TAP/Parser/YAMLish/Writer.pm blib/lib/TAP/Parser/YAMLish/Writer.pm
cp lib/TAP/Parser/Result/Unknown.pm blib/lib/TAP/Parser/Result/Unknown.pm
cp lib/TAP/Parser/YAMLish/Reader.pm blib/lib/TAP/Parser/YAMLish/Reader.pm
cp lib/TAP/Parser/Scheduler.pm blib/lib/TAP/Parser/Scheduler.pm
cp lib/TAP/Parser/Result/Plan.pm blib/lib/TAP/Parser/Result/Plan.pm
cp lib/TAP/Parser/Source/Perl.pm blib/lib/TAP/Parser/Source/Perl.pm
cp lib/TAP/Parser/Result/Test.pm blib/lib/TAP/Parser/Result/Test.pm
cp lib/App/Prove/State/Result/Test.pm blib/lib/App/Prove/State/Result/Test.pm
cp lib/TAP/Parser/Result/Comment.pm blib/lib/TAP/Parser/Result/Comment.pm
cp lib/TAP/Parser/Source.pm blib/lib/TAP/Parser/Source.pm
cp lib/TAP/Formatter/Console.pm blib/lib/TAP/Formatter/Console.pm
cp lib/TAP/Parser/Iterator/Stream.pm blib/lib/TAP/Parser/Iterator/Stream.pm
cp lib/App/Prove.pm blib/lib/App/Prove.pm
cp lib/App/Prove/State.pm blib/lib/App/Prove/State.pm
cp lib/TAP/Harness.pm blib/lib/TAP/Harness.pm
cp lib/TAP/Parser/Aggregator.pm blib/lib/TAP/Parser/Aggregator.pm
cp lib/TAP/Parser/Scheduler/Spinner.pm blib/lib/TAP/Parser/Scheduler/Spinner.pm
cp bin/prove blib/script/prove
/home/chris/dev/perls/rel/perl-5.10.0/bin/perl "-MExtUtils::MY" -e "MY->fixin(shift)" blib/script/prove
Manifying blib/man1/prove.1
Manifying blib/man3/TAP::Parser::Result::Pragma.3
Manifying blib/man3/TAP::Parser::Iterator::Array.3
Manifying blib/man3/App::Prove::State::Result.3
Manifying blib/man3/TAP::Base.3
Manifying blib/man3/TAP::Formatter::Console::ParallelSession.3
Manifying blib/man3/TAP::Parser::Result.3
Manifying blib/man3/TAP::Formatter::Console::Session.3
Manifying blib/man3/TAP::Parser::Scheduler::Job.3
Manifying blib/man3/TAP::Parser::Result::YAML.3
Manifying blib/man3/TAP::Parser.3
Manifying blib/man3/TAP::Parser::IteratorFactory.3
Manifying blib/man3/TAP::Parser::Iterator.3
Manifying blib/man3/TAP::Formatter::Color.3
Manifying blib/man3/TAP::Parser::Iterator::Process.3
Manifying blib/man3/TAP::Parser::Grammar.3
Manifying blib/man3/Test::HACKING.3
Manifying blib/man3/Test::Harness.3
Manifying blib/man3/TAP::Parser::Result::Bailout.3
Manifying blib/man3/TAP::Parser::Utils.3
Manifying blib/man3/TAP::Parser::ResultFactory.3
Manifying blib/man3/TAP::Parser::Multiplexer.3
Manifying blib/man3/TAP::Object.3
Manifying blib/man3/TAP::Parser::YAMLish::Writer.3
Manifying blib/man3/TAP::Parser::Result::Version.3
Manifying blib/man3/TAP::Parser::Result::Unknown.3
Manifying blib/man3/TAP::Parser::YAMLish::Reader.3
Manifying blib/man3/TAP::Parser::Scheduler.3
Manifying blib/man3/TAP::Parser::Result::Plan.3
Manifying blib/man3/TAP::Parser::Source::Perl.3
Manifying blib/man3/TAP::Parser::Result::Test.3
Manifying blib/man3/App::Prove::State::Result::Test.3
Manifying blib/man3/TAP::Formatter::Console.3
Manifying blib/man3/TAP::Parser::Source.3
Manifying blib/man3/TAP::Parser::Result::Comment.3
Manifying blib/man3/TAP::Parser::Iterator::Stream.3
Manifying blib/man3/App::Prove::State.3
Manifying blib/man3/App::Prove.3
Manifying blib/man3/TAP::Harness.3
Manifying blib/man3/TAP::Parser::Aggregator.3
Manifying blib/man3/TAP::Parser::Scheduler::Spinner.3

[MSG] [Fri Feb  6 22:59:07 2009] MAKE TEST passed: PERL_DL_NONLAZY=1 /home/chris/dev/perls/rel/perl-5.10.0/bin/perl "-Iblib/lib" "-Iblib/arch" "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/*.t t/compat/*.t
t/000-load......................# Testing Test::Harness 3.14, Perl 5.010000, /home/chris/dev/perls/rel/perl-5.10.0/bin/perl
ok
t/aggregator....................ok
t/bailout.......................ok
t/base..........................ok
t/callbacks.....................ok
t/compat/env....................ok
t/compat/failure................ok
t/compat/inc-propagation........ok
t/compat/inc_taint..............ok
t/compat/nonumbers..............ok
t/compat/regression.............ok
t/compat/test-harness-compat....ok
t/compat/version................ok
t/console.......................ok
t/errors........................ok
t/glob-to-regexp................ok
t/grammar.......................ok
t/harness-subclass..............ok
t/harness.......................ok
t/iterators.....................ok
t/multiplexer...................ok
t/nofork-mux....................ok
t/nofork........................ok
t/object........................ok
t/parse.........................ok
t/parser-config.................ok
t/parser-subclass...............ok
t/premature-bailout.............ok
t/process.......................ok
t/prove.........................ok
t/proveenv......................ok
t/proverc.......................ok
t/proverun......................ok
t/regression....................ok
t/results.......................ok
t/scheduler.....................ok
t/source........................ok
t/spool.........................ok
t/state.........................ok
t/state_results.................ok
t/streams.......................ok
t/taint.........................ok
t/testargs......................ok
t/unicode.......................ok
t/utils.........................ok
t/yamlish-output................ok
t/yamlish-writer................ok
t/yamlish.......................ok
All tests successful.
Files=48, Tests=10962, 66 wallclock secs (10.60 usr  0.81 sys + 41.96 cusr 10.94 csys = 64.31 CPU)
Result: PASS

[MSG] [Fri Feb  6 22:59:07 2009] Sending test report for 'Test-Harness-3.14'
[MSG] [Fri Feb  6 22:59:07 2009] DEFAULT 'munge_test_report' HANDLER RETURNING 'sub return value'
[MSG] [Fri Feb  6 22:59:07 2009] Successfully sent 'pass' report for 'Test-Harness-3.14'
