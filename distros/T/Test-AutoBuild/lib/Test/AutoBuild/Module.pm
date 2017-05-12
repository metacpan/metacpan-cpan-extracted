# -*- perl -*-
#
# Test::AutoBuild::Module by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>
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
# $Id: Module.pm,v 1.42 2007/12/10 03:16:16 danpb Exp $

=pod

=head1 NAME

Test::AutoBuild::Module - represents a code module to be built

=head1 SYNOPSIS

  use Test::AutoBuild::Module;

  my $module = Test::AutoBuild::Module->new(name => $name,
					    label => $label,
					    sources => $sources,
					    [dependencies => \@modules,]
					    [env => \%env,]
					    [options => \%options,]
					    [groups => \@groups,]
					    [dir => $directory]);

  $module->build();
  $module->install();


=head1 DESCRIPTION

The Test::AutoBuild::Module module provides a representation of
a single code module to be built / tested.

=head1 OPTIONS

The valid configuration options for the C<modules> block are

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Module;

use strict;
use warnings;
use Carp qw(confess);
use File::Spec::Functions qw(rel2abs catdir file_name_is_absolute catfile);
use Class::MethodMaker
    new_with_init => "new",
    get_set => [qw(
		   artifacts
		   depends
		   changed
		   changes
		   dir
		   env
		   groups
		   label
		   links
		   name
		   packages
		   installed
		   sources
		   use_archive
		   admin_email
		   admin_name
		   group_email
		   group_name
		   )];

use Cwd;
use Log::Log4perl;

=item my $module = Test::AutoBuild::Module->new(name => $name,
						label => $label,
						sources => $sources,
						[depends => \@modules,]
						[links => \%links,]
						[artifacts => \%artifacts,]
						[env => \%env,]
						[options => \%options,]
						[groups => \@groups,]
						[dir => $directory]);

Creates a new code module object. C<name> is a alphanumeric
token for the name of the module. C<label> is a short human
friendly title for the module. C<depends> is an array
ref containing a list of dependant module names. C<env> is
a hash ref of environment variables to define when building
the module. C<groups> is the optional list of groups to
which the module belongs. C<dir> is the directory in which
the module was checked out, if different from C<name>. The
C<controlfile> parameter is the name of the build control
file to run if different from the global default.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->name(exists $params{name} ? $params{name} : confess "name parameter is required");
    $self->label(exists $params{label} ? $params{label} : confess "label parameter is required");
    $self->links(exists $params{links} ? $params{links} : []);
    $self->artifacts(exists $params{artifacts} ? $params{artifacts} : []);
    $self->packages({});
    $self->installed({});
    $self->depends(exists $params{depends} ? $params{depends} : []);
    $self->env(exists $params{env} ? $params{env} : {});
    $self->groups(exists $params{groups} ? $params{groups} : ["global"]);
    $self->dir(exists $params{dir} ? $params{dir} : $self->{name});

    $self->sources(exists $params{sources} ? $params{sources} : confess "sources parameter is required");

    $self->admin_email(exists $params{admin_email} ? $params{admin_email} : undef);
    $self->admin_name(exists $params{admin_name} ? $params{admin_name} : $self->label . " administrator");
    $self->group_email(exists $params{group_email} ? $params{group_email} : undef);
    $self->group_name(exists $params{group_name} ? $params{group_name} : $self->label . " developers");

    $self->use_archive(exists $params{use_archive} ? $params{use_archive} : 1);
    $self->{options} = exists $params{options} ? $params{options} : {};
    $self->{is_installed} = {};
    $self->{results} = {
	checkout => {
	    status => "pending",
	},
	build => {
	    status => "pending",
	},
    };
}

=item my $label = $module->label([$newlabel]);

Returns the label of this module, a short
human friendly title. If the C<newlabel>
parameter is supplied the label is also updated.

=item my $name = $module->name([$newname]);

Returns the name of this module, a short
alphanumeric token. If the C<newname>
parameter is supplied the name is also updated.

=item my $sources = $module->sources($newsources)

