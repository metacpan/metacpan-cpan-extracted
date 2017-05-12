package Siebel::Srvrmgr::IPC;

=pod

=head1 NAME

Siebel::Srvrmgr::IPC - IPC functionality for Siebel::Srvrmgr classes.

=head1 SYNOPSIS

	use Siebel::Srvrmgr::IPC qw(safe_open3);

	my ( $pid, $write_h, $read_h, $error_h ) = safe_open3( \@params );

=head1 DESCRIPTION

This module exports a single function (C<safe_open3>) used for running a external program, reading it's STDOUT, STDERR and writing to STDIN by
using IPC.

This module is based on L<IPC::Open3::Callback> from Lucas Theisen (see SEE ALSO section).

=cut

use warnings;
use strict;
use IPC::Open3;
use Carp;
use Symbol 'gensym';
use IO::Socket;
use Config;
use POSIX qw(WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG WIFSTOPPED);
use Exporter 'import';
our @EXPORT_OK = qw(safe_open3 check_system);

our $VERSION = '0.29'; # VERSION

=pod

=head1 EXPORTS

=head2 safe_open3

C<safe_open3> functions executes a "safe" version of L<IPC::Open3> that will execute additional processing required for using C<select> in Microsoft
Windows OS (if automatically detected). For other OS's, the default functionality of L<IPC::Open3> is used.

Expects as parameter an array reference with the external program to execute, including the arguments for it.

Returns (in this order):

=over

=item 1.

The PID of the child process executing the external program.

=item 2.

The writer handle to the child process.

=item 3.

The reader handle to the child process.

=item 4.

The error handle for the child process.

=back

=cut

sub safe_open3 {
    return ( $Config{osname} eq 'MSWin32' )
      ? Siebel::Srvrmgr::IPC::_mswin_open3( $_[0] )
      : Siebel::Srvrmgr::IPC::_default_open3( $_[0] );
}

sub _mswin_open3 {
    my $cmd_ref = shift;
    my ( $inRead,  $inWrite )  = Siebel::Srvrmgr::IPC::_mswin_pipe();
    my ( $outRead, $outWrite ) = Siebel::Srvrmgr::IPC::_mswin_pipe();
    my ( $errRead, $errWrite ) = Siebel::Srvrmgr::IPC::_mswin_pipe();
    my $pid = open3(
        '>&' . fileno($inRead),
        '<&' . fileno($outWrite),
        '<&' . fileno($errWrite),
        @{$cmd_ref}
    );
    return ( $pid, $inWrite, $outRead, $errRead );
}

sub _mswin_pipe {
    my ( $read, $write ) =
      IO::Socket->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC );
    Siebel::Srvrmgr::IPC::_check_shutdown( 'read', $read->shutdown(SHUT_WR) )
      ;    # No more writing for reader
    Siebel::Srvrmgr::IPC::_check_shutdown( 'write', $write->shutdown(SHUT_RD) )
      ;    # No more reading for writer
    return ( $read, $write );
}

sub _check_shutdown {
    my ( $which, $ret ) = @_;    # which handle name will be partly shutdown

    unless ( defined($ret) ) {
        confess "first argument of shutdown($which) is not a valid filehandle";
    }
    else {
        confess "An error ocurred when trying shutdown($which): $!"
          if ( $ret == 0 );
    }
}

sub _default_open3 {
    my $cmd_ref = shift;
    my ( $inFh, $outFh, $errFh ) = ( gensym(), gensym(), gensym() );
    return ( open3( $inFh, $outFh, $errFh, @{$cmd_ref} ), $inFh, $outFh,
        $errFh );
}

=head2 check_system

For non-Windows systems, returns additional information about the child process created by a C<system> call as a string. Also, it returns a boolean (in Perl sense)
indicating if this is a error (1) or not (0);

Expects as parameter the environment variable C<${^CHILD_ERROR_NATIVE}> value, available right after the C<system> call.

=cut

# :TODO:22-09-2014 13:26:35:: should implement exceptions to this
sub check_system {
    my $child_error = shift;

    unless ( $Config{osname} eq 'MSWin32' ) {

        if ( WIFEXITED($child_error) ) {

            if ( WEXITSTATUS($child_error) == 0 ) {
                return
'Child process terminate with call to exit() with return code = '
                  . WEXITSTATUS($child_error), 0;
            }
            else {
                return
'Child process terminate with call to exit() with return code = '
                  . WEXITSTATUS($child_error), 1;
            }
        }

        if ( WIFSIGNALED($child_error) ) {
            return 'Child process terminated due signal: '
              . WTERMSIG($child_error), 1;
        }

        if ( WIFSTOPPED($child_error) ) {
            return 'Child process was stopped with ' . WSTOPSIG($child_error),
              1;
        }
        else {
            return 'Not able to check child process information', undef;
        }

    }
    else {
        return;
    }

}

=pod

=head1 SEE ALSO

=over

=item *

L<https://github.com/lucastheisen/ipc-open3-callback>

=item *

L<IPC::Open3>

=item *

L<IO::Socket>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
