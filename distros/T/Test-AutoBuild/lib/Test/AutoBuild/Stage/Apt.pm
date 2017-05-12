# -*- perl -*-
#
# Test::AutoBuild::Stage::Apt
#
# Copyright (C) 2005 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Stage::Apt - Create index for APT package management tool

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::Apt

  # Create an index of RPMs, structured by module, restricted
  # to only include the module 'autobuild-dev'
  my $stage = Test::AutoBuild::Stage::Apt->new(name => "apt",
					       label => "Create apt index",
					       options => {
						 directory => "/var/lib/builder/public_html/dist",
						 format => "rpm",
						 type => "modules",
						 components => ["autobuild-dev"],
					       });


  # Create an index of RPMs, structured by module, for all
  # configured modules
  my $stage = Test::AutoBuild::Stage::Apt->new(name => "apt",
					       label => "Create apt index",
					       options => {
						 directory => "/var/lib/builder/public_html/dist",
						 format => "rpm",
						 type => "modules",
					       });

  # Create an index of RPMs, structured by group, for all
  # configured groups
  my $stage = Test::AutoBuild::Stage::Apt->new(name => "apt",
					       label => "Create apt index",
					       options => {
						 directory => "/var/lib/builder/public_html/dist",
						 format => "rpm",
						 type => "groups",
					       });


  $stage->run($runtime);

=head1 DESCRIPTION

This module invokes the C<genbasedir> command to generate a package
index, enabling the C<apt-get(8)> command to install RPMs directly off
the build status pages. The components in the index can either be
groups or modules. By default this stage will create an index for
all groups or modules defined in the runtime object, but this can
be restricted to a subset. At a future date this will be tweaked to
also support indexing Debian packages. The packages are hard linked
into the distribute directories, so no significant additional disk
space is consumed over that already used by the builder distribution
site.

=head1 CONFIGURATION

In addition to the standard parameters defined by the L<Test::AutoBuild::Stage>
module, this module accepts four entries in the C<options> parameter:

=over 4

=item directory

The full path to the directory containing RPMs to be indexed.

=item format

The format of the packages to index, either C<rpm> or C<debian>,
although the latter is not yet functional, defaults to C<rpm>.

=item type

How to structure the package indexes, either by C<group>, or by
C<module>, defaults to C<module>.

=item components

Optionally restrict the index to a subset of the groups / modules,
by specifying an array of group / module names.

=back

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::Apt;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Log::Log4perl;
use File::Spec::Functions;
use File::Path;
use Test::AutoBuild::Lib;

=item $stage->process($runtime);

This method will link in the generated packages to directory
named in the C<directory> option, and then run the C<genbasedir>
command to index them.

=cut

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();
    my $directory = $self->option('directory');
    my $format = $self->option("format") || "rpm";
    my $type = $self->option("type") || "module";
    my $components = $self->option("components");

    mkpath($directory);

    if ($type eq "module") {
	my @modules = $components ? @{$components} : $runtime->modules;
	foreach my $name (@modules) {
	    my $module = $runtime->module($name);

	    if ($format eq "rpm") {
		my $rpmdir = catfile($directory, "RPMS.$name");
		my $srpmdir = catfile($directory, "SRPMS.$name");

		mkpath($rpmdir);
		mkpath($srpmdir);

		foreach my $filename (keys %{$module->packages}) {
		    if ($filename =~ /\.src\.rpm$/) {
			$log->info("Copy $filename $srpmdir");
			Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $srpmdir);
		    } elsif ($filename =~ /\.rpm$/) {
			$log->info("Copy $filename $rpmdir");
			Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $rpmdir);
		    }
		}
	    } elsif ($format eq "debian") {
		my $debdir = catfile($directory, "debian.$name");
		mkpath($debdir);

		foreach my $filename (keys %{$module->packages}) {
		    if ($filename =~ /\.deb$/) {
			$log->info("Copy $filename $debdir");
			Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $debdir);
		    }
		}
	    }
	}
    } else {
	my @groups = $components ? @{$components} : $runtime->groups;
	foreach my $name (@groups) {
	    my $group = $runtime->group($name);

	    if ($format eq "rpm") {
		my $rpmdir = catfile($directory, "RPMS.$name");
		my $srpmdir = catfile($directory, "SRPMS.$name");

		mkpath($rpmdir);
		mkpath($srpmdir);

		foreach my $modname (@{$group->modules}) {
		    my $module = $runtime->module($modname);
		    print "Got $modname $module\n";
		    foreach my $filename (keys %{$module->packages}) {
			if ($filename =~ /\.src\.rpm$/) {
			    $log->info("Copy $filename $srpmdir");
			    Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $srpmdir);
			} elsif ($filename =~ /\.rpm$/) {
			    $log->info("Copy $filename $rpmdir");
			    Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $rpmdir);
			}
		    }
		}
	    } elsif ($format eq "debian") {
		my $debdir = catfile($directory, "debian.$name");
		mkpath($debdir);

		foreach my $module ($group->modules) {
		    foreach my $filename (keys %{$module->packages}) {
			if ($filename =~ /\.deb$/) {
			    $log->info("Copy $filename $debdir");
			    Test::AutoBuild::Lib::_copy({ 'link' => 1 }, $filename, $debdir);
			}
		    }
		}
	    }
	}

    }

    my $cmdopt = $self->option("command") || {};
    my $mod = $cmdopt->{module} || "Test::AutoBuild::Command::Local";
    my $opts = $cmdopt->{options} || {};
    eval "use $mod;";
    die "cannot load $mod: $!" if $@;

    my @cmd = ("genbasedir",
	       "--flat",
	       $directory);
    my $c = $mod->new(cmd => \@cmd,
		      dir => $directory,
		      options => $opts);

    my ($output, $errors);
    my $status = $c->run(\$output, \$errors);

    $output = "" unless defined $output;
    $errors = "" unless defined $errors;

    $log->debug("Output: [$output]") if $output;
    $log->debug("Errors: [$errors]") if $errors;

    die "command '" . join("' '", @cmd) . "' exited with status $status\n$errors" if $status;
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, C<apt-get(8)>

=cut