Returns an array references, where each element is as
hash with two keys. The value associated with the key
C<repository> is the name of the soruce repository. The
value associated with the key C<path> is the path within
the source repository to checkout. If the C<$newsources>
parameter is supplied, the list of sources is updated

=item my $path = $module->dir($newpath);

Returns the path for the directory checked
out of source control. Typically this is
the same as the module name. If the C<newpath>
parameter is supplied the dir is updated.

=item my \@modules = $module->depends([\@modules]);

Returns an array ref of dependant module names. If the
C<modules> parameter is supplied then the list of
dependants is updated.

=item my $value = $module->option($name[, $newvalue]);

Returns the value of the option referenced by C<name>.
If the C<newvalue> parameter is supplied, then the
option is also updated. Options are arbitrary key +
value pairs intended for stages to use for configuring
module specific options. For example the
L<Test::AutoBuild::Stage::Build> module uses the
C<control-file> option key to allow override of the
shell script used to perform a build. To avoid clashes
between multiple different stages, try to use reasonably
description option key names, preferrably at least 2
words long.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   # XXX fixme
   if (0) {
   if (! exists $self->{options}->{$name}) {
       my $groups = $self->runtime->groups;
       foreach (@{$self->groups()}) {
	   my $value = $groups->{$_}->option($name);
	   return $value if defined $value;
       }
   }
   }

   return $self->{options}->{$name};
}


=item my $bool = $module->is_installed($dir);

Returns a true value if this modules files are installed
into the directory C<$dir>.

=cut

sub is_installed {
    my $self = shift;
    my $dir = shift;
    $self->{is_installed}->{$dir} = shift if @_;
    return $self->{is_installed}->{$dir};
}

=item $module->install($runtime, $dir);

Installs all this module's files from a previously populated build
cache, into the directory C<$dir>. If any dependant modules have
not yet been installed, they will be installed first.

=cut

sub install {
    my $self = shift;
    my $runtime = shift;
    my $dir = shift;

    my $log = Log::Log4perl->get_logger();

    if ($self->is_installed($dir)) {
	$log->debug("Module " . $self->name . " is already installed into '$dir'");
	return;
    }

    foreach my $depend (@{$self->depends}) {
	$runtime->module($depend)->install($runtime, $dir);
    }

    my $archive = $runtime->archive;
    if (!defined $archive) {
	die "cannot install files with an archive";
    }
    $log->debug("Installing module " . $self->name . " into '$dir'");
    $archive->extract_files($self->name, "installed", $dir, { link => 1});
    $self->is_installed($dir, 1);
}


=item $module->test_status($name);

Retrieves the status of the test called C<$name>. The status
will be one of the C<success>, C<failed>, C<cached>. If there
is no test called C<$name>, an error will be thrown.

=cut

sub test_status {
    my $self = shift;
    my $name = shift;

    die "no test with name $name" unless exists $self->{results}->{"test-" . $name};

    return $self->{results}->{"test-" . $name}->{status};
}


=item $module->test_output_log_file($name);

Retrieves the name of the logfile into which console output
for the test called C<$name> should be saved. The logfile name
will be relative to the runtime's log root directory.

=cut

sub test_output_log_file {
    my $self = shift;
    my $name = shift;

    return $self->_result_log_file("test-$name", "output");
}

=item $module->test_result_log_file($name);

Retrieves the name of the logfile into which formal results
for the test called C<$name> should be saved. The logfile name
will be relative to the runtime's log root directory.

=cut

sub test_result_log_file {
    my $self = shift;
    my $name = shift;

    return $self->_result_log_file("test-$name", "result");
}


=item my $seconds = $module->test_start_date($name);

Retrieves the timestamp at which the test called C<$name> began
execution. If no test called C<$name> has been run yet, an error
will be thrown.

=cut


sub test_start_date {
    my $self = shift;
    my $name = shift;

    die "no test with name $name" unless exists $self->{results}->{"test-" . $name};

    return $self->{results}->{"test-" . $name}->{start_date};
}


=item my $seconds = $module->test_end_date($name);

Retrieves the timestamp at which the test called C<$name> completed
execution. If no test called C<$name> has been run yet, an error
will be thrown.

=cut


