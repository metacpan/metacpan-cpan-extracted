# Paranoid::IO -- Paranoid IO support
#
# $Id: lib/Paranoid/IO.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
#
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
# (c) 2005 - 2021, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2021, Paranoid Inc. (www.paranoid.com)
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

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(pclose pcloseAll popen preopen ptell pseek pflock pread
    pnlread pwrite pnlwrite pappend pnlappend ptruncate pnltruncate);
@EXPORT_OK = ( @EXPORT, qw(PIOBLKSIZE PIOMAXFSIZE PIOLOCKSTACK) );
%EXPORT_TAGS = ( all => [@EXPORT_OK] );

use constant PDEFPERM   => 0666;
use constant PDEFMODE   => O_CREAT | O_RDWR;
use constant PDEFBLKSZ  => 4096;
use constant PDEFFILESZ => 65536;
use constant PFLMASK    => LOCK_SH | LOCK_EX | LOCK_UN;
use constant PIGNMFLAGS => O_TRUNC | O_CREAT | O_EXCL;

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
        # Usage:    PIOBLKSIZE = $bytes;

        $mblksz;
    }

    my $mfsz = PDEFFILESZ;

    sub PIOMAXFSIZE : lvalue {

        # Purpose:  Gets/sets default max file size for I/O
        # Returns:  $mfsz
        # Usage:    PIOMAXFSIZE = bytes;

        $mfsz;
    }

    my %lstack;
    my $lsflag = 0;

    sub PIOLOCKSTACK : lvalue {

        # Purpose:  Enables/disables the flock lock stack
        # Returns:  $lsflag
        # Usage:    PIOLOCKSTACK = 1;

        $lsflag;
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

        subPreamble( PDLEVEL4, '$', $fh );

        if ( defined $fh and ref $fh eq 'GLOB' ) {
            foreach ( keys %files ) {
                if ( $files{$_}{fh} eq $fh ) {
                    $rv = $_ and last;
                }
            }
        }

        subPostamble( PDLEVEL4, '$', $rv );

        return $rv;
    }

    sub pclose ($) {

        # Purpose:  Closes a cached file handle
        # Returns:  Boolean
        # Usage:    $rv = plcose($filename)
        # Usage:    $rv = plcose($fh)

        my $filename = shift;
        my $rv       = 1;
        my $fh;

        subPreamble( PDLEVEL1, '$', $filename );

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
            if ( defined $filename ) {
                delete $files{$filename};
                delete $lstack{$filename};
            }

            Paranoid::ERROR =
                pdebug( 'error closing file handle: %s', PDLEVEL1, $! )
                unless $rv;
        }

        subPostamble( PDLEVEL1, '$', $rv );

        return $rv;
    }

    sub pcloseAll {

        # Purpose:  Closes all filehandles
        # Returns:  Boolean
        # Usage:    $rv = pcloseAll();

        my @files = @_;
        my $rv    = 1;

        subPreamble( PDLEVEL1, '@', @files );

        @files = keys %files unless @files;
        foreach (@files) {
            $rv = 0 unless pclose($_);
        }

        subPostamble( PDLEVEL1, '$', $rv );

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

        subPreamble( PDLEVEL3, '$;$$', $filename, $mode, $perms );

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

        subPostamble( PDLEVEL3, '$', $rv );

        return $rv;
    }

    sub _reopen {

        # Purpose:  Reopens an open file handle
        # Returns:  rv of _open
        # Usage:    $rv = _reopen($filename);
        # Usage:    $rv = _reopen($fh);

        my $filename = shift;
        my ( %tmp, $fh, $pos, $rv, $af );

        subPreamble( PDLEVEL3, '$', $filename );

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

                # Reopen should ignore O_TRUNC, O_CREAT, and O_EXCL on reopens
                $tmp{mode} &= ~PIGNMFLAGS if $tmp{mode} & PIGNMFLAGS;

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

                    # Delete any existing lock stack
                    delete $lstack{$filename};
                }
            }
        }

        subPostamble( PDLEVEL3, '$', $rv );

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

        subPreamble( PDLEVEL2, '$;$$', $filename, $mode, $perms );

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

        subPostamble( PDLEVEL2, '$', $rv );

        return $rv;
    }

    sub preopen {

        # Purpose:  Reopens either the named files or all
        # Returns:  Boolean
        # Usage:    $rv = preopen();
        # Usage:    $rv = preopen(@filenames);

        my @files = @_;
        my $rv    = 1;

        subPreamble( PDLEVEL2, '@', @files );

        @files = keys %files unless @files;
        foreach (@files) { $rv = 0 unless _reopen($_) }

        subPostamble( PDLEVEL2, '$', $rv );

        return $rv;
    }

    sub _pflock {

        # Purpose:  Performs file-locking operations on the passed filename
        # Returns:  Boolean
        # Usage:    $rv = _pflock($filename, LOCK_EX);

        my $filename = shift;
        my $lock     = shift;
        my ( $rv, $fh, $rl );
        local $!;

        subPreamble( PDLEVEL3, '$$', $filename, $lock );

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
                $rl = $lock & PFLMASK;
                $rv = flock $fh, $lock;

                # Record change to internal state if we're tracking this file
                if ($rv) {
                    if ( defined $filename and exists $files{$filename} ) {
                        $files{$filename}{ltype} = $rl;
                    } else {
                        pdebug(
                            'flock succeeded on file opened outside of the'
                                . ' Paranoid::IO framework (%s)',
                            PDLEVEL1, $filename
                            );
                    }
                } else {
                    pdebug(
                        ( ( $lock & LOCK_NB ) ? 'non-blocking' : '' )
                        . 'flock attempt failed on %s',
                        PDLEVEL1, $filename
                        );
                }
            }
        }

        subPostamble( PDLEVEL3, '$', $rv );

        return $rv;
    }

    sub _plsflock {

        my $filename = shift;
        my $lock     = shift;
        my ( $fh, $stack, $rl, $ll, $lsl, $rv );

        subPreamble( PDLEVEL3, '$$', $filename, $lock );

        # Var Key:
        #   lock:   lock passed to function (can include LOCK_NB)
        #   rl:     real lock (stripping LOCK_NB)
        #   ll:     last lock (as performed by last _pflock()
        #   lsl:    last lock recorded in the lock stack

        # Translate glob to filename for lock stack tracking purposes
        $fh = $filename;
        $filename = _pfFhind($filename) if ref $filename eq 'GLOB';

        # Get the current lock state
        $ll = $files{$filename}{ltype}
            if defined $filename and exists $files{$filename};
        if ( defined $ll ) {

            # Get the real lock level for comparison
            $rl = $lock & PFLMASK;

            # File has been opened, at least, with popen, and has a locktype
            # entry
            $lstack{$filename} = [] unless exists $lstack{$filename};
            $stack = $lstack{$filename};
            $lsl   = $$stack[-1];

            #warn "lock: $lock\nrl: $rl\nll: $ll\nlsl: $lsl\n";
            pdebug(
                'something has gone awry during lock tracking.'
                    . 'll: %s lsl: %s',
                PDLEVEL1, $ll, $lsl
                )
                if defined $lsl
                    and $lsl != $ll;

            # Adjust as necessary
            if ( $rl == LOCK_UN ) {

                # Remove a lock from the stack
                pop @$stack;

                if ( scalar @$stack ) {

                    # Still have locks in the stack that must not be degraded
                    $rv = 1;
                    if ( $ll != $$stack[-1] ) {

                        # Apply the new level
                        $rv = _pflock( $filename, $$stack[-1] );
                    }

                } else {

                    # No locks in the stack to preserve, so go ahead and
                    # release the lock
                    $rv = _pflock( $filename, LOCK_UN );

                }

            } elsif ( $rl == LOCK_SH ) {

                # Upgrade lock to preserve previous exclusive lock on the
                # stack, if necessary
                if ( defined $lsl and $lsl == LOCK_EX ) {
                    $lock = ( LOCK_EX | ( $lock & LOCK_NB ) );
                    $rl = LOCK_EX;
                }

                $rv = $ll == $rl ? 1 : _pflock( $filename, $lock );
                push @$stack, $rl if $rv;

            } elsif ( $rl == LOCK_EX ) {
                push @$stack, $rl;
                $rv = $ll == $rl ? 1 : _pflock( $filename, $lock );
            } else {
                pdebug( 'unknown lock type: %x', PDLEVEL1, $lock );
            }

            # Report some diagnostics
            if ( scalar @$stack ) {
                pdebug( 'lock stack depth: %s', PDLEVEL4, scalar @$stack );
                if ( $ll == $$stack[-1] ) {
                    pdebug( 'preserved lock at %s', PDLEVEL4, $ll );
                } else {
                    pdebug( 'switched lock from %s to %s',
                        PDLEVEL4, $ll, $$stack[-1] );
                }
            } else {
                pdebug( 'no locks remaining', PDLEVEL4 );
            }

            # Delete empty stacks to avoid memory leaks
            delete $lstack{$filename} unless scalar @$stack;

        } else {
            if ( defined $fh and !defined $filename ) {
                $rv = _pflock( $fh, $lock );
            } else {
                pdebug( 'file %s is unknown to Paranoid::IO so far',
                    PDLEVEL1, $filename );
            }
        }

        subPostamble( PDLEVEL3, '$', $rv );

        return $rv;
    }

    sub pflock {

        # Purpose:  Performs file-locking operations on the passed filename
        # Returns:  Boolean
        # Usage:    $rv = pflock($filename, LOCK_EX);

        my $filename = shift;
        my $lock     = shift;
        my ( $rv, $fh );

        subPreamble( PDLEVEL2, '$$', $filename, $lock );

        # NOTE:  retrieving the file handle might seem silly, but if a process
        # is forked, and the first thing they do on a file is apply an flock,
        # the first I/O operation will close and reopen the file to avoid
        # confusion with the parent process and, therefore, losing the lock.
        #
        # End sum, this is a necessary evil in order to preserve locks a
        # before any effective I/O is done in the child.
        if ( defined $filename ) {
            $fh = popen($filename);
            $rv =
                  PIOLOCKSTACK()
                ? _plsflock( $filename, $lock )
                : _pflock( $filename, $lock );
        }

        subPostamble( PDLEVEL2, '$', $rv );

        return $rv;
    }

    sub plockstat {

        # Purpose:  Returns the the status of the last lock applied via
        #           pflock()
        # Returns:  LOCK_*
        # Usage:    $lock = plockstat($filename);

        my $filename = shift;
        my $rv;

        subPreamble( PDLEVEL2, '$', $filename );

        if ( defined $filename ) {

            # Get the missing variable
            $filename = _pfFhind($filename) if ref $filename eq 'GLOB';
            if ( defined $filename and exists $files{$filename} ) {
                $rv = $files{$filename}{ltype};
            } else {
                pdebug(
                    'attempted to retrieve lock status for file not opened'
                        . ' with the Paranoid::IO framework (%s)',
                    PDLEVEL1, $filename
                    );
            }
        }

        subPostamble( PDLEVEL2, '$', $rv );

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

    subPreamble( PDLEVEL2, '$', $filename );

    if ( defined $filename ) {

        $fh = popen( $filename, O_RDWR );
        if ( defined $fh ) {
            $rv = sysseek $fh, 0, SEEK_CUR;
            Paranoid::ERROR =
                pdebug( 'error attempting to ptell: %s', PDLEVEL1, $! )
                unless $rv;
        }
    }

    subPostamble( PDLEVEL2, '$', $rv );

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

    subPreamble( PDLEVEL2, '$$;$', $filename, $setpos, $whence );

    if ( defined $filename ) {

        $fh = popen( $filename, O_RDWR );
        if ( defined $fh ) {
            $whence = SEEK_SET unless defined $whence;
            $rv = sysseek $fh, $setpos, $whence;
            Paranoid::ERROR =
                pdebug( 'error attempting to pseek: %s', PDLEVEL1, $! )
                unless $rv;
        }
    }

    subPostamble( PDLEVEL2, '$', $rv );

    return $rv;
}

