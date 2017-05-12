# -*- perl -*-
#
# Test::AutoBuild by Dan Berrange, Richard Jones
#
# Copyright (C) 2002 Dan Berrange, Richard Jones
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id$

=pod

=head1 NAME

Test::AutoBuild - Automated build engine controller

=head1 SYNOPSIS

  use Test::AutoBuild;
  use Config::Record;

  my $config = new Config::Record (file => $filename);
  my $builder = new Test::AutoBuild (config => $config);

  my ($status, $log) = $builder->run($timestamp);

  if ($status) {
     print STDERR $log, "\n";
  }

  exit $status;

=head1 DESCRIPTION

This module provides the build controller, tieing together various
subsystems to form an integrated engine. It is wholely reponsible
for loading the various runtime objects (stages, modules, repositories,
package types, monitors, publishers) based on their definitions in the
configuration file and then invoking the build. This object does not,
however, contain any logic pertaining to how the build is run, since
this is all delegated to the stages defined in the configuration file.

=head1 SETUP

After installing the modules, the first setup step is to create
an unprivileged user to run the build as. By convention the
user is called 'builder', in a similarly named group and a home
directory of /var/lib/builder. So as root, execute the following
commands:

 $ groupadd builder
 $ useradd -g builder -m -d /var/lib/builder builder

NB, with the combined contents of the source checkout, the cache
and the virtual installed root, and HTTP site, the disk space
requirements can be pretty large for any non-trivial software.
Based on the applications being built, anywhere between 100MB
and many GB of disk space make be neccessary. For Linux, making
/var/lib/builder a dedicated partition with LVM (Logical Volume
Manager) will enable additional space to be easily grafted on
without requiring a re-build.

The next step is to create the basic directory structure within
the user's home directory for storing the various files. There
are directories required for storing the source code, a virtual
root directory for installing files, a build archive, package
spool directories, and publishing directories for HTTP and FTP
servers. To facilitate quick setup, a script is provided to
create all the required directories. Run this script as the
unprivileged user

  $ su - builder
  $ auto-build-make-root /var/lib/builder

It will display a list of all the directories it creates, but
for advance reference, they are

   /var/lib/builder/install-root
   /var/lib/builder/source-root
   /var/lib/builder/log-root
   /var/lib/builder/build-archive

   /var/lib/builder/package-root
   /var/lib/builder/package-root/rpm
   /var/lib/builder/package-root/rpm/BUILD
   /var/lib/builder/package-root/rpm/RPMS
   /var/lib/builder/package-root/rpm/RPMS/noarch
   /var/lib/builder/package-root/rpm/RPMS/i386
   /var/lib/builder/package-root/rpm/RPMS/i486
   /var/lib/builder/package-root/rpm/RPMS/i586
   /var/lib/builder/package-root/rpm/RPMS/i686
   /var/lib/builder/package-root/rpm/RPMS/x86_64
   /var/lib/builder/package-root/rpm/RPMS/ia32e
   /var/lib/builder/package-root/rpm/RPMS/ia64
   /var/lib/builder/package-root/rpm/RPMS/sparc
   /var/lib/builder/package-root/rpm/SPECS
   /var/lib/builder/package-root/rpm/SOURCES
   /var/lib/builder/package-root/rpm/SRPMS
   /var/lib/builder/package-root/zips
   /var/lib/builder/package-root/tars
   /var/lib/builder/package-root/debian


=head1 CONFIGURATION

The configuration file determines all aspects of operation
of the build engine, from the modules built, through the
package types detected, archival method, to build workflow
stages, and much more. The example build configuration file
installed by default should provide a fully functional build
instance running under /var/lib/builder, which is capable of
building Test-AutoBuild, versions 1.0.x and 1.1.x, along
with the AutoBuild-Applet. A good sanity check for correct
installation, is to ensure that the example build configuration
succeeds when run.

The configuration file is split into a number of logical
groups, which will be considered in turn below. The minimal
level of configuration to get started involves editing the
list of modules, along with the source repository definitions.

=head2 General runtime

The following options define miscellaneous aspects of the
build engine runtime environment.

=over 4

=item root

The C<root> option is a grouping under which core directories
of the build engine are defined.

  root = {
    ... nested options...
  }

The following nested options are permitted with the C<root> option

=over 4

=item source