sub test_end_date {
    my $self = shift;
    my $name = shift;

    die "no test with name $name" unless exists $self->{results}->{"test-" . $name};

    return $self->{results}->{"test-" . $name}->{end_date};
}


=item my @names = $module->tests

Retrieves the list of all known test names which have been executed
for this module.

=cut

sub tests {
    my $self = shift;

    return map { /^test-(.*)$/ ; $1 }
      sort { $self->{results}->{$a}->{order} <=> $self->{results}->{$b}->{order} }
      grep { /^test-/ } keys %{$self->{results}};
}

=item my $status = $module->build_status;

Retrieves the status of the module build. If the module has not
yet been built, it will return 'pending'; if the build has been
run it will return one of 'success', 'failed', or 'cached'; if
the module's build was skipped due to a dependant module failing,
the status will be 'skipped'.

=cut

sub build_status {
    my $self = shift;
    return $self->{results}->{build}->{status};
}


=item $module->build_output_log_file();

Retrieves the name of the logfile into which console output
for the build process should be saved. The logfile name
will be relative to the runtime's log root directory.

=cut


sub build_output_log_file {
    my $self = shift;
    return $self->_result_log_file("build", "output");
}

=item $module->build_result_log_file();

Retrieves the name of the logfile into which results
for the build process unittests should be saved. The
logfile name will be relative to the runtime's log
root directory.

=cut


sub build_result_log_file {
    my $self = shift;
    return $self->_result_log_file("build", "result");
}

=item my $seconds = $module->test_start_date();

Retrieves the timestamp at which the build process began
execution. If the build has not run yet, an undefined value
will be returned.

=cut

sub build_start_date {
    my $self = shift;
    return $self->{results}->{build}->{start_date};
}


=item my $seconds = $module->test_end_date();

Retrieves the timestamp at which the build process completed
execution. If the build has not run yet, an undefined value
will be returned.

=cut


sub build_end_date {
    my $self = shift;
    return $self->{results}->{build}->{end_date};
}

=item my $status = $module->checkout_status;

Retrieves the status of the module SCM checkout. If the module has not
yet been checked out, it will return 'pending'; Ff the checkout has been
run it will return one of 'success', 'failed'. If it was 'success' then
the C<changes> method will return a list of changesets.

=cut

sub checkout_status {
    my $self = shift;
    return $self->{results}->{checkout}->{status};
}


=item $module->checkout_output_log_file();

Retrieves the name of the logfile into which console output
for the checkout process should be saved. The logfile name
will be relative to the runtime's log root directory.

=cut


sub checkout_output_log_file {
    my $self = shift;
    return $self->_result_log_file("checkout", "output");
}

=item my $seconds = $module->test_start_date();

Retrieves the timestamp at which the checkout process began
execution. If the checkout has not run yet, an undefined value
will be returned.

=cut

sub checkout_start_date {
    my $self = shift;
    return $self->{results}->{checkout}->{start_date};
}


=item my $seconds = $module->test_end_date();

Retrieves the timestamp at which the checkout process completed
execution. If the checkout has not run yet, an undefined value
will be returned.

=cut


sub checkout_end_date {
    my $self = shift;
    return $self->{results}->{checkout}->{end_date};
}

# Internal method, may disappear at any time!
sub _result_log_file {
    my $self = shift;
    my $cmdname = shift;
    my $type = shift;

    return $self->name . "-" . $cmdname . "-" . $type . ".log";
}

# Internal method, may disappear at any time!
sub _add_result {
    my $self = shift;
    my $action = shift;
    my $status = shift;
    my $start = shift || time;
    my $end = shift || $start;

    die "already got a result for action $action"
      if exists $self->{results}->{$action} &&
	!($action eq "build" && $self->{results}->{$action}->{status} eq "pending") &&
	!($action eq "checkout" && $self->{results}->{$action}->{status} eq "pending");

    my @results = keys %{$self->{results}};

    $self->{results}->{$action} = {
      order => $#results+1,
      status => $status,
      start_date => $start,
      end_date => $end,
    };
}


=item my $stauts = $module->status