sub pwrite {

    # Purpose:  Performs a syswrite w/locking
    # Returns:  Integer/undef
    # Usage:    $bytes = pwrite($filename, $text);
    # Usage:    $bytes = pwrite($filename, $text, $length);
    # Usage:    $bytes = pwrite($filename, $text, $length, $offset);
    # Usage:    $bytes = pwrite($filename, $text, $length, $offset, $nolock);

    my $filename = shift;
    my $out      = shift;
    my $wlen     = shift;
    my $offset   = shift;
    my $nolock   = shift;
    my $bytes    = defined $out ? length $out : 0;
    my ( $fh, $rv );

    subPreamble( PDLEVEL2, '$$;$$$', $filename, $bytes, $wlen, $offset,
        $nolock );

    if ( defined $filename and defined $out and length $out ) {

        # Opportunistically open a file handle if needed,
        # otherwise, just retrieve the existing file handle
        $fh = popen( $filename, O_WRONLY | O_CREAT );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {
            if ( $nolock or pflock( $filename, LOCK_EX ) ) {
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
                pflock( $filename, LOCK_UN ) unless $nolock;
            }
        }
    }

    subPostamble( PDLEVEL2, '$', $rv );

    return $rv;
}

sub pnlwrite {

    # Purpose:  Wrapper for pwrite w/o internal flocking
    # Returns:  RV of pwrite
    # Usage:    $bytes = pnlwrite($filename, $text, $length);
    # Usage:    $bytes = pnlwrite($filename, $text, $length, $offset);

    my $filename = shift;
    my $out      = shift;
    my $wlen     = shift;
    my $offset   = shift;

    return pwrite( $filename, $out, $wlen, $offset, 1 );
}

