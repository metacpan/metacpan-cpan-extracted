# -*- perl -*-
#
# Test::AutoBuild::Runtime by Dan Berrange
#
# Copyright (C) 2005 Dan Berrange
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

Test::AutoBuild::Runtime - Builder runtime state

=head1 SYNOPSIS

  use Test::AutoBuild::Runtime;

  my $runtime = new Test::AutoBuild::Runtime (archive_manager => $archive_manager,
					      monitors => \%monitors,
					      repositories => \%repositories,
					      modules => \%modules,
					      package_types => \%package_types,
					      publishers => \%publishers,
					      groups => \%groups,
					      platforms => \%platforms,
					      source_root => $dir,
					      install_root => $dir,
					      package_root => $dir,
					      log_root => $dir,
					      counter => $counter);

  my $archive = $runtime->archive;

  my @monitor_names = $runtime->monitors;
  my @repository_names = $runtime->repositories;
  my @module_names = $runtime->modules;
  my @package_types_names = $runtime->package_types;
  my @publisher_names = $runtime->publishers;
  my @group_names = $runtime->groups;
  my @platform_names = $runtime->platforms;

  my $monitor = $runtime->monitor($name);
  my $repository = $runtime->repository($name);
  my $module = $runtime->module($name);
  my $package_type = $runtime->package_type($name);
  my $publisher = $runtime->publisher($name);
  my $group = $runtime->group($name);
  my $platform = $runtime->platform($name);

  $runtime->attribute($key, $value);
  my $value = $runtime->attribute($key);
  my %attributes = $runtime->attributes()

  my $dir = $runtime->source_root();
  my $dir = $runtime->install_root();
  my $dir = $runtime->package_root();
  my $dir = $runtime->log_root();


=head1 DESCRIPTION

This module provides access to the core objects comprising the
build engine, including monitors, repositories, modules, package
types, publishers and groups. The runtime state object is made
available to the C<run> method of stages in the build engine.

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Runtime;

use warnings;
use strict;
use Carp qw(confess);
use Log::Log4perl;
use Sys::Hostname;
use File::Spec::Functions;
use List::Util qw(shuffle);
use Class::MethodMaker
    new_with_init => qw(new),
    get_set => [qw(
		   counter
		   timestamp
		   source_root
		   install_root
		   package_root
		   log_root
		   admin_email
		   admin_name
		   archive_manager
		   group_email
		   group_name
		   )];

our $VERSION = "1.1.0";

=item  my $runtime = Test::AutoBuild::Runtime->new(archive => $archive,
						   monitors => \%monitors,
						   repositories => \%repositories,
						   modules => \%modules,
						   package_types => \%package_types,
						   publishers => \%publishers,
						   groups => \%groups,
						   platforms => \%platforms,
						   source_root => $dir,
						   counter => $counter);

Creates a new runtime state object. The C<archive> parameter requires an instance
of the L<Test::AutoBuild::Archive> module. The C<monitors> parameter requires an
hash reference of L<Test::AutoBuild::Monitor> objects. The C<monitors> parameter requires an
hash reference of L<Test::AutoBuild::Repository> objects. The C<repositories> parameter requires an
hash reference of L<Test::AutoBuild::Module> objects. The C<package_types> parameter requires an
hash reference of L<Test::AutoBuild::PackageType> objects. The C<publishers> parameter requires an
hash reference of L<Test::AutoBuild::Publisher> objects. The C<groups> parameter requires an
hash reference of L<Test::AutoBuild::Group> objects. The C<platforms> parameter requires an
hash reference of L<Test::AutoBuild::Platform> objects.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->{monitors} = exists $params{monitors} ? $params{monitors} : {};
    $self->{repositories} = exists $params{repositories} ? $params{repositories} : {};
    $self->{modules} = exists $params{modules} ? $params{modules} : {};
    $self->{package_types} = exists $params{package_types} ? $params{package_types} : {};
    $self->{publishers} = exists $params{publishers} ? $params{publishers} : {};
    $self->{groups} = exists $params{groups} ? $params{groups} : {};
    $self->{platforms} = exists $params{platforms} ? $params{platforms} : {};
    $self->{attributes} = {};

    $self->timestamp(exists $params{timestamp} ? $params{timestamp} : time);
    $self->source_root(exists $params{source_root} ? $params{source_root} : catfile($ENV{HOME}, "source-root"));
    $self->install_root(exists $params{install_root} ? $params{install_root} : catfile($ENV{HOME}, "install-root"));
    $self->package_root(exists $params{package_root} ? $params{package_root} : catfile($ENV{HOME}, "package-root"));
    $self->log_root(exists $params{log_root} ? $params{log_root} : catfile($ENV{HOME}, "log-root"));
    $self->counter(exists $params{counter} ? $params{counter} : confess "counter parameter is required");
    $self->archive_manager(exists $params{archive_manager} ? $params{archive_manager} : undef);

