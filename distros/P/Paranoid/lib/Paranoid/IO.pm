# Paranoid::IO -- Paranoid IO support
#
# (c) 2005 - 2017, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Paranoid/IO.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $
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

package Paranoid::IO;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Cwd qw(realpath);
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Input;
use IO::Handle;

($VERSION) = ( q$Revision: 2.07 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(pclose pcloseAll popen preopen ptell pseek pflock pread
    pnlread pwrite pappend ptruncate);
@EXPORT_OK = ( @EXPORT, qw(PIOBLKSIZE PIOMAXFSIZE) );
%EXPORT_TAGS = ( all => [@EXPORT_OK] );

use constant PDEFPERM   => 0666;
use constant PDEFMODE   => O_CREAT | O_RDWR;
use constant PDEFBLKSZ  => 4096;
use constant PDEFFILESZ => 65536;

#####################################################################
#
# Module code follows
#
#####################################################################

{

    my $mblksz = PDEFBLKSZ;

    sub PIOBLKSIZE : lvalue {

        # Purpose:  Gets/sets default block size for I/O
        # Returns:  $mblksz
        # Usage:    PIOBLKSIZE

        $mblksz;
    }

    my $mfsz = PDEFFILESZ;

    sub PIOMAXFSIZE : lvalue {

        # Purpose:  Gets/sets default max file size for I/O
        # Returns:  $mfsz
        # Usage:    PIOBLKSIZE

        $mfsz;
    }

    # %files:  {name} => {
    #   pid     => $pid,
    #   mode    => $mode,
    #   perms   => $perms,
    #   fh      => $fh,
    #   real    => $realpath,
    #   ltype   => $lock,
    #   }
    my %files;

    sub _pfFhind ($) {

        # Purpose:  Searches for a filename based on the
        #           current file handle
        # Returns:  String/undefined
        # Usage:    $rv = _pfFhind($fh);

        my $fh = shift;
        my $rv;

        pdebug( 'entering w/%s', PDLEVEL2, $fh );
        pIn();

        if ( defined $fh and ref $fh eq 'GLOB' ) {
            foreach ( keys %files ) {
                if ( $files{$_}{fh} eq $fh ) {
                    $rv = $_ and last;
                }
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }

    sub pclose {

        # Purpose:  Closes a cached file handle
        # Returns:  Boolean
        # Usage:    $rv = plcose($filename)
        # Usage:    $rv = plcose($fh)

        my $filename = shift;
        my $rv       = 1;
        my $fh;

        pdebug( 'entering w/%s', PDLEVEL2, $filename );
        pIn();

        if ( defined $filename ) {

            # Get the missing variable
            if ( ref $filename eq 'GLOB' ) {
                $fh       = $filename;
                $filename = _pfFhind($fh);
            } else {
                $fh = $files{$filename}{fh} if exists $files{$filename};
            }

            # Close the filehandle
            if ( defined $fh and fileno $fh ) {
                flock $fh, LOCK_UN;
                $rv = close $fh;
            }

            # Clean up internal data structures
            delete $files{$filename} if defined $filename;

            Paranoid::ERROR =
                pdebug( 'error closing file handle: %s', PDLEVEL1, $! )
                unless $rv;
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }

    sub pcloseAll {

        # Purpose:  Closes all filehandles
        # Returns:  Boolean
        # Usage:    $rv = pcloseAll();

        my @files = @_;
        my $rv    = 1;

        pdebug( 'entering', PDLEVEL3 );
        pIn();

        @files = keys %files unless @files;
        foreach (@files) {
            $rv = 0 unless pclose($_);
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

        return $rv;
    }

    sub _open {

        # Purpose:  Performs the sysopen call
        # Returns:  rv of sysopen
        # Usage:    $rv = _open($filename);
        # Usage:    $rv = _open($filename, $mode);
        # Usage:    $rv = _open($filename, $mode, $perms);

        my $filename = shift;
        my $mode     = shift;
        my $perms    = shift;
        my ( %tmp, $f, $fh, $rv );

        pdebug( 'entering w/(%s)(%s)(%s)',
            PDLEVEL3, $filename, $mode, $perms );
        pIn();

        if ( defined $filename ) {

            # Detaint mode/perms
            $rv    = 1;
            $mode  = PDEFMODE unless defined $mode;
            $perms = PDEFPERM unless defined $perms;
            unless ( detaint( $mode, 'int' ) ) {
                $rv = 0;
                Paranoid::ERROR =
                    pdebug( 'invalid mode passed: %s', PDLEVEL1, $mode );
            }
            unless ( detaint( $perms, 'int' ) ) {
                $rv = 0;
                Paranoid::ERROR =
                    pdebug( 'invalid perm passed: %s', PDLEVEL1, $perms );
            }

            # Prep file record
            %tmp = (
                mode  => $mode,
                perms => $perms,
                pid   => $$,
                ltype => LOCK_UN,
                );

            # Detaint filename
            if ($rv) {
                if ( detaint( $filename, 'filename', $f ) ) {

                    # Attempt to open the fila
                    $rv =
                        ( $tmp{mode} & O_CREAT )
                        ? sysopen $fh, $f, $tmp{mode}, $tmp{perms}
                        : sysopen $fh,
                        $f, $tmp{mode};
                    if ($rv) {
                        $tmp{fh}          = $fh;
                        $tmp{real}        = realpath($filename);
                        $files{$filename} = {%tmp};
                    } else {
                        Paranoid::ERROR = pdebug( 'failed to open %s: %s',
                            PDLEVEL1, $filename, $! );
                    }

                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to detaint %s', PDLEVEL1, $filename );
                }
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

        return $rv;
    }

    sub _reopen {

        # Purpose:  Reopens an open file handle
        # Returns:  rv of _open
        # Usage:    $rv = _reopen($filename);
        # Usage:    $rv = _reopen($fh);

        my $filename = shift;
        my ( %tmp, $fh, $pos, $rv, $af );

        pdebug( 'entering w/(%s)', PDLEVEL3, $filename );
        pIn();

        if ( defined $filename and exists $files{$filename} ) {

            # Get a copy of the file record
            %tmp = %{ $files{$filename} };
            $fh  = $tmp{fh};

            # Get the current cursor position
            $pos = fileno $fh ? sysseek $fh, 0, SEEK_CUR : 0;
            $af = $fh->autoflush;

            # Close the old file handle
            $tmp{fh} = $fh = undef;
            if ( pclose($filename) ) {

                # Remove O_TRUNC
                $tmp{mode} ^= O_TRUNC if $tmp{mode} & O_TRUNC;

                # Open the file and move the cursor back where it was
                $rv = _open( @tmp{qw(real mode perms)} );
                if ($rv) {

                    # Move the cursor back to where it was
                    $fh = $files{ $tmp{real} }{fh};
                    $fh->autoflush($af);
                    $rv = sysseek $fh, $pos, SEEK_SET;

                    # Move the record over to the original file name
                    $files{$filename} = { %{ $files{ $tmp{real} } } };
                    delete $files{ $tmp{real} } if $filename ne $tmp{real};
                }
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

        return $rv;
    }

    sub popen {

        # Purpose:  Performs a sysopen with file descriptor caching
        # Returns:  file handle
        # Usage:    $fh = popen($filename, $mode, $perms);

        my $filename = shift;
        my $mode     = shift;
        my $perms    = shift;
        my ( %tmp, $fh, $f, $pos, $rv );

        pdebug( 'entering w/(%s)(%s)(%s)',
            PDLEVEL2, $filename, $mode, $perms );
        pIn();

        # Make sure we weren't passed a file handle, but if we
        # were attempt to find the actual filename
        if ( defined $filename ) {
            if ( ref $filename eq 'GLOB' ) {
                $fh       = $filename;
                $filename = _pfFhind($filename);
            } else {
                $fh = $files{$filename}{fh} if exists $files{$filename};
            }
        }

        if ( defined $filename and exists $files{$filename} ) {

            # Make sure pid is the same
            if ( $files{$filename}{pid} == $$ ) {

                if ( fileno $fh ) {

                    # Return existing filehandle
                    pdebug( 'returning cached file handle', PDLEVEL2 );
                    $rv = $fh;

                } else {

                    # Reopen a filehandle that was closed outside
                    # of this module
                    pdebug( 'reopening closed file handle', PDLEVEL2 );
                    $rv = $files{$filename}{fh} if _reopen($filename);
                }

            } else {

                pdebug( 'reopening inherited file handle in child',
                    PDLEVEL2 );
                $rv = $files{$filename}{fh} if _reopen($filename);

            }

        } elsif ( defined $filename ) {

            pdebug( 'opening new file handle', PDLEVEL2 );
            $rv = $files{$filename}{fh} if _open( $filename, $mode, $perms );

        } elsif ( !defined $filename and defined $fh ) {
            Paranoid::ERROR =
                pdebug( 'popen called with an unmanaged file handle',
                PDLEVEL1 );
            $rv = fileno $fh ? $fh : undef;
        } else {
            Paranoid::ERROR =
                pdebug( 'attempted to open a file with an undefined name',
                PDLEVEL1 );
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }

    sub preopen {

        # Purpose:  Reopens either the named files or all
        # Returns:  Boolean
        # Usage:    $rv = preopen();
        # Usage:    $rv = preopen(@filenames);

        my @files = @_;
        my $rv    = 1;

        pdebug( 'entering w/%s', PDLEVEL2, @files );
        pIn();

        @files = keys %files unless @files;
        foreach (@files) { $rv = 0 unless _reopen($_) }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }

    sub pflock {

        # Purpose:  Performs file-locking operations on the passed filename
        # Returns:  Boolean
        # Usage:    $rv = pflock($filename, LOCK_EX);

        my $filename = shift;
        my $lock     = shift;
        my ( $rv, $fh );
        local $!;

        pdebug( 'entering w/(%s)(%s)', PDLEVEL2, $filename, $lock );
        pIn();

        if ( defined $filename ) {

            # Get the missing variable
            if ( ref $filename eq 'GLOB' ) {
                $fh       = $filename;
                $filename = _pfFhind($fh);
            } else {
                $fh = $files{$filename}{fh} if exists $files{$filename};
            }

            if ( defined $fh ) {

                # Apply the lock
                $rv = flock $fh, $lock;

                # Record change to internal state if we're tracking this file
                $files{$filename}{ltype} = $lock
                    if defined $filename
                        and exists $files{$filename};

                Paranoid::ERROR =
                    pdebug( 'error attempting to pflock: %s', PDLEVEL1, $! )
                    unless $rv;
            }
        }

        pOut();
        pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

        return $rv;
    }
}

sub ptell {

    # Purpose:  Returns the cursor position in the file handle
    # Returns:  Integer
    # Usage:    $pos = ptell($filename);

    my $filename = shift;
    my ( $rv, $fh );
    local $!;

    pdebug( 'entering w/%s', PDLEVEL2, $filename );
    pIn();

    if ( defined $filename ) {

        $fh = popen( $filename, O_RDWR );
        if ( defined $fh ) {
            $rv = sysseek $fh, 0, SEEK_CUR;
            Paranoid::ERROR =
                pdebug( 'error attempting to ptell: %s', PDLEVEL1, $! )
                unless $rv;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub pseek {

    # Purpose:  Performs a sysseek
    # Returns:  Integer/undef
    # Usage:    $cur = pseek($filename, $curpos, $whence);

    my $filename = shift;
    my $setpos   = shift;
    my $whence   = shift;
    my ( $rv, $fh );
    local $!;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL2, $filename, $setpos,
        $whence );
    pIn();

    if ( defined $filename ) {

        $fh = popen( $filename, O_RDWR );
        if ( defined $fh ) {
            $rv = sysseek $fh, $setpos, $whence;
            Paranoid::ERROR =
                pdebug( 'error attempting to pseek: %s', PDLEVEL1, $! )
                unless $rv;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub pwrite {

    # Purpose:  Performs a syswrite w/locking
    # Returns:  Integer/undef
    # Usage:    $bytes = pwrite($filename, $text);
    # Usage:    $bytes = pwrite($filename, $text, $length);
    # Usage:    $bytes = pwrite($filename, $text, $length, $offset);

    my $filename = shift;
    my $out      = shift;
    my $wlen     = shift;
    my $offset   = shift;
    my ( $fh, $rv );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL2, $filename, $out, $wlen, $offset );
    pIn();

    if ( defined $filename and defined $out and length $out ) {

        # Opportunistically open a file handle if needed,
        # otherwise, just retrieve the existing file handle
        $fh = popen( $filename, O_WRONLY | O_CREAT | O_TRUNC );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {
            if ( pflock( $filename, LOCK_EX ) ) {
                $wlen   = length $out unless defined $wlen;
                $offset = 0           unless defined $offset;
                $rv = syswrite $fh, $out, $wlen, $offset;
                if ( defined $rv ) {
                    pdebug( 'wrote %d bytes', PDLEVEL2, $rv );
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to write to file handle: %s',
                        PDLEVEL1, $! );
                }
                pflock( $filename, LOCK_UN );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub pappend ($$;$$) {

    # Purpose:  Appends the data to the end of the file,
    #           but does not move the file cursor
    # Returns:  Integer/undef
    # Usage:    $rv = pappend($filename, $content);
    # Usage:    $rv = pappend($filename, $content, $length);
    # Usage:    $rv = pappend($filename, $content, $length, $offset);

    my $filename = shift;
    my $out      = shift;
    my $wlen     = shift;
    my $offset   = shift;
    my ( $fh, $pos, $rv );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL2, $filename, $out, $wlen, $offset );
    pIn();

    if ( defined $filename and defined $out and length $out ) {

        # Opportunistically opena file handle in append mode
        $fh = popen( $filename, O_WRONLY | O_CREAT | O_APPEND );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {

            # Lock the file
            if ( pflock( $filename, LOCK_EX ) ) {

                # Save the current position
                $pos = sysseek $fh, 0, SEEK_CUR;

                # Seek to the end of the file
                if ( $pos and sysseek $fh, 0, SEEK_END ) {

                    # write the content
                    $wlen   = length $out unless defined $wlen;
                    $offset = 0           unless defined $offset;
                    $rv = syswrite $fh, $out, $wlen, $offset;
                    if ( defined $rv ) {
                        pdebug( 'wrote %d bytes', PDLEVEL2, $rv );
                    } else {
                        Paranoid::ERROR =
                            pdebug( 'failed to write to file handle: %s',
                            PDLEVEL1, $! );
                    }
                }

                # Seek back to original position
                sysseek $fh, $pos, SEEK_SET;

                # Unlock the file handle
                pflock( $filename, LOCK_UN );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub pread ($\$;@) {

    # Purpose:  Performs a sysread w/locking
    # Returns:  Integer/undef
    # Usage:    $bytes = pread($filename, $text, $length);
    # Usage:    $bytes = pread($filename, $text, $length, $offset);

    my $filename = shift;
    my $sref     = shift;
    my $rlen     = shift;
    my $offset   = shift;
    my $nolock   = shift;
    my ( $fh, $rv );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL2, $filename, $sref, $rlen, $offset );
    pIn();

    if ( defined $filename ) {

        # Opportunistically open a file handle if needed,
        # otherwise, just retrieve the existing file handle
        $fh = popen( $filename, O_RDONLY );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {
            if ( $nolock or pflock( $filename, LOCK_SH ) ) {
                $rlen   = PIOBLKSIZE unless defined $rlen;
                $offset = 0          unless defined $offset;
                $rv = sysread $fh, $$sref, $rlen, $offset;
                if ( defined $rv ) {
                    pdebug( 'read %d bytes', PDLEVEL2, $rv );
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to read from file handle: %s',
                        PDLEVEL1, $! );
                }
                pflock( $filename, LOCK_UN ) unless $nolock;
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub pnlread ($\$;@) {

    # Purpose:  Wrapper for pread
    # Returns:  RV of pread
    # Usage:    $bytes = pnlread($filename, $text, $length);
    # Usage:    $bytes = pnlread($filename, $text, $length, $offset);

    my $filename = shift;
    my $sref     = shift;
    my $rlen     = shift;
    my $offset   = shift;

    return pread( $filename, $$sref, $rlen, $offset, 1 );
}

sub ptruncate {

    # Purpose:  Truncates the specified file
    # Returns:  RV of truncate
    # Usage:    $rv = ptruncate($filename);
    # Usage:    $rv = ptruncate($filename, $pos);

    my $filename = shift;
    my $pos      = shift;
    my ( $rv, $fh, $cpos );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL2, $filename, $pos );
    pIn();

    if ( defined $filename ) {
        $pos = 0 unless defined $pos;
        $fh = popen( $filename, O_RDWR | O_CREAT );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {
            if ( pflock( $filename, LOCK_EX ) ) {
                $cpos = sysseek $fh, 0, SEEK_CUR;
                $rv = truncate $fh, $pos;
                if ($rv) {
                    sysseek $fh, $pos, SEEK_SET if $cpos > $pos;
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to truncate file: %s', PDLEVEL1, $! );
                }
                pflock( $filename, LOCK_UN );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

END {

    # Attempt to clean close all filehandles
    pcloseAll();
}

1;

__END__

=head1 NAME

Paranoid::IO - Paranoid IO support

=head1 VERSION

$Id: lib/Paranoid/IO.pm, 2.07 2019/01/30 18:25:27 acorliss Exp $

=head1 SYNOPSIS

  use Fcntl qw(:DEFAULT :flock :mode :seek);
  use Paranoid::IO;

  # Implicit open
  $chars = pread("./foo.log", $in, 2048);

  # Implcit write/append
  $chars = pwrite("./bar.log", $out);
  $chars = pappend("./bar.log", $out);

  # Adjust block read size
  PIOBLKSIZE = 8192;

  # Adjust max file size for file scans
  PIOMAXFSIZE = 65536;

  # Explicit open
  $fh = popen($filename, O_RDWR | O_CREAT | O_TRUNC, 0600);
  $rv = pseek($filename, 0, SEEK_END);
  if ($rv > 0) {
    pseek($filename, 0, SEEK_SET) && ptruncate($filename);
  }
  $rv = pwrite($fileanme, $text) && pclose($filename);

  $rv = pclose($filename);

=head1 DESCRIPTION

B<Paranoid::IO> is intended to make basic file I/O access easier while
keeping with the tenets of paranoid programming.  Most of these calls are
essentially wrappers for the basic system calls (exposed as L<sysopen>,
L<syswrite>, etc.) with some additional logic to reduce the need to explicitly
code every step of normal safe access rules, such as file locking.  In the
most basic of usage patterns, even explicitly opening files isn't necessary.

For the most part the system calls that are wrapped here act identically as
the underlying calls, both in the arguments they take and the values they
return.  The one notable difference, however, is the I<popen> function itself.
A glob variable isn't passed for assignation since this module stores those
references internally along with some meta data, so I<popen> returns file
handles directly.

That semantic, however, is what gives the rest of the functions the
flexibility of accepting either a file name or a file handle to work on.  In
the case of file names some of these functions can open files automatically,
and the rest of the features are granted automatically.

In the case of passing file handles the full feature set of this module is
only available if the file handle was originally opened with I<popen>.  The
calls will still work even if it wasn't, but some of the safety features, like
being fork-safe, won't have the meta data to work properly.

The features provided by this module are:

=over

=item * Opportunistic file access

=item * File handle caching

=item * Fork-safe file access

=item * Inherent file locking

=item * O_APPEND access patterns where needed even for files not opened with
O_APPEND

=item * Intelligent file tracking

=back

The following sections will explain each feature in more depth:

=head2 Opportunistic file access

Opportunistic file access is defined here as not needing the explicit I/O
handling for what can be implied.  For instance, to read content from a file
one can simply use the I<pread> function without having to open and apply a
shared file lock.  In a similar manner one should be able to write or append
to a file.  Files are automatically opened (with the file mode being intuited
by the type of call) as needed.  Only where more complicated access patterns
(such as read/write file handles) should an explicit I<popen> call be needed.

Opportunism is limited to where it makes sense, however.  Files are not
opportunistically opened if the first I/O call is to I<pseek>, I<ptell>, or
I<pflock>.  The intent of the file I/O (in regards to read/write file modes)
is impossible to tell within those calls.

=head2 File handle caching

This module provides a replacement for Perl's internal L<sysopen>, which
should be used even where read/write file access is necessary.  One key
benefit for doing so is that it provides internal file handle caching based on
the file name.  All the additional functions provided by this module use it
internally to retrieve that cached file handle to avoid the overhead of
repetitive opening and closing of files.

=head2 Fork-safe file access

A greater benefit of I<popen>, however, is in it's fork-safe behavior.  Every
call checks to see if the file handle it has was inherited from its parent,
and if so, transparently closed and reopened so I/O can continue without both
processes conflicting over cursor positions and buffers.  After files are
reopened read cursors are placed at the same location they were prior to the
first I/O access in the child.

File modes are preserved without the obvious conflicts of intent as well.  
Files opened in the parent with B<O_TRUNC> are reopened without that flag 
to prevent content from being clobbered.

=head2 Inherent file locking

Except where explicitly ignored (like for I<pnlread>) all read, write, and
append operations use locking internally, alleviating the need for the
developer to do so explicitly.  Locks are applied and removed as quickly as
possible to facilitate concurrent access.

=head2 O_APPEND access patterns

I<pappend> allows you to mimic B<O_APPEND> access patterns even for files that
weren't explicitly opened with B<O_APPEND>.  If you open a file with B<O_RDWR>
you can still call I<pappend> and the content will be appended to the end of
the file, without moving the file's cursor position for regular reads and
writes.

=head2 Intelligent file tracking

I<popen> caches file handles by file name.  If files are opened with relative
paths this has the potential to cause some confusion if the process or
children are changing their working directories.  In anticipation of this
I<popen> also tracks the real path (as resolved by the L<realpath> system 
call) and file name.  This way you can still access the same file regardless
of the process or its children's movements on the file system.

This could be, however, a double-edged sword if your program intends to open
identically named files in multiple locations.  If that is your intent you
would be cautioned to avoid using relative paths with I<popen>.

=head1 SUBROUTINES/METHODS

=head2 PIOBLKSIZE

    PIOBLKSIZE = 65536;

This lvalue function is not exported by default.  It is used to determine the
default block size to read when a size is not explicitly passed.  Depending on
hardware and file system parameters there might be performance gains to be
had when doing default-sized reads.

The default is 4096, which is generally a safe size for most applications.

=head2 PIOMAXFSIZE

    PIOMAXFSIZE = 131072;

This lvalue function is not exported by default.  It is used to determine the
maximum file size that will be read.  This is not used in this module, but
provided for use in dependent modules that may want to impose file size
limits, such as L<Paranoid::IO::Line> and others.

The default is 65536.

=head2 popen

    $fh = popen($filename);
    $fh = popen($filename, $mode);
    $fh = popen($filename, $mode, $perms);
    $fh = popen($fh);

Returns a file handle if the file could be opened.  If the mode is omitted the
default is B<O_CREAT | O_RDWR>.  File permissions (for newly created files)
default to B<0666 ^ UMASK>.

Failures to open a file will result in an undef return value, with a text
description of the fault stored in B<Paranoid::ERROR>.

If a file handle is passed to I<popen> it will attempt to match it to a
tracked file handle and, if identified, take the appropriate action.  If it
doesn't match any tracked file handles it will just return that file handle
back to the caller.

=head2 pclose

    $rv = pclose($filename);
    $rv = pclose($fh);

Returns the value from L<close>.  Attempts to close a file that's already
closed is considered a success, and true value is returned.  Handing it a
stale file handle, however, will be handed to the internal B<close>, with all
the expected results.

=head2 preopen

    $rv = preopen();
    $rv = preopen(@filenames);
    $rv = preopen(@filehandles);

This checks each tracked file handle (i.e., file handles that were opened by
I<popen>) and reopens them if necessary.  This is typically only useful after
a fork.  It is also not striclty necessary since every call to a function in
this module does that with every invocation, but if you have several file
handles that you may not access immediately you run the risk of the parent
moving the current file position before the child gets back to those files.
You may or may not care.  If you do, use this function immediately after a
fork.

Called with a list of file names means that only those files are examined and
reopened.  Any failure to reopen any single file handle will result in a false
return value.  That said, any failures will not interrupt the function from
trying every file in the list.

=head2 pcloseAll

    $rv = pcloseAll();
    $rv = pcloseAll(@filenames);
    $rv = pcloseAll(@filehandles);

This function returns a boolean value denoting any errors while trying to
close every tracked file handle.  This function is also not strictly necessary
for all the normal Perl I/O reasons, but it's here for those that want to be
explicit.

=head2 ptell

    $pos = ptell($filename);
    $pos = ptell($fh);

Returns the current position of the file cursor.  Returns the results of
L<sysseek>, which means that any successful seek is true, even if the cursor
is at the beginning of the file.  In that instance it returns "0 but true"
which is boolean true while converting to an integer appropriately.

Any failures are returned as false or undef.

=head2 pseek

    $rv = pseek($filename, $pos, $whence);
    $rv = pseek($fh, $pos, $whence);

This returns the return value from L<sysseek>.  The appropriate whence values
sould be one of the B<SEEK_*> constants as exported by L<Fcntl>.

=head2 pflock

    $rv = pflock($filename, $locktype);
    $rv = pflock($fh, $locktype);

This returns the return value from L<flock>.  The appropriate lock type values
should be one of the B<LOCK_*> constants as exported by L<Fcntl>.

B<NOTE:> This function essentially acts like a pass-through to the native
L<flock> function for any file handle not opened via this module's functions.

=head2 pread

    $bytes = pread($filename, $text, $length);
    $bytes = pread($filename, $text, $length, $offset);
    $bytes = pread($fh, $text, $length);
    $bytes = pread($fh, $text, $length, $offset);

This returns the number of bytes read, or undef on errors.  If this is called
prior to an explicit I<popen> it will default to a mode of B<O_RDONLY>.  Length
defaults to B<PIOBLKSIZE>.

=head2 pnlread

    $bytes = pnlread($filename, $text, $length);
    $bytes = pnlread($filename, $text, $length, $offset);
    $bytes = pnlread($fh, $text, $length);
    $bytes = pnlread($fh, $text, $length, $offset);

File locks are inherent on all reads and writes.  There are plenty of
legitimate scenarios where a read needs to be done ignoring any file locks.
It is for those situations that this function exists.  It acts identically in
every way to I<pread> with the lone exception that it does not perform file
locking.

=head2 pwrite

    $bytes = pwrite($filename, $text);
    $bytes = pwrite($filename, $text, $length);
    $bytes = pwrite($filename, $text, $length, $offset);
    $bytes = pwrite($fh, $text);
    $bytes = pwrite($fj, $text, $length);
    $bytes = pwrite($fh, $text, $length, $offset);

This returns the number of bytes written, or undef for any critical failures.
If this is called prior to an explicit I<popen> it uses a default mode of
B<O_WRONLY | O_CREAT | O_TRUNC>.

=head2 pappend

    $bytes = pappend($filename, $text);
    $bytes = pappend($filename, $text, $length);
    $bytes = pappend($filename, $text, $length, $offset);
    $bytes = pappend($fh, $text);
    $bytes = pappend($fh, $text, $length);
    $bytes = pappend($fh, $text, $length, $offset);

This behaves identically to I<pwrite> with the sole exception that this
preserves the file position after explicitly seeking and writing to the end of
the file.  The default mode here, however, would be B<O_WRONLY | O_CREAT |
O_APPEND> for those files not explicitly opened.

=head2 ptruncate

    $rv = ptruncate($filename);
    $rv = ptruncate($filename, $pos);
    $rv = ptruncate($fh);
    $rv = ptruncate($fh, $pos);

This returns the result of the internal L<truncate> call.  If called without
an explicit I<popen> it will open the named file with the default mode of
B<O_RDWR | O_CREAT>.  Omitting the position to truncate from will result in
the file being truncated at the beginning of the file.

=head1 DEPENDENCIES

=over

=item o

L<Cwd>

=item o

L<Fcntl>

=item o

L<IO::Handle>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Input>

=back

=head1 BUGS AND LIMITATIONS

It may not always be benficial to cache file handles.  You must explicitly
I<pclose> file handles to avoid that.  That said, with straight Perl you'd
have to either explicitly close the file handles or use lexical scoping,
anyway.  From that perspective I don't find it onerous to do so, especially
with all of the other code-saving features this module provides.

=head1 AUTHOR

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2005 - 2017, Arthur Corliss (corliss@digitalmages.com)

