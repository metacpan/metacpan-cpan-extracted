# -*- perl -*-
#
# Test::AutoBuild::Repository by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2002 Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Repository - Source control repository access

=head1 SYNOPSIS

  use Test::AutoBuild::Repository

  my $rep = Test::AutoBuild::Repository->new(
	       name => $name,
	       options => \%options,
	       env => \%env,
	       label => $label);

  # Checkout / update the location '$src_path'
  # into local directory '$dst_path'
  my ($changed, $changes) = $rep->export($runtime, $src_path, $dst_path);

  # If the repository impl supports it, get the more
  # recent repository global changelist number
  my $changelist = $rep->changelist($runtime);

=head1 DESCRIPTION

This module provides the API for interacting with the source
control repositories. A repository implementation has to be
able to do two main things

 * Get a checkout of a new module
 * Update an existing checkout, determining if any
   changes where made

Optionally, it can also extract & return the details of all
changelists committed since the previous checkout operation.

=head1 CONFIGURATION

The valid configuration options for the C<repositories> block are

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Repository;

use strict;
use warnings;
use Test::AutoBuild::Lib;
use Log::Log4perl;

use Class::MethodMaker
    [ new => [qw/ -init new /],
      scalar => [qw/ name label /]];

=item my $rep = Test::AutoBuild::Repository->new(name => $name,
	   label => $label,
	   options => \%options,
	   env => \%env);

This method creates a new repository. The C<name> argument is an
alphanumeric token representing the name of the repository. The
C<label> argument is a human friendly name of the repository. The
optional C<options> argument is a hashref of implementation
specific options. The optional C<env> argument is a hashref of
environment variables to set when running the commands to access
the repository.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    $self->name(exists $params{name} ? $params{name} : die "name parameter is required");
    $self->label(exists $params{label} ? $params{label} : die "label parameter is required");
    $self->{options} = exists $params{options} ? $params{options} : {};
    $self->{env} = exists $params{env} ? $params{env} : {};
    $self->{modules} = {};
}


=item my $value = $rep->changelist($runtime);

Returns the changelist to which the repository is synchronized. This
is defined to be the most recent changelist, not newer than the timestamp
to which the build runtime is set. This method should be implemented by
any repository types which support changelists. For those that don't the
default implementation will throw an error.

=cut

sub changelist {
    my $self = shift;
    my $runtime = shift;

    die "module " . ref($self) . " does not support changelists";
}

=item my $name = $rep->name([$name]);

When run without any arguments, returns the alphanumeric token representing
the name of the repository. If a single argument is supplied, this is use to
update the name.

=item my $label = $rep->label([$label]);

When run without any arguments, returns the human friendly string representing
the label of the repository. If a single argument is supplied, this is use to
update the label.

=item my $value = $rep->option($name[, $value]);

When run with a single argument, retuns the option value corresponding to
the name specified in the first argument. If a second argument is supplied,
then the option value is updated.

=cut

sub option {
   my $self = shift;
   my $name = shift;

   $self->{options}->{$name} = shift if @_;

   return $self->{options}->{$name};
}

=item my $value = $rep->env($name[, $value]);

When run with a single argument, retuns the environment variable corresponding
to the name specified in the first argument. If a second argument is supplied,
then the environment variable is updated.

=cut

sub env {
   my $self = shift;
   my $name = shift;

   $self->{env}->{$name} = shift if @_;
   return $self->{env}->{$name};
}




=item my ($changed, $changes) = $rep->export($runtime, $src, $dst);

Exports the location C<$src> into the directory C<$dst>. Returns zero if
there were no changes to export; non-zero if the module was new or changed.
The second return parameter is a hash reference whose keys are change numbers,
and values are the corresponding L<Test::AutoBuild::Change> objects. This
second parameter is optional, since not all repositories maintain changelists.
This is a virtual method which must be implemented by all subclasses.

=cut

sub export {
    my $self = shift;
    my $runtime = shift;
    my $src = shift;
    my $dst = shift;
    die "class " . ref($self) . " forgot to implement the export method";
}

=item my ($output, $errors) = $rep->_run($cmd);

Runs the command specified in the first argument, having first
setup the environment variables specified when the repository
was created. It returns any text written to standard out by the
command

=cut

sub _run {
    my $self = shift;
    my $cmd = shift;
    my $dir = shift;
    my $logfile = shift;

    my $cmdopt = $self->option("command") || {};
    my $mod = $cmdopt->{module} || "Test::AutoBuild::Command::Local";
    my $opts = $cmdopt->{options} || {};
    eval "use $mod;";
    die "cannot load $mod: $!" if $@;

    my $c = $mod->new(cmd => $cmd,
		      dir => $dir,
		      env => $self->{env},
		      options => $opts);

    my ($output, $errors);
    my $status = $c->run(\$output, \$errors);

    $output = "" unless defined $output;
    $errors = "" unless defined $errors;

    die "command '" . join("' '", @{$cmd}) . "' exited with status $status\n$errors" if $status;

    if ($logfile) {
	$self->_append_log($logfile, join(" ", @{$cmd}) . "\n");
	$self->_append_log($logfile, $output) if $output ne "";
	$self->_append_log($logfile, $errors) if $errors ne "";
    }

    return ($output, $errors);
}

sub _append_log {
    my $self = shift;
    my $logfile = shift;
    my $data = shift;

    open LOG, ">>$logfile"
	or die "cannot append $logfile: $!";
    print LOG $data;
    close LOG
	or die "cannot save $logfile: $!";
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2002 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Module>, L<Test::AutoBuild::Repository::CVS>, L<Test::AutoBuild::Repository::GNUArch>, L<Test::AutoBuild::Repository::Perforce>, L<Test::AutoBuild::Repository::Mercurial>, L<Test::AutoBuild::Repository::Subversion>, L<Test::AutoBuild::Repository::Disk>, L<Test::AutoBuild::Repository::SVK>

=cut