Retrieves the overall status of this module. If the module
failed to checkout from SCM, then the SCM status is returned.
If the module build failed, is pending, or was skipped, then
this returns 'failed', 'pending', or 'skipped' respectively;
If any test script failed, this returns 'failed'; otherwise
it returns 'success'.

=cut

sub status {
    my $self = shift;

    if ($self->checkout_status() ne "success") {
	return $self->checkout_status();
    }

    if ($self->build_status() eq "cached" ||
	$self->build_status() eq "success") {
	foreach my $name ($self->tests) {
	    if ($self->{results}->{"test-" . $name}->{status} eq "failed") {
		return "failed";
	    }
	}
	return "success";
    } else {
	return $self->build_status();
    }
}

=item my @paths = $module->paths($repository)

Returns the list of source paths to be checked
out from the repository C<$repository>. If there
are no paths associated with that repository,
returns an empty list.

=cut

sub paths {
    my $self = shift;
    my $repository = shift or die;

    my $sources = $self->sources();
    my @paths;
    foreach my $entry (@{$sources}) {
	if ($entry->{repository} eq $repository->name) {
	    push @paths, $entry->{path};
	}
    }
    return @paths;
}


# Internal method liable to disappear!
sub _save_log {
    my $self = shift;
    my $logfile = shift;
    my $data = shift;

    open LOG, ">$logfile"
	or die "cannot create $logfile: $!";
    print LOG $data;
    close LOG
	or die "cannot save $logfile: $!";
}

=item my $status = $module->invoke_shell($runtime, $controlfile, $logfile, \@args);

This method spawns a shell, and executes the command C<$controlfile> saving its
combined stdout/stderr output to the file C<$logfile>. The command will have
C<@args> passed as command line arguments, and will be run in the context
of the environment returned by the C<get_shell_env> method. The return value
of this method will be zero upon success, otherwise it will return the exit
status of the command. Before invoking the command C<$controlfile> the current
directory will be changed to the directory returned by the C<dir> method
beneath the runtime's source root. Any errors encountered while trying to
spawn the shell, or invoke the command will also be logged in the file given
by the C<$logfile> parameter.

=cut

sub invoke_shell {
    my $self = shift;
    my $runtime = shift;
    my $controlfile = shift;
    my $logfile = shift;
    my $args = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Running $controlfile with output to $logfile args (". join(", ", @{$args}) . ")");

    my $wkdir = catdir($runtime->source_root, $self->dir);

    if (!file_name_is_absolute($controlfile)) {
	$controlfile = rel2abs($controlfile, $wkdir);
    }
    if (!-e $controlfile) {
	$self->_save_log($logfile, "cannot find control file '$controlfile'");
	return 1;
    }
    if (!-x _) {
	$self->_save_log($logfile, "control file '$controlfile' is not executable");
	return 1;
    }

    my $status;
    eval {
	my %env = $runtime->get_shell_environment($self);
	foreach my $key (%{$self->env}) {
	    $env{$key} = $self->env->{$key};
	}

	my $cmdopt = $self->option("command") || {};
	my $mod = $cmdopt->{module} || "Test::AutoBuild::Command::Local";
	my $opts = $cmdopt->{options} || {};
	eval "use $mod;";
	die "cannot load $mod: $!" if $@;

	my $c = $mod->new(cmd => [$controlfile, @{$args}],
			  dir => $wkdir,
			  env => \%env,
			  options => $opts);

	$status = $c->run($logfile, $logfile);
    };
    if ($@) {
	$self->_save_log($logfile, $@);
	return 1;
    }
    $log->debug("Job status is $status");
    return $status;
}


=item $module->run_task($runtime, $taskname, $controlfile);

This method runs a task named C<$taskname> by invoking the
shell command C<$controlfile> in the source directory for
this module. The taskname must either be C<build> or be
prefixed by the string C<test->. If the taskname is L<build>
then after execution any files created in the install root
will be recorded as installed files - later available by
invoking the C<installed> method. Likewise any files created
in the package root, matching known package types will be
recorded as generated packages - later available by invoking
the C<packags> method. The start and end times of the task,
along with its success/failure status will be record and
later available from the corresponding C<build_XXX> or
C<test_XXX> methods matching the C<$taskname>. The controfile
will be invoked with a single command line argument, which
is the full path to a file into which formal test results
should be saved. Regular, free format, build / test output
will automatically be captured to an alternate log file.

