#!perl

package Test::Mojo::UserAgent;
use warnings FATAL => 'all';
use FindBin();
use lib $FindBin::RealBin;

use Role::Tiny::With;

with 'Role::Test::Module';

__PACKAGE__->run( module => "Module::Build", tests => 13 );

sub lol {
    [
        [
            "Para",
"bindoc binhtml destdir distcheck distclean distdir distmeta distsign disttest fakeinstall html installdirs installsitebin installsitescript installvendorbin installvendorscript libdoc libhtml pardist ppd ppmdist realclean skipcheck testall testcover testdb testpod testpodcoverage versioninstall"
        ],
        [ "head1", "NAME" ],
        [ "Para",  "Module::Build - Build and install Perl modules" ],
        [ "head1", "SYNOPSIS" ],
        [ "Para",  "Standard process for building & installing modules:" ],
        [
            "Verbatim",
            "  perl Build.PL\n  ./Build\n  ./Build test\n  ./Build install"
        ],
        [
            "Para",
"Or, if you're on a platform (like DOS or Windows) that doesn't require the \"./\" notation, you can do this:"
        ],
        [
            "Verbatim",
            "  perl Build.PL\n  Build\n  Build test\n  Build install"
        ],
        [ "head1", "DESCRIPTION" ],
        [
            "Para",
"Module::Build is a system for building, testing, and installing Perl modules. It is meant to be an alternative to ExtUtils::MakeMaker. Developers may alter the behavior of the module through subclassing. It also does not require a make on your system - most of the Module::Build code is pure-perl and written in a very cross-platform way."
        ],
        [
            "Para",
"See \"COMPARISON\" for more comparisons between Module::Build and other installer tools."
        ],
        [
            "Para",
"To install Module::Build, and any other module that uses Module::Build for its installation process, do the following:"
        ],
        [
            "Verbatim",
"  perl Build.PL       # 'Build.PL' script creates the 'Build' script\n  ./Build             # Need ./ to ensure we're using this \"Build\" script\n  ./Build test        # and not another one that happens to be in the PATH\n  ./Build install"
        ],
        [
            "Para",
"This illustrates initial configuration and the running of three 'actions'. In this case the actions run are 'build' (the default action), 'test', and 'install'. Other actions defined so far include:"
        ],
        [
            "Verbatim",
"  build                          manifest\n  clean                          manifest_skip\n  code                           manpages\n  config_data                    pardist\n  diff                           ppd\n  dist                           ppmdist\n  distcheck                      prereq_data\n  distclean                      prereq_report\n  distdir                        pure_install\n  distinstall                    realclean\n  distmeta                       retest\n  distsign                       skipcheck\n  disttest                       test\n  docs                           testall\n  fakeinstall                    testcover\n  help                           testdb\n  html                           testpod\n  install                        testpodcoverage\n  installdeps                    versioninstall"
        ],
        [
            "Para",
            "You can run the 'help' action for a complete list of actions."
        ],
        [ "head1", "GUIDE TO DOCUMENTATION" ],
        [
            "Para",
            "The documentation for Module::Build is broken up into sections:"
        ],
        [
            "over-text",
            [ "item-text", "General Usage (", "Module::Build", ")" ],
            [
                "Para",
"This is the document you are currently reading. It describes basic usage and background information. Its main purpose is to assist the user who wants to learn how to invoke and control Module::Build scripts at the command line."
            ],
            [
                "item-text",                "Authoring Reference (",
                "Module::Build::Authoring", ")"
            ],
            [
                "Para",
"This document describes the structure and organization of Module::Build, and the relevant concepts needed by authors who are writing Build.PL scripts for a distribution or controlling Module::Build processes programmatically."
            ],
            [ "item-text", "API Reference (", "Module::Build::API", ")" ],
            [ "Para",      "This is a reference to the Module::Build API." ],
            [ "item-text", "Cookbook (", "Module::Build::Cookbook", ")" ],
            [
                "Para",
"This document demonstrates how to accomplish many common tasks. It covers general command line usage and authoring of Build.PL scripts. Includes working examples."
            ]
        ],
        [ "head1", "ACTIONS" ],
        [
            "Para",
"There are some general principles at work here. First, each task when building a module is called an \"action\". These actions are listed above; they correspond to the building, testing, installing, packaging, etc., tasks."
        ],
        [
            "Para",
"Second, arguments are processed in a very systematic way. Arguments are always key=value pairs. They may be specified at perl Build.PL time (i.e. perl Build.PL destdir=/my/secret/place), in which case their values last for the lifetime of the Build script. They may also be specified when executing a particular action (i.e. Build test verbose=1), in which case their values last only for the lifetime of that command. Per-action command line parameters take precedence over parameters specified at perl Build.PL time."
        ],
        [
            "Para",
"The build process also relies heavily on the Config.pm module. If the user wishes to override any of the values in Config.pm, she may specify them like so:"
        ],
        [ "Verbatim", "  perl Build.PL --config cc=gcc --config ld=gcc" ],
        [ "Para",     "The following build actions are provided by default." ],
        [
            "over-text",
            [ "item-text", "build" ],
            [ "Para",      "[version 0.01]" ],
            [
                "Para",
"If you run the Build script without any arguments, it runs the build action, which in turn runs the code and docs actions."
            ],
            [ "Para", "This is analogous to the MakeMaker make all target." ],
            [ "item-text", "clean" ],
            [ "Para",      "[version 0.01]" ],
            [
                "Para",
"This action will clean up any files that the build process may have created, including the blib/ directory (but not including the _build/ directory and the Build script itself)."
            ],
            [ "item-text", "code" ],
            [ "Para",      "[version 0.20]" ],
            [ "Para",      "This action builds your code base." ],
            [
                "Para",
"By default it just creates a blib/ directory and copies any .pm and .pod files from your lib/ directory into the blib/ directory. It also compiles any .xs files from lib/ and places them in blib/. Of course, you need a working C compiler (probably the same one that built perl itself) for the compilation to work properly."
            ],
            [
                "Para",
"The code action also runs any .PL files in your lib/ directory. Typically these create other files, named the same but without the .PL ending. For example, a file lib/Foo/Bar.pm.PL could create the file lib/Foo/Bar.pm. The .PL files are processed first, so any .pm files (or other kinds that we deal with) will get copied correctly."
            ],
            [ "item-text", "config_data" ],
            [ "Para",      "[version 0.26]" ],
            [ "Para",      "..." ],
            [ "item-text", "diff" ],
            [ "Para",      "[version 0.14]" ],
            [
                "Para",
"This action will compare the files about to be installed with their installed counterparts. For .pm and .pod files, a diff will be shown (this currently requires a 'diff' program to be in your PATH). For other files like compiled binary files, we simply report whether they differ."
            ],
            [
                "Para",
"A flags parameter may be passed to the action, which will be passed to the 'diff' program. Consult your 'diff' documentation for the parameters it will accept - a good one is -u:"
            ],
            [ "Verbatim",  "  ./Build diff flags=-u" ],
            [ "item-text", "dist" ],
            [ "Para",      "[version 0.02]" ],
            [
                "Para",
"This action is helpful for module authors who want to package up their module for source distribution through a medium like CPAN. It will create a tarball of the files listed in MANIFEST and compress the tarball using GZIP compression."
            ],
            [
                "Para",
"By default, this action will use the Archive::Tar module. However, you can force it to use binary \"tar\" and \"gzip\" executables by supplying an explicit tar (and optional gzip) parameter:"
            ],
            [
                "Verbatim",
"  ./Build dist --tar C:\\path\\to\\tar.exe --gzip C:\\path\\to\\zip.exe"
            ],
            [ "item-text", "distcheck" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"Reports which files are in the build directory but not in the MANIFEST file, and vice versa. (See \"manifest\" for details.)"
            ],
            [ "item-text", "distclean" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"Performs the 'realclean' action and then the 'distcheck' action."
            ],
            [ "item-text", "distdir" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"Creates a \"distribution directory\" named \$dist_name-\$dist_version (if that directory already exists, it will be removed first), then copies all the files listed in the MANIFEST file to that directory. This directory is what the distribution tarball is created from."
            ],
            [ "item-text", "distinstall" ],
            [ "Para",      "[version 0.37]" ],
            [
                "Para",
"Performs the 'distdir' action, then switches into that directory and runs a perl Build.PL, followed by the 'build' and 'install' actions in that directory. Use PERL_MB_OPT or .modulebuildrc to set options that should be applied during subprocesses"
            ],
            [ "item-text", "distmeta" ],
            [ "Para",      "[version 0.21]" ],
            [
                "Para",
                "Creates the META.yml file that describes the distribution."
            ],
            [
                "Para",
"META.yml is a file containing various bits of metadata about the distribution. The metadata includes the distribution name, version, abstract, prerequisites, license, and various other data about the distribution. This file is created as META.yml in a simplified YAML format."
            ],
            [
                "Para",
"META.yml file must also be listed in MANIFEST - if it's not, a warning will be issued."
            ],
            [
                "Para",
"The current version of the META.yml specification can be found on CPAN as CPAN::Meta::Spec."
            ],
            [ "item-text", "distsign" ],
            [ "Para",      "[version 0.16]" ],
            [
                "Para",
"Uses Module::Signature to create a SIGNATURE file for your distribution, and adds the SIGNATURE file to the distribution's MANIFEST."
            ],
            [ "item-text", "disttest" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"Performs the 'distdir' action, then switches into that directory and runs a perl Build.PL, followed by the 'build' and 'test' actions in that directory. Use PERL_MB_OPT or .modulebuildrc to set options that should be applied during subprocesses"
            ],
            [ "item-text", "docs" ],
            [ "Para",      "[version 0.20]" ],
            [
                "Para",
"This will generate documentation (e.g. Unix man pages and HTML documents) for any installable items under blib/ that contain POD. If there are no bindoc or libdoc installation targets defined (as will be the case on systems that don't support Unix manpages) no action is taken for manpages. If there are no binhtml or libhtml installation targets defined no action is taken for HTML documents."
            ],
            [ "item-text", "fakeinstall" ],
            [ "Para",      "[version 0.02]" ],
            [
                "Para",
"This is just like the install action, but it won't actually do anything, it will just report what it would have done if you had actually run the install action."
            ],
            [ "item-text", "help" ],
            [ "Para",      "[version 0.03]" ],
            [
                "Para",
"This action will simply print out a message that is meant to help you use the build process. It will show you a list of available build actions too."
            ],
            [
                "Para",
"With an optional argument specifying an action name (e.g. Build help test), the 'help' action will show you any POD documentation it can find for that action."
            ],
            [ "item-text", "html" ],
            [ "Para",      "[version 0.26]" ],
            [
                "Para",
"This will generate HTML documentation for any binary or library files under blib/ that contain POD. The HTML documentation will only be installed if the install paths can be determined from values in Config.pm. You can also supply or override install paths on the command line by specifying install_path values for the binhtml and/or libhtml installation targets."
            ],
            [
                "Para",
"With an optional html_links argument set to a false value, you can skip the search for other documentation to link to, because that can waste a lot of time if there aren't any links to generate anyway:"
            ],
            [ "Verbatim",  "  ./Build html --html_links 0" ],
            [ "item-text", "install" ],
            [ "Para",      "[version 0.01]" ],
            [
                "Para",
"This action will use ExtUtils::Install to install the files from blib/ into the system. See \"INSTALL PATHS\" for details about how Module::Build determines where to install things, and how to influence this process."
            ],
            [
                "Para",
"If you want the installation process to look around in \@INC for other versions of the stuff you're installing and try to delete it, you can use the uninst parameter, which tells ExtUtils::Install to do so:"
            ],
            [ "Verbatim", "  ./Build install uninst=1" ],
            [
                "Para",
"This can be a good idea, as it helps prevent multiple versions of a module from being present on your system, which can be a confusing situation indeed."
            ],
            [ "item-text", "installdeps" ],
            [ "Para",      "[version 0.36]" ],
            [
                "Para",
"This action will use the cpan_client parameter as a command to install missing prerequisites. You will be prompted whether to install optional dependencies."
            ],
            [
                "Para",
"The cpan_client option defaults to 'cpan' but can be set as an option or in .modulebuildrc. It must be a shell command that takes a list of modules to install as arguments (e.g. 'cpanp -i' for CPANPLUS). If the program part is a relative path (e.g. 'cpan' or 'cpanp'), it will be located relative to the perl program that executed Build.PL."
            ],
            [
                "Verbatim",
"  /opt/perl/5.8.9/bin/perl Build.PL\n  ./Build installdeps --cpan_client 'cpanp -i'\n  # installs to 5.8.9"
            ],
            [ "item-text", "manifest" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"This is an action intended for use by module authors, not people installing modules. It will bring the MANIFEST up to date with the files currently present in the distribution. You may use a MANIFEST.SKIP file to exclude certain files or directories from inclusion in the MANIFEST. MANIFEST.SKIP should contain a bunch of regular expressions, one per line. If a file in the distribution directory matches any of the regular expressions, it won't be included in the MANIFEST."
            ],
            [
                "Para",
"The following is a reasonable MANIFEST.SKIP starting point, you can add your own stuff to it:"
            ],
            [
                "Verbatim",
"  ^_build\n  ^Build\$\n  ^blib\n  ~\$\n  \\.bak\$\n  ^MANIFEST\\.SKIP\$\n  CVS"
            ],
            [
                "Para",
"See the \"distcheck\" and \"skipcheck\" actions if you want to find out what the manifest action would do, without actually doing anything."
            ],
            [ "item-text", "manifest_skip" ],
            [ "Para",      "[version 0.3608]" ],
            [
                "Para",
"This is an action intended for use by module authors, not people installing modules. It will generate a boilerplate MANIFEST.SKIP file if one does not already exist."
            ],
            [ "item-text", "manpages" ],
            [ "Para",      "[version 0.28]" ],
            [
                "Para",
"This will generate man pages for any binary or library files under blib/ that contain POD. The man pages will only be installed if the install paths can be determined from values in Config.pm. You can also supply or override install paths by specifying there values on the command line with the bindoc and libdoc installation targets."
            ],
            [ "item-text", "pardist" ],
            [ "Para",      "[version 0.2806]" ],
            [
                "Para",
"Generates a PAR binary distribution for use with PAR or PAR::Dist."
            ],
            [
                "Para",
"It requires that the PAR::Dist module (version 0.17 and up) is installed on your system."
            ],
            [ "item-text", "ppd" ],
            [ "Para",      "[version 0.20]" ],
            [ "Para",      "Build a PPD file for your distribution." ],
            [
                "Para",
"This action takes an optional argument codebase which is used in the generated PPD file to specify the (usually relative) URL of the distribution. By default, this value is the distribution name without any path information."
            ],
            [ "Para", "Example:" ],
            [
                "Verbatim",
"  ./Build ppd --codebase \"MSWin32-x86-multi-thread/Module-Build-0.21.tar.gz\""
            ],
            [ "item-text", "ppmdist" ],
            [ "Para",      "[version 0.23]" ],
            [
                "Para",
"Generates a PPM binary distribution and a PPD description file. This action also invokes the ppd action, so it can accept the same codebase argument described under that action."
            ],
            [
                "Para",
"This uses the same mechanism as the dist action to tar & zip its output, so you can supply tar and/or gzip parameters to affect the result."
            ],
            [ "item-text", "prereq_data" ],
            [ "Para",      "[version 0.32]" ],
            [
                "Para",
"This action prints out a Perl data structure of all prerequisites and the versions required. The output can be loaded again using eval(). This can be useful for external tools that wish to query a Build script for prerequisites."
            ],
            [ "item-text", "prereq_report" ],
            [ "Para",      "[version 0.28]" ],
            [
                "Para",
"This action prints out a list of all prerequisites, the versions required, and the versions actually installed. This can be useful for reviewing the configuration of your system prior to a build, or when compiling data to send for a bug report."
            ],
            [ "item-text", "pure_install" ],
            [ "Para",      "[version 0.28]" ],
            [
                "Para",
"This action is identical to the install action. In the future, though, when install starts writing to the file \$(INSTALLARCHLIB)/perllocal.pod, pure_install won't, and that will be the only difference between them."
            ],
            [ "item-text", "realclean" ],
            [ "Para",      "[version 0.01]" ],
            [
                "Para",
"This action is just like the clean action, but also removes the _build directory and the Build script. If you run the realclean action, you are essentially starting over, so you will have to re-create the Build script again."
            ],
            [ "item-text", "retest" ],
            [ "Para",      "[version 0.2806]" ],
            [
                "Para",
"This is just like the test action, but doesn't actually build the distribution first, and doesn't add blib/ to the load path, and therefore will test against a previously installed version of the distribution. This can be used to verify that a certain installed distribution still works, or to see whether newer versions of a distribution still pass the old regression tests, and so on."
            ],
            [ "item-text", "skipcheck" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"Reports which files are skipped due to the entries in the MANIFEST.SKIP file (See \"manifest\" for details)"
            ],
            [ "item-text", "test" ],
            [ "Para",      "[version 0.01]" ],
            [
                "Para",
"This will use Test::Harness or TAP::Harness to run any regression tests and report their results. Tests can be defined in the standard places: a file called test.pl in the top-level directory, or several files ending with .t in a t/ directory."
            ],
            [
                "Para",
"If you want tests to be 'verbose', i.e. show details of test execution rather than just summary information, pass the argument verbose=1."
            ],
            [
                "Para",
"If you want to run tests under the perl debugger, pass the argument debugger=1."
            ],
            [
                "Para",
"If you want to have Module::Build find test files with different file name extensions, pass the test_file_exts argument with an array of extensions, such as [qw( .t .s .z )]."
            ],
            [
                "Para",
"If you want test to be run by TAP::Harness, rather than Test::Harness, pass the argument tap_harness_args as an array reference of arguments to pass to the TAP::Harness constructor."
            ],
            [
                "Para",
"In addition, if a file called visual.pl exists in the top-level directory, this file will be executed as a Perl script and its output will be shown to the user. This is a good place to put speed tests or other tests that don't use the Test::Harness format for output."
            ],
            [
                "Para",
"To override the choice of tests to run, you may pass a test_files argument whose value is a whitespace-separated list of test scripts to run. This is especially useful in development, when you only want to run a single test to see whether you've squashed a certain bug yet:"
            ],
            [ "Verbatim", "  ./Build test --test_files t/something_failing.t" ],
            [
                "Para",
                "You may also pass several test_files arguments separately:"
            ],
            [
                "Verbatim",
                "  ./Build test --test_files t/one.t --test_files t/two.t"
            ],
            [ "Para",      "or use a glob()-style pattern:" ],
            [ "Verbatim",  "  ./Build test --test_files 't/01-*.t'" ],
            [ "item-text", "testall" ],
            [ "Para",      "[version 0.2807]" ],
            [
                "Para",
"[Note: the 'testall' action and the code snippets below are currently in alpha stage, see http://www.nntp.perl.org/group/perl.module.build/2007/03/msg584.html ]"
            ],
            [
                "Para",
"Runs the test action plus each of the test\$type actions defined by the keys of the test_types parameter."
            ],
            [
                "Para",
"Currently, you need to define the ACTION_test\$type method yourself and enumerate them in the test_types parameter."
            ],
            [
                "Verbatim",
"  my \$mb = Module::Build->subclass(\n    code => q(\n      sub ACTION_testspecial { shift->generic_test(type => 'special'); }\n      sub ACTION_testauthor  { shift->generic_test(type => 'author'); }\n    )\n  )->new(\n    ...\n    test_types  => {\n      special => '.st',\n      author  => ['.at', '.pt' ],\n    },\n    ..."
            ],
            [ "item-text", "testcover" ],
            [ "Para",      "[version 0.26]" ],
            [
                "Para",
"Runs the test action using Devel::Cover, generating a code-coverage report showing which parts of the code were actually exercised during the tests."
            ],
            [
                "Para",
"To pass options to Devel::Cover, set the \$DEVEL_COVER_OPTIONS environment variable:"
            ],
            [
                "Verbatim",
                "  DEVEL_COVER_OPTIONS=-ignore,Build ./Build testcover"
            ],
            [ "item-text", "testdb" ],
            [ "Para",      "[version 0.05]" ],
            [
                "Para",
"This is a synonym for the 'test' action with the debugger=1 argument."
            ],
            [ "item-text", "testpod" ],
            [ "Para",      "[version 0.25]" ],
            [
                "Para",
"This checks all the files described in the docs action and produces Test::Harness-style output. If you are a module author, this is useful to run before creating a new release."
            ],
            [ "item-text", "testpodcoverage" ],
            [ "Para",      "[version 0.28]" ],
            [
                "Para",
"This checks the pod coverage of the distribution and produces Test::Harness-style output. If you are a module author, this is useful to run before creating a new release."
            ],
            [ "item-text", "versioninstall" ],
            [ "Para",      "[version 0.16]" ],
            [
                "Para",
"** Note: since only.pm is so new, and since we just recently added support for it here too, this feature is to be considered experimental. **"
            ],
            [
                "Para",
"If you have the only.pm module installed on your system, you can use this action to install a module into the version-specific library trees. This means that you can have several versions of the same module installed and use a specific one like this:"
            ],
            [ "Verbatim", "  use only MyModule => 0.55;" ],
            [
                "Para",
"To override the default installation libraries in only::config, specify the versionlib parameter when you run the Build.PL script:"
            ],
            [ "Verbatim", "  perl Build.PL --versionlib /my/version/place/" ],
            [
                "Para",
"To override which version the module is installed as, specify the version parameter when you run the Build.PL script:"
            ],
            [ "Verbatim", "  perl Build.PL --version 0.50" ],
            [
                "Para",
"See the only.pm documentation for more information on version-specific installs."
            ]
        ],
        [ "head1", "OPTIONS" ],
        [ "head2", "Command Line Options" ],
        [
            "Para",
"The following options can be used during any invocation of Build.PL or the Build script, during any action. For information on other options specific to an action, see the documentation for the respective action."
        ],
        [
            "Para",
"NOTE: There is some preliminary support for options to use the more familiar long option style. Most options can be preceded with the -- long option prefix, and the underscores changed to dashes (e.g. --use-rcfile). Additionally, the argument to boolean options is optional, and boolean options can be negated by prefixing them with no or no- (e.g. --noverbose or --no-verbose)."
        ],
        [
            "over-text",
            [ "item-text", "quiet" ],
            [ "Para",      "Suppress informative messages on output." ],
            [ "item-text", "verbose" ],
            [
                "Para",
"Display extra information about the Build on output. verbose will turn off quiet"
            ],
            [ "item-text", "cpan_client" ],
            [
                "Para",
"Sets the cpan_client command for use with the installdeps action. See installdeps for more details."
            ],
            [ "item-text", "use_rcfile" ],
            [
                "Para",
"Load the ~/.modulebuildrc option file. This option can be set to false to prevent the custom resource file from being loaded."
            ],
            [ "item-text", "allow_mb_mismatch" ],
            [
                "Para",
"Suppresses the check upon startup that the version of Module::Build we're now running under is the same version that was initially invoked when building the distribution (i.e. when the Build.PL script was first run). As of 0.3601, a mismatch results in a warning instead of a fatal error, so this option effectively just suppresses the warning."
            ],
            [ "item-text", "debug" ],
            [
                "Para",
"Prints Module::Build debugging information to STDOUT, such as a trace of executed build actions."
            ]
        ],
        [ "head2", "Default Options File (", ".modulebuildrc", ")" ],
        [ "Para",  "[version 0.28]" ],
        [
            "Para",
"When Module::Build starts up, it will look first for a file, \$ENV{HOME}/.modulebuildrc. If it's not found there, it will look in the .modulebuildrc file in the directories referred to by the environment variables HOMEDRIVE + HOMEDIR, USERPROFILE, APPDATA, WINDIR, SYS\$LOGIN. If the file exists, the options specified there will be used as defaults, as if they were typed on the command line. The defaults can be overridden by specifying new values on the command line."
        ],
        [
            "Para",
"The action name must come at the beginning of the line, followed by any amount of whitespace and then the options. Options are given the same as they would be on the command line. They can be separated by any amount of whitespace, including newlines, as long there is whitespace at the beginning of each continued line. Anything following a hash mark (#) is considered a comment, and is stripped before parsing. If more than one line begins with the same action name, those lines are merged into one set of options."
        ],
        [
            "Para",
"Besides the regular actions, there are two special pseudo-actions: the key * (asterisk) denotes any global options that should be applied to all actions, and the key 'Build_PL' specifies options to be applied when you invoke perl Build.PL."
        ],
        [
            "Verbatim",
"  *           verbose=1   # global options\n  diff        flags=-u\n  install     --install_base /home/ken\n              --install_path html=/home/ken/docs/html\n  installdeps --cpan_client 'cpanp -i'"
        ],
        [
            "Para",
"If you wish to locate your resource file in a different location, you can set the environment variable MODULEBUILDRC to the complete absolute path of the file containing your options."
        ],
        [ "head2", "Environment variables" ],
        [
            "over-text",
            [ "item-text", "MODULEBUILDRC" ],
            [ "Para",      "[version 0.28]" ],
            [
                "Para",
"Specifies an alternate location for a default options file as described above."
            ],
            [ "item-text", "PERL_MB_OPT" ],
            [ "Para",      "[version 0.36]" ],
            [
                "Para",
"Command line options that are applied to Build.PL or any Build action. The string is split as the shell would (e.g. whitespace) and the result is prepended to any actual command-line arguments."
            ]
        ],
        [ "head1", "INSTALL PATHS" ],
        [ "Para",  "[version 0.19]" ],
        [
            "Para",
"When you invoke Module::Build's build action, it needs to figure out where to install things. The nutshell version of how this works is that default installation locations are determined from Config.pm, and they may be overridden by using the install_path parameter. An install_base parameter lets you specify an alternative installation root like /home/foo, and a destdir lets you specify a temporary installation directory like /tmp/install in case you want to create bundled-up installable packages."
        ],
        [
            "Para",
"Natively, Module::Build provides default installation locations for the following types of installable items:"
        ],
        [
            "over-text",
            [ "item-text", "lib" ],
            [ "Para",      "Usually pure-Perl module files ending in .pm." ],
            [ "item-text", "arch" ],
            [
                "Para",
"\"Architecture-dependent\" module files, usually produced by compiling XS, Inline, or similar code."
            ],
            [ "item-text", "script" ],
            [
                "Para",
"Programs written in pure Perl. In order to improve reuse, try to make these as small as possible - put the code into modules whenever possible."
            ],
            [ "item-text", "bin" ],
            [
                "Para",
"\"Architecture-dependent\" executable programs, i.e. compiled C code or something. Pretty rare to see this in a perl distribution, but it happens."
            ],
            [ "item-text", "bindoc" ],
            [
                "Para",
"Documentation for the stuff in script and bin. Usually generated from the POD in those files. Under Unix, these are manual pages belonging to the 'man1' category."
            ],
            [ "item-text", "libdoc" ],
            [
                "Para",
"Documentation for the stuff in lib and arch. This is usually generated from the POD in .pm files. Under Unix, these are manual pages belonging to the 'man3' category."
            ],
            [ "item-text", "binhtml" ],
            [
                "Para",
"This is the same as bindoc above, but applies to HTML documents."
            ],
            [ "item-text", "libhtml" ],
            [
                "Para",
"This is the same as libdoc above, but applies to HTML documents."
            ]
        ],
        [
            "Para",
"Four other parameters let you control various aspects of how installation paths are determined:"
        ],
        [
            "over-text",
            [ "item-text", "installdirs" ],
            [
                "Para",
"The default destinations for these installable things come from entries in your system's Config.pm. You can select from three different sets of default locations by setting the installdirs parameter as follows:"
            ],
            [
                "Verbatim",
"                          'installdirs' set to:\n                   core          site                vendor\n\n              uses the following defaults from Config.pm:\n\n  lib     => installprivlib  installsitelib      installvendorlib\n  arch    => installarchlib  installsitearch     installvendorarch\n  script  => installscript   installsitescript   installvendorscript\n  bin     => installbin      installsitebin      installvendorbin\n  bindoc  => installman1dir  installsiteman1dir  installvendorman1dir\n  libdoc  => installman3dir  installsiteman3dir  installvendorman3dir\n  binhtml => installhtml1dir installsitehtml1dir installvendorhtml1dir [*]\n  libhtml => installhtml3dir installsitehtml3dir installvendorhtml3dir [*]\n\n  * Under some OS (eg. MSWin32) the destination for HTML documents is\n    determined by the C<Config.pm> entry C<installhtmldir>."
            ],
            [
                "Para",
"The default value of installdirs is \"site\". If you're creating vendor distributions of module packages, you may want to do something like this:"
            ],
            [ "Verbatim", "  perl Build.PL --installdirs vendor" ],
            [ "Para",     "or" ],
            [ "Verbatim", "  ./Build install --installdirs vendor" ],
            [
                "Para",
"If you're installing an updated version of a module that was included with perl itself (i.e. a \"core module\"), then you may set installdirs to \"core\" to overwrite the module in its present location."
            ],
            [
                "Para",
"(Note that the 'script' line is different from MakeMaker - unfortunately there's no such thing as \"installsitescript\" or \"installvendorscript\" entry in Config.pm, so we use the \"installsitebin\" and \"installvendorbin\" entries to at least get the general location right. In the future, if Config.pm adds some more appropriate entries, we'll start using those.)"
            ],
            [ "item-text", "install_path" ],
            [
                "Para",
                "Once the defaults have been set, you can override them."
            ],
            [ "Para", "On the command line, that would look like this:" ],
            [
                "Verbatim",
"  perl Build.PL --install_path lib=/foo/lib --install_path arch=/foo/lib/arch"
            ],
            [ "Para", "or this:" ],
            [
                "Verbatim",
"  ./Build install --install_path lib=/foo/lib --install_path arch=/foo/lib/arch"
            ],
            [ "item-text", "install_base" ],
            [
                "Para",
"You can also set the whole bunch of installation paths by supplying the install_base parameter to point to a directory on your system. For instance, if you set install_base to \"/home/ken\" on a Linux system, you'll install as follows:"
            ],
            [
                "Verbatim",
"  lib     => /home/ken/lib/perl5\n  arch    => /home/ken/lib/perl5/i386-linux\n  script  => /home/ken/bin\n  bin     => /home/ken/bin\n  bindoc  => /home/ken/man/man1\n  libdoc  => /home/ken/man/man3\n  binhtml => /home/ken/html\n  libhtml => /home/ken/html"
            ],
            [
                "Para",
"Note that this is different from how MakeMaker's PREFIX parameter works. install_base just gives you a default layout under the directory you specify, which may have little to do with the installdirs=site layout."
            ],
            [
                "Para",
"The exact layout under the directory you specify may vary by system - we try to do the \"sensible\" thing on each platform."
            ],
            [ "item-text", "destdir" ],
            [
                "Para",
"If you want to install everything into a temporary directory first (for instance, if you want to create a directory tree that a package manager like rpm or dpkg could create a package from), you can use the destdir parameter:"
            ],
            [ "Verbatim", "  perl Build.PL --destdir /tmp/foo" ],
            [ "Para",     "or" ],
            [ "Verbatim", "  ./Build install --destdir /tmp/foo" ],
            [
                "Para",
"This will effectively install to \"/tmp/foo/\$sitelib\", \"/tmp/foo/\$sitearch\", and the like, except that it will use File::Spec to make the pathnames work correctly on whatever platform you're installing on."
            ],
            [ "item-text", "prefix" ],
            [
                "Para",
"Provided for compatibility with ExtUtils::MakeMaker's PREFIX argument. prefix should be used when you want Module::Build to install your modules, documentation, and scripts in the same place as ExtUtils::MakeMaker's PREFIX mechanism."
            ],
            [ "Para", "The following are equivalent." ],
            [
                "Verbatim",
"    perl Build.PL --prefix /tmp/foo\n    perl Makefile.PL PREFIX=/tmp/foo"
            ],
            [
                "Para",
"Because of the complex nature of the prefixification logic, the behavior of PREFIX in MakeMaker has changed subtly over time. Module::Build's --prefix logic is equivalent to the PREFIX logic found in ExtUtils::MakeMaker 6.30."
            ],
            [
                "Para",
"The maintainers of MakeMaker do understand the troubles with the PREFIX mechanism, and added INSTALL_BASE support in version 6.31 of MakeMaker, which was released in 2006."
            ],
            [
                "Para",
"If you don't need to retain compatibility with old versions (pre-6.31) of ExtUtils::MakeMaker or are starting a fresh Perl installation we recommend you use install_base instead (and INSTALL_BASE in ExtUtils::MakeMaker). See \"Installing in the same location as ExtUtils::MakeMaker\" in Module::Build::Cookbook for further information."
            ]
        ],
        [ "head1", "COMPARISON" ],
        [
            "Para",
"A comparison between Module::Build and other CPAN distribution installers."
        ],
        [
            "over-bullet",
            [
                "item-bullet",
                "ExtUtils::MakeMaker",
                " requires ",
                "make",
                " and use of a ",
                "Makefile",
                ". ",
                "Module::Build",
                " does not, nor do other pure-perl installers following the ",
                "Build.PL",
                " spec such as ",
                "Module::Build::Tiny",
". In practice, this is usually not an issue for the end user, as ",
                "make",
" is already required to install most CPAN modules, even on Windows."
            ],
            [
                "item-bullet",
                "ExtUtils::MakeMaker",
" has been a core module in every version of Perl 5, and must maintain compatibility to install the majority of CPAN modules. ",
                "Module::Build",
" was added to core in Perl 5.10 and removed from core in Perl 5.20, and (like ",
                "ExtUtils::MakeMaker",
") is only updated to fix critical issues and maintain compatibility. ",
                "Module::Build",
                " and other non-core installers like ",
                "Module::Build::Tiny",
                " are installed from CPAN by declaring themselves as a ",
                "configure",
" phase prerequisite, and in this way any installer can be used in place of ",
                "ExtUtils::MakeMaker",
                "."
            ],
            [
                "item-bullet",
                "Customizing the build process with ",
                "ExtUtils::MakeMaker",
                " involves overriding certain methods that form the ",
                "Makefile",
                " by defining the subs in the ",
                "MY::",
                " namespace, requiring in-depth knowledge of ",
                "Makefile",
", but allowing targeted customization of the entire build. Customizing ",
                "Module::Build",
                " involves subclassing ",
                "Module::Build",
" itself, adding or overriding pure-perl methods that represent build actions, which are invoked as arguments passed to the generated ",
                "./Build",
" script. This is a simpler concept but requires redefining the standard build actions to invoke your customizations. ",
                "Module::Build::Tiny",
                " does not allow for customization."
            ],
            [
                "item-bullet",
                "Module::Build",
" provides more features and a better experience for distribution authors than ",
                "ExtUtils::MakeMaker",
". However, tools designed specifically for authoring, such as ",
                "Dist::Zilla",
                " and its spinoffs ",
                "Dist::Milla",
                " and ",
                "Minilla",
", provide these features and more, and generate a configure script (",
                "Makefile.PL",
                "/",
                "Build.PL",
") that will use any of the various installers separately on the end user side. ",
                "App::ModuleBuildTiny",
" is an alternative standalone authoring tool for distributions using ",
                "Module::Build::Tiny",
                ", which requires only a simple two-line ",
                "Build.PL",
                "."
            ]
        ],
        [ "head1", "TO DO" ],
        [
            "Para",
"The current method of relying on time stamps to determine whether a derived file is out of date isn't likely to scale well, since it requires tracing all dependencies backward, it runs into problems on NFS, and it's just generally flimsy. It would be better to use an MD5 signature or the like, if available. See cons for an example."
        ],
        [
            "Verbatim",
            " - append to perllocal.pod\n - add a 'plugin' functionality"
        ],
        [ "head1", "AUTHOR" ],
        [ "Para",  "Ken Williams <kwilliams\@cpan.org>" ],
        [
            "Para",
"Development questions, bug reports, and patches should be sent to the Module-Build mailing list at <module-build\@perl.org>."
        ],
        [
            "Para",
"Bug reports are also welcome at <http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build>."
        ],
        [
            "Para",
"The latest development version is available from the Git repository at <https://github.com/Perl-Toolchain-Gang/Module-Build>"
        ],
        [ "head1", "COPYRIGHT" ],
        [
            "Para",
            "Copyright (c) 2001-2006 Ken Williams. All rights reserved."
        ],
        [
            "Para",
"This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself."
        ],
        [ "head1", "SEE ALSO" ],
        [
            "Para",
"perl(1), Module::Build::Cookbook, Module::Build::Authoring, Module::Build::API, ExtUtils::MakeMaker"
        ],
        [ "Para", "META.yml Specification: CPAN::Meta::Spec" ],
        [ "Para", "http://www.dsmit.com/cons/" ],
        [ "Para", "http://search.cpan.org/dist/PerlBuildSystem/" ]
    ]

}

