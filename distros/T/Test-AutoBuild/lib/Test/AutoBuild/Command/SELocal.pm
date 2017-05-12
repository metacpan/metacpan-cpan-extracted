# -*- perl -*-
#
# Test::AutoBuild::Command::SELocal
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

Test::AutoBuild::Command::SELocal - A locally executed command with mandatory access control

=head1 SYNOPSIS

  use Test::AutoBuild::Command::SELocal;

  my $cmd = Test::AutoBuild::Command::SELocal->new(cmd => \@cmd, dir => $path);

  # Execute the command
  my $status = $counter->run($stdout, $stderr)

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Command::SELocal;

use warnings;
use strict;
use Log::Log4perl;
use Symbol qw(gensym);

use base qw(Test::AutoBuild::Command::Local);

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    die "no security context specified" unless
	$self->options->{"context"};
}

sub _execute {
    my $self = shift;

    my ($dadr,$dadw,$dade) = (gensym, gensym, gensym);
    my ($kidr,$kidw,$kide) = (gensym, gensym, gensym);

    pipe $kidr, $dadr or die "cannot create pipe for stdin:$!";
    pipe $dadw, $kidw or die "cannot create pipe for stdout:$!";
    pipe $dade, $kide or die "cannot create pipe for stderr:$!";

    my $log = Log::Log4perl->get_logger();

    my $context = $self->options->{"context"};
    $log->info("Executing with context '$context'");

    my $kid = fork();

    die "cannot fork child:$!" unless defined $kid;

    if ($kid) {
	close $kidr;
	close $kidw;
	close $kide;

	close $dadr;

	return ($kid, $dadw, $dade);
    } else {
	close $dadr;
	close $dadw;
	close $dade;

	open CONTEXT, ">/proc/self/attr/exec"
	    or die "cannot write to /proc/self/attr/exec: $!";
	print CONTEXT $context;
	close CONTEXT;

	open \*STDIN, "<&=" . fileno($kidr) or die "cannot dup stdin: $!";
	close($kidr);
	open \*STDOUT, ">&=" . fileno($kidw) or die "cannot dup stdout: $!";
	close($kidw);
	open \*STDERR, ">&=" . fileno($kide) or die "cannot dup stderr: $!";
	close($kide);

	exec $self->cmd;

	die "cannot execute child: $!";
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>,

=head1 COPYRIGHT

Copyright (C) 2007 Daniel Berrange

=head1 SEE ALSO

C<perl(1)>, L<Test::AutoBuild>, L<Test::AutoBuild::Runtime>, L<Test::AutoBuild::Command>

=cut