=cut

sub run_task {
    my $self = shift;
    my $runtime = shift;
    my $taskname = shift;
    my $controlfile = shift;



    my $log = Log::Log4perl->get_logger();
    foreach my $depend (@{$self->depends}) {
	$runtime->module($depend)->install($runtime, $runtime->install_root);
    }
    my $before_packages;
    my $before_installed;
    if ($taskname eq "build") {
	$before_packages = $runtime->package_snapshot();
	$before_installed = $runtime->installed_snapshot();
    }

    my $resultlog = catfile($runtime->log_root, $self->_result_log_file($taskname, "result"));
    my $outputlog = catfile($runtime->log_root, $self->_result_log_file($taskname, "output"));

    unlink($outputlog) if -f $outputlog;
    unlink($resultlog) if -f $resultlog;

    my $start = time;
    my $res = $self->invoke_shell($runtime, $controlfile, $outputlog, [$resultlog]);
    my $end = time;
    my $status = $res ? "failed" : "success";
    if ($res) {
	$log->debug("Failed with status $res");
    }
    $self->_add_result($taskname, $status, $start, $end);

    if ($taskname eq "build") {
	if ($self->build_status() eq 'success') {
	    my $after_packages = $runtime->package_snapshot ();
	    my $after_installed = $runtime->installed_snapshot();

	    $self->packages(Test::AutoBuild::Lib::new_packages ($before_packages, $after_packages));
	    $self->installed(Test::AutoBuild::Lib::new_packages ($before_installed, $after_installed));
	    $self->is_installed($runtime->install_root, 1);
	}
    }
}


=item $module->cachable_run_task

This is a wrapper around the C<run_task> method which makes use
of the currently configured L<Test::AutoBuild::ArchiveManager> to
cache successfull invocations of a task. On subsequent invocations,
provided there have been no source code checkout changes since the
previous archive, and no dependant modules have been re-built, the
archived result will be restored, rather than invoking the task
again. From the caller's POV, there should be no functional difference
between C<cachable_run_task> and C<run_task>, with the exception that
the former will be alot faster if the archive is used.

=cut

sub cachable_run_task {
    my $self = shift;
    my $runtime = shift;
    my $taskname = shift;
    my $controlfile = shift;

    my $log = Log::Log4perl->get_logger();
    my $arcman = $runtime->archive_manager();

    if ($self->should_skip($runtime)) {
	$self->_add_result($taskname, "skipped");
	$log->info("skipping " . $taskname);
	return;
    }

    if ($self->use_archive &&
	defined $arcman) {
	my $cache = $arcman->get_previous_archive($runtime);
	if ($self->archive_usable($runtime, $cache, $taskname)) {
	    $self->unarchive_result($runtime, $cache, $taskname);
	} else {
	    $self->run_task($runtime, $taskname, $controlfile);
	}

	my $archive = $arcman->get_current_archive($runtime);
	$self->archive_result($runtime, $archive, $taskname);
    } else {
	$log->info("skipping cache entirely");
	$self->run_task($runtime, $taskname, $controlfile);
    }
}


=item $module->unarchive_result($runtime, $cache, $taskname)

This method restores the result of the task C<$taskname>
from an old archive C<$cache>. C<$cache> will be a subclass
of the C<Test::AutoBuild::Archive> module. If the taskname
is C<build>, then the log files, build results, intalled
files, generated packages, and source changelogs will all
be restored. If the taskname is prefixed by C<test->, then
the log files and test results will be restored.

=cut