#    $self->admin_email(exists $params{admin_email} ? $params{admin_email} : confess "admin_email parameter is required");
    $self->admin_email(exists $params{admin_email} ? $params{admin_email} : "root\@" . hostname());
    $self->admin_name(exists $params{admin_name} ? $params{admin_name} : "Build Administrator");
    $self->group_email(exists $params{group_email} ? $params{group_email} : $self->admin_email);
    $self->group_name(exists $params{group_name} ? $params{group_name} : $self->admin_name);

    $self->_sort_modules();
}

=item $runtime->_sort_modules()

Regenerates the internally cached sorted list of modules, by
performing a topological sort of modules against their declared
build dependancies. There is generally no need to call this method.

=cut

sub _sort_modules {
    my $self = shift;

    my $order = [];

    my %pairs;  # all pairs ($l, $r)
    my %npred;  # number of predecessors
    my %succ;   # list of successors

    # tsort code by Jeffrey S. Haemer, <jsh@boulder.qms.com>
    # SEE ALSO tsort(1), tcsh(1), tchrist(1)
    # Algorithm stolen from Jon Bentley (I<More Programming Pearls>, pp. 20-23),
    # Who, in turn, stole it from Don Knuth
    # (I<Art of Computer Programming, volume 1: Fundamental Algorithms>,
    # Section 2.2.3)

    foreach my $name ($self->modules) {
	my $depends = $self->module($name)->depends();
	if ($#{$depends} > -1) {
	    foreach my $depmod (@{$depends}) {
		die "module $name depends on non-existent module $depmod"
		    unless defined $self->modules($depmod);
		next if defined $pairs{$depmod}{$name};
		$pairs{$depmod}{$name}++;
		$npred{$depmod} += 0;
		$npred{$name}++;
		push @{$succ{$depmod}}, $name;
	    }
	} else {
	    $pairs{$name}{$name}++;
	    $npred{$name} += 0;
	    push @{$succ{$name}}, $name;
	}
    }
    # create a list of nodes without predecessors
    my @list = shuffle(grep {!$npred{$_}} keys %npred);
    while (@list) {
	$_ = pop @list;
	push @{$order}, $_;
	foreach my $child (@{$succ{$_}}) {
	    # depth-first (default)
	    push @list, $child unless --$npred{$child};
	}
    }

    $self->{sorted_modules} = $order;
}


=item my $archive = $runtime->archive_manager;

Returns an instance of the L<Test::AutoBuild::ArchiveManager>
module to use for persisting build state across cycles.


=item my $archive = $runtime->archive;

Returns the active archive object

=cut

sub archive {
    my $self = shift;
    return $self->archive_manager ?
	$self->archive_manager->get_current_archive($self) :
	undef;
}


=item my $monitor_names = $runtime->monitors;

Returns a list of monitor names, which can be used to
retrieve a L<Test::AutoBuild::Monitor> object from the
C<monitor> method.

=cut

sub monitors {
    my $self = shift;
    return keys %{$self->{monitors}};
}

