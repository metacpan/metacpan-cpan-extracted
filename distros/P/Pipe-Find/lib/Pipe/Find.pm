package Pipe::Find;

our $DATE = '2016-03-05'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       find_pipe_processes
                       get_stdin_pipe_process
                       get_stdout_pipe_process
               );

sub find_pipe_processes {
    my $mypid = shift // $$;

    my %procinfos;
    my $get_proc_info = sub {
        my $pid = shift;
        return $procinfos{$pid} if $procinfos{$pid};
        $procinfos{$pid} = {
            pid     => $pid,
            exe     => readlink("/proc/$pid/exe"),
            cmdline => do {
                local $/;
                open my($fh), "<", "/proc/$pid/cmdline";
                ~~<$fh>;
            },
        };
    };

    my $procs = {};
  FIND:
    {
        my $dh;

        opendir $dh, "/proc/$mypid/fd" or last;
        my %pipes_by_fd;
        my %fds_by_pipe;
        for my $fd (readdir $dh) {
            my $pipe = readlink "/proc/$mypid/fd/$fd";
            next unless $pipe && $pipe =~ /\Apipe:/;
            $pipes_by_fd{$fd} = $pipe;
            $fds_by_pipe{$pipe} = $fd;
        }
        last unless keys %pipes_by_fd;
        for my $fd (keys %pipes_by_fd) { $procs->{$fd} = undef }

        opendir $dh, "/proc" or last;
        my @pids = grep {/\A\d+\z/} readdir($dh);

        my %fds_by_pid;
      PID:
        for my $opid (@pids) {
            opendir $dh, "/proc/$opid/fd" or next PID;
            for my $ofd (readdir $dh) {
                my $pipe = readlink "/proc/$opid/fd/$ofd";
                next unless $pipe && $pipe =~ /\Apipe:/;
                next if $opid == $mypid && $ofd == $fds_by_pipe{$pipe};
                my $fd = $fds_by_pipe{$pipe} or next;
                $procs->{$fd} = $get_proc_info->($opid);
                push @{ $fds_by_pid{$opid} }, $fd;
                delete $pipes_by_fd{$fd};
            }
            last PID unless keys %pipes_by_fd;
        }

    }

    $procs;
}

sub get_stdin_pipe_process {
    find_pipe_processes()->{0};
}

sub get_stdout_pipe_process {
    find_pipe_processes()->{1};
}

1;
# ABSTRACT: Find the processes behind the pipes that you open

__END__

=pod

=encoding UTF-8

=head1 NAME

Pipe::Find - Find the processes behind the pipes that you open

=head1 VERSION

This document describes version 0.04 of Pipe::Find (from Perl distribution Pipe-Find), released on 2016-03-05.

=head1 SYNOPSIS

 use Pipe::Find qw(find_pipe_processes get_stdout_pipe_process);
 $procs = find_pipe_processes(); # hashref, key=fd, value=process info hash

 if ($procs->{0}) {
     say "STDIN is connected to a pipe";
     say "pid=$procs->{0}{pid}";
     say "cmdline=$procs->{0}{cmdline}";
     say "exe=$procs->{0}{exe}";
 }
 if ($procs->{1}) {
     say "STDOUT is connected to a pipe";
     ...
 }
 if ($procs->{2}) {
     say "STDERR is connected to a pipe";
     ...
 }
 # ...

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 find_pipe_processes([ $pid ]) => \%procs

List all processes behind the pipes that your process opens. (You can also find
pipes for another process by passing its PID.)

Currently only works on Linux. Works by listing C</proc/$$/fd> and selecting all
fd's that symlinks to C<pipe:*>. Then it will list all C</proc/*/fd> and find
matching pipes.

STDIN pipe is at fd 0, STDOUT pipe at fd 1, STDERR at fd 2.

=head2 get_stdin_pipe_process() => \%procinfo

Basically a shortcut to get the fd 0 only, since this is common. Return undef if
STDIN is not piped.

If you plan on getting process information for both STDIN and STDOUT, it's
better to use C<find_pipe_processes()> than calling this function and
C<get_stdout_pipe_process()>, because the latter will scan twice.

=head2 get_stdout_pipe_process() => \%procinfo

Basically a shortcut to get the fd 1 only, since this is common. Return undef if
STDOUT is not piped.

If you plan on getting process information for both STDIN and STDOUT, it's
better to use C<find_pipe_processes()> than calling this function and
C<get_stdin_pipe_process()>, because the latter will scan twice.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pipe-Find>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pipe-Find>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pipe-Find>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