sub pappend {

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
    my $nolock   = shift;
    my ( $fh, $pos, $rv );

    subPreamble( PDLEVEL2, '$$;$$', $filename, $out, $wlen, $offset,
        $nolock );

    if ( defined $filename and defined $out and length $out ) {

        # Opportunistically open a file handle in append mode
        $fh = popen( $filename, O_WRONLY | O_CREAT | O_APPEND );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {

            # Lock the file
            if ( $nolock or pflock( $filename, LOCK_EX ) ) {

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
                pflock( $filename, LOCK_UN ) unless $nolock;
            }
        }
    }

    subPostamble( PDLEVEL2, '$', $rv );

    return $rv;
}

sub pnlappend {

    # Purpose:  Wrapper for pappend w/o internal flocking
    # Returns:  RV of pappend
    # Usage:    $bytes = pnlappend($filename, $text, $length);
    # Usage:    $bytes = pnlappend($filename, $text, $length, $offset);

    my $filename = shift;
    my $out      = shift;
    my $wlen     = shift;
    my $offset   = shift;

    return pappend( $filename, $out, $wlen, $offset, 1 );
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

    subPreamble( PDLEVEL2, '$\$;$$$', $filename, $sref, $rlen, $offset,
        $nolock );

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

    subPostamble( PDLEVEL2, '$', $rv );

    return $rv;
}