=item my $monitor = $runtime->monitor($name);

Retrieves the L<Test::AutoBuild::Monitor> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub monitor {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{monitors}->{$name}) {
	confess "no monitor called $name";
    }
    return $self->{monitors}->{$name};
}


=item my $repository_names = $runtime->repositories;

Returns a list of repository names, which can be used to
retrieve a L<Test::AutoBuild::Repository> object from the
C<repository> method.

=cut

sub repositories {
    my $self = shift;
    return keys %{$self->{repositories}};
}

=item my $repository = $runtime->repository($name);

Retrieves the L<Test::AutoBuild::Repository> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub repository {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{repositories}->{$name}) {
	confess "no repository called $name";
    }
    return $self->{repositories}->{$name};
}


=item my $module_names = $runtime->modules;

Returns a list of module names, which can be used to
retrieve a L<Test::AutoBuild::Module> object from the
C<module> method.

=cut

sub modules {
    my $self = shift;
    return keys %{$self->{modules}};
}


=item my $module_names = $runtime->sorted_modules;

Returns a list of module names, sorted topologically according
to their declared build dependancies. The names can be used to
retrieve a L<Test::AutoBuild::Module> object from the
C<module> method.

=cut

sub sorted_modules {
    my $self = shift;
    return @{$self->{sorted_modules}};
}


=item my $module = $runtime->module($name);

Retrieves the L<Test::AutoBuild::Module> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub module {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{modules}->{$name}) {
	confess "no module called $name";
    }
    return $self->{modules}->{$name};
}


=item my $package_type_names = $runtime->package_types;

Returns a list of package type names, which can be used to
retrieve a L<Test::AutoBuild::PackageType> object from the
C<package_type> method.

=cut

sub package_types {
    my $self = shift;
    return keys %{$self->{package_types}};
}

=item my $package_type = $runtime->package_type($name);

Retrieves the L<Test::AutoBuild::PackageType> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub package_type {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{package_types}->{$name}) {
	confess "no package_type called $name";
    }
    return $self->{package_types}->{$name};
}


=item my $publisher_names = $runtime->publishers;

Returns a list of publisher names, which can be used to
retrieve a L<Test::AutoBuild::Publisher> object from the
C<publisher> method.

=cut

sub publishers {
    my $self = shift;
    return keys %{$self->{publishers}};
}

=item my $publisher = $runtime->publisher($name);

Retrieves the L<Test::AutoBuild::Publisher> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub publisher {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{publishers}->{$name}) {
	confess "no publisher called $name";
    }
    return $self->{publishers}->{$name};
}


=item my $group_names = $runtime->groups;

Returns a list of group names, which can be used to
retrieve a L<Test::AutoBuild::Group> object from the
C<group> method.

=cut

sub groups {
    my $self = shift;
    return keys %{$self->{groups}};
}

=item my $group = $runtime->group($name);

Retrieves the L<Test::AutoBuild::Group> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub group {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{groups}->{$name}) {
	confess "no group called $name";
    }
    return $self->{groups}->{$name};
}


=item my $platform_names = $runtime->platforms;

Returns a list of platform names, which can be used to
retrieve a L<Test::AutoBuild::Platform> object from the
C<platform> method.

=cut

sub platforms {
    my $self = shift;
    return keys %{$self->{platforms}};
}


=item my $platform = $runtime->platform($name);

Retrieves the L<Test::AutoBuild::Platform> object corresponding
to the name specified by the C<$name> parameter.

=cut

sub platform {
    my $self = shift;
    my $name = shift;
    if (!exists $self->{platforms}->{$name}) {
	confess "no platform called $name";
    }
    return $self->{platforms}->{$name};
}


sub host_platform {
    my $self = shift;
    foreach my $name ($self->platforms) {
	my $platform = $self->platform($name);
	if ($platform->name eq "host") {
	    return $platform;
	}
    }
    die "cannot locate host platform";
}