sub unarchive_result {
    my $self = shift;
    my $runtime = shift;
    my $cache = shift;
    my $taskname = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Restoring result for $taskname");

    $self->_add_result($taskname,
		       "cached",
		       $cache->get_data($self->name, $taskname)->{start_date},
		       $cache->get_data($self->name, $taskname)->{end_date},
		       );

    $cache->extract_files($self->name, $taskname, $runtime->log_root, { link => 1 });

    if ($taskname eq "build") {
	$log->debug("Unarchiving build packages and changes");

	# Changes from source repository
	# Don't toggle 'changed' flag because this is a cached build
	#$self->changed($cache->get_data($self->name, "changes")->{changed});
	$self->changes($cache->get_data($self->name, "changes")->{changes});

	# Installed files
	$self->installed($cache->extract_files($self->name, "installed", $runtime->install_root, { link => 1 }));

	# Generated packages
	$self->packages($cache->extract_files($self->name, "packages", $runtime->package_root, { link => 1}));
    }
}

=item my $bool = $module->archive_usable($runtime, $archive, $taskname)

Returns a true value, if the archive C<$archive> contains a usable saved
entry for the task C<$taskname>. An archive for a module's task is defined
to be usable if all dependant modules are also usable; if the archive
contains a bucket with the name C<$taskname>; if the status of the save
task is C<success> or C<cached>; and if no source code changes have been
made.

=cut

sub archive_usable {
    my $self = shift;
    my $runtime = shift;
    my $archive = shift;
    my $taskname = shift;

    my $log = Log::Log4perl->get_logger();

    if (!defined $archive) {
	$log->info("archive does not exist");
	return 0;
    }

    $log->debug("Checking usability of " . $self->name, " for $taskname in cache " . $archive->key);

    my $all_deps_ok = 1;
    foreach my $depend (@{$self->depends}) {
	if (!$runtime->module($depend)->archive_usable($runtime, $archive, $taskname)) {
	    $log->info("Archive is not usable because module $depend was not a success");
	    return 0;
	}
    }

    if (!$archive->has_data($self->name, $taskname)) {
	$log->info("no cached data for command $taskname");
	return 0;
    }

    my $data = $archive->get_data($self->name, $taskname);
    if ($data->{status} ne "success" &&
	$data->{status} ne "cached") {
	$log->info("archive was not a success");
	return 0;
    }

    if ($self->changed) {
	$log->info("Not using archive because code changes have been made");
	return 0;
    }

    $log->info("using archive for " . $taskname);
    return 1;
}

=item $module->archive_result($runtime, $archive, $taskname)

This method saves the result of the task C<$taskname>
to a new archive C<$archive>. C<$archive> will be a subclass
of the C<Test::AutoBuild::Archive> module. If the taskname
is C<build>, then the log files, build results, intalled
files, generated packages, and source changelogs will all
be saved. If the taskname is prefixed by C<test->, then
the log files and test results will be saved.

=cut


sub archive_result {
    my $self = shift;
    my $runtime = shift;
    my $archive = shift;
    my $taskname = shift;

    my $log = Log::Log4perl->get_logger();
    $log->debug("Saving result for $taskname " . $self->{results}->{$taskname}->{status});
    $archive->save_data($self->name,
			$taskname,
			$self->{results}->{$taskname});

    my $stdout_log = catfile($runtime->log_root, $self->_result_log_file($taskname, "stdout"));
    my $result_log = catfile($runtime->log_root, $self->_result_log_file($taskname, "result"));

    my $stdout_log_stat = stat $stdout_log;
    my $result_log_stat = stat $result_log;

    my $logs = {};
    $logs->{$stdout_log} = $stdout_log_stat if $stdout_log_stat;
    $logs->{$result_log} = $result_log_stat if $stdout_log_stat;

    $archive->save_files($self->name,
			 $taskname,
			 $logs,
			 { link => 1, base => $runtime->log_root });

    if ($taskname eq "build") {
	$log->debug("Saving build install fils, packages and changes");

	$archive->save_files($self->name,
			     "installed",
			     $self->installed,
			     {
				 link => 1,
				 base => $runtime->install_root,
			     });
	$archive->save_files($self->name,
			     "packages",
			     $self->packages(),
			     {
				 link => 1,
				 base => $runtime->package_root,
			     });
	$archive->save_data($self->name,
			    "changes",
			    {
				changed => $self->changed,
				changes => $self->changes(),
			    });
    }
}


