# Paranoid -- Paranoia support for safer programs
#
# $Id: lib/Paranoid.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
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

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(psecureEnv);
@EXPORT_OK   = ( @EXPORT, qw(PTRUE_ZERO) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PTRUE_ZERO   => '0 but true';
use constant DEFAULT_PATH => '/bin:/sbin:/usr/bin:/usr/sbin';

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

    $path = DEFAULT_PATH unless defined $path;

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

$Id: lib/Paranoid.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid;

  $errMsg = Paranoid::ERROR;

  psecureEnv("/bin:/usr/bin");

  sub foo {
    # this function can return '0' as a valid return value
    # that should be construed as a boolean true value

    return PTRUE_ZERO;
  }

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

=head1 IMPORT LISTS

This module exports the following symbols by default:

    psecureEnv

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    all         @defaults PTRUE_ZERO

=head1 SUBROUTINES/METHODS

=head2 psecureEnv

  psecureEnv("/bin:/usr/bin");

This function deletes some of the dangerous environment variables that can be
used to subvert perl when being run in setuid applications.  It also sets the
path, either to the passed argument (if passed) or a default of
"/bin:/sbin:/usr/bin:/usr/sbin".

B<NOTE:> I did explicitly exclude I</usr/local> directories from the default
path for the following reason:  I</usr/local> is often used by admins to stash
random scripts and programs which may not have undergone any serious scrutiny
and review for security issues.  Only the base OS directories are presumed as
safe, and even that may be stretching the truth as it is.  You can override
the defaults as desired.

=head2 Paranoid::ERROR

  $errMsg = Paranoid::ERROR;
  Paranoid::ERROR = $errMsg;

This lvalue function is not exported and must be referenced via the 
B<Paranoid> namespace.

=head2 PTRUE_ZERO

This is a constant that evaluates to '0 but true', which allows I<0> to be
passed for boolean true use-cases.

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

L<Paranoid::Data::AVLTree>: AVL-Balanced Tree Class

=item o

L<Paranoid::Data::AVLTree::AVLNode>: AVL-Balanced Tree Node Class

=item o

L<Paranoid::Debug>: Command-line debugging framework and functions

=item o

L<Paranoid::Filesystem>: Filesystem operation functions

=item o

L<Paranoid::Glob>: Paranoid Glob objects

=item o

L<Paranoid::IO>: File I/O wrappers for sysopen, etc.

=item o 

L<Paranoid::IO::FileMultiplexer>: File Multiplexer Object

=item o 

L<Paranoid::IO::FileMultiplexer::Block>: Block-level Allocator/Accessor

=item o 

L<Paranoid::IO::FileMultiplexer::Block::BATHeader>: BAT Header Block

=item o 

L<Paranoid::IO::FileMultiplexer::Block::FileHeader>: File Header Block

=item o 

L<Paranoid::IO::FileMultiplexer::Block::StreamHeader>: Stream Header Block

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

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