=item my $value = $runtime->attribute($name[, $value]);

Retrieves the attribute value corresponding to the key
given in the C<$name> parameter. If the optional C<$value>
parameter is supplied, then the attribute value is set.

=cut

sub attribute {
    my $self = shift;
    my $name = shift;
    $self->{attributes}->{$name} = shift if @_;
    return $self->{attributes}->{$name};
}

=item my @names = $runtime->attributes;

Returns the names of the runtime attributes passed between stages

=cut

sub attributes {
    my $self = shift;
    return keys %{$self->{attributes}};
}



=item my $build_counter = $runtime->build_counter;

Returns the unique counter for this cycle of the builder

=cut

sub build_counter {
    my $self = shift;
    $self->{build_counter} = $self->counter->generate($self) unless defined $self->{build_counter};
    return $self->{build_counter};
}



sub module_admin_email {
    my $self = shift;
    my $module = shift;
    return $module->admin_email ? $module->admin_email : $self->admin_email;
}


sub module_admin_name {
    my $self = shift;
    my $module = shift;
    return $module->admin_name ? $module->admin_name : $self->admin_name;
}


sub module_group_email {
    my $self = shift;
    my $module = shift;
    return $module->group_email ? $module->group_email : $self->group_email;
}


sub module_group_name {
    my $self = shift;
    my $module = shift;
    return $module->group_name ? $module->group_name : $self->group_name;
}

=item my $timestamp = $runtime->timestamp;

Returns the time to which the source repositories are
synchronized

=item $runtime->notify($event_name, @args);

Notify all monitors about the event specified by the C<$event_name>
parameter. The following C<@args> are event dependant and passed
through to monitors unchanged.

=cut

sub notify {
    my $self = shift;
    my $event_name = shift;
    my @args = @_;

    foreach my $name ($self->monitors) {
	$self->monitor($name)->notify($event_name, @args);
    }
}


=item my $dir = $runtime->source_root();

Retrieve the directory in which modules' sources are
checked out from the repositories

=item my $dir = $runtime->install_root();

Retrieve the directory into which modules install built
files.

=item my $dir = $runtime->package_root();

Retrieve the directory in which binary packages are
placed.

=item my $dir = $runtime->log_root();

Retrieve the directory in which log files are placed.

=item my \%packages = $runtime->package_snapshot();

Takes a snapshot of all packages on disk for each package
type. The keys in the returned hash ref will be the fully
qualified filenames of the packages, while the values
will be instances of Test::AutoBuild::Package class.

=cut

sub package_snapshot {
    my $self = shift;

    my $packages = {};
    foreach my $name ($self->package_types) {
	my $packs = $self->package_type($name)->snapshot();

	map { $packages->{$_} = $packs->{$_} } keys %{$packs};
    }
    return $packages;
}

sub installed_snapshot {
    my $self = shift;

    my $install_package_type =
	Test::AutoBuild::PackageType->new(name => "install",
					  label => "Install root",
					  extension => '',
					  spool => $self->install_root);
    return $install_package_type->snapshot();
}


=item my @values = $runtime->expand_macros($value[, \%restrictions]);

Replaces macros of the form %key in the string provided in
the C<$value> argument. A macro can expand to multiple values,
so the single input, can turn into multiple outputs, hence the
return from this method is an array of strings. A macro which
usually expands to multiple values can be restricted to a single
value by specifying the value in the optional C<%restrictions>
parameter.

The macros which will be expanded are:

=over 4

=item %m

List of modules, or the 'module' entry in the C<%restrictions> parameter

=item %p

List of package types, or the 'package_type' entry in the C<%restrictions> parameter

=item %g

List of groups, or the 'group' entry in the C<%restrictions> parameter

=item %r

List of repositories, or the 'reposiry' entry in the C<%restrictions> parameter

=item %h

Hostname of the builder

=item %c

Build cycle counter

=back

=cut