sub checkout {
    my $self = shift;
    my $runtime = shift;

    # List of all changes
    my %changes;

    my $logfile = catfile($runtime->log_root, $self->checkout_output_log_file());
    unlink($logfile) if -f $logfile;

    $self->changes({});

    my $start = time;
    foreach my $entry (@{$self->sources()}) {
	my $repository = $runtime->repository($entry->{repository});
	if (!defined $repository) {
	    $self->_add_result("checkout", "failed", $start, time);
	    $self->_save_log($logfile, "cannot find repository definition '" .
			     $entry->{repository} ."'");
	    return;
	}

	my $path = $entry->{path};
	my $src;
	my $dst;
	# scmpath -> localpath
	if ($path =~ /^\s*(\S+)\s*->\s*(\S+)\s*$/) {
	    $src = $1;
	    $dst = catfile($self->dir, $2);
	} else {
	    $src = $path;
	    $dst = $self->dir;
	}

	my ($changed, $changes);
	eval {
	    ($changed, $changes) = $repository->export($runtime, $src, $dst, $logfile);
	};
	if ($@) {
	    $self->_add_result("checkout", "failed", $start, time);
	    $self->_save_log($logfile, "cannot export module $@");
	    return;
	}
	if ($changed) {
	    $self->changed(1);
	}
	if (defined $changes) {
	    foreach (keys %{$changes}) {
		$changes{$_} = $changes->{$_};
	    }
	}
    }

    $self->_add_result("checkout", "success", $start, time);

    $self->changes(\%changes);
}


sub check_source {
    my $self = shift;

    my $now = time;
    if ($self->checkout_status() eq "pending") {
	if (! -d $self->dir) {
	    $self->_add_result("checkout", "failed", $now, $now);
	} elsif ($self->checkout_status eq "pending") {
	    $self->_add_result("checkout", "success", $now, $now);
	}
    }
}

=item $module->build($runtime, $controlfile);

Runs the build task, by invoking the shell command C<$controlfile>
in the source directory of this module. Refer to the C<run_task>
and C<invoke_shell> methods for further details of the context of
execution. Results and information about the task can later be
invoking the various C<build_XXX> methods.

=cut

sub build {
    my $self = shift;
    my $runtime = shift;
    my $controlfile = shift;

    $self->cachable_run_task($runtime, "build", $controlfile);
}

=item $module->test($runtime, $testname, $controlfile);

Runs a test task with the name C<$testname>, by invoking the shell
command C<$controlfile> in the source directory of this module. Refer
to the C<run_task> and C<invoke_shell> methods for further details
of the context of execution. Results and information about the
task can later be retrieved passing the C<$testname> to the various
C<test_XXX> methods.

=cut

sub test {
    my $self = shift;
    my $runtime = shift;
    my $testname = shift;
    my $controlfile = shift;

    $self->cachable_run_task($runtime, "test-$testname", $controlfile);
}

=item my $bool = $module->should_skip($runtime);

Determines if execution of tasks for this module should be
skipped. A module should be skipped, if any of its dependant
modules have a value returned by their C<build_status>
methods of 'failed', 'pending' or 'skipped'.

=cut

sub should_skip {
    my $self = shift;
    my $runtime = shift;
    my $log = Log::Log4perl->get_logger();
    my $depends = $self->depends();

    # Skip any modules which failed SCM checkout
    if ($self->checkout_status() ne "success") {
	return 1;
    }

    # Skip any modules which depend on modules which
    # are still pending, or failed their build
    my $skip = 0;
    foreach my $depend (@{$depends}) {
	my $module = $runtime->module($depend);
	if ($module->build_status() eq 'pending') {
	    $log->warn("Skipping " . $self->label() . " because " . $module->label() . " has not run");
	    $skip = 1;
	}

	if ($module->build_status() ne 'success' &&
	    $module->build_status() ne 'cached' ) {
	    $log->debug("Skipping " . $self->label() . " because " . $module->label() . " failed");
	    $skip = 1;
	}
    }

    return $skip;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002-2004 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Runtime>, L<Test::AutoBuild::Repository>,
L<Test::AutoBuild::Stage>

=cut
