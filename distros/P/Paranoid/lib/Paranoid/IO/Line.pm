# Paranoid::IO::Line -- Paranoid Line-based I/O functions
#
# $Id: lib/Paranoid/IO/Line.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
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
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::IO::Line;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Fcntl qw(:DEFAULT :seek :flock :mode);
use Paranoid qw(:all);
use Paranoid::Debug qw(:all);
use Paranoid::IO qw(:all);
use Paranoid::Input qw(:all);

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

@EXPORT      = qw(sip nlsip tailf nltailf slurp nlslurp piolClose);
@EXPORT_OK   = ( @EXPORT, qw(PIOMAXLNSIZE) );
%EXPORT_TAGS = ( all => [@EXPORT_OK], );

use constant STAT_INO => 1;
use constant STAT_SIZ => 7;
use constant PDEFLNSZ => 2048;

use constant PBFLAG => 0;
use constant PBBUFF => 1;

use constant PBF_DRAIN  => 0;
use constant PBF_NORMAL => 1;
use constant PBF_DELETE => -1;

#####################################################################
#
# Module code follows
#
#####################################################################

{
    my $mlnsz = PDEFLNSZ;

    sub PIOMAXLNSIZE : lvalue {

        # Purpose:  Gets/sets default line size of I/O
        # Returns:  $mlnsz
        # Usage:    $limit = PIOMAXLNSIZE;
        # Usage:    FSZLIMIT = 100;

        $mlnsz;
    }

    # Manage buffers: $buffers{$name} => [$flag, $content ];
    my %buffers;

    sub _chkBuffer { return exists $buffers{ $_[0] } }

    sub _chkStat {

        # Purpose:  Checks stat data to see if the underlying
        #           file has changed
        # Returns:  Boolean
        # Usage:    $rv = _chkStat($file);

        my $file = shift;
        my $rv   = 0;
        my ( $fh, $fpos, @fstat, @fhstat );

        subPreamble( PDLEVEL3, '$', $file );

        # Check to see if we can get a valid file handle
        if ( defined( $fh = popen( $file, O_RDONLY ) ) ) {
            @fhstat = stat $fh;
            $fpos   = ptell($fh);

            if ( @fhstat and $fpos < $fhstat[STAT_SIZ] ) {

                # Still have content to read, continue on
                pdebug( 'still have content to drain', PDLEVEL3 );
                $rv = 1;

            } else {

                # Check the file system to see if we're still
                # operating on the same file
                @fstat = stat $file;

                if ( scalar @fstat ) {

                    # Check inode
                    if ( $fhstat[STAT_INO] != $fstat[STAT_INO] ) {
                        pdebug( 'file was replaced with a new file',
                            PDLEVEL3 );
                    } else {
                        if ( $fstat[STAT_SIZ] < $fpos ) {
                            pdebug( 'file was truncated', PDLEVEL3 );
                        } else {
                            pdebug( 'file is unchanged', PDLEVEL3 );
                            $rv = 1;
                        }
                    }

                } else {
                    pdebug( 'file was deleted', PDLEVEL3 );
                }
            }
        } else {
            pdebug( 'invalid/non-existent file', PDLEVEL3 );
        }

        subPostamble( PDLEVEL3, '$', $rv );

        return $rv;
    }

    sub piolClose {

        # Purpose:  Closes file handles and deletes the associated
        #           buffer
        # Returns:  Boolean
        # Usage:    $rv = piolClose($file);

        my $file = shift;

        delete $buffers{$file};

        return pclose($file);
    }

    sub sip ($\@;$$) {

        # Purpose:  Reads a chunk from the passwed handle or file name
        # Returns:  Number of lines read or undef critical failures
        # Usage:    $nlines = sip($fh, @lines);
        # Usage:    $nlines = sip($filename, @lines);
        # Usage:    $nlines = sip($filename, @lines, 1);

        my $file    = shift;
        my $aref    = shift;
        my $doChomp = shift;
        my $noLocks = shift;
        my $rv      = 1;
        my ( $buffer, $bflag, $in, $content, $bread, $irv, @tmp, $line );

        subPreamble( PDLEVEL1, '$\@;$$', $file, $aref, $doChomp, $noLocks );

        @$aref = ();

        # Check the file
        piolClose($file) unless _chkStat($file);

        # Get/initialize buffer
        if ( exists $buffers{$file} ) {
            $bflag  = $buffers{$file}[PBFLAG];
            $buffer = $buffers{$file}[PBBUFF];
        } else {
            $buffers{$file} = [ PBF_NORMAL, '' ];
            $buffer         = '';
            $bflag          = PBF_NORMAL;
        }

        # Read what we can
        $content = '';
        $bread   = 0;
        while ( $bread < PIOMAXFSIZE ) {
            $irv = $noLocks ? pnlread( $file, $in ) : pread( $file, $in );
            if ( defined $irv ) {
                $bread += $irv;
                $content .= $in;
                last if $irv < PIOBLKSIZE;
            } else {
                $rv = undef;
                last;
            }
        }

        # Post processing
        if ($rv) {

            if ( length $content ) {

                # Add the buffer
                $content = "$buffer$content";

                # Process buffer drain conditions
                pdebug( 'starting buffer flag: (%s)', PDLEVEL4, $bflag );
                pdebug( 'starting buffer: (%s)',      PDLEVEL4, $buffer );
                if ( !$bflag and $content =~ /@{[NEWLINE_REGEX]}/so ) {
                    pdebug( 'draining to next newline', PDLEVEL4 );
                    $content =~ s/^.*?@{[NEWLINE_REGEX]}//so;
                    $bflag  = PBF_NORMAL;
                    $buffer = '';
                }

                # Check for newlines
                if ( $content =~ /@{[NEWLINE_REGEX]}/so ) {

                    # Split lines along newline boundaries
                    @tmp = split m/(@{[NEWLINE_REGEX]})/so, $content;
                    while ( scalar @tmp > 1 ) {
                        if ( length $tmp[0] > PIOMAXLNSIZE ) {
                            splice @tmp, 0, 2;
                            $line = undef;
                        } else {
                            $line = join '', splice @tmp, 0, 2;
                        }
                        push @$aref, $line;
                    }

                    # Check for undefined lines
                    $rv = scalar @$aref;
                    @$aref = grep {defined} @$aref;
                    if ( $rv != scalar @$aref ) {
                        Paranoid::ERROR =
                            pdebug( 'found %s lines over PIOMAXLNSIZE',
                            PDLEVEL1, $rv - @$aref );
                        $rv = undef;
                    }

                    # Check for an unterminated line at the end and
                    # buffer appropriately
                    if ( scalar @tmp ) {

                        # Content left over, update the buffer
                        if ( length $tmp[0] > PIOMAXLNSIZE ) {
                            $buffer = '';
                            $bflag  = PBF_DRAIN;
                            $rv     = undef;
                            Paranoid::ERROR =
                                pdebug( 'buffer is over PIOMAXLNSIZE',
                                PDLEVEL1 );
                        } else {
                            $buffer = $tmp[0];
                            $bflag  = PBF_NORMAL;
                        }
                    } else {

                        # Nothing left over, make sure the buffer is empty
                        $buffer = '';
                        $bflag  = PBF_NORMAL;
                    }

                } else {

                    # Check buffered block for PIOILNSIZE limit
                    if ( length $content > PIOMAXLNSIZE ) {
                        $buffer = '';
                        $bflag  = PBF_DRAIN;
                        $rv     = undef;
                        Paranoid::ERROR =
                            pdebug( 'block is over PIOMAXLNSIZE', PDLEVEL1 );
                    } else {
                        $rv     = 0;
                        $buffer = $content;
                        $bflag  = PBF_NORMAL;
                    }
                }
                pdebug( 'ending buffer flag: (%s)', PDLEVEL4, $bflag );
                pdebug( 'ending buffer: (%s)',      PDLEVEL4, $buffer );

            } else {
                $rv = 0;
            }
        }

        # Set PTRUE_ZERO if needed
        $rv = PTRUE_ZERO if defined $rv and $rv == 0;

        # Save the buffer
        $buffers{$file}[PBFLAG] = $bflag;
        $buffers{$file}[PBBUFF] = $buffer;

        # Chomp if necessary
        pchomp(@$aref) if $doChomp and scalar @$aref;

        pdebug( 'returning %s lines', PDLEVEL2, scalar @$aref );

        subPostamble( PDLEVEL1, '$', $rv );

        return $rv;
    }

}