sub expected_tree {
    [
        {
            "tag"  => "Para",
            "text" =>
"bindoc binhtml destdir distcheck distclean distdir distmeta distsign disttest fakeinstall html installdirs installsitebin installsitescript installvendorbin installvendorscript libdoc libhtml pardist ppd ppmdist realclean skipcheck testall testcover testdb testpod testpodcoverage versioninstall"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" => "Module::Build - Build and install Perl modules"
                }
            ],
            "tag"  => "head1",
            "text" => "NAME"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
                      "Standard process for building & installing modules:"
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  perl Build.PL\n  ./Build\n  ./Build test\n  ./Build install"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Or, if you're on a platform (like DOS or Windows) that doesn't require the \"./\" notation, you can do this:"
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
                      "  perl Build.PL\n  Build\n  Build test\n  Build install"
                }
            ],
            "tag"  => "head1",
            "text" => "SYNOPSIS"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"Module::Build is a system for building, testing, and installing Perl modules. It is meant to be an alternative to ExtUtils::MakeMaker. Developers may alter the behavior of the module through subclassing. It also does not require a make on your system - most of the Module::Build code is pure-perl and written in a very cross-platform way."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"See \"COMPARISON\" for more comparisons between Module::Build and other installer tools."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"To install Module::Build, and any other module that uses Module::Build for its installation process, do the following:"
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  perl Build.PL       # 'Build.PL' script creates the 'Build' script\n  ./Build             # Need ./ to ensure we're using this \"Build\" script\n  ./Build test        # and not another one that happens to be in the PATH\n  ./Build install"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"This illustrates initial configuration and the running of three 'actions'. In this case the actions run are 'build' (the default action), 'test', and 'install'. Other actions defined so far include:"
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
"  build                          manifest\n  clean                          manifest_skip\n  code                           manpages\n  config_data                    pardist\n  diff                           ppd\n  dist                           ppmdist\n  distcheck                      prereq_data\n  distclean                      prereq_report\n  distdir                        pure_install\n  distinstall                    realclean\n  distmeta                       retest\n  distsign                       skipcheck\n  disttest                       test\n  docs                           testall\n  fakeinstall                    testcover\n  help                           testdb\n  html                           testpod\n  install                        testpodcoverage\n  installdeps                    versioninstall"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"You can run the 'help' action for a complete list of actions."
                }
            ],
            "tag"  => "head1",
            "text" => "DESCRIPTION"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"The documentation for Module::Build is broken up into sections:"
                },
                {
                    "kids" => [
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is the document you are currently reading. It describes basic usage and background information. Its main purpose is to assist the user who wants to learn how to invoke and control Module::Build scripts at the command line."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "General Usage (Module::Build)"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This document describes the structure and organization of Module::Build, and the relevant concepts needed by authors who are writing Build.PL scripts for a distribution or controlling Module::Build processes programmatically."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" =>
                              "Authoring Reference (Module::Build::Authoring)"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is a reference to the Module::Build API."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "API Reference (Module::Build::API)"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This document demonstrates how to accomplish many common tasks. It covers general command line usage and authoring of Build.PL scripts. Includes working examples."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "Cookbook (Module::Build::Cookbook)"
                        }
                    ],
                    "text" => "",
                    "tag"  => "over-text",
                }
            ],
            "tag"  => "head1",
            "text" => "GUIDE TO DOCUMENTATION"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"There are some general principles at work here. First, each task when building a module is called an \"action\". These actions are listed above; they correspond to the building, testing, installing, packaging, etc., tasks."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Second, arguments are processed in a very systematic way. Arguments are always key=value pairs. They may be specified at perl Build.PL time (i.e. perl Build.PL destdir=/my/secret/place), in which case their values last for the lifetime of the Build script. They may also be specified when executing a particular action (i.e. Build test verbose=1), in which case their values last only for the lifetime of that command. Per-action command line parameters take precedence over parameters specified at perl Build.PL time."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"The build process also relies heavily on the Config.pm module. If the user wishes to override any of the values in Config.pm, she may specify them like so:"
                },
                {
                    "tag"  => "Verbatim",
                    "text" => "  perl Build.PL --config cc=gcc --config ld=gcc"
                },
                {
                    "tag"  => "Para",
                    "text" =>
                      "The following build actions are provided by default."
                },
                {
                    "kids" => [
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.01]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you run the Build script without any arguments, it runs the build action, which in turn runs the code and docs actions."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is analogous to the MakeMaker make all target."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "build"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.01]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action will clean up any files that the build process may have created, including the blib/ directory (but not including the _build/ directory and the Build script itself)."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "clean"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.20]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
                                      "This action builds your code base."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"By default it just creates a blib/ directory and copies any .pm and .pod files from your lib/ directory into the blib/ directory. It also compiles any .xs files from lib/ and places them in blib/. Of course, you need a working C compiler (probably the same one that built perl itself) for the compilation to work properly."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The code action also runs any .PL files in your lib/ directory. Typically these create other files, named the same but without the .PL ending. For example, a file lib/Foo/Bar.pm.PL could create the file lib/Foo/Bar.pm. The .PL files are processed first, so any .pm files (or other kinds that we deal with) will get copied correctly."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "code"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.26]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "..."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "config_data"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.14]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action will compare the files about to be installed with their installed counterparts. For .pm and .pod files, a diff will be shown (this currently requires a 'diff' program to be in your PATH). For other files like compiled binary files, we simply report whether they differ."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"A flags parameter may be passed to the action, which will be passed to the 'diff' program. Consult your 'diff' documentation for the parameters it will accept - a good one is -u:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" => "  ./Build diff flags=-u"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "diff"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.02]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action is helpful for module authors who want to package up their module for source distribution through a medium like CPAN. It will create a tarball of the files listed in MANIFEST and compress the tarball using GZIP compression."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"By default, this action will use the Archive::Tar module. However, you can force it to use binary \"tar\" and \"gzip\" executables by supplying an explicit tar (and optional gzip) parameter:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ./Build dist --tar C:\\path\\to\\tar.exe --gzip C:\\path\\to\\zip.exe"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "dist"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Reports which files are in the build directory but not in the MANIFEST file, and vice versa. (See \"manifest\" for details.)"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distcheck"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Performs the 'realclean' action and then the 'distcheck' action."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distclean"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Creates a \"distribution directory\" named \$dist_name-\$dist_version (if that directory already exists, it will be removed first), then copies all the files listed in the MANIFEST file to that directory. This directory is what the distribution tarball is created from."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distdir"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.37]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Performs the 'distdir' action, then switches into that directory and runs a perl Build.PL, followed by the 'build' and 'install' actions in that directory. Use PERL_MB_OPT or .modulebuildrc to set options that should be applied during subprocesses"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distinstall"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.21]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Creates the META.yml file that describes the distribution."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"META.yml is a file containing various bits of metadata about the distribution. The metadata includes the distribution name, version, abstract, prerequisites, license, and various other data about the distribution. This file is created as META.yml in a simplified YAML format."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"META.yml file must also be listed in MANIFEST - if it's not, a warning will be issued."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The current version of the META.yml specification can be found on CPAN as CPAN::Meta::Spec."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distmeta"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.16]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Uses Module::Signature to create a SIGNATURE file for your distribution, and adds the SIGNATURE file to the distribution's MANIFEST."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "distsign"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Performs the 'distdir' action, then switches into that directory and runs a perl Build.PL, followed by the 'build' and 'test' actions in that directory. Use PERL_MB_OPT or .modulebuildrc to set options that should be applied during subprocesses"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "disttest"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.20]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This will generate documentation (e.g. Unix man pages and HTML documents) for any installable items under blib/ that contain POD. If there are no bindoc or libdoc installation targets defined (as will be the case on systems that don't support Unix manpages) no action is taken for manpages. If there are no binhtml or libhtml installation targets defined no action is taken for HTML documents."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "docs"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.02]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is just like the install action, but it won't actually do anything, it will just report what it would have done if you had actually run the install action."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "fakeinstall"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.03]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action will simply print out a message that is meant to help you use the build process. It will show you a list of available build actions too."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"With an optional argument specifying an action name (e.g. Build help test), the 'help' action will show you any POD documentation it can find for that action."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "help"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.26]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This will generate HTML documentation for any binary or library files under blib/ that contain POD. The HTML documentation will only be installed if the install paths can be determined from values in Config.pm. You can also supply or override install paths on the command line by specifying install_path values for the binhtml and/or libhtml installation targets."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"With an optional html_links argument set to a false value, you can skip the search for other documentation to link to, because that can waste a lot of time if there aren't any links to generate anyway:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" => "  ./Build html --html_links 0"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "html"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.01]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action will use ExtUtils::Install to install the files from blib/ into the system. See \"INSTALL PATHS\" for details about how Module::Build determines where to install things, and how to influence this process."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want the installation process to look around in \@INC for other versions of the stuff you're installing and try to delete it, you can use the uninst parameter, which tells ExtUtils::Install to do so:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" => "  ./Build install uninst=1"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This can be a good idea, as it helps prevent multiple versions of a module from being present on your system, which can be a confusing situation indeed."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "install"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.36]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action will use the cpan_client parameter as a command to install missing prerequisites. You will be prompted whether to install optional dependencies."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The cpan_client option defaults to 'cpan' but can be set as an option or in .modulebuildrc. It must be a shell command that takes a list of modules to install as arguments (e.g. 'cpanp -i' for CPANPLUS). If the program part is a relative path (e.g. 'cpan' or 'cpanp'), it will be located relative to the perl program that executed Build.PL."
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  /opt/perl/5.8.9/bin/perl Build.PL\n  ./Build installdeps --cpan_client 'cpanp -i'\n  # installs to 5.8.9"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "installdeps"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is an action intended for use by module authors, not people installing modules. It will bring the MANIFEST up to date with the files currently present in the distribution. You may use a MANIFEST.SKIP file to exclude certain files or directories from inclusion in the MANIFEST. MANIFEST.SKIP should contain a bunch of regular expressions, one per line. If a file in the distribution directory matches any of the regular expressions, it won't be included in the MANIFEST."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The following is a reasonable MANIFEST.SKIP starting point, you can add your own stuff to it:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ^_build\n  ^Build\$\n  ^blib\n  ~\$\n  \\.bak\$\n  ^MANIFEST\\.SKIP\$\n  CVS"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"See the \"distcheck\" and \"skipcheck\" actions if you want to find out what the manifest action would do, without actually doing anything."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "manifest"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.3608]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is an action intended for use by module authors, not people installing modules. It will generate a boilerplate MANIFEST.SKIP file if one does not already exist."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "manifest_skip"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.28]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This will generate man pages for any binary or library files under blib/ that contain POD. The man pages will only be installed if the install paths can be determined from values in Config.pm. You can also supply or override install paths by specifying there values on the command line with the bindoc and libdoc installation targets."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "manpages"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.2806]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Generates a PAR binary distribution for use with PAR or PAR::Dist."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"It requires that the PAR::Dist module (version 0.17 and up) is installed on your system."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "pardist"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.20]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
                                      "Build a PPD file for your distribution."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action takes an optional argument codebase which is used in the generated PPD file to specify the (usually relative) URL of the distribution. By default, this value is the distribution name without any path information."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "Example:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ./Build ppd --codebase \"MSWin32-x86-multi-thread/Module-Build-0.21.tar.gz\""
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "ppd"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.23]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Generates a PPM binary distribution and a PPD description file. This action also invokes the ppd action, so it can accept the same codebase argument described under that action."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This uses the same mechanism as the dist action to tar & zip its output, so you can supply tar and/or gzip parameters to affect the result."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "ppmdist"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.32]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action prints out a Perl data structure of all prerequisites and the versions required. The output can be loaded again using eval(). This can be useful for external tools that wish to query a Build script for prerequisites."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "prereq_data"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.28]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action prints out a list of all prerequisites, the versions required, and the versions actually installed. This can be useful for reviewing the configuration of your system prior to a build, or when compiling data to send for a bug report."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "prereq_report"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.28]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action is identical to the install action. In the future, though, when install starts writing to the file \$(INSTALLARCHLIB)/perllocal.pod, pure_install won't, and that will be the only difference between them."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "pure_install"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.01]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This action is just like the clean action, but also removes the _build directory and the Build script. If you run the realclean action, you are essentially starting over, so you will have to re-create the Build script again."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "realclean"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.2806]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is just like the test action, but doesn't actually build the distribution first, and doesn't add blib/ to the load path, and therefore will test against a previously installed version of the distribution. This can be used to verify that a certain installed distribution still works, or to see whether newer versions of a distribution still pass the old regression tests, and so on."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "retest"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Reports which files are skipped due to the entries in the MANIFEST.SKIP file (See \"manifest\" for details)"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "skipcheck"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.01]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This will use Test::Harness or TAP::Harness to run any regression tests and report their results. Tests can be defined in the standard places: a file called test.pl in the top-level directory, or several files ending with .t in a t/ directory."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want tests to be 'verbose', i.e. show details of test execution rather than just summary information, pass the argument verbose=1."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want to run tests under the perl debugger, pass the argument debugger=1."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want to have Module::Build find test files with different file name extensions, pass the test_file_exts argument with an array of extensions, such as [qw( .t .s .z )]."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want test to be run by TAP::Harness, rather than Test::Harness, pass the argument tap_harness_args as an array reference of arguments to pass to the TAP::Harness constructor."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"In addition, if a file called visual.pl exists in the top-level directory, this file will be executed as a Perl script and its output will be shown to the user. This is a good place to put speed tests or other tests that don't use the Test::Harness format for output."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"To override the choice of tests to run, you may pass a test_files argument whose value is a whitespace-separated list of test scripts to run. This is especially useful in development, when you only want to run a single test to see whether you've squashed a certain bug yet:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ./Build test --test_files t/something_failing.t"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"You may also pass several test_files arguments separately:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ./Build test --test_files t/one.t --test_files t/two.t"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "or use a glob()-style pattern:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
                                      "  ./Build test --test_files 't/01-*.t'"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "test"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.2807]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"[Note: the 'testall' action and the code snippets below are currently in alpha stage, see http://www.nntp.perl.org/group/perl.module.build/2007/03/msg584.html ]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Runs the test action plus each of the test\$type actions defined by the keys of the test_types parameter."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Currently, you need to define the ACTION_test\$type method yourself and enumerate them in the test_types parameter."
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  my \$mb = Module::Build->subclass(\n    code => q(\n      sub ACTION_testspecial { shift->generic_test(type => 'special'); }\n      sub ACTION_testauthor  { shift->generic_test(type => 'author'); }\n    )\n  )->new(\n    ...\n    test_types  => {\n      special => '.st',\n      author  => ['.at', '.pt' ],\n    },\n    ..."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "testall"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.26]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Runs the test action using Devel::Cover, generating a code-coverage report showing which parts of the code were actually exercised during the tests."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"To pass options to Devel::Cover, set the \$DEVEL_COVER_OPTIONS environment variable:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  DEVEL_COVER_OPTIONS=-ignore,Build ./Build testcover"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "testcover"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.05]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is a synonym for the 'test' action with the debugger=1 argument."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "testdb"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.25]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This checks all the files described in the docs action and produces Test::Harness-style output. If you are a module author, this is useful to run before creating a new release."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "testpod"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.28]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This checks the pod coverage of the distribution and produces Test::Harness-style output. If you are a module author, this is useful to run before creating a new release."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "testpodcoverage"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" => "[version 0.16]"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"** Note: since only.pm is so new, and since we just recently added support for it here too, this feature is to be considered experimental. **"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you have the only.pm module installed on your system, you can use this action to install a module into the version-specific library trees. This means that you can have several versions of the same module installed and use a specific one like this:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" => "  use only MyModule => 0.55;"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"To override the default installation libraries in only::config, specify the versionlib parameter when you run the Build.PL script:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  perl Build.PL --versionlib /my/version/place/"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"To override which version the module is installed as, specify the version parameter when you run the Build.PL script:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" => "  perl Build.PL --version 0.50"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"See the only.pm documentation for more information on version-specific installs."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "versioninstall"
                        }
                    ],
                    "text" => "",
                    "tag"  => "over-text"
                }
            ],
            "tag"  => "head1",
            "text" => "ACTIONS"
        },
        {
            "kids" => [
                {
                    "kids" => [
                        {
                            "tag"  => "Para",
                            "text" =>
"The following options can be used during any invocation of Build.PL or the Build script, during any action. For information on other options specific to an action, see the documentation for the respective action."
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"NOTE: There is some preliminary support for options to use the more familiar long option style. Most options can be preceded with the -- long option prefix, and the underscores changed to dashes (e.g. --use-rcfile). Additionally, the argument to boolean options is optional, and boolean options can be negated by prefixing them with no or no- (e.g. --noverbose or --no-verbose)."
                        },
                        {
                            "kids" => [
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Suppress informative messages on output."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "quiet"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Display extra information about the Build on output. verbose will turn off quiet"
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "verbose"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Sets the cpan_client command for use with the installdeps action. See installdeps for more details."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "cpan_client"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Load the ~/.modulebuildrc option file. This option can be set to false to prevent the custom resource file from being loaded."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "use_rcfile"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Suppresses the check upon startup that the version of Module::Build we're now running under is the same version that was initially invoked when building the distribution (i.e. when the Build.PL script was first run). As of 0.3601, a mismatch results in a warning instead of a fatal error, so this option effectively just suppresses the warning."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "allow_mb_mismatch"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Prints Module::Build debugging information to STDOUT, such as a trace of executed build actions."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "debug"
                                }
                            ],
                            "text" => "",
                            "tag"  => "over-text"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "Command Line Options"
                },
                {
                    "kids" => [
                        {
                            "tag"  => "Para",
                            "text" => "[version 0.28]"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"When Module::Build starts up, it will look first for a file, \$ENV{HOME}/.modulebuildrc. If it's not found there, it will look in the .modulebuildrc file in the directories referred to by the environment variables HOMEDRIVE + HOMEDIR, USERPROFILE, APPDATA, WINDIR, SYS\$LOGIN. If the file exists, the options specified there will be used as defaults, as if they were typed on the command line. The defaults can be overridden by specifying new values on the command line."
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"The action name must come at the beginning of the line, followed by any amount of whitespace and then the options. Options are given the same as they would be on the command line. They can be separated by any amount of whitespace, including newlines, as long there is whitespace at the beginning of each continued line. Anything following a hash mark (#) is considered a comment, and is stripped before parsing. If more than one line begins with the same action name, those lines are merged into one set of options."
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"Besides the regular actions, there are two special pseudo-actions: the key * (asterisk) denotes any global options that should be applied to all actions, and the key 'Build_PL' specifies options to be applied when you invoke perl Build.PL."
                        },
                        {
                            "tag"  => "Verbatim",
                            "text" =>
"  *           verbose=1   # global options\n  diff        flags=-u\n  install     --install_base /home/ken\n              --install_path html=/home/ken/docs/html\n  installdeps --cpan_client 'cpanp -i'"
                        },
                        {
                            "tag"  => "Para",
                            "text" =>
"If you wish to locate your resource file in a different location, you can set the environment variable MODULEBUILDRC to the complete absolute path of the file containing your options."
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "Default Options File (.modulebuildrc)"
                },
                {
                    "kids" => [
                        {
                            "kids" => [
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" => "[version 0.28]"
                                        },
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Specifies an alternate location for a default options file as described above."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "MODULEBUILDRC"
                                },
                                {
                                    "kids" => [
                                        {
                                            "tag"  => "Para",
                                            "text" => "[version 0.36]"
                                        },
                                        {
                                            "tag"  => "Para",
                                            "text" =>
"Command line options that are applied to Build.PL or any Build action. The string is split as the shell would (e.g. whitespace) and the result is prepended to any actual command-line arguments."
                                        }
                                    ],
                                    "tag"  => "item-text",
                                    "text" => "PERL_MB_OPT"
                                }
                            ],
                            "text" => "",
                            "tag"  => "over-text"
                        }
                    ],
                    "tag"  => "head2",
                    "text" => "Environment variables"
                }
            ],
            "tag"  => "head1",
            "text" => "OPTIONS"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" => "[version 0.19]"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"When you invoke Module::Build's build action, it needs to figure out where to install things. The nutshell version of how this works is that default installation locations are determined from Config.pm, and they may be overridden by using the install_path parameter. An install_base parameter lets you specify an alternative installation root like /home/foo, and a destdir lets you specify a temporary installation directory like /tmp/install in case you want to create bundled-up installable packages."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Natively, Module::Build provides default installation locations for the following types of installable items:"
                },
                {
                    "kids" => [
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Usually pure-Perl module files ending in .pm."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "lib"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"\"Architecture-dependent\" module files, usually produced by compiling XS, Inline, or similar code."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "arch"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Programs written in pure Perl. In order to improve reuse, try to make these as small as possible - put the code into modules whenever possible."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "script"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"\"Architecture-dependent\" executable programs, i.e. compiled C code or something. Pretty rare to see this in a perl distribution, but it happens."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "bin"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Documentation for the stuff in script and bin. Usually generated from the POD in those files. Under Unix, these are manual pages belonging to the 'man1' category."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "bindoc"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Documentation for the stuff in lib and arch. This is usually generated from the POD in .pm files. Under Unix, these are manual pages belonging to the 'man3' category."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "libdoc"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is the same as bindoc above, but applies to HTML documents."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "binhtml"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This is the same as libdoc above, but applies to HTML documents."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "libhtml"
                        }
                    ],
                    "text" => "",
                    "tag"  => "over-text"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Four other parameters let you control various aspects of how installation paths are determined:"
                },
                {
                    "kids" => [
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The default destinations for these installable things come from entries in your system's Config.pm. You can select from three different sets of default locations by setting the installdirs parameter as follows:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"                          'installdirs' set to:\n                   core          site                vendor\n\n              uses the following defaults from Config.pm:\n\n  lib     => installprivlib  installsitelib      installvendorlib\n  arch    => installarchlib  installsitearch     installvendorarch\n  script  => installscript   installsitescript   installvendorscript\n  bin     => installbin      installsitebin      installvendorbin\n  bindoc  => installman1dir  installsiteman1dir  installvendorman1dir\n  libdoc  => installman3dir  installsiteman3dir  installvendorman3dir\n  binhtml => installhtml1dir installsitehtml1dir installvendorhtml1dir [*]\n  libhtml => installhtml3dir installsitehtml3dir installvendorhtml3dir [*]\n\n  * Under some OS (eg. MSWin32) the destination for HTML documents is\n    determined by the C<Config.pm> entry C<installhtmldir>."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The default value of installdirs is \"site\". If you're creating vendor distributions of module packages, you may want to do something like this:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
                                      "  perl Build.PL --installdirs vendor"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "or"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
                                      "  ./Build install --installdirs vendor"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you're installing an updated version of a module that was included with perl itself (i.e. a \"core module\"), then you may set installdirs to \"core\" to overwrite the module in its present location."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"(Note that the 'script' line is different from MakeMaker - unfortunately there's no such thing as \"installsitescript\" or \"installvendorscript\" entry in Config.pm, so we use the \"installsitebin\" and \"installvendorbin\" entries to at least get the general location right. In the future, if Config.pm adds some more appropriate entries, we'll start using those.)"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "installdirs"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Once the defaults have been set, you can override them."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"On the command line, that would look like this:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  perl Build.PL --install_path lib=/foo/lib --install_path arch=/foo/lib/arch"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "or this:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  ./Build install --install_path lib=/foo/lib --install_path arch=/foo/lib/arch"
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "install_path"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"You can also set the whole bunch of installation paths by supplying the install_base parameter to point to a directory on your system. For instance, if you set install_base to \"/home/ken\" on a Linux system, you'll install as follows:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"  lib     => /home/ken/lib/perl5\n  arch    => /home/ken/lib/perl5/i386-linux\n  script  => /home/ken/bin\n  bin     => /home/ken/bin\n  bindoc  => /home/ken/man/man1\n  libdoc  => /home/ken/man/man3\n  binhtml => /home/ken/html\n  libhtml => /home/ken/html"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Note that this is different from how MakeMaker's PREFIX parameter works. install_base just gives you a default layout under the directory you specify, which may have little to do with the installdirs=site layout."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The exact layout under the directory you specify may vary by system - we try to do the \"sensible\" thing on each platform."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "install_base"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you want to install everything into a temporary directory first (for instance, if you want to create a directory tree that a package manager like rpm or dpkg could create a package from), you can use the destdir parameter:"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
                                      "  perl Build.PL --destdir /tmp/foo"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "or"
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
                                      "  ./Build install --destdir /tmp/foo"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"This will effectively install to \"/tmp/foo/\$sitelib\", \"/tmp/foo/\$sitearch\", and the like, except that it will use File::Spec to make the pathnames work correctly on whatever platform you're installing on."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "destdir"
                        },
                        {
                            "kids" => [
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Provided for compatibility with ExtUtils::MakeMaker's PREFIX argument. prefix should be used when you want Module::Build to install your modules, documentation, and scripts in the same place as ExtUtils::MakeMaker's PREFIX mechanism."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" => "The following are equivalent."
                                },
                                {
                                    "tag"  => "Verbatim",
                                    "text" =>
"    perl Build.PL --prefix /tmp/foo\n    perl Makefile.PL PREFIX=/tmp/foo"
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"Because of the complex nature of the prefixification logic, the behavior of PREFIX in MakeMaker has changed subtly over time. Module::Build's --prefix logic is equivalent to the PREFIX logic found in ExtUtils::MakeMaker 6.30."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"The maintainers of MakeMaker do understand the troubles with the PREFIX mechanism, and added INSTALL_BASE support in version 6.31 of MakeMaker, which was released in 2006."
                                },
                                {
                                    "tag"  => "Para",
                                    "text" =>
"If you don't need to retain compatibility with old versions (pre-6.31) of ExtUtils::MakeMaker or are starting a fresh Perl installation we recommend you use install_base instead (and INSTALL_BASE in ExtUtils::MakeMaker). See \"Installing in the same location as ExtUtils::MakeMaker\" in Module::Build::Cookbook for further information."
                                }
                            ],
                            "tag"  => "item-text",
                            "text" => "prefix"
                        }
                    ],
                    "text" => "",
                    "tag"  => "over-text"
                }
            ],
            "tag"  => "head1",
            "text" => "INSTALL PATHS"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"A comparison between Module::Build and other CPAN distribution installers."
                },
                {
                    "kids" => [
                        {
                            "tag"  => "item-bullet",
                            "text" =>
"ExtUtils::MakeMaker requires make and use of a Makefile. Module::Build does not, nor do other pure-perl installers following the Build.PL spec such as Module::Build::Tiny. In practice, this is usually not an issue for the end user, as make is already required to install most CPAN modules, even on Windows."
                        },
                        {
                            "tag"  => "item-bullet",
                            "text" =>
"ExtUtils::MakeMaker has been a core module in every version of Perl 5, and must maintain compatibility to install the majority of CPAN modules. Module::Build was added to core in Perl 5.10 and removed from core in Perl 5.20, and (like ExtUtils::MakeMaker) is only updated to fix critical issues and maintain compatibility. Module::Build and other non-core installers like Module::Build::Tiny are installed from CPAN by declaring themselves as a configure phase prerequisite, and in this way any installer can be used in place of ExtUtils::MakeMaker."
                        },
                        {
                            "tag"  => "item-bullet",
                            "text" =>
"Customizing the build process with ExtUtils::MakeMaker involves overriding certain methods that form the Makefile by defining the subs in the MY:: namespace, requiring in-depth knowledge of Makefile, but allowing targeted customization of the entire build. Customizing Module::Build involves subclassing Module::Build itself, adding or overriding pure-perl methods that represent build actions, which are invoked as arguments passed to the generated ./Build script. This is a simpler concept but requires redefining the standard build actions to invoke your customizations. Module::Build::Tiny does not allow for customization."
                        },
                        {
                            "tag"  => "item-bullet",
                            "text" =>
"Module::Build provides more features and a better experience for distribution authors than ExtUtils::MakeMaker. However, tools designed specifically for authoring, such as Dist::Zilla and its spinoffs Dist::Milla and Minilla, provide these features and more, and generate a configure script (Makefile.PL/Build.PL) that will use any of the various installers separately on the end user side. App::ModuleBuildTiny is an alternative standalone authoring tool for distributions using Module::Build::Tiny, which requires only a simple two-line Build.PL."
                        }
                    ],
                    "text" => "",
                    "tag"  => "over-bullet"
                }
            ],
            "tag"  => "head1",
            "text" => "COMPARISON"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"The current method of relying on time stamps to determine whether a derived file is out of date isn't likely to scale well, since it requires tracing all dependencies backward, it runs into problems on NFS, and it's just generally flimsy. It would be better to use an MD5 signature or the like, if available. See cons for an example."
                },
                {
                    "tag"  => "Verbatim",
                    "text" =>
" - append to perllocal.pod\n - add a 'plugin' functionality"
                }
            ],
            "tag"  => "head1",
            "text" => "TO DO"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" => "Ken Williams <kwilliams\@cpan.org>"
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Development questions, bug reports, and patches should be sent to the Module-Build mailing list at <module-build\@perl.org>."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"Bug reports are also welcome at <http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build>."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"The latest development version is available from the Git repository at <https://github.com/Perl-Toolchain-Gang/Module-Build>"
                }
            ],
            "tag"  => "head1",
            "text" => "AUTHOR"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"Copyright (c) 2001-2006 Ken Williams. All rights reserved."
                },
                {
                    "tag"  => "Para",
                    "text" =>
"This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself."
                }
            ],
            "tag"  => "head1",
            "text" => "COPYRIGHT"
        },
        {
            "kids" => [
                {
                    "tag"  => "Para",
                    "text" =>
"perl(1), Module::Build::Cookbook, Module::Build::Authoring, Module::Build::API, ExtUtils::MakeMaker"
                },
                {
                    "tag"  => "Para",
                    "text" => "META.yml Specification: CPAN::Meta::Spec"
                },
                {
                    "tag"  => "Para",
                    "text" => "http://www.dsmit.com/cons/"
                },
                {
                    "tag"  => "Para",
                    "text" => "http://search.cpan.org/dist/PerlBuildSystem/"
                }
            ],
            "tag"  => "head1",
            "text" => "SEE ALSO"
        }
    ]
}

