# Paranoid -- Paranoia support for safer programs
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);

($VERSION) = ( q$Revision: 2.06 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(psecureEnv);
@EXPORT_OK   = ( @EXPORT, qw(PTRUE_ZERO) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PTRUE_ZERO => '0 but true';

#####################################################################
#
# Module code follows
#
#####################################################################

#BEGIN {
#die "This module requires taint mode to be enabled!\n" unless
#  ${^TAINT} == 1;
#delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
#$ENV{PATH} = '/bin:/sbin:/usr/bin:/usr/sbin';
#no ops qw(backtick system exec);
#  :subprocess = system, backtick, exec, fork, glob
#  :dangerous = syscall, dump, chroot
#  :others = mostly IPC stuff
#  :filesys_write = link, unlink, rename, mkdir, rmdir, chmod,
#                   chown, fcntl
#  :sys_db = getpwnet, etc.
#}

sub psecureEnv (;$) {

    # Purpose:  To delete taint-unsafe environment variables and to sanitize
    #           the PATH variable
    # Returns:  True (1) -- no matter what
    # Usage:    psecureEnv();

    my $path = shift;

    $path = '/bin:/usr/bin' unless defined $path;

    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
    $ENV{PATH} = $path;
    if ( exists $ENV{TERM} ) {
        if ( $ENV{TERM} =~ /^([\w\+\.\-]+)$/s ) {
            $ENV{TERM} = $1;
        } else {
            $ENV{TERM} = 'vt100';
        }
    }

    return 1;
}

{
    my $errorMsg = '';

    sub ERROR : lvalue {

        # Purpose:  To store/retrieve a string error message
        # Returns:  Scalar string
        # Usage:    $errMsg = Paranoid::ERROR;
        # Usage:    Paranoid::ERROR = $errMsg;

        $errorMsg;
    }
}

1;

__END__

=head1 NAME

Paranoid - Paranoia support for safer programs

=head1 VERSION

$Id: lib/Paranoid.pm, 2.06 2018/08/05 01:21:48 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid;

  $errMsg = Paranoid::ERROR;

  psecureEnv("/bin:/usr/bin");

=head1 DESCRIPTION

This collection of modules started out as modules which perform things
(debatably) in a safer and taint-safe manner.  Since then it's also grown to
include functionality that fit into the same framework and conventions of the
original modules, including keeping the debug hooks for command-line
debugging.

All the modules below are intended to be used directly in your programs if you
need the functionality they provide.

This module does provide one function meant to secure your environment 
enough to satisfy taint-enabled programs, and as a container which holds the 
last reported error from any code in the Paranoid framework.

=head1 SUBROUTINES/METHODS

=head2 psecureEnv

  psecureEnv("/bin:/usr/bin");

This function deletes some of the dangerous environment variables that can be
used to subvert perl when being run in setuid applications.  It also sets the
path, either to the passed argument (if passed) or a default of
"/bin:/usr/bin".

=head2 Paranoid::ERROR

  $errMsg = Paranoid::ERROR;
  Paranoid::ERROR = $errMsg;

This lvalue function is not exported and must be referenced via the 
B<Paranoid> namespace.

=head1 TAINT NOTES

Taint-mode programming can be somewhat of an adventure until you know all the
places considered dangerous under perl's taint mode.  The following functions
should generally have their arguments detainted before using:

  exec        system      open        glob
  unlink      mkdir       chdir       rmdir
  chown       chmod       umask       utime
  link        symlink     kill        eval
  truncate    ioctl       fcntl       chroot
  setpgrp     setpriority syscall     socket
  socketpair  bind        connect

=head1 DEPENDENCIES

While this module itself doesn't have any external dependencies various child
modules do.  Please check their documentation for any particulars should you
use them.

=head1 SEE ALSO

The following modules are available for use.  You should check their POD for
specifics on use:

=over

=item o

L<Paranoid::Args>: Command-line argument parsing functions

=item o

L<Paranoid::Data>: Misc. data manipulation functions

=item o

L<Paranoid::Debug>: Command-line debugging framework and functions

=item o

L<Paranoid::Filesystem>: Filesystem operation functions

=item o

L<Paranoid::Glob>: Paranoid Glob objects

=item o

L<Paranoid::IO>: File I/O wrappers for sysopen, etc.

=item o

L<Paranoid::IO::Line>: I/O functions for working with line-based files

=item o

L<Paranoid::IO::Lockfile>: I/O functions for working with lock files

=item o

L<Paranoid::Input>: Input-related functions (file reading, detainting)

=item o

L<Paranoid::Log>: Unified logging framework and functions

=item o

L<Paranoid::Log::Buffer>: Buffered-based logging mechanism

=item o

L<Paranoid::Log::File>: File-based logging mechanism

=item o

L<Paranoid::Module>: Run-time module loading functions

=item o

L<Paranoid::Network>: Network-related functions

=item o

L<Paranoid::Network::IPv4>: General IPv4-related functions

=item o

L<Paranoid::Network::IPv6>: General IPv6-related functions

=item o

L<Paranoid::Network::Socket>: Wrapper module for Socket & Socket6

=item o

L<Paranoid::Process>: Process management functions

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

