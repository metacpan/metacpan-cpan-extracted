# -*- perl -*-
#
# Test::AutoBuild::Stage::RSyncStatus
#
# Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2011 Red Hat, Inc.
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
# $Id: RSyncStatus.pm,v 1.9 2007/12/08 17:35:16 danpb Exp $

=pod

=head1 NAME

Test::AutoBuild::Stage::RSyncStatus - Create an index for RSyncStatus package management tool

=head1 SYNOPSIS

  use Test::AutoBuild::Stage::RSyncStatus

  my $stage = Test::AutoBuild::Stage::RSyncStatus->new(name => "rsync",
					       label => "Copy status pages to a target host",
					       options => {
						 target-uri => "rsync://somehost:var/lib/builder/public_html/public_html",
						 source-dir => "/var/lib/builder/public_html/public_html",
					       });

  $stage->run($runtime);

=head1 DESCRIPTION

This module invokes the C<rsync(1)> command to copy the status pages to a
target host using rsync.

=head1 CONFIGURATION

In addition to the standard parameters defined by the L<Test::AutoBuild::Stage>
module, this module accepts two entries in the C<options> parameter:

=over 4

=item target-uri

The RSync URI for the target host location.

=item source-dir

The of the local directory to be copied

=back

=head2 EXAMPLE

  {
    name = rsync
    label = Copy status page to target host
    module = Test::AutoBuild::Stage::RSyncStatus
    critical = 0
    options = {
      source-dir = /var/lib/builder/public_html/dist
      target-uri = rsync://somehost/var/lib/builder/public_html/public_html
    }
  }


=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Stage::RSyncStatus;

use base qw(Test::AutoBuild::Stage);
use warnings;
use strict;
use Log::Log4perl;

=item $stage->process($runtime);

This method invokes rsync to copy the local directory to the
target host

=cut

sub process {
    my $self = shift;
    my $runtime = shift;

    my $log = Log::Log4perl->get_logger();
    my $source = $self->option("source-dir");
    my $target = $self->option("target-uri");

    die "source-dir is required" unless $source;
    die "target-uri is required" unless $target;

    my $cmdopt = $self->option("command") || {};
    my $mod = $cmdopt->{module} || "Test::AutoBuild::Command::Local";
    my $opts = $cmdopt->{options} || {};
    eval "use $mod;";
    die "cannot load $mod: $!" if $@;

    # rync needs a trailing '/' to ensure we copy the contents
    # of the dir, not the dir itself
    $source .= "/";

    my @cmd = ("rsync",
	       "-av", "--delete",
	       $source, $target);
    my $c = $mod->new(cmd => \@cmd,
		      dir => $source,
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

Copyright (C) 2011 Red Hat, Inc.

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild::Stage>, C<rsync(1)>

=cut