The location into which modules' source code will be checked
out from version control. If not specified this option defaults
to the location $HOME/source-root

  root = {
    ...
    source = /var/lib/builder/source-root
    ...
  }

Thus, a module with a name of 'dbus-dev' would be checked out
into the directory

  /var/lib/builder/source-root/dbus-dev

=item install

The location into which a module's build process would install
files to be used by dependant modules later in the build cycle.
This location is made available to a module's build control
file via the environment variable $AUTOBUILD_INSTALL_ROOT. If
not specified this option defaults to the location $HOME/install-root

  root = {
    ...
    install = /var/lib/builder/install-root
    ...
  }

Consider, for example, a module 'mozilla' which depends on a
library 'openssl'. The 'openssl' module would be listed as a
dependant module so that it is built first. The build of 'openssl'
would install itself into the install root, perhaps by passing
the 'prefix' argument to a configure script:

  ./configure --prefix=$AUTOBUILD_INSTALL_ROOT

The later build of mozilla, would then build against this version
of openssl, by using

  ./configure --with-openssl=$AUTOBUILD_INSTALL_ROOT

=item package

The location in which a module's build process will create any
binary packages it generates, for example RPMs, or Debian packages.
The packages are typically placed into a package type specific
sub-directory. This location is made available to a module's
build control file via the environment variable $AUTOBUILD_PACKAGE_ROOT.
If not specified, this option defaults to the location $HOME/package-root

  root = {
    ...
    package = /var/lib/builder/package-root
    ...
  }

Consider, for example, a module which generates an RPM, of itself.
The $AUTOBUILD_PACKAGE_ROOT directory would be used to set the
'_topdir' macro for the RPM build process

  rpmbuild --define '_topdir $AUTOBUILD_PACKAGE_ROOT/rpm' -ta foo.tar.gz

=item log

The location in which the output from a module's build control
file will be spooled during execution. If not specified, this
option defaults to the location $HOME/log-root. The control file's standard
output and error streams will be combined into one.

  root = {
    ...
    log = /var/lib/builder/log-root
    ...
  }

=back

=item admin-email

The email address of the build engine administrator, typically linked
from the bottom of the HTML status pages. This is also the address
spammed with build status alerts if the L<Test::AutoBuild::Stage::EmailAlert>
module is in use.

  admin-email = admin@example.com

=item admin-name

The full name of the build engine administrator, typically displayed
on the bottom of the HTML status pages.

  admin-name = John Doe

=item log4perl

A configuration block controlling the output of debug information
during execution of the build. The data here is passed straight
through to the C<init> method in the L<Log::Log4perl> module, so
consult that module's manual page for possible configuration options.
The example setting, enables display of progress through the build
workflow. To get maximum possible debug information, change the
C<log4perl.rootLogger> option to 'DEBUG' instead of 'WARN'.

  log4perl = {
    log4perl.rootLogger = WARN, Screen

    # To get progress updates
    log4perl.logger.Test.AutoBuild.Monitor.Log4perl = INFO

    log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr = 1
    log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
  }

=item counter

This configuration block determines the module used to generate the unique
build cycle counter.

  counter = {
    ..nested options..
  }

The nested options allowed within this block are

=over 4

=item module

The full package name of the subclass of L<Test::AutoBuild::Counter>
used to generate the build cycle counter. Consult that module for a
list of known implementations. The exmaple configuration sets the
build counter to match the timestamp taken at the start of the build
cycle.

  module = Test::AutoBuild::Counter::Timestamp

=item options

This is defines a set of options as key, value pairs which are passed
to the counter object created. The valid keys for this are specific
to the package specified in the C<module> parameter above, so consult
the manual page corresponding to the module defined there. If using
the C<Test::AutoBuild::Counter::ChangeList> class, and there is a
source repository named, C<mysvn>, one would set an option such as

  options = {
    repository = mysvn
  }

=back

=back

=head2 Source repositories

The C<repositories> configuration block, defines the source
repositories from which modules are checked out. The keys
in the block form the short name of the repository, and is
referenced later when defining the paths for modules' source
checkout

  repositories = {
    myrepo = {
      ... definition of myrepo ...
    }
    otherrepo = {
      ... definition of otherrepo ...
    }
  }

Within each repository definition the following options are
supported

=over 4

=item label

The free-text display name of the repository, typically used
in the HTML status pages.

=item module

