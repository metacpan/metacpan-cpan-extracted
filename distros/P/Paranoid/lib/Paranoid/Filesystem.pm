# Paranoid::Filesystem -- Filesystem support for paranoid programs
#
# $Id: lib/Paranoid/Filesystem.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the "Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>",
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

package Paranoid::Filesystem;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Cwd qw(realpath);
use Errno qw(:POSIX);
use Fcntl qw(:DEFAULT :seek :flock :mode);
use Paranoid;
use Paranoid::Debug qw(:all);
use Paranoid::Process qw(ptranslateUser ptranslateGroup);
use Paranoid::Input;
use Paranoid::IO;
use Paranoid::Glob;

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT = qw(
    preadDir     psubdirs    pfiles
    pmkdir       prm         prmR      ptouch
    ptouchR      pchmod      pchmodR   pchown
    pchownR      pwhich
    );
@EXPORT_OK = (
    @EXPORT, qw(
        ptranslateLink
        pcleanPath
        ptranslatePerms
        ) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant PERMMASK => 0777;

#####################################################################
#
# Module code follows
#
#####################################################################

sub pmkdir ($;$\%) {

    # Purpose:  Simulates a 'mkdir -p' command in pure Perl
    # Returns:  True (1) if all targets were successfully created,
    #           False (0) if there are any errors
    # Usage:    $rv = pmkdir("/foo/{a1,b2}");
    # Usage:    $rv = pmkdir("/foo", 0750);
    # Usage:    $rv = pmkdir("/foo", 0750, %errors);

    my $path = shift;
    my $mode = shift;
    my $eref = shift || {};
    my ( $dirs, $directory, $subdir, @parts, $i );
    my $rv = 1;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $path, $mode );
    pIn();

    # Create a glob object if we weren't handed one.
    if ( defined $path ) {
        $dirs =
            ref $path eq 'Paranoid::Glob'
            ? $path
            : Paranoid::Glob->new( globs => [$path] );
    }

    # Leave Paranoid::Glob's errors in place if there was a problem
    $rv = 0 unless defined $dirs;

    # Set and detaint mode
    if ($rv) {
        $mode = ptranslatePerms( defined $mode ? $mode : umask ^ PERMMASK );
        unless ( detaint( $mode, 'int' ) ) {
            Paranoid::ERROR =
                pdebug( 'invalid mode argument passed', PDLEVEL1 );
            $rv = 0;
        }
    }

    # Start creating directories
    if ($rv) {

        # Iterate over each directory in the glob
        foreach $directory (@$dirs) {
            pdebug( 'processing %s', PDLEVEL2, $directory );

            # Skip directories already present
            next if -d $directory;

            # Otherwise, split so we can backtrack to the first available
            # subdirectory and start creating subdirectories from there
            @parts = split m#/+#s, $directory;
            $i = $parts[0] eq '' ? 1 : 0;
            $i++ while $i < $#parts and -d join '/', @parts[ 0 .. $i ];
            while ( $i <= $#parts ) {
                $subdir = join '/', @parts[ 0 .. $i ];
                unless ( -d $subdir ) {
                    if ( mkdir $subdir, $mode ) {

                        # Make sure perms are applied
                        chmod $mode, $subdir;

                    } else {

                        # Error out and halt all work
                        Paranoid::ERROR = pdebug( 'failed to create %s: %s',
                            PDLEVEL1, $subdir, $! );
                        $rv = 0;
                        last;
                    }
                }
                $i++;
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub prm ($;\%) {

    # Purpose:  Simulates a "rm -f" command in pure Perl
    # Returns:  True (1) if all targets were successfully removed,
    #           False (0) if there are any errors
    # Usage:    $rv = prm("/foo");
    # Usage:    $rv = prm("/foo", %errors);

    my $target = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob, @fstat );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $target, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    # Start removing files
    if ($rv) {

        # Consolidate the entries
        $glob->consolidate;

        # Iterate over entries
        foreach ( reverse @$glob ) {
            pdebug( 'processing %s', PDLEVEL2, $_ );

            # Stat the file
            @fstat = lstat $_;

            unless (@fstat) {

                # If the file is missing, consider the removal successful and
                # move on.
                next if $! == ENOENT;

                # Report remaining errors (permission denied, etc.)
                $rv = 0;
                $$errRef{$_} = $!;
                Paranoid::ERROR =
                    pdebug( 'failed to remove %s: %s', PDLEVEL1, $_, $! );
                next;
            }

            if ( S_ISDIR( $fstat[2] ) ) {

                # Remove directories
                unless ( rmdir $_ ) {

                    # Record errors
                    $rv = 0;
                    $$errRef{$_} = $!;
                    Paranoid::ERROR =
                        pdebug( 'failed to remove %s: %s', PDLEVEL1, $_, $! );
                }

            } else {

                # Remove all non-directories
                unless ( unlink $_ ) {

                    # Record errors
                    $rv = 0;
                    $$errRef{$_} = $!;
                    Paranoid::ERROR =
                        pdebug( 'failed to remove %s: %s', PDLEVEL1, $_, $! );
                }
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub prmR ($;$\%) {

    # Purpose:  Recursively calls prm to simulate "rm -rf"
    # Returns:  True (1) if all targets were successfully removed,
    #           False (0) if there are any errors
    # Usage:    $rv = prmR("/foo");
    # Usage:    $rv = prmR("/foo", 1);
    # Usage:    $rv = prmR("/foo", 1, %errors);

    my $target = shift;
    my $follow = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $target, $follow, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ($rv) {

        # Load the directory tree and execute prm
        $rv = $glob->recurse( $follow, 1 ) && prm( $glob, %$errRef );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub preadDir ($\@;$) {

    # Purpose:  Populates the passed array ref with a list of all the
    #           directory entries (minus the '.' & '..') in the passed
    #           directory
    # Returns:  True (1) if the read was successful,
    #           False (0) if there are any errors
    # Usage:    $rv = preadDir("/tmp", @entries);
    # Usage:    $rv = preadDir("/tmp", @entries, 1);

    my ( $dir, $aref, $noLinks ) = @_;
    my $rv = 1;
    my $fh;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $dir, $aref, $noLinks );
    pIn();
    @$aref = ();

    # Validate directory and exit early, if need be
    unless ( defined $dir and -e $dir and -d _ and -r _ ) {
        $rv = 0;
        Paranoid::ERROR = pdebug( (
                  !defined $dir ? 'undefined value passed as directory name'
                : !-e _         ? 'directory (%s) does not exist'
                : !-d _         ? '%s is not a directory'
                : 'directory (%s) is not readable by the effective user'
            ),
            PDLEVEL1, $dir
            );
    }

    if ($rv) {

        # Read the directory's contents
        $rv = opendir $fh, $dir;

        if ($rv) {

            # Get the list, filtering out '.' & '..'
            foreach ( readdir $fh ) {
                push @$aref, "$dir/$_" unless m/^\.\.?$/s;
            }
            closedir $fh;

            # Filter out symlinks, if necessary
            @$aref = grep { !-l $_ } @$aref if $noLinks;

        } else {
            Paranoid::ERROR = pdebug( 'error opening directory (%s): %s',
                PDLEVEL1, $dir, $! );
        }
    }

    pdebug( 'returning %d entries', PDLEVEL2, scalar @$aref );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub psubdirs ($\@;$) {

    # Purpose:  Performs a preadDir but filters out all non-directory entries
    #           so that only subdirectory entries are returned.  Can
    #           optionally filter out symlinks to directories as well.
    # Returns:  True (1) if the directory read was successful,
    #           False (0) if there are any errors
    # Usage:    $rv = psubdirs($dir, @entries);
    # Usage:    $rv = psubdirs($dir, @entries, 1);

    my ( $dir, $aref, $noLinks ) = @_;
    my $rv = 0;

    # Validate arguments
    $noLinks = 0 unless defined $noLinks;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $dir, $aref, $noLinks );
    pIn();

    # Empty target array and retrieve list
    $rv = preadDir( $dir, @$aref, $noLinks );

    # Filter out all non-directories
    @$aref = grep { -d $_ } @$aref if $rv;

    pdebug( 'returning %d entries', PDLEVEL2, scalar @$aref );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pfiles ($\@;$) {

    # Purpose:  Performs a preadDir but filters out all directory entries
    #           so that only file entries are returned.  Can
    #           optionally filter out symlinks to files as well.
    # Returns:  True (1) if the directory read was successful,
    #           False (0) if there are any errors
    # Usage:    $rv = pfiles($dir, @entries);
    # Usage:    $rv = pfiles($dir, @entries, 1);

    my ( $dir, $aref, $noLinks ) = @_;
    my $rv = 0;

    # Validate arguments
    $noLinks = 0 unless defined $noLinks;

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $dir, $aref );
    pIn();

    # Empty target array and retrieve list
    @$aref = ();
    $rv = preadDir( $dir, @$aref, $noLinks );

    # Filter out all non-files
    @$aref = grep { -f $_ } @$aref if $rv;

    pdebug( 'returning %d entries', PDLEVEL2, scalar @$aref );

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pcleanPath {

    # Purpose:  Removes/resolves directory artifacts like '/../', etc.
    # Returns:  Filtered string
    # Usage:    $filename = pcleanPath($filename);

    my $filename = shift;

    pdebug( 'entering w/(%s)', PDLEVEL1, $filename );
    pIn();

    if ( defined $filename ) {

        # Strip all //+, /./, and /{parent}/../
        while ( $filename =~ m#/\.?/+#s ) { $filename =~ s#/\.?/+#/#sg }
        while ( $filename =~ m#/(?:(?!\.\.)[^/]{2,}|[^/])/\.\./#s ) {
            $filename =~ s#/(?:(?!\.\.)[^/]{2,}|[^/])/\.\./#/#sg;
        }

        # Strip trailing /. and leading /../
        $filename =~ s#/\.$##s;
        while ( $filename =~ m#^/\.\./#s ) { $filename =~ s#^/\.\./#/#s }

        # Strip any ^[^/]+/../
        while ( $filename =~ m#^[^/]+/\.\./#s ) {
            $filename =~ s#^[^/]+/\.\./##s;
        }

        # Strip any trailing /^[^/]+/..$
        while ( $filename =~ m#/[^/]+/\.\.$#s ) {
            $filename =~ s#/[^/]+/\.\.$##s;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $filename );

    return $filename;
}

sub ptranslateLink {

    # Purpose:  Performs either a full (realpath) or a partial one (last
    #           filename element only) on the passed filename
    # Returns:  Altered filename if successful, undef if there are any
    #           failures
    # Usage:    $filename = ptranslateLink($filename);
    # Usage:    $filename = ptranslateLink($filename, 1);

    my $link           = shift;
    my $fullyTranslate = shift || 0;
    my $nLinks         = 0;
    my ( $i, $target );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $link, $fullyTranslate );
    pIn();

    # Validate link and exit early, if need be
    unless ( defined $link and scalar lstat $link ) {
        Paranoid::ERROR = pdebug( 'link (%s) does not exist on filesystem',
            PDLEVEL1, $link );
        pOut();
        pdebug( 'leaving w/rv: undef', PDLEVEL1 );
        return undef;
    }

    # Check every element in the path for symlinks and translate it if
    # if a full translation was requested
    if ($fullyTranslate) {

        # Resolve the link
        $target = realpath($link);

        # Make sure we got an answer
        if ( defined $target ) {

            # Save the answer
            $link = $target;

        } else {

            # Report our inability to resolve the link
            Paranoid::ERROR =
                pdebug( 'link (%s) couldn\'t be resolved fully: %s',
                PDLEVEL1, $link, $! );
            $link = undef;
        }

    } else {

        # Is the file passed a symlink?
        if ( -l $link ) {

            # Yes it is, let's get the target
            $target = readlink $link;
            pdebug( 'last element is a link to %s', PDLEVEL1, $target );

            # Is the target a relative filename?
            if ( $target =~ m#^(?:\.\.?/|[^/])#s ) {

                # Yupper, replace the filename with the target
                $link =~ s#[^/]+$#$target#s;

            } else {

                # The target is fully qualified, so replace link entirely
                $link = $target;
            }
        }
    }

    $link = pcleanPath($link) if defined $link;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $link );

    return $link;
}

sub ptouch ($;$\%) {

    # Purpose:  Simulates a "touch" command in pure Perl
    # Returns:  True (1) if all targets were successfully touched,
    #           False (0) if there are any errors
    # Usage:    $rv = ptouch("/foo/*");
    # Usage:    $rv = ptouch("/foo/*", $tstamp);
    # Usage:    $rv = ptouch("/foo/*", $tstamp, %errors);

    my $target = shift;
    my $stamp  = shift;
    my $errRef = shift;
    my $rv     = 1;
    my $irv    = 1;
    my ( $glob, $tglob, $fh );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $target, $stamp, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ($rv) {

        # Apply the default timestamp if omitted
        $stamp = time unless defined $stamp;

        unless ( detaint( $stamp, 'int' ) ) {
            Paranoid::ERROR = pdebug( 'Invalid characters in timestamp: %s',
                PDLEVEL2, $stamp );
            $rv = 0;
        }
    }

    # Start touching stuff
    if ($rv) {

        # Consolidate the entries
        $glob->consolidate;

        # Iterate over entries
        foreach $target (@$glob) {
            pdebug( 'processing %s', PDLEVEL2, $target );
            $irv = 1;

            # Create the target if it does not exist
            unless ( -e $target ) {
                pdebug( 'creating empty file (%s)', PDLEVEL2, $target );
                $fh = popen( $target, O_CREAT | O_EXCL | O_RDWR )
                    || popen( $target, O_RDWR );
                if ( defined $fh ) {
                    pclose($target);
                } else {
                    $$errRef{$target} = $!;
                    $irv = $rv = 0;
                }
            }

            # Touch the file
            if ($irv) {
                unless ( utime $stamp, $stamp, $target ) {
                    $$errRef{$target} = $!;
                    $rv = 0;
                }
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub ptouchR ($;$$\%) {

    # Purpose:  Calls ptouch recursively
    # Returns:  True (1) if all targets were successfully touched,
    #           False (0) if there are any errors
    # Usage:    $rv = ptouchR("/foo");
    # Usage:    $rv = ptouchR("/foo", $tstamp);
    # Usage:    $rv = ptouchR("/foo", $tstamp, $follow);
    # Usage:    $rv = ptouchR("/foo", $tstamp, $follow, %errors);

    my $target = shift;
    my $stamp  = shift;
    my $follow = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL1, $target, $stamp, $follow, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ($rv) {

        # Load the directory tree and execute prm
        $rv = $glob->recurse( $follow, 1 )
            && ptouch( $glob, $stamp, %$errRef );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub ptranslatePerms {

    # Purpose:  Translates symbolic permissions (as supported by userland
    #           chmod, etc.) into the octal permissions.
    # Returns:  Numeric permissions if valid symbolic permissions were passed,
    #           undef otherwise
    # Usage:    $perm = ptranslatePerms('ug+srw');

    my $perm = shift;
    my $rv   = undef;
    my ( @tmp, $o, $p );

    pdebug( 'entering w/(%s)', PDLEVEL1, $perm );
    pIn();

    # Validate permissions string
    if ( defined $perm and $perm =~ /^\d+$/s ) {

        if ( $perm =~ /^0/s ) {
            if ( $perm =~ /^0[0-8]{3,4}$/s ) {

                # String representation of octal number
                eval "\$perm = $perm;";
                detaint( $perm, 'int', $p );

            } else {
                pdebug( 'invalid octal presentation: %s', PDLEVEL1, $perm );
            }

        } else {

            # Probably a converted integer already, treat it as verbatim
            detaint( $perm, 'int', $p );
        }

    } elsif ( defined $perm and $perm =~ /^([ugo]+)([+\-])([rwxst]+)$/s ) {

        # Translate symbolic representation
        $o = $p = 00;
        @tmp = ( $1, $2, $3 );
        $o = S_IRWXU if $tmp[0] =~ /u/s;
        $o |= S_IRWXG if $tmp[0] =~ /g/s;
        $o |= S_IRWXO if $tmp[0] =~ /o/s;
        $p = ( S_IRUSR | S_IRGRP | S_IROTH ) if $tmp[2] =~ /r/s;
        $p |= ( S_IWUSR | S_IWGRP | S_IWOTH ) if $tmp[2] =~ /w/s;
        $p |= ( S_IXUSR | S_IXGRP | S_IXOTH ) if $tmp[2] =~ /x/s;
        $p &= $o;
        $p |= S_ISVTX if $tmp[2] =~ /t/s;
        $p |= S_ISGID if $tmp[2] =~ /s/s && $tmp[0] =~ /g/s;
        $p |= S_ISUID if $tmp[2] =~ /s/s && $tmp[0] =~ /u/s;

    } else {

        # Report invalid characters in permission string
        Paranoid::ERROR =
            pdebug( 'invalid permissions (%s)', PDLEVEL1, $perm );

    }
    $rv = $p;

    pOut();
    pdebug( (
            defined $rv
            ? sprintf( 'leaving w/rv: %04o', $rv )
            : 'leaving w/rv: undef'
        ),
        PDLEVEL1
        );

    return $rv;
}

sub pchmod ($$;\%) {

    # Purpose:  Simulates a "chmod" command in pure Perl
    # Returns:  True (1) if all targets were successfully chmod'd,
    #           False (0) if there are any errors
    # Usage:    $rv = pchmod("/foo", $perms);
    # Usage:    $rv = pchmod("/foo", $perms, %errors);

    my $target = shift;
    my $perms  = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob, @fstat );
    my ( $ptrans, $cperms, $addPerms, @tmp );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL1, $target, $perms, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    # Convert perms if they're symbolic
    if ( defined $perms and defined( $ptrans = ptranslatePerms($perms) ) ) {
        if ( $perms =~ /[ugo]+[+-]/si ) {
            $addPerms = $perms =~ /-/s ? 0 : 1;
        } else {
            $ptrans = undef;
        }
    } else {
        pdebug( 'invalid permissions passed: %s', PDLEVEL1, $perms );
        $rv = 0;
    }

    if ($rv) {

        # Consolidate the entries
        $glob->consolidate;

        # Iterate over entries
        foreach (@$glob) {
            pdebug( 'processing %s', PDLEVEL2, $_ );

            if ( defined $ptrans ) {

                # Get the current file mode
                @fstat = stat $_;
                unless (@fstat) {
                    $rv = 0;
                    $$errRef{$_} = $!;
                    Paranoid::ERROR =
                        pdebug( 'failed to adjust permissions of %s: %s',
                        PDLEVEL1, $_, $! );
                    next;
                }

                # If ptrans is defined we're going to do relative
                # application of permissions
                pdebug(
                    $addPerms
                    ? sprintf( 'adding perms %04o',   $ptrans )
                    : sprintf( 'removing perms %04o', $ptrans ),
                    PDLEVEL2
                    );

                # Get the current permissions
                $cperms = $fstat[2] & PERMMASK;
                pdebug(
                    sprintf( 'current permissions of %s: %04o', $_, $cperms ),
                    PDLEVEL2
                    );
                $cperms =
                    $addPerms
                    ? ( $cperms | $ptrans )
                    : ( $cperms & ( PERMMASK ^ $ptrans ) );
                pdebug( sprintf( 'new permissions of %s: %04o', $_, $cperms ),
                    PDLEVEL2 );
                unless ( chmod $cperms, $_ ) {
                    $rv = 0;
                    $$errRef{$_} = $!;
                    Paranoid::ERROR =
                        pdebug( 'failed to adjust permissions of %s: %s',
                        PDLEVEL1, $_, $! );
                }

            } else {

                # Otherwise, the permissions are explicit
                #
                # Detaint number mode
                if ( detaint( $perms, 'int' ) ) {

                    # Detainted, now apply
                    pdebug(
                        sprintf(
                            'assigning permissions of %04o to %s',
                            $perms, $_
                            ),
                        PDLEVEL2
                        );
                    unless ( chmod $perms, $_ ) {
                        $rv = 0;
                        $$errRef{$_} = $!;
                    }
                } else {

                    # Detainting failed -- report
                    $$errRef{$_} = $!;
                    Paranoid::ERROR =
                        pdebug( 'failed to detaint permissions mode',
                        PDLEVEL1 );
                    $rv = 0;
                }
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pchmodR ($$;$\%) {

    # Purpose:  Recursively calls pchmod
    # Returns:  True (1) if all targets were successfully chmod'd,
    #           False (0) if there are any errors
    # Usage:    $rv = pchmodR("/foo", $perms);
    # Usage:    $rv = pchmodR("/foo", $perms, $follow);
    # Usage:    $rv = pchmodR("/foo", $perms, $follow, %errors);

    my $target = shift;
    my $perms  = shift;
    my $follow = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL1, $target, $perms, $follow, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ($rv) {

        # Load the directory tree and execute pchmod
        $rv = $glob->recurse( $follow, 1 )
            && pchmod( $glob, $perms, %$errRef );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pchown ($$;$\%) {

    # Purpose:  Simulates a "chown" command in pure Perl
    # Returns:  True (1) if all targets were successfully owned,
    #           False (0) if there are any errors
    # Usage:    $rv = pchown("/foo", $user);
    # Usage:    $rv = pchown("/foo", $user, $group);
    # Usage:    $rv = pchown("/foo", $user, $group, %errors);

    my $target = shift;
    my $user   = shift;
    my $group  = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob, @fstat );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL1, $target, $user, $group, $errRef );
    pIn();

    # Translate to UID/GID
    $user  = -1 unless defined $user;
    $group = -1 unless defined $group;
    $user  = ptranslateUser($user)   unless $user  =~ /^-?\d+$/s;
    $group = ptranslateGroup($group) unless $group =~ /^-?\d+$/s;
    unless ( defined $user and defined $group ) {
        $rv = 0;
        Paranoid::ERROR =
            pdebug( 'unsuccessful at translating uid/gid', PDLEVEL1 );
    }

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ( $rv and ( $user != -1 or $group != -1 ) ) {

        # Proceed
        pdebug( 'UID: %s GID: %s', PDLEVEL2, $user, $group );

        # Consolidate the entries
        $glob->consolidate;

        # Process the list
        foreach (@$glob) {

            pdebug( 'processing %s', PDLEVEL2, $_ );

            unless ( chown $user, $group, $_ ) {
                $rv = 0;
                $$errRef{$_} = $!;
                Paranoid::ERROR =
                    pdebug( 'failed to adjust ownership of %s: %s',
                    PDLEVEL1, $_, $! );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pchownR ($$;$$\%) {

    # Purpose:  Calls pchown recursively
    # Returns:  True (1) if all targets were successfully owned,
    #           False (0) if there are any errors
    # Usage:    $rv = pchownR("/foo", $user);
    # Usage:    $rv = pchownR("/foo", $user, $group);
    # Usage:    $rv = pchownR("/foo", $user, $group, $follow);
    # Usage:    $rv = pchownR("/foo", $user, $group, $follow, %errors);

    my $target = shift;
    my $user   = shift;
    my $group  = shift;
    my $follow = shift;
    my $errRef = shift;
    my $rv     = 1;
    my ( $glob, $tglob );

    pdebug( 'entering w/(%s)(%s)(%s)(%s)(%s)',
        PDLEVEL1, $target, $user, $group, $follow, $errRef );
    pIn();

    # Prep error hash
    $errRef = {} unless defined $errRef;
    %$errRef = ();

    # Create a glob object if we weren't handed one.
    if ( defined $target ) {
        $glob =
            ref $target eq 'Paranoid::Glob'
            ? $target
            : Paranoid::Glob->new( globs => [$target] );
    }
    $rv = 0 unless defined $glob;

    if ($rv) {

        # Load the directory tree and execute pchown
        $rv = $glob->recurse( $follow, 1 )
            && pchown( $glob, $user, $group, %$errRef );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub pwhich {

    # Purpose:  Simulates a "which" command in pure Perl
    # Returns:  The full path to the requested program if successful
    #           undef if not found
    # Usage:    $filename = pwhich('ls');

    my $binary      = shift;
    my @directories = grep /^.+$/s, split /:/s, $ENV{PATH};
    my $match       = undef;

    pdebug( 'entering w/(%s)', PDLEVEL1, $binary );
    pIn();

    # Try to detaint filename
    if ( detaint( $binary, 'filename', $b ) ) {

        # Success -- start searching directories in PATH
        foreach (@directories) {
            pdebug( 'searching %s', PDLEVEL2, $_ );
            if ( -r "$_/$b" && -x _ ) {
                $match = "$_/$b";
                $match =~ s#/+#/#sg;
                last;
            }
        }

    } else {

        # Report detaint failure
        Paranoid::ERROR = pdebug( 'failed to detaint %s', PDLEVEL1, $binary );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $match );

    return $match;
}

1;

__END__

=head1 NAME

Paranoid::Filesystem - Filesystem Functions

=head1 VERSION

$Id: lib/Paranoid/Filesystem.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::Filesystem;

  $rv = pmkdir("/foo/{a1,b2}");

  $rv = preadDir("/tmp", @entries);
  $rv = psubdirs("/etc", @dirList);
  $rv = pfiles("/etc", @filesList);

  $rv = ptouch("/foo/*", $tstamp);
  $rv = ptouchR("/foo", $tstamp, $follow, %errors);
  $rv = pchmod("/foo", $perms);
  $rv = pchmodR("/foo", $perms, $follow, %errors);
  $rv = pchown("/foo", $user, $group);
  $rv = pchownR("/foo", $user, $group, $follow, %errors);

  $rv = prm("/foo");
  $rv = prmR("/foo", 1, %errors);

  $fullname = pwhich('ls');
  $cleaned  = pcleanPath($filename);
  $noLinks  = ptranslateLink("/etc/foo/bar.conf");
  $rv       = ptranslatePerms("ug+rwx");

=head1 DESCRIPTION

This module provides a few functions to make accessing the filesystem a little
easier, while instituting some safety checks.  If you want to enable debug
tracing into each function you must set B<PDEBUG> to at least 9.

B<pcleanPath>, B<ptranslateLink>, and B<ptranslatePerms> are only exported 
if this module is used with the B<:all> target.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    preadDir psubdirs pfiles pmkdir prm prmR ptouch
    ptouchR pchmod pchmodR pchown pchownR pwhich

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    all         @defaults ptranslateLink pcleanPath 
                ptranslatePerms

=head1 SUBROUTINES/METHODS

=head2 pmkdir

  $rv = pmkdir("/foo/{a1,b2}");
  $rv = pmkdir("/foo", 0750);
  $rv = pmkdir("/foo", 0750, %errors);

This function simulates a 'mkdir -p {path}', returning false if it fails for
any reason other than the directory already being present.  The second
argument (permissions) is optional, but if present should be an octal number.
Shell-style globs are supported as the path argument.

If you need to make a directory that includes characters which would normally
be interpreted as shell expansion characters you can offer a B<Paranoid::Glob>
object as the path argument instead.  Creating such an object while passing it
a I<literal> value will prevent any shell expansion from happening.

This method also allows you to call B<pmkdir> with a list of directories to
create, rather than just relying upon shell expansion to construct the list.

=head2 prm

  $rv = prm("/foo");
  $rv = prm("/foo", %errors);

This function unlinks non-directories and rmdir's directories.

File arguments are processed through L<Paranoid::Glob> and expanded into 
multiple targets if globs are detected.  You can also use a Paranoid::Glob
object with a multitude of entities to delete instead of a string.

The optional second argument is a hash in which any error messages is stored
(with the file/directory name as the key).  Attempting to delete something
that's not present is not considered a failure.

=head2 prmR

  $rv = prmR("/foo");
  $rv = prmR("/foo", 1);
  $rv = prmR("/foo", 1, %errors);

This function works the same as B<prm> but performs a recursive delete,
similar to "rm -r" on the command line.  An optional second argument determines
if symbolic links are followed and the targets also recursively deleted.

=head2 preadDir

  $rv = preadDir("/tmp", @entries);
  $rv = preadDir("/tmp", @entries, 1);

This function populates the passed array with the contents of the specified
directory.  If there are any problems reading the directory the return value
will be false and a string explaining the error will be stored in
B<Paranoid::ERROR>.

All entries in the returned list will be prefixed with the directory name.  An
optional third boolean argument can be given to filter out symlinks from the
results.

=head2 psubdirs

  $rv = psubdirs("/etc", @dirList);

This function calls B<preadDir> in the background and filters the list for
directory (or symlinks to) entries.  It also returns a true if the command was
processed with no problems, and false otherwise.

Like B<preadDir> an optional third boolean argument can be passed that causes
symlinks to be filtered out.

=head2 pfiles

  $rv = pfiles("/etc", @filesList);

This function calls B<preadDir> in the background and filters the list for
file (or symlinks to) entries.  It also returns a true if the command was
processed with no problems, and false otherwise.

Like B<preadDir> an optional third boolean argument can be passed that causes
symlinks to be filtered out.

=head2 pcleanPath

  $cleaned = pcleanPath($filename);

This function takes a filename and cleans out any '.', '..', and '//+'
occurrences within the path.  It does not remove '.' or '..' as the first path
element, however, in order to preserve the root of the relative path.

B<NOTE:> this function does not do any checking to see if the passed
filename/path actually exists or is valid in any way.  It merely removes the
unnecessary artifacts from the string.

If you're resolving an existing filename and want symlinks resolved to the
real path as well you might be interested in B<Cwd>'s B<realpath> function
instead.

=head2 ptranslateLink

  $noLinks = ptranslateLink("/etc/foo/bar.conf");

This functions tests if passed filename is a symlink, and if so, translates it
to the final target.  If a second argument is passed and evaluates to true it
will check every element in the path and do a full translation to the final
target.

The final target is passed through pcleanPath beforehand to remove any
unneeded path artifacts.  If an error occurs (like circular link references
or the target being nonexistent) this function will return undef.
You can retrieve the reason for failure from B<Paranoid::ERROR>.

Obviously, testing for symlinks requires testing against the filesystem, so
the target must be valid and present.

B<Note:> because of the possibility that relative links are being used
(including levels of '..') all links are translated fully qualified from /.

=head2 ptouch

  $rv = ptouch("/foo/*");
  $rv = ptouch("/foo/*", $tstamp);
  $rv = ptouch("/foo/*", $tstamp, %errors);

Simulates the UNIX touch command.  Like the UNIX command this will create
zero-byte files if they don't exist.  The time stamp is an integer denoting
the time in UNIX epoch seconds.

Shell-style globs are supported, as are L<Paranoid::Glob> objects.

The error message from each failed operation will be placed into the passed
hash using the file name as the key.

=head2 ptouchR

  $rv = ptouchR("/foo");
  $rv = ptouchR("/foo", $tstamp);
  $rv = ptouchR("/foo", $tstamp, $follow);
  $rv = ptouchR("/foo", $tstamp, $follow, %errors);

This function works the same as B<ptouch>, but offers one additional
argument (the third argument), boolean, which indicates whether or not the
command should follow symlinks.

You cannot use this function to create new, non-existant files, this only
works to update an existing directory heirarchy's mtime.

=head2 ptranslatePerms

  $rv = ptranslatePerms("ug+rwx");

This translates symbolic mode notation into an octal number.  It fed invalid 
permissions it will return undef.  It understands the following symbols:

  u            permissions apply to user
  g            permissions apply to group
  o            permissions apply to all others
  r            read privileges
  w            write privileges
  x            execute privileges
  s            setuid/setgid (depending on u/g)
  t            sticky bit

B<EXAMPLES>

  # Add user executable privileges
  $perms = (stat "./foo")[2];
  chmod $perms | ptranslatePerms("u+x"), "./foo";

  # Remove all world privileges
  $perms = (stat "./bar")[2];
  chmod $perms ^ ptranslatePerms("o-rwx"), "./bar";

B<NOTE:> If this function is called with a numeric representation of
permissions, it will return them as-is.  This allows for this function to be
called indiscriminately where you might be given permissions in either format,
but ultimately want them only in numeric presentation.

=head2 pchmod

  $rv = pchmod("/foo", $perms);
  $rv = pchmod("/foo", $perms, %errors);

This function takes a given permission and applies it to every file given to
it.  The permission can be an octal number or symbolic notation (see 
I<ptranslatePerms> for specifics).  If symbolic notation is used the
permissions will be applied relative to the current permissions on each
file.  In other words, it acts exactly like the B<chmod> program.

File arguments are processed through L<Paranoid::Glob> and expanded into 
multiple targets if globs are detected. or you can hand it a glob object
directly.

The error message from each failed operation will be placed into the passed
hash using the filename as the key.

The return value will be true unless any errors occur during the actual
chmod operation including attempting to set permissions on non-existent
files.  

=head2 pchmodR

  $rv = pchmodR("/foo", $perms);
  $rv = pchmodR("/foo", $perms, $follow);
  $rv = pchmodR("/foo", $perms, $follow, %errors);

This function works the same as B<pchmod>, but offers one additional
argument (the third argument), boolean, which indicates whether or not the
command should follow symlinks.

=head2 pchown

  $rv = pchown("/foo", $user);
  $rv = pchown("/foo", $user, $group);
  $rv = pchown("/foo", $user, $group, %errors);

This function takes a user and/or a named group or ID and applies it to
every file given to it.  If either the user or group is undefined it leaves
that portion of ownership unchanged.

File arguments are processed through L<Paranoid::Glob> and expanded into 
multiple targets if globs are detected, or you can hand it a populated glob
object directly.

The error message from each failed operation will be placed into the passed
hash using the filename as the key.

The return value will be true unless any errors occur during the actual
chown operation including attempting to set permissions on non-existent
files.  

=head2 pchownR

  $rv = pchownR("/foo", $user);
  $rv = pchownR("/foo", $user, $group);
  $rv = pchownR("/foo", $user, $group, $follow);
  $rv = pchownR("/foo", $user, $group, $follow, %errors);

This function works the same as B<pchown>, but requires one additional
argument (the fourth argument), boolean, which indicates whether or not the
command should follow symlinks.

=head2 pwhich

  $fullname = pwhich('ls');

This function tests each directory in your path for a binary that's both
readable and executable by the effective user.  It will return only one
match, stopping the search on the first match.  If no matches are found it
will return undef.

=head1 DEPENDENCIES

=over

=item o

L<Cwd>

=item o

L<Errno>

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Glob>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::Process>

=back

=head1 BUGS AND LIMITATIONS

B<ptranslateLink> is probably pointless for 99% of the uses out there, you're
better off using B<Cwd>'s B<realpath> function instead.  The only thing it can
do differently is translating a single link itself, without translating any
additional symlinks found in the preceding path.  But, again, you probably
won't want that in most circumstances.

All of the B<*R> recursive functions have the potential to be very expensive
in terms of memory usage.  In an attempt to be fast (and reduce excessive 
function calls and stack depth) it utilizes L<Paranoid::Glob>'s B<recurse> 
method.  In essence, this means that the entire directory tree is loaded into 
memory at once before any operations are performed.

For the most part functions meant to simulate userland programs try to act
just as those programs would in a shell environment.  That includes filtering
arguments through shell globbing expansion, etc.  Should you have a filename
that should be treated as a literal string you should put it into a
L<Paranoid::Glob> object as a literal first, and then hand the glob to the
functions.

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

