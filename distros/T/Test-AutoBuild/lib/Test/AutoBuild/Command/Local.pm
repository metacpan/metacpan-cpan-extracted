# -*- perl -*-
#
# Test::AutoBuild::Command::Local
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

Test::AutoBuild::Command::Local - A locally executed command

=head1 SYNOPSIS

  use Test::AutoBuild::Command::Local;

  my $cmd = Test::AutoBuild::Command::Local->new(cmd => \@cmd, dir => $path);

  # Execute the command
  my $status = $counter->run($stdout, $stderr)

=head1 METHODS

=over 4

=cut

package Test::AutoBuild::Command::Local;

use warnings;
use strict;
use Log::Log4perl;
use POSIX;
use Symbol qw(gensym);
#use Cwd;

use base qw(Test::AutoBuild::Command);


=item my $status = $cmd->run($stdout, $stderr);

Execute the command sending its STDOUT to <$stdout> and its STDERR
to C<$stderr>. The C<$stdout> and C<$stderr> parameters can either
contain file paths into which output will be written; be instances
of C<IO::Handle> to which output will be written, or simply be scalar
references to collect the data in memory. If they are undef, then
the output will be discarded. The returned C<$status> is the command
exit status, typically zero for success, non-zero for failure.

=cut


sub run {
    my $self = shift;
    my $stdout = shift;
    my $stderr = shift;

    my $log = Log::Log4perl->get_logger();

    my $cwd = getcwd;
    if ($self->dir) {
	die "cannot change into '" . $self->dir . "': $!" unless chdir $self->dir;
    }

    $log->debug("running: '" . join("' '", $self->cmd) . "' in /" . getcwd  . "'");

    local %ENV = %ENV;
    my %env = $self->env;
    foreach my $key (keys %env) {
	$log->debug("Set env $key to " . $env{$key});
	$ENV{$key} = $env{$key};
    }

    my $status;
    eval {
	my @cmd = $self->cmd;
	$status = $self->_run($stdout, $stderr);
    };
    my $err = $@;
    if ($self->dir) {
	die "cannot change back into '$cwd': $!" unless chdir $cwd;
    }
    die $err if $err;
    return $status;
}

sub _run {
    my $self = shift;
    my $stdout = shift;
    my $stderr = shift;

    my $stdoutfh;
    my $stderrfh;
    if (defined $stdout) {
	if (ref($stdout)) {
	    if (UNIVERSAL::isa($stdout, "IO::Handle")) {
		$stdoutfh = $stdout;
	    }
	} else {
	    $stdoutfh = IO::File->new($stdout, "w+");
	    die "cannot open $stdout" unless $stdoutfh;
	}
    }
    if (defined $stderr) {
	if (ref($stderr)) {
	    if (UNIVERSAL::isa($stderr, "IO::Handle")) {
		$stderrfh = $stderr;
	    }
	} else {
	    if (defined $stdout && !ref($stdout) && $stderr eq $stdout) {
		$stderrfh = $stdoutfh;
	    } else {
		$stderrfh = IO::File->new($stderr, "w+");
		die "cannot open $stderr" unless $stderrfh;
	    }
	}
    }

    my ($kid, $kidout, $kiderr) = $self->_execute();
    eval {
	while (1) {
	    my ($r,$w,$e) = ('','','');
	    vec($r, fileno($kidout), 1) = 1 if $kidout;
	    vec($r, fileno($kiderr), 1) = 1 if $kiderr;
	    my ($n, $ignore) = select($r, $w, $e, undef);

	    if ($kidout && vec($r, fileno($kidout), 1)) {
		my $data;
		my $bytes = POSIX::read fileno($kidout), $data, 1024;

		if (!$bytes || $bytes == 0) {
		    close ($kidout);
		    $kidout = undef;
		} else {
		    if ($stdoutfh) {
			POSIX::write fileno($stdoutfh), $data, $bytes;
		    } elsif (defined $stdout &&
			     ref($stdout)) {
			${$stdout} .= $data;
		    }
		}
	    }
	    if ($kiderr && vec($r, fileno($kiderr), 1)) {
		my $data;
		my $bytes = POSIX::read fileno($kiderr), $data, 1024;

		if (!$bytes || $bytes == 0) {
		    close ($kiderr);
		    $kiderr = undef;
		} else {
		    if ($stderrfh) {
			POSIX::write fileno($stderrfh), $data, $bytes;
		    } elsif (defined $stderr &&
			     ref($stderr)) {
			${$stderr} .= $data;
		    }
		}
	    }
	    last unless $kiderr || $kidout;
	}
    };
    my $err = $@;

    my $pid = waitpid $kid, 0;
    die "got unexpected child $pid instead of $kid" if $pid != $kid;
    my $status = ($? >> 8);

    close $kidout if $kidout;
    close $kiderr if $kiderr;
    close $stdoutfh if $stdoutfh;
    close $stderrfh if $stderrfh;

    die $err if $err;

    return $status;
}


sub _execute {
    my $self = shift;

    my ($dadr,$dadw,$dade) = (gensym, gensym, gensym);
    my ($kidr,$kidw,$kide) = (gensym, gensym, gensym);

    pipe $kidr, $dadr or die "cannot create pipe for stdin:$!";
    pipe $dadw, $kidw or die "cannot create pipe for stdout:$!";
    pipe $dade, $kide or die "cannot create pipe for stderr:$!";

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