The full package name of a subclass of C<Test::AutoBuild::Repository>
which implements the checkout procedure for the repository type. There
are repository types for common version control systems such as Subversion,
CVS, Perforce and GNUArch, as well as a simple non-versioned repository.
Refer to the L<Test::AutoBuild::Repository> module for a list of known
repository types and their corresponding package names.

  module = Test::AutoBuild::Repository::Subversion

=item env

Lists a set of environment variables which will be set whenever running
any repository commands. The possible environment variable names vary
according to the type of repository, so refer to the manual page for the
repository module defined in the C<module> option. For example, the CVS
repository type uses the CVSROOT environment variable to specify the
repository location.

  env = {
    CVSROOT = :pserver:nonymous@cvs.gna.org:/cvs/testautobuild
  }

=item option

A set of configuration options specific to the type of repository
configure. Again, refer to the manual page for the repository module
defined in the C<module> option. For example, the GNU Arch repository
type supports the 'archive-name' option

  options = {
    archive-name = lord@emf.net--2004
  }

=back

=head2 Modules

The C<modules> configuration block defines the list of modules to be
checked out of source control and built. The keys in the block form
the short names for the modules, used, for example, in creating filenames
for assets relating to the module, and the name of the checkout directory
under the source root. If building multiple branches of a module, it is
common to post-fix the module name with a version / branch name.

  modules = {
    mymod-1.0 = {
      .. definition of mymod version 1.0..
    }
    mymod-dev = {
      .. definition of mymod development snapshot...
    }
  }

Within the configuration block of an individual module the following
options are permitted

=over 4

=item label

The free-text display name for the module, typically used in HTML status
pages, and email alerts.

  label = Test-AutoBuild (Development branch)

=item source

This block defines the repository containing the source to be checked
out for the module. There are two keys in the block, the value associated
with the key C<repository>, is the name of a repository previously defined
in the config file. The value associated with the key C<path> is the path
to checkout within the repository. The syntax for path values is dependant
on the type of repository being accessed. For details refer to the manual
pages for the corresponding modules:

=over 4

=item CVS

Refer to L<Test::AutoBuild::Repository::CVS>

=item GNU Arch

Refer to L<Test::AutoBuild::Repository::GNUArch>

=item Subversion

Refer to L<Test::AutoBuild::Repository::Subversion>

=item Perforce

Refer to L<Test::AutoBuild::Repository::Perforce>

=item Mercurial

Refer to L<Test::AutoBuild::Repository::Mercurial>

=item SVK

Refer to L<Test::AutoBuild::Repository::SVK>

=item Local disk

Refer to L<Test::AutoBuild::Repository::Disk>

=back

An example config entry for a module checked out of CVS is

    source = {
	repository = gna-cvs
	path = /testautobuild
    }


=item sources

If a module's source is split amongst several locations, this block
is used instead of the C<source> block. It allows defintion of a list
of source paths to checkout. It is a list, where each entry matches
the format of the C<source> parameter. For example

  sources = (
    {
      repository = gna-cvs
      path = /testautobuild
    }
    {
      repository = local-disk
      path = /testautobuild-autobuild.sh -> autobuild.sh
    }
  )

NB, not all repository types play nicely together when checking out
from multiple paths. Consult manual pages for individual repository
types for futher information

=item groups

Lists the groups to which the module belongs. The values in the list
must be group names, specified earlier in the top level C<groups>
configuration block.

  groups = (
    software
    perl
  )

=item env

Defines a set of environment variables which will be set whenever
running the build/test control files for the module. The only
restriction on variables set here, are that none should be named
with the prefix AUTOBUILD_, otherwise they are liable to be
overridden by variables set by the build engine.

  env = (
    SKIP_TESTS = 1
  )

=item options

The options parameter is used to specify module specific data
which will be used by stages in the workflow engine. Consult the
manual pages for individual stages in use, for further details
on which options are possible. The most common option is
C<control-file> which can be used to override the default name
of the command to invoke to run the build. For compatability
with version 1.0.x of autobuild, this should be set to 'rollingbuild.sh'

  options = {
    control-file = rollingbuild.sh
  }

=item links

The links configuration block defines a simple list of hyperlinks
relating to the module. This is typically used to provide links to
a graphical front end for the source repository, or a link to a
project homepage. The two keys with the block are C<href> and C<label>

  links = (
    {
      href = http://www.autobuild.org/
      label = Project homepage
    }
    {
      href = http://cvs.gna.org/viewcvs/testautobuild/testautobuild/?only_with_tag=RELEASE_1_0_0
      label = Browse source code
    }
  )