sub nlsip {

    # Purpose:  Wrapper for sip that enables non-locking reads
    # Returns:  Return value from sip
    # Usage:    $nlines = nlsip($file, @lines);

    my $file    = shift;
    my $aref    = shift;
    my $doChomp = shift;

    return sip( $file, @$aref, $doChomp, 1 );
}

sub tailf ($\@;$$$) {

    # Purpose:  Augments sip's tailing abilities by seeking to
    #           the end (or, optionally, backwards)
    # Returns:  Number of lines tailed
    # Usage:    $nlines = tail($filename, @lines);
    # Usage:    $nlines = tail($filename, @lines, $chomp);
    # Usage:    $nlines = tail($filename, @lines, $lnOffset);

    my $file    = shift;
    my $aref    = shift;
    my $doChomp = shift || 0;
    my $offset  = shift || -10;
    my $noLocks = shift;
    my ( $rv, $ofsb, @lines );

    subPreamble( PDLEVEL1, '$\@;$$$', $file, $aref, $doChomp, $offset,
        $noLocks );

    @$aref = ();

    # Check to see if we've already opened this file
    if ( _chkBuffer($file) ) {

        # Offset is only used on the initial open
        $offset = 0;

    } else {

        # TODO: At some point we might want to honor positive offsets to mimic
        # the behavior of UNIX tail

        # Calculate how far back we need to go from the end
        $ofsb = $offset * ( PIOMAXLNSIZE +1 );
        Paranoid::ERROR =
            pdebug( 'WARNING:  called with a positive line offset', PDLEVEL1 )
            unless $ofsb < 0;

        # Open the file and move the cursor
        pseek( $file, $ofsb, SEEK_END ) if popen( $file, O_RDONLY );

    }

    # If $offset is set we have trailing lines to handle
    if ($offset) {

        # Consume everything to the end of the file
        do {
            $noLocks
                ? nlsip( $file, @lines, $doChomp )
                : sip( $file, @lines, $doChomp );
            push @$aref, @lines;
        } while scalar @lines;

        # Trim list to the request size
        if ( scalar @$aref > abs $offset ) {
            splice @$aref, 0, @$aref - abs $offset;
        }
        $rv = scalar @$aref;
        $rv = PTRUE_ZERO unless $rv;

    } else {

        # Do a single sip
        $rv =
            $noLocks
            ? nlsip( $file, @$aref, $doChomp )
            : sip( $file, @$aref, $doChomp );
    }

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

sub nltailf ($\@;$$$) {

    # Purpose:  Wrapper for sip that enables non-locking reads
    # Returns:  Return value from sip
    # Usage:    $nlines = nlsip($file, @lines);

    my $file    = shift;
    my $aref    = shift;
    my $doChomp = shift;
    my $offset  = shift;

    return tailf( $file, @$aref, $doChomp, $offset, 1 );
}

sub slurp ($\@;$$) {

    # Purpose:  Reads a file into memory
    # Returns:  Number of lines read/undef
    # Usage:    $nlines = slurp($filename, @lines;
    # Usage:    $nlines = slurp($filename, @lines, 1);

    my $file    = shift;
    my $aref    = shift;
    my $doChomp = shift || 0;
    my $noLocks = shift;
    my $rv      = 1;
    my @fstat;

    subPreamble( PDLEVEL1, '$\@;$$', $file, $aref, $doChomp, $noLocks );

    # Start sipping
    $rv = sip( $file, @$aref, $doChomp, $noLocks );
    if ( ref $file eq 'GLOB' ) {
        @fstat = stat $file if fileno $file;
    } else {
        @fstat = stat $file;
    }
    if ( scalar @fstat and $fstat[STAT_SIZ] > PIOMAXFSIZE ) {
        Paranoid::ERROR = pdebug( 'file size exceeds PIOMAXFSIZE', PDLEVEL1 );
        $rv = undef;
    }

    # Count lins if sip never complained
    $rv = scalar @$aref if defined $rv;

    # Close everything out
    piolClose($file);

    subPostamble( PDLEVEL1, '$', $rv );

    return $rv;
}

sub nlslurp ($\@;$$) {

    # Purpose:  Performs a non-locking slurp
    # Returns:  Number of lines/undef
    # Usage:    $nlines = nlslurp($filename, @lines);
    # Usage:    $nlines = nlslurp($filename, @lines, 1);

    my $file    = shift;
    my $aref    = shift;
    my $doChomp = shift || 0;

    return slurp( $file, @$aref, $doChomp, 1 );
}

1;

__END__

=head1 NAME

Paranoid::IO::Line - Paranoid Line-based I/O functions

=head1 VERSION

$Id: lib/Paranoid/IO/Line.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

  use Paranoid::IO::Line;

  PIOMAXLNSIZE = 4096;

  $nlines = sip($filename, @lines);
  $nlines = sip($filename, @lines, 1);
  $nlines = tailf($filename, @lines);
  $nlines = tailf($filename, @lines, 1);
  $nlines = tailf($filename, @lines, 1, -100);

  piolClose($filename);

  $nlines = slurp($filename, @lines);

  # Non-locking variants
  $nlines = nlsip($filename, @lines);
  $nlines = nltailf($filename, @lines);
  $nlines = nlslurp($filename, @lines);

=head1 DESCRIPTION

This module extends and leverages L<Paranoid::IO>'s capabilities with an eye
towards line-based text files, such as log files.  It does so while
maintaining a paranoid stance towards I/O.  For that reason the functions here
only work on limited chunks of data at a time, both in terms of maximum memory
kept in memory at a time and the maximum record length.  L<Paranoid::IO>
provides I<PIOMAXFSIZE> which controls the former, but this module provides
I<PIOMAXLNSIZE> which controls the latter.

Even with the paranoid slant of these functions they should really be treated
as convenience functions which can simplify higher level code without
incurring any significant risk to the developer or system.  They inherit not
only opportunistic I/O but platform-agnostic record separators via internal
use of I<pchomp> from L<Paranoid::Input>.

B<NOTE:> while this does build off the foundation provided by L<Paranoid::IO>
it is important to note that you should not work on the same files using
:<Paranoid::IO>'s functions while also using the functions in this module.
While the former works from raw I/O the latter has to manage buffers in order
to identify record boundaries.  If you were to, say, I<sip> from a file, then
I<pread> or I<pseek> elsewhere it would render those buffers not only useless,
but corrupt.  This is important to note since the functions here do leverage
the file handle caching features provided by I<popen>.

It should also be noted that since we're anticipating line-based records we
expect every line, even the last line in a file, to be properly terminated
with a record separator (new line sequence).

As with all L<Paranoid> modules string descriptions of errors can be retrieved
from L<Paranoid::ERROR> as they occur.

=head1 IMPORT LISTS

This module exports the following symbols by default:

    sip nlsip tailf nltailf slurp nlslurp piolClose

The following specialized import lists also exist:

    List        Members
    --------------------------------------------------------
    all         @defaults PIOMAXLNSIZE

=head1 SUBROUTINES/METHODS

=head2 PIOMAXLNSIZE

The valute returned/set by this lvalue function is the maximum line length
supported by functions like B<sip> (documented below).  Unless explicitly set
this defaults to 2KB.  Any lines found which exceed this are discarded.

=head2 sip

    $nlines = sip($filename, @lines);
    $nlines = sip($filename, @lines, 1);

This function allows you to read a text file into memory in chunks, the 
lines of which are placed into the passed array reference.  The chunks are 
read in at up to L<PIOMAXFSIZE> in size at a time.  File locking is used 
and autochomping is also supported.

This returns the number of lines extracted or boolean false if any errors
occurred, such as lines exceeding I<PIOMAXLNSIZE> or other I/O errors.  If
there were no errors but also no content it will return B<0 but true>, which
will satisfy boolean tests.

The passed array is always purged prior to execution.  This can potentially
help differentiate types of errors:

    $nlines = sip($filename, @lines);

    warn "successfully extracted lines" 
        if $nlines and scalar @lines;
    warn "no errors, but no lines" 
        if $nlines and ! scalar @lines;
    warn "line length exceeded on some lines" 
        if !$nlines and scalar @lines;
    warn "I/O errors or all lines exceeded line length" 
        if !$nlines and ! scalar @lines;

Typically, if all one cares about is extracting good lines and discarding bad
ones all you need is:

    warn "good to go" if scalar @lines or $nlines;
 
    # or, more likely:
    if (@lines) {
        # process input...
    }

B<NOTE:> I<sip> does try to check the file stat with every call.  This allows
us to automatically flush buffers and reopen files in the event that the file
you're sipping from was truncated, deleted, or overwritten.

The third argument is a boolean option which controls whether lines are
automatically chomped or not.  It defaults to not.

=head2 nlsip

    $nlines = nlsip($filename, @lines);
    $nlines = nlsip($filename, @lines, 1);

A very thin wrapper for I<sip> that disables file locking.

=head2 tailf

    $nlines = tailf($filename, @lines);
    $nlines = tailf($filename, @lines, 1);
    $nlines = tailf($filename, @lines, 1, -100);

The only difference between this function and B<sip> is that tailf opens the
file and immediately seeks to the end.  If an optional fourth argument is
passed it will seek backwards to extract and return that number of lines (if
possible).  Depending on the number passed one must be prepared for enough
memory to be allocated to store B<PIOMAXLNSIZE> * that number. If no number is
specified it is assumed to be B<-10>.  Specifying this argument on a file
already opened by I<sip> or I<tailf> will have no effect.

Return values are identical to I<sip>.

=head2 nltailf

    $nlines = nltailf($filename, @lines);
    $nlines = nltailf($filename, @lines, -100);
    $nlines = nltailf($filename, @lines, -100, 1);

A very thin wrapper for I<tailf> that disables file locking.

=head2 slurp

  $nlines = slurp($filename, @lines);
  $nlines = slurp($filename, @lines, 1);

This function is essentially another wrapper for I<sip>, but with some
different behavior.  While I<sip> was written from the expectation that the
developer would be either working on chunks from a very large file or a file
that may grow while being accessed.  I<slurp>, on the other hand, expects to
work exclusively on small files that can safely fit into memory.  It also sees
no need to cache file handles since all operations will subsequently be done
in memory.

Files with slurp are explicitly closed after the read.  All the normal
safeguards apply:  I<PIOMAXFSIZE> is the largest amount of data that will be
read into memory, and all lines must be within I<PIOMAXLNSIZE>.

The third argument is a boolean option which controls whether lines are
automatically chomped or not.  It defaults to not.

=head2 nlslurp

  $nlines = nlslurp($filename, @lines);
  $nlines = nlslurp($filename, @lines, 1);

A very thin wrapper for I<slurp> that disables file locking.

=head2 piolClose

  $rv = piolClose($filename);

This closes all file handles and deletes any existing buffers.  Works
indiscriminatley and returns the exit value of I<pclose>.

=head1 DEPENDENCIES

=over

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Input>

=item o

L<Paranoid::IO>

=back

=head1 BUGS AND LIMITATIONS

While all of these functions will just as happily accept file handles as well
as file names doing will almost certainly cause any number of bugs.  Beyond
the inherited L<Paranoid::IO> issues (like not getting the fork-safe features
for any file handle opened directly by the developer) there are other issues.
Buffers, for instance, can only be managed by one consistent name, there is no
way to correlate them and make them interchangeable.  There are other
subtleties as well, but there is no need to detail them all.

Suffice it to say that when using this module one should only use file names,
and use them consistently.

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

