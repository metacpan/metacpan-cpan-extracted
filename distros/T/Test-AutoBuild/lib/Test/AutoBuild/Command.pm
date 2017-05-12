# -*- perl -*-
#
# Test::AutoBuild::Command
#
# Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2007 Daniel Berrange
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

Test::AutoBuild::Command - The base class for executing commands

=head1 SYNOPSIS

  use Test::AutoBuild::Command;

  my $cmd = Test::AutoBuild::Command->new(cmd => \@cmd, dir => $path, env => \%ENV);

  # Execute the command
  my $status = $counter->run($stdout, $stderr)

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Command;

use warnings;
use strict;
use Log::Log4perl;

use Class::MethodMaker
    [ new => [qw/ -init new /],
      scalar => [qw/ dir /],
      array => [qw/ cmd /],
      hash => [qw/ env options /]];

=item my $stage = Test::AutoBuild::Command->new(cmd => \@cmd, dir => $path);

Creates a new command to be executed. The C<cmd> argument provides an
array ref for the command line to be run. The optional C<dir> parameter
provides a directory path which will be setup as the current working
directory prior to executing the command.

=cut

sub init {
    my $self = shift;
    my %params = @_;

    die "cmd parameter is required" unless $params{cmd};
    $self->cmd(@{$params{cmd}});
    $self->dir($params{dir}) if $params{dir};
    $self->env(%{$params{env}}) if $params{env};
    $self->options(%{$params{options}}) if $params{options};
}


=item my $status = $cmd->run($stdout, $stderr);

Execute the command sending its STDOUT to <$stdout> and its STDERR
to C<$stderr>. The C<$stdout> and C<$stderr> parameters can either
contain file paths into which output will be written; be instances
of C<IO::Handle> to which output will be written, or simply be scalar
references to collect the data in memory. If they are undef, then
the output will be discarded. The returned C<$status> is the command
exit status, typically zero for success, non-zero for failure.

This method must be implemented by subclasses.

=cut


sub run {
    my $self = shift;

    die "class " . ref($self) . " forgot to implement the run method";
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,

=head1 COPYRIGHT

Copyright (C) 2007 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>,
L<Test::AutoBuild::Command::Local>, L<Test::AutoBuild::Command::SELocal>

=cut
