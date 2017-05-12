# -*- perl -*-
#
# Test::AutoBuild::Monitor::Pipe by Daniel Berrange <dan@berrange.com>
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

Test::AutoBuild::Monitor::Pipe - Monitor progress through a pipe

=head1 SYNOPSIS

  use Test::AutoBuild::Monitor::Pipe

  my $monitor = Test::AutoBuild::Pipe->new(
		      options => {
			path => "/var/lib/builder/monitor",
			mode = 0644
		      },
		      env => \%env);

  # Emit some events
  $monitor->notify("begin-stage", "build", time);
  $monitor->notify("end-stage", "build", time, $status);

=head1 DESCRIPTION

This module sends events down a pipe, one line per event. The
data is formatted in the scheme:

   begin-stage('build', '12450052')
   end-stage('build', '12452345', 'failed')

=head1 CONFIGURATION

Along with the standard configuration parameters for
C<Test::AutoBuild::Monitor>, this module expects two
options to be set:

=over 4

=item path

The full path to the FIFO pipe. The pipe will be created if
it does not already exist

=item mask

The permissions mask to use when creating the file, in
decimal, not octal. Defaults to 493, which is 0755 in
octal, if not specified.

=back

=head2 EXAMPLE

  pipe = {
    label = FIFO monitor
    module = Test::AutoBuild::Monitor::Pipe
    options = {
      path = /var/lib/builder/monitor
      # 0755 in decimal
      mask = 493
    }
  }

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Monitor::Pipe;

use base qw(Test::AutoBuild::Monitor);
use warnings;
use strict;
use IO::File;
use Test::AutoBuild::Lib;
use Carp qw(confess);
use POSIX qw(mkfifo);

=item $monitor->init(%params);

This method initializes a new monitor & is called automatically
by the C<new> method. The C<%params> parameters are passed through
from the C<new> method.

=cut

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    die "path option is required" unless defined $self->option("path");
    $self->option("mask", 493) unless defined $self->option("mask");
}


sub DESTROY {
    my $self = shift;

    if ($self->{pipe}) {
	$self->{pipe}->close();
    }
}

sub _open_pipe {
    my $self = shift;

    my $path = $self->option("path");
    my $mask = $self->option("mask");

    if (-e $path && !-p $path) {
	confess "path $path already exists and is not a pipe";
    }

    if (!-e $path && !(mkfifo $path, $mask)) {
	confess "cannot create fifo pipe: $!";
    }

    $self->{pipe} = IO::File->new(">$path")
	or confess "cannot open fifo pipe: $!";
}

=item $monitor->process($event_name, @args);

This method writes the event to the FIFO pipe and flushes
the output stream

=cut

sub process {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    $self->_open_pipe() unless defined $self->{pipe};

    my $args = join (", ", map { "'" . $_ . "'" } map { $_ =~ s/'/\\'/g; $_ } map { $_ =~ s/\\/\\\\/g; $_ } @args);
    $self->{pipe}->print($name, "(", $args, ")", "\n");
    $self->{pipe}->flush;
}


1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2005 Daniel Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Monitor>

=cut