sub expected_find_title {
    "Module::Build - Build and install Perl modules";
}

sub expected_find_events {
    []
}

sub define_cases {
    []
}

sub define_find_cases {
    [

        # Item-text
        {
            name            => "build options",
            find            => "head1=ACTIONS[0]/item-text",
            expected_struct => [
                {
                    tag  => "head1",
                    text => "ACTIONS",
                    nth  => 0,
                },
                {
                    tag => "item-text",
                },
            ],
            expected_find => [
                "build",           "clean",
                "code",            "config_data",
                "diff",            "dist",
                "distcheck",       "distclean",
                "distdir",         "distinstall",
                "distmeta",        "distsign",
                "disttest",        "docs",
                "fakeinstall",     "help",
                "html",            "install",
                "installdeps",     "manifest",
                "manifest_skip",   "manpages",
                "pardist",         "ppd",
                "ppmdist",         "prereq_data",
                "prereq_report",   "pure_install",
                "realclean",       "retest",
                "skipcheck",       "test",
                "testall",         "testcover",
                "testdb",          "testpod",
                "testpodcoverage", "versioninstall",
            ],
        },

        # Same (over-text is optional since it just has kids)
        {
            name            => "build options",
            find            => "head1=ACTIONS[0]/over-text/item-text",
            expected_struct => [
                {
                    tag  => "head1",
                    text => "ACTIONS",
                    nth  => 0,
                },
                {
                    tag => "over-text",
                },
                {
                    tag => "item-text",
                },
            ],
            expected_find => [
                "build",           "clean",
                "code",            "config_data",
                "diff",            "dist",
                "distcheck",       "distclean",
                "distdir",         "distinstall",
                "distmeta",        "distsign",
                "disttest",        "docs",
                "fakeinstall",     "help",
                "html",            "install",
                "installdeps",     "manifest",
                "manifest_skip",   "manpages",
                "pardist",         "ppd",
                "ppmdist",         "prereq_data",
                "prereq_report",   "pure_install",
                "realclean",       "retest",
                "skipcheck",       "test",
                "testall",         "testcover",
                "testdb",          "testpod",
                "testpodcoverage", "versioninstall",
            ],
        },
    ]
}