sub pnlread ($\$;@) {

    # Purpose:  Wrapper for pread w/o internal flocking
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
    # Usage:    $rv = ptruncate($filename, $pos, 1);

    my $filename = shift;
    my $pos      = shift;
    my $nolock   = shift;
    my ( $rv, $fh, $cpos );

    subPreamble( PDLEVEL2, '$;$$', $filename, $pos, $nolock );

    if ( defined $filename ) {
        $pos = 0 unless defined $pos;
        $fh = popen( $filename, O_RDWR | O_CREAT );

        # Smoke 'em if you got'em...
        if ( defined $fh ) {
            if ( $nolock or pflock( $filename, LOCK_EX ) ) {
                $cpos = sysseek $fh, 0, SEEK_CUR;
                $rv = truncate $fh, $pos;
                if ($rv) {
                    sysseek $fh, $pos, SEEK_SET if $cpos > $pos;
                } else {
                    Paranoid::ERROR =
                        pdebug( 'failed to truncate file: %s', PDLEVEL1, $! );
                }
                pflock( $filename, LOCK_UN ) unless $nolock;
            }
        }
    }

    subPostamble( PDLEVEL2, '$', $rv );

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

$Id: lib/Paranoid/IO.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

  use Fcntl qw(:DEFAULT :flock :mode :seek);
  use Paranoid::IO qw(:all);

  # Implicit open
  $chars = pread("./foo.log", $in, 2048);

  # Implcit write/append
  $chars = pwrite("./bar.log", $out);
  $chars = pappend("./bar.log", $out);

  # Adjust block read size
  PIOBLKSIZE = 8192;

  # Adjust max file size for file scans
  PIOMAXFSIZE = 65536;

  # Enable flock lock stack
  PIOLOCKSTACK = 1;

  # Explicit open with explicit locking
  $fh = popen($filename, O_RDWR | O_CREAT | O_TRUNC, 0600);
  $rv = pseek($filename, 0, SEEK_END);
  $rv = pflock($filename, LOCK_EX);
  if ($rv > 0) {
    pseek($filename, 0, SEEK_SET) && ptruncate($filename);
  }
  $rv = pwrite($filename, $text)
  $rv = ptell($filename);
  $rv = plockstat($filename);

  # Calls that ignore file locks
  $rv = pnlwrite($filename, $text)
  $rv = pnlappend($filename, $text)
  $rv = pnlread($filename, $text)

  # After fork
  $rv = preopen();

  $rv = pclose($filename);
  $rv = pcloseAll();

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

=item * O_APPEND access patterns where needed even for files not opened with O_APPEND

=item * Intelligent file tracking

=item * Optional flock lock stack for transactional I/O patterns

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
opportunistically opened if the first I/O call is to I<pseek> or I<ptell>.
The intent of the file I/O (in regards to read/write file modes)
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

If you're managing flocks directly, however, all of the read/write functions
in this module not only support an option boolean argument to disable internal
flocking, but also have I<pnl*> wrapper functions that set that argument for
you.

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

=head2 Optional flock lock stack for transactional I/O patterns

Complex I/O patterns on file I/O can sometimes extensive nested function calls
that each manipulate flocks independently.  Those nested calls can come into
conflict when one call degrades a needed lock applied by a previous call.

For instance, a pattern where a new block needs to be allocated to an opened
file, but an index of blocks must be maintained within the same file.  One
might have a function which retrieves the list of block addresses from the
index, and that function rationally applies a shared flock before reading, and
removes it afterwards.  One might try to get an exclusive lock on the file,
then retrieve the index using the existing function. That function, however,
would end up replacing your exclusive lock with the shared lock, potentially
making it impossible to reacquire that exclusive lock depending on other
processes and their I/O.

The lock stack attempts to solve those kinds of problems by maintaining a
stack of flocks, and making sure that no new locks degrade the previous locks.
In previous example, it would notice that the stack was opened with an
exclusive lock, and when the index retrieval function attempts to apply the
shared lock, it would simply upgrade that lock to preserve the exclusive lock.
Since a stack tracks each call to L<pflock()>, once that function attempts to
release the shared lock, the lock stack would simply pop off it's upgraded
call from the stack, and make sure the preceding lock stays in place.

Another way to describe this in psuedo code:

    # Enable the lock stack
    PIOLOCKSTACK = 1;

    sub readIdx {
        pflock($file, LOCK_SH);
        # ... read data
        pflock($file, LOCK_UN);
        # ... return data
    }

    sub writeIdx {
        pflock($file, LOCK_EX);
        # ... write data
        pflock($file, LOCK_UN);
    }

    sub writeData {
        pflock($file, LOCK_EX);
        # ... write data
        pflock($file, LOCK_UN);
    }

    sub writeTx {
        pflock($file, LOCK_EX);
        readIdx();
        writeData();
        writeIdx();
        pflock($file, LOCK_UN);
    }

    # Execute the transaction
    writeTx();

Without the lock stack, executing the transaction function would cause the
following to happen:

    writeTx:
        # apply LOCK_EX
        # readIdx:
            # apply LOCK_SH
            # read data
            # release all locks w/LOCK_UN
        # writeData:
            # apply LOCK_EX
            # ERROR: any write decisions at this point based on the previous
            # ERROR: index read may cause file corruption because the index
            # ERROR: may have changed while this process was waiting to 
            # ERROR: reacquire the exclusive lock!

With the lock stack in place, however, it goes like this:

    writeTx:
        # apply LOCK_EX
            # lock stack: (LOCK_EX)
        # readIdx:
            # asks for LOCK_SH, but maintains LOCK_EX
                # lock stack: (LOCK_EX, LOCK_EX)
            # read data
            # deletes its lock from the stack, but preserves the previous lock
                # lock stack: (LOCK_EX)
        # writeData:
            # asks for LOCK_EX
                # lock stack: (LOCK_EX, LOCK_EX)
            # writes data
            # deletes its lock from the stack, but preserves the previous lock
                # lock stack: (LOCK_EX)
        # writeIdx:
            # asks for LOCK_EX
                # lock stack: (LOCK_EX, LOCK_EX)
            # writes data
            # deletes its lock from the stack, but preserves the previous lock
                # lock stack: (LOCK_EX)
        # release lock
            # lock stack: ()

At no point was the advisory lock lost, and hence, transactional integrity
was preserved for all compliant processes.

The lock stack is off by default to allow the developer complete control over
locking and I/O patterns, but it's there to make functions easier to write
without having to worry about any locks applied outside of their code scope.

One downside of the lock stack is that affects all I/O performed via the
L<Paranoid::IO> framework, it is not locallized to specific file handles.  For
that reason, one must be confident that flocks are applied as atomically as
possible throughout the code space leveraging it.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    pclose pcloseAll popen preopen ptell pseek pflock 
    plockstat pread pnlread pwrite pappend ptruncate

The following specialized import lists also exist:

    List        Members
    ---------------------------------------------------------
    all         @defaults PIOBLKSIZE PIOMAXFSIZE PIOLOCKSTACK

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

=head2 PIOLOCKSTACK

    PIOLOCKSTACK = 1

This lvalue function is not exported by default.  It is used to enable the 
flock lock stack functionality in order to support transactional I/O patterns.
It is disabled by default.

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

=head2 plockstat

    $lock = plockstat($filename);

This returns the last flock applied via L<pflock>.

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

This is a wrapper function for B<pread> that calls it with inherent file
locking disabled.  It is assumed that the dev is either managing flocks
directly, or they're not needed for this application.

=head2 pwrite

    $bytes = pwrite($filename, $text);
    $bytes = pwrite($filename, $text, $length);
    $bytes = pwrite($filename, $text, $length, $offset);
    $bytes = pwrite($filename, $text, $length, $nolock);
    $bytes = pwrite($fh, $text);
    $bytes = pwrite($fj, $text, $length);
    $bytes = pwrite($fh, $text, $length, $offset);
    $bytes = pwrite($fh, $text, $length, $offset, $nolock);

This returns the number of bytes written, or undef for any critical failures.
If this is called prior to an explicit I<popen> it uses a default mode of
B<O_WRONLY | O_CREAT | O_TRUNC>.

The optional boolean fifth argument (I<nolock>) will bypass automatic flocks
since it assumes you're managing the lock directly.

=head2 pnlwrite

    $bytes = pnlwrite($filename, $text);
    $bytes = pnlwrite($filename, $text, $length);
    $bytes = pnlwrite($filename, $text, $length, $offset);
    $bytes = pnlwrite($fh, $text);
    $bytes = pnlwrite($fj, $text, $length);
    $bytes = pnlwrite($fh, $text, $length, $offset);

This is a wrapper function for B<pwrite> that calls it with inherent file
locking disabled.  It is assumed that the dev is either managing flocks
directly, or they're not needed for this application.

=head2 pappend

    $bytes = pappend($filename, $text);
    $bytes = pappend($filename, $text, $length);
    $bytes = pappend($filename, $text, $length, $offset);
    $bytes = pappend($filename, $text, $length, $offset, $nolock);
    $bytes = pappend($fh, $text);
    $bytes = pappend($fh, $text, $length);
    $bytes = pappend($fh, $text, $length, $offset, $nolock);

This behaves identically to I<pwrite> with the sole exception that this
preserves the file position after explicitly seeking and writing to the end of
the file.  The default mode here, however, would be B<O_WRONLY | O_CREAT |
O_APPEND> for those files not explicitly opened.

The optional boolean fifth argument (I<nolock>) will bypass automatic flocks
since it assumes you're managing the lock directly.

=head2 pnlappend

    $bytes = pnlappend($filename, $text);
    $bytes = pnlappend($filename, $text, $length);
    $bytes = pnlappend($filename, $text, $length, $offset);
    $bytes = pnlappend($fh, $text);
    $bytes = pnlappend($fj, $text, $length);
    $bytes = pnlappend($fh, $text, $length, $offset);

This is a wrapper function for B<pappend> that calls it with inherent file
locking disabled.  It is assumed that the dev is either managing flocks
directly, or they're not needed for this application.

=head2 ptruncate

    $rv = ptruncate($filename);
    $rv = ptruncate($filename, $pos, $nolock);
    $rv = ptruncate($fh);
    $rv = ptruncate($fh, $pos, $nolock);

This returns the result of the internal L<truncate> call.  If called without
an explicit I<popen> it will open the named file with the default mode of
B<O_RDWR | O_CREAT>.  Omitting the position to truncate from will result in
the file being truncated at the beginning of the file.

The optional boolean third argument (I<nolock>) will bypass automatic flocks
since it assumes you're managing the lock directly.

=head2 pnltruncate

    $rv = pnltruncate($filename);
    $rv = pnltruncate($fh);

This is a wrapper function for B<pnltruncate> that calls it with inherent file
locking disabled.  It is assumed that the dev is either managing flocks
directly, or they're not needed for this application.

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

(c) 2005 - 2021, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2021, Paranoid Inc. (www.paranoid.com)

