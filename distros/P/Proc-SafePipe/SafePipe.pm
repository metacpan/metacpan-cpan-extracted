# $Id: SafePipe.pm,v 1.1 2000-09-23 21:23:56-04 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use 5.003_98;	# piped close errno resetting

=head1 NAME

Proc::SafePipe - popen() and `` without calling the shell

=head1 SYNOPSIS

    $fh		= popen_noshell 'r', 'decrypt', $input;
    ($fh, $pid)	= popen_noshell 'w', 'ssh', $host, "cat >$output";

    $all_output	= backtick_noshell 'decrypt', $input;
    @lines	= backtick_noshell $cmd, @arg;

=head1 DESCRIPTION

These functions provide a simple way to read from or write to commands
which are run without being interpreted by the shell.  They croak if
there's a system failure, such as a failed fork.

=over 4

=cut

package Proc::SafePipe;

use Carp	qw(croak);
use Exporter	  ();
use Symbol	qw(gensym);

use vars	qw($VERSION @ISA @EXPORT);

$VERSION	= 0.01;
@ISA		= qw(Exporter);
@EXPORT		= qw(popen_noshell backtick_noshell);

=item B<popen_noshell> I<mode> I<command> [I<arg>]...

This function is similar to popen() except that the I<command> and its
related I<arg>s are never interpreted by a shell, they are passed to
exec() as-is.  The I<mode> argument must be C<'r'> or C<'w'>.

If called in an array context the return value is a list consisting of
the filehandle and the PID of the child.  In a scalar context only the
filehandle is returned.

=cut

sub popen_noshell {
    @_ > 1 or croak 'Usage: popen_noshell {r|w} command [arg]...';
    my ($type, @cmd) = @_;
    if ($type eq 'r')		{ $type = '-|' }
    elsif ($type eq 'w')	{ $type = '|-' }
    else {
	croak "Invalid popen mode `$type'"
    }

    my $fh = gensym;
    my $pid = open $fh, $type;
    defined $pid			or croak "Can't fork: $!";
    if (!$pid) {
	local $^W; # disable exec failure warning
	exec { $cmd[0] } @cmd		or croak "Can't exec $cmd[0]: $!";
    }
    wantarray ? ($fh, $pid) : $fh;
}

=item B<backtick_noshell> I<command> [I<arg>]...

This function runs the given I<command> with the given I<arg>s and
returns the output, like C<``> does.  The difference is that the
arguments are not filtered through a shell, they are exec()ed directly.

The return value is either all the output from the command (if in a
scalar context) or a list of the lines gathered from the command (in an
array context).  The exit status of the command is in $?.

=cut

sub backtick_noshell {
    @_ >= 1 or croak 'Usage: backtick_noshell command [arg]...';
    my @cmd = @_;
    my ($fh, @output);

    $fh = popen_noshell 'r', @cmd;
    @output = <$fh>;
    close $fh or !$! or croak "Error closing $fh: $!";
    wantarray ? @output : join '', @output;
}

1

__END__

=back

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=cut