sub expand_macros {
    my $self = shift;
    my $value = shift;

    my %macros = (
	'm' => sub { $self->modules },
	'p' => sub { $self->package_types },
	'g' => sub { $self->groups },
	'r' => sub { $self->repositories },
	'h' => sub { hostname },
	'c' => sub { $self->counter },
    );

    if (@_) {
	my $restrictions = shift;
	$macros{m} = sub { $restrictions->{module}} if exists $restrictions->{module};
	$macros{p} = sub { $restrictions->{package_type}} if exists $restrictions->{package_type};
	$macros{g} = sub { $restrictions->{group}} if exists $restrictions->{group};
	$macros{r} = sub { $restrictions->{repository}} if exists $restrictions->{repository};
    }

    my @input = ($value);
    my @output;
    while (my $output = shift @input) {
	if ($output =~ /%(\w+)/) {
	    my $key = $1;
	    if (!exists $macros{$key}) {
		die "unknown macro %$key in $value";
	    }
	    my $code = $macros{$key};
	    my @macros = &$code;
	    foreach my $macro (@macros) {
		my $newoutput = $output;
		$newoutput =~ s/%$key/$macro/ex;
		push @input, $newoutput;
	    }
	} else {
	    push @output, $output;
	}
    }
    return @output;
}


=item my %env = $module->get_shell_environment($module);

Returns a hash containing the set of shell environment
variables to set when running the commands for the
module C<$module>. The following environment variables
are set

=over 4

=item $AUTO_BUILD_ROOT

Legacy variable for compatability with Test-AutoBuild 1.0.x.
Use $AUTOBUILD_INSTALL_ROOT instead.

=item $AUTO_BUILD_COUNTER

Legacy variable for compatability with Test-AutoBuild 1.0.x.
Use $AUTOBUILD_COUNTER instead.

=item $AUTOBUILD_INSTALL_ROOT

The location into which a module will install its files, typically
used as value for --prefix argument to configure scripts. This
is based on the value return by the C<install_root> method.

=item $AUTOBUILD_PACKAGE_ROOT

The location into which a module will create binary packages. For
example, $AUTOBUILD_PACKAGE_ROOT/rpm would be used to set %_topdir
when building RPMs. This is based on the value return by the
C<package_root> method.

=item $AUTOBUILD_SOURCE_ROOT

The location into which the module was checked out. This
is based on the value return by the C<install_root> method.

=item $AUTOBUILD_MODULE

The name of the module being built. This can be used in conjunction
with the $AUTOBUILD_SOURCE_ROOT to determine the top level directory
of the module's source.

=item $AUTOBUILD_COUNTER

The build counter value, based on the value return by the C<build_counter>
method. This counter is not guarenteed to be different on each build
cycle

=item $AUTOBUILD_TIMESTAMP

The build counter value, based on the value return by the C<build_counter>
method. This counter will uniquely refer to a particular checkout of the
source code.

=back

The returned hash will also include module specific environment
entries from the C<env> method.

=cut


sub get_shell_environment {
    my $self = shift;
    my $module = shift;

    my %env;

    $env{AUTO_BUILD_ROOT} = $self->install_root;
    $env{AUTO_BUILD_COUNTER} = $self->build_counter;

    # New style vars
    $env{AUTOBUILD_COUNTER} = $self->build_counter;
    $env{AUTOBUILD_TIMESTAMP} = $self->timestamp;
    $env{AUTOBUILD_INSTALL_ROOT} = $self->install_root;
    $env{AUTOBUILD_PACKAGE_ROOT} = $self->package_root;
    $env{AUTOBUILD_SOURCE_ROOT} = $self->source_root;
    $env{AUTOBUILD_MODULE} = $module->name;

    return %env;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel P. Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, L<Test::AutoBuild::Module>,
L<Test::AutoBuild::Repository>, L<Test::AutoBuild::PackageType>,
L<Test::AutoBuild::Monitor>, L<Test::AutoBuild::Group>,
L<Test::AutoBuild::Publisher>

=cut