=item artifacts

The artifacts configuration block defines a list of build artifacts
which will be published to the distribution sites. This is typically
used to provide access to items such as build reports on code coverage,
code complexity, bug analysis, etc, or metadata files such as the
module's README, or copyright notices. With the block, the C<src>
parameter is a filename glob relative to the base of the module's
code checkout; the C<dst> parameter is the name of the destination
file (or directory if the source glob matches multiple files), and
will also form the URL string; the C<label> key gives a label for
hyperlinks to the artifact, and finally the C<publisher> is the name
of a file publisher, as defined in the top level C<publishers> config
block.

  artifacts = (
    {
      src = README
      dst = README
      label = Readme
      publisher = copy
    }
    {
      src = blib/coverage/*
      dst = coverage/
      label = Code Test & POD coverage Reports
      publisher = copy
    }
  )

=back

=head2 Groups

The following options define grouping of modules, primarily
used for grouping modules in the HTML status display. The
keys in the configuration block for the short group name,
used when defining group membership in the module configuration.

  groups = {
    perl = {
      label = Perl modules
    }
    software = {
      label = Software
    }
    docs = {
      label = Documentation
    }
  }

The following options are allowed within each group definition

=over 4

=item label

The free-text display name of the group

=back

=head2 Package types

The following options define binary package types to detect
and publish.

=head2 Publishers

The following options define mechanisms for publishing files
to distribution directories.

=head2 Platforms

The following options define aspects of the host platform

=head2 Build archive

The following options define the mechanism used for archiving
module build output between build cycles.

=head2 Workflow stages

The following options defined the workflow followed for a
build cycle


=head1 METHODS

=over 4

=cut

package Test::AutoBuild;

use warnings;
use strict;

use Test::AutoBuild::Lib;
use Test::AutoBuild::Runtime;
use Test::AutoBuild::Group;
use Test::AutoBuild::Platform;
use Test::AutoBuild::PackageType;
use Test::AutoBuild::Stage::Group;
use Class::MethodMaker
    new_with_init => qw(new),
    get_set => [qw(root_stage)];

use Log::Log4perl qw(:levels);
use File::Spec::Functions;
use UNIVERSAL;

use vars qw($VERSION);
$VERSION = '1.2.4';

=item $builder = Test::AutoBuild->new(config => $config);

Creates a new builder instance, loading configuration parameters
from the C<$config> parameter, whose value is an instance of the
C<Config::Record> module.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->{verbose} = exists $params{verbose} ? $params{verbose} : 0;
    $self->{debug} = exists $params{debug} ? $params{debug} : 0;

    my $config_file = exists $params{config} ? $params{config} : die "config parameter is required";
    my ($config, $config_data, $config_error)
	= Test::AutoBuild::Lib::load_templated_config($config_file);

    if ($config_error) {
	if ($config_data) {
	    printf STDERR $config_data;
	}
	die $config_error;
    }

    my $engine_file = $config->get("engine");
    my ($engine, $engine_data, $engine_error)
	= Test::AutoBuild::Lib::load_templated_config($engine_file,
						      { config => $config->record } );

    if ($engine_error) {
	if ($engine_data) {
	    print STDERR $engine_data;
	}
	die $engine_error;
    }

    $self->{config} = $engine;

    $self->setup_log4perl;

    $self->{lock} = $self->load_lock();
    $self->{repositories} = $self->load_repositories();
    $self->{groups} = $self->load_groups();
    $self->{package_types} = $self->load_package_types();
    $self->{modules} = $self->load_modules($self->{groups});
    $self->{publishers} = $self->load_publishers();
    $self->{monitors} = $self->load_monitors();
    $self->{platforms} = $self->load_platforms();
    $self->{counter} = $self->load_counter();
    $self->{archive_manager} = $self->load_archive_manager();
    my $stage = Test::AutoBuild::Stage::Group->new(name => "root",
						 label => "Root stage");
    $self->load_stages($stage, $self->{config});
    $self->root_stage($stage);
}


sub setup_log4perl {
    my $self = shift;

    my $opt = $self->config->get("log4perl");
    my $conf = join "\n", map { $_ . " = " . $opt->{$_} } keys %{$opt};
    unless ($conf) {
	$conf = q(
		  log4perl.rootLogger             = INFO, Screen
		  log4perl.appender.Screen        = Log::Log4perl::Appender::Screen
		  log4perl.appender.Screen.stderr = 1
		  log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
		  );
    }
    Log::Log4perl->init( \$conf );

    if ($self->{debug} > 1) {
	my $logger = Log::Log4perl->get_logger("");
	$logger->level($DEBUG, 0);
    } elsif ($self->{debug} > 0) {
	my $logger = Log::Log4perl->get_logger("Test::AutoBuild");
	$logger->level($DEBUG, 0);
    } elsif ($self->{verbose}) {
	my $logger = Log::Log4perl->get_logger("Test::AutoBuild");
	$logger->level($INFO, 0);
    }
}

=item $config = $builder->config([$name, [$default]]);

If invoked with no arguments returns the Config::Record object
storing the builder configuration. If invoked with a single
argument, returns the configuration value with the matching
name. An optional default value can be provided in the second
argument

=cut

sub config {
    my $self = shift;

    if (@_) {
	my $name = shift;
	return $self->{config}->get($name, @_);
    }
    return $self->{config};
}

=item $builder->run();

Executes the build process. This is the heart of the auto build
engine. It performs the following actions:

 * Reads the list of modules, source control repositories,
   package types and output modules from the configuration
   file
 * Initializes the build cache
 * Takes out an exclusive file lock to prevent > 1 builder
   running at the same time.
 * Changes the (nice) priority of the AutoBuild process
 * Checks the code for each module out of its respective
   source control repository.
 * Does a topological sort to determine the build order
   for all modules
 * For each module to be built:
    - Take a snapshot of the package & virtual root install
      directories
    - Change to the top level source directory of the module
    - Run the rollingbuild.sh script
    - Take another snapshot & compare to determine which
      files were install in the virtual root & which packages
      were generated
    - Save the intsalled files and packages in the cache.
 * Invoke each requested output module, for example, HTML
   status generator, package & log file copiers, email
   alerts

=cut

sub run {
    my $self = shift;
    my $timestamp = shift || time;

    unless ($self->{lock}->lock) {
	return;
    }
    eval {
	$self->do_run($timestamp);
    };
    my $err = $@;
    $self->{lock}->unlock;
    if ($err) {
	die $err;
    }
}

sub do_run {
    my $self = shift;
    my $timestamp = shift;

    my $log = Log::Log4perl->get_logger();

    my $runtime = Test::AutoBuild::Runtime->new(repositories => $self->{repositories},
						groups => $self->{groups},
						package_types => $self->{package_types},
						modules => $self->{modules},
						publishers => $self->{publishers},
						monitors => $self->{monitors},
						platforms => $self->{platforms},
						archive_manager => $self->{archive_manager},
						source_root => $self->config("root/source", $ENV{HOME} . "/source-root"),
						install_root => $self->config("root/install", $ENV{HOME} . "/install-root"),
						package_root => $self->config("root/package", $ENV{HOME} . "/package-root"),
						log_root => $self->config("root/log", $ENV{HOME} . "/log-root"),
						admin_email => $self->config("admin-email"),
						admin_name => $self->config("admin-name"),
						group_email => $self->config("group-email", undef),
						group_name => $self->config("group-name", undef),
						counter => $self->{counter},
						timestamp => $timestamp);

    $log->debug("Changing into source directory " . $runtime->source_root);
    unless (chdir $runtime->source_root) {
	die "cannot change into source root " . $runtime->source_root;
    }

    # Global environment overrides
    my $env = $self->config("env", {});
    local %ENV = %ENV;
    foreach (keys %{$env}) {
	$log->debug("Setting global environment '$_' to '" . $env->{$_} . "'");
	$ENV{$_} = $env->{$_};
    }

    $runtime->notify("beginCycle", time);

    my $results = $self->root_stage->prepare($runtime);
    $runtime->attribute("results", $results);
    $self->root_stage->run($runtime);

    if (defined $runtime->archive_manager) {
	$runtime->archive->save_data("AUTOBUILD",
				     "RUN",
				     {
					 name => $self->root_stage->name,
					 label => $self->root_stage->label,
					 start_time => $self->root_stage->start_time,
					 end_time => $self->root_stage->end_time,
				     });
    }
    $runtime->notify("endCycle", time);
}

sub start_time {
    my $self = shift;
    return $self->root_stage->start_time;
}

sub end_time {
    my $self = shift;
    return $self->root_stage->end_time;
}

sub succeeded {
    my $self = shift;
    return $self->root_stage->succeeded;
}

sub failed {
    my $self = shift;
    return $self->root_stage->failed;
}

sub aborted {
    my $self = shift;
    return $self->root_stage->aborted;
}

sub log {
    my $self = shift;
    return $self->root_stage->log;
}

=item my \%groups = $autobuild->load_groups();

Creates the C<Test::AutoBuild::Publisher> objects for each publisher
defined in the build configuration.

=cut

sub load_groups {
    my $self = shift;

    my $data = $self->config->get("groups", {});
    my $groups = {};

    foreach my $name (keys %{$data}) {
	my $params = $data->{$name};
	my $group = Test::AutoBuild::Group->new(name => $name, %{$params});
	$groups->{$name} = $group;
    }

    $groups->{global} = Test::AutoBuild::Group->new(name => "global", label => "Global")
	unless exists $groups->{global};

    return $groups;
}

=item my \%publishers = $autobuild->load_publishers();

Creates the C<Test::AutoBuild::Publisher> objects for each publisher
defined in the build configuration.

=cut

sub load_publishers {
    my $self = shift;

    my $data = $self->config->get("publishers", {
      copy => {
	label => "File Copier",
	module => "Test::AutoBuild::Publisher::Copy"
      }
    });
    my $publishers = {};

    foreach my $name (keys %{$data}) {
	my $params = $data->{$name};
	die "no label for $name group" unless exists $params->{label};

	my $module = $data->{$name}->{module};
	die "no module for $name publisher" unless defined $module;

	eval "use $module;";
	die "could not load module '$module' for publisher '$name': $@" if $@;
	my $publisher = $module->new(name => $name, %{$params});
	$publishers->{$name} = $publisher;
    }

    return $publishers;
}

=item my \%monitors = $autobuild->load_monitors();

Creates the C<Test::AutoBuild::Monitor> objects for each monitor
defined in the build configuration.

=cut

sub load_monitors {
    my $self = shift;

    my $data = $self->config->get("monitors", {
      log4perl => {
	label => "Log4perl Monitor",
	module => "Test::AutoBuild::Monitor::Log4perl"
      }
    });
    my $monitors = {};

    foreach my $name (keys %{$data}) {
	my $params = $data->{$name};
	die "no label for $name group" unless exists $params->{label};

	my $module = $data->{$name}->{module};
	die "no module for $name monitor" unless defined $module;

	eval "use $module;";
	die "could not load module '$module' for monitor '$name': $@" if $@;
	my $monitor = $module->new(name => $name, %{$params});
	$monitors->{$name} = $monitor;
    }

    return $monitors;
}


=item my \%platforms = $autobuild->load_platforms();

Creates the C<Test::AutoBuild::Platform> objects for each platform
defined in the build configuration.

=cut

sub load_platforms {
    my $self = shift;

    my $data = $self->config->get("platforms");
    my $platforms = {};

    foreach my $name (keys %{$data}) {
	my $params = $data->{$name};

	my $platform = Test::AutoBuild::Platform->new(name => $name, %{$params});
	$platforms->{$name} = $platform;
    }

    return $platforms;
}

=item my \@repositories = $autobuild->load_repositories();

Creates the C<Test::AutoBuild::Repository> objects for each repository
defined in the build configuration.

=cut

sub load_repositories {
    my $self = shift;

    my $data = $self->config->get("repositories", {});
    my $reps = {};

    foreach my $name (keys %{$data}) {
	my $module = $data->{$name}->{module};
	die "no module for $name repository" unless defined $module;
	eval "use $module;";
	die "could not load module '$module' for repository '$name': $@" if $@;

	my $rep = $module->new(name => $name, %{$data->{$name}});
	$reps->{$name} = $rep;
    }

    return $reps;
}



=item my \%package_types = $autobuild->load_package_types();

Creates the C<Test::AutoBuild::PackageType> objects for each package type
defined in the build configuration.

=cut

sub load_package_types {
    my $self = shift;

    my $data = $self->config->get("package-types", {});
    my $package_types = {};

    foreach my $name (keys %{$data}) {
	$package_types->{$name} = Test::AutoBuild::PackageType->new(name => $name, %{$data->{$name}});
    }

    return $package_types;
}



=item my \%modules = $autobuild->load_modules();

Creates the C<Test::AutoBuild::Module> obkjects for each module
defined in the build configuration.

=cut

sub load_modules {
    my $self = shift;
    my $groups = shift;

    my $log = Log::Log4perl->get_logger();
    my $data = $self->config->get("modules");
    my $modules = {};

    MODULE: foreach my $name (keys %{$data}) {
	my $params = $data->{$name};
	next unless (! exists $params->{enabled} || $params->{enabled});
	my $module_package = $params->{module} || "Test::AutoBuild::Module";
	eval "use $module_package;";
	die "could not load module '$module_package' for module '$name': $@" if $@;

	if (exists $params->{source}) {
	    $params->{sources} = [ $params->{source} ];
	    delete $params->{source};
	}

	my $module = $module_package->new(name => $name,
					  runtime => $self,
					  %{$params});
	for my $group (@{$module->groups}) {
	    if (!exists $groups->{$group}) {
		$log->error("Name '$name' refers to a group '$group' which is not defined");
		next;
	    }
	    next MODULE unless $groups->{$group}->enabled();
	}
	$modules->{$name} = $module;
    }

    return $modules;
}


sub load_archive_manager {
    my $self = shift;

    if ($self->config("archive/enabled", "0")) {
	my $archive_module = $self->config("archive/module");
	eval "use $archive_module;";
	die "could not load module '$archive_module' for archive manager: $@" if $@;
	return $archive_module->new(options => $self->config("archive/options", {}),
				    'max-age' => $self->config("archive/max-age", "7d"),
				    'max-instance' => $self->config("archive/max-instance", 20),
				    'max-size' => $self->config("archive/max-size", "500m"));
    }
    return undef;
}

sub load_counter {
    my $self = shift;

    my $counter_module = $self->config("counter/module", "Test::AutoBuild::Counter::Time");
    eval "use $counter_module;";
    die "could not load module '$counter_module' for counter: $@" if $@;
    return $counter_module->new(options => $self->config("counter/options", {}));
}


sub load_stages {
    my $self = shift;
    my $stage = shift;
    my $config = shift;

    my $substages = $config->get("stages", []);
    for (my $i = 0 ; $i <= $#{$substages} ; $i++) {
	my $module = $config->get("stages/[$i]/module");
	my $name = $config->get("stages/[$i]/name");
	my $label = $config->get("stages/[$i]/label");
	my $critical = $config->get("stages/[$i]/critical", 1);
	my $enabled = $config->get("stages/[$i]/enabled", 1);
	my $options = $config->get("stages/[$i]/options", {});

	eval "use $module;";
	die "cannot load module '$module' for stage '$name': $@" if $@;

	my $substage = $module->new(name => $name,
				    label => $label,
				    critical => $critical,
				    enabled => $enabled,
				    options => $options);

	$stage->add_stage($substage);
	if ($substage->can("add_stage")) {
	    $self->load_stages($substage, $config->view("stages/[$i]"));
	}
    }
}


sub load_lock {
    my $self = shift;

    my $module = $self->config->get("lock/module", "Test::AutoBuild::Lock");
    eval "use $module;";
    die "cannot load module '$module' for lock: $@" if $@;

    return $module->new($self->config->get("lock/file", catfile($ENV{HOME}, ".build.mutex")),
			$self->config->get("lock/method", "file"));
}

1 # So that the require or use succeeds.

__END__

=back

=head1 TODO

The task tracker on the Gna! project site (L<www.autobuild.org>) contains
a list of all things we'd like to do.

Oh and 100% Pod & code test coverage - L<Devel::Cover> WILL EAT YOUR BRAAAAANE!

=head1 BUGS

Probably a few, so report them to the bug tracker linked from the Gna!
project site L<www.autobuild.org>.

=head1 AUTHORS

Daniel P. Berrange, Dennis Gregorovic

=head1 COPYRIGHT

Copyright (C) 2002-2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<http://www.autobuild.org>, L<Test::AutoBuild::Runtime>,
L<Test::AutoBuild::Module>, L<Test::AutoBuild::Stage>,
L<Test::AutoBuild::Repository>, L<Test::AutoBuild::PackageType>,
L<Test::AutoBuild::Publisher>, L<Test::AutoBuild::Repository>,
L<Test::AutoBuild::Counter>, L<Test::AutoBuild::Group>,

=cut
