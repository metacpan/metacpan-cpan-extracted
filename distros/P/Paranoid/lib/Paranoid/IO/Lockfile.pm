# Paranoid::IO::Lockfile -- Paranoid Lockfile support
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/IO/Lockfile.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $
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

package Paranoid::IO::Lockfile;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Fcntl qw(:flock O_RDWR O_CREAT O_EXCL);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::IO;

($VERSION) = ( q$Revision: 2.07 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(plock pexclock pshlock punlock);
@EXPORT_OK   = @EXPORT;
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PRIV_UMASK => 0660;

#####################################################################
#
# Module code follows
#
#####################################################################

sub plock {

    # Purpose:  Opens and locks the specified file.
    # Returns:  True/false
    # Usage:    $rv = plock( $filename );
    # Usage:    $rv = plock( $filename, $lockType );
    # Usage:    $rv = plock( $filename, $lockType, $fileMode );

    my $filename = shift;
    my $type     = shift;
    my $perms    = shift;
    my ( $rv, $fh );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $filename, $type, $perms );
    pIn();

    # Set the defaults
    $perms = PRIV_UMASK unless defined $perms;
    $type  = LOCK_EX    unless defined $type;

    # Open the file and apply the lock
    $fh = popen( $filename, O_RDWR | O_CREAT | O_EXCL, $perms )
        || popen( $filename, O_RDWR, $perms );
    $rv = pflock( $filename, $type ) if defined $fh;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pexclock {

    # Purpose:  Applies an exclusive lock
    # Returns:  True/false
    # Usage:    $rv = pexclock($filename);

    my $filename = shift;
    my $mode     = shift;
    my $rv       = 1;
    my $fh;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $filename, $mode );
    pIn();

    $rv = plock( $filename, LOCK_EX, $mode );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pshlock {

    # Purpose:  Applies a shared lock
    # Returns:  True/false
    # Usage:    $rv = pshlock($filename);

    my $filename = shift;
    my $mode     = shift;
    my $rv       = 1;
    my $fh;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $filename, $mode );
    pIn();

    $rv = plock( $filename, LOCK_SH, $mode );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub punlock {

    # Purpose:  Removes any existing locks on the file
    # Returns:  True/false
    # Usage:    $rv = punlock($filename);

    my $filename = shift;
    my $mode     = shift;
    my $rv       = 1;
    my $fh;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $filename, $mode );
    pIn();

    $rv = plock( $filename, LOCK_UN, $mode );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::IO::Lockfile - Paranoid Lockfile support

=head1 VERSION

$Id: lib/Paranoid/IO/Lockfile.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::IO::Lockfile;
  use Fcntl qw(:flock);  # only needed if you use plock in lieu 
                         # of the other functions

  $rv = plock($lockfile);
  $rv = plock($lockfile, LOCK_SH | LOCK_NB);
  $rv = plock($lockfile, LOCK_SH | LOCK_NB, $mode);

  $rv = pexclock($lockfile);
  $rv = pshlock($lockfile);
  $rv = punlock($lockfile);

=head1 DESCRIPTION

This module provides convenience functions for using a lockfile to coordinate
multi-process activities.  While basically just a thin wrapper for
L<Paranoid::IO> functions it removes the small tedium of having to perform
the multiple opens required to ensure all processes are working off the same
files while avoiding race conditions.

=head1 SUBROUTINES/METHODS

=head2 plock

  $rv = plock($filename);
  $rv = plock($filename, LOCK_EX);
  $rv = plock($filename, LOCK_EX, 0666);

Creates or opens the requested file while applying the lock condition.  The
lock type defaults to B<LOCK_EX> if omitted, while the file permissions
default to B<0660>.  As always, L<umask> applies.

There is one scenario in which one would want to use I<plock> in lieu of
I<pexclock>, etc:  if you wish to perform non-blocking lock attempts.  All
convenience functions are blocking.

=head2 pexclock

  $rv = pexclock($filename);
  $rv = pexclock($filename, $mode);

A wrapper for B<plock($filename, LOCK_EX)>.

=head2 pshlock

  $rv = pshlock($filename);
  $rv = pshlock($filename, $mode);

A wrapper for B<plock($filename, LOCK_SH)>.

=head2 punlock

  $rv = punlock($filename);
  $rv = punlock($filename, $mode);

A wrapper for B<plock($filename, LOCK_UN)>.  This does not close the open 
file handle to the lock file.  For that you need to call L<Paranoid::IO's>
I<pclose> function.

=head1 DEPENDENCIES

=over

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::IO>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

