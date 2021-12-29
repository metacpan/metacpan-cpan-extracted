#
#
#   # Will need to zero out all data between old eos and new eosParanoid::IO::FileMultiplexer::Block -- PIOFM Base Block Class
#
# $Id: lib/Paranoid/IO/FileMultiplexer/Block.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
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

package Paranoid::IO::FileMultiplexer::Block;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid;
use Paranoid::IO qw(:all);
use Paranoid::Debug qw(:all);
use Fcntl qw(:DEFAULT :flock :mode :seek);

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant MINBSIZE  => 4_096;
use constant MAXBSIZE  => 1_048_576;
use constant TEST32INT => 1 << 32;
use constant MAX32VAL  => 0b11111111_11111111_11111111_11111111;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

    # Purpose:  Creates a block object
    # Returns:  Object reference or undef
    # Usage:    $obj = Paranoid::IO::FileMultiplexer::Block->new(
    #                   $filename, $bnum, $bsize);

    my $class = shift;
    my $file  = shift;
    my $bnum  = shift;
    my $bsize = shift;
    my $self  = {
        file      => $file,
        blockNum  => 0,
        blockSize => MINBSIZE,
        minPos    => 0,
        maxPos    => MINBSIZE - 1,
        };

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL3, $file, $bnum, $bsize );
    pIn();

    bless $self, $class;

    # Check mandatory values
    $self = undef
        unless defined $bnum
            and defined $bsize
            and defined $file
            and length $file;
    pdebug( 'invalid or missing arguments', PDLEVEL1 )
        unless defined $self;

    if ( defined $self ) {

        # Make sure we only have positive values for the block number and size
        $$self{blockNum}  = int $bnum;
        $$self{blockSize} = int $bsize if defined $bsize;
        $$self{minPos}    = $$self{blockNum} * $$self{blockSize};
        $$self{maxPos}    = $$self{minPos} + $$self{blockSize} - 1;

        # Make sure block size is in range and a multiple of MINBSIZE
        $self = undef
            unless $$self{blockSize} >= MINBSIZE
                and $$self{blockSize} <= MAXBSIZE
                and $$self{blockSize} % MINBSIZE == 0;
        pdebug( 'invalid block size', PDLEVEL1 ) unless defined $self;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $self );

    return $self;
}

sub recalibrate {

    # Purpose:  Recalibrates min/max positions in the block based
    #           on block size.
    # Returns:  Boolean
    # Usage:    $rv = $obj->recalibrate;

    my $self = shift;

    $$self{minPos} = $$self{blockNum} * $$self{blockSize};
    $$self{maxPos} = $$self{minPos} + $$self{blockSize} - 1;

    return 1;
}

sub blockNum {

    # Purpose:  Returns the block number
    # Returns:  Integer
    # Usage:    $bn = $obj->blockNum;

    my $self = shift;
    return $$self{blockNum};
}

sub blockSize {

    # Purpose:  Returns the block size
    # Returns:  Integer
    # Usage:    $bs = $obj->blockSize;

    my $self = shift;
    return $$self{blockSize};
}

sub minPos {

    # Purpose:  Returns the min writable file position for the block
    # Returns:  Integer
    # Usage:    $minp = $obj->minPos;

    my $self = shift;
    return $$self{minPos};
}

sub maxPos {

    # Purpose:  Returns the max writable file position for the block
    # Returns:  Integer
    # Usage:    $maxp = $obj->maxPos;

    my $self = shift;
    return $$self{maxPos};
}

sub allocate {

    # Purpose:  Writes a new block to disk
    # Returns:  Boolean
    # Usage:    $rv = $obj->allocate;

    my $self   = shift;
    my $file   = $$self{file};
    my $minPos = $$self{minPos};
    my $maxPos = $$self{maxPos};
    my $rv     = 0;

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    if ( pflock( $$self{file}, LOCK_EX ) ) {

        # Seek and write a null byte at the end of the block
        pdebug( 'end of file should be at %s', PDLEVEL4, $minPos );
        pseek( $file, 0, SEEK_END );
        if ( ptell($file) == $minPos ) {
            pseek( $file, $maxPos, SEEK_SET );
            $rv = pwrite( $file, pack 'x' );
        } else {
            pdebug('block already allocated');
        }

        pflock( $$self{file}, LOCK_UN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub bread {

    # Purpose:  Reads the contents of the entire block. or a specified range
    # Returns:  Integer (bytes read) or undef on error
    # Usage:    $bytesRead = $obj->bread(\$content);
    # Usage:    $bytesRead = $obj->bread(\$content, $start);
    # Usage:    $bytesRead = $obj->bread(\$content, undef, $bytes);
    # Usage:    $bytesRead = $obj->bread(\$content, $start, $bytes);

    my $self  = shift;
    my $cref  = shift;
    my $start = shift;
    my $bytes = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my $minp  = $$self{minPos};
    my $maxp  = $$self{maxPos};
    my $rv    = '0 but true';

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL3, $cref, $start, $bytes );
    pIn();

    # NOTE:  This method intentionally allows reads of a length greater than
    # the block size, but it will only return content from within the block
    # boundaries.

    # Error out if we were not given a valid scalar ref
    unless ( defined $cref and ref($cref) eq 'SCALAR' ) {
        $rv = undef;
        pdebug( 'invalid argument for content ref', PDLEVEL1 );
    }

    # Set start to beginning of block if not specified
    $start = 0 unless defined $start;

    # Set default bytes if not specified
    $bytes = $bsize - $start unless defined $bytes;

    # Make sure start is in range
    if ( $minp + $start > $maxp ) {
        pdebug( 'starting position is out of range', PDLEVEL1 );
        $rv = undef;
    }

    if ($rv) {

        # Make sure we limit read to our block
        $bytes = ( $maxp + 1 ) - ( $minp + $start )
            if ( $minp + $start + $bytes ) > ( $maxp + 1 );

        # Perform the read
        if ( pseek( $file, $minp + $start, SEEK_SET ) ) {
            $rv = pread( $file, $$cref, $bytes );
        } else {
            $rv = undef;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub bwrite {

# Purpose:  Writes the contents of the entire block. or a specified range
# Returns:  Integer (bytes written) or undef on error
# Usage:    $bytesWritten = $obj->bwrite($content);
# Usage:    $bytesWritten = $obj->bwrite($content, $start );
# Usage:    $bytesWritten = $obj->bwrite($content, $start, $length );
# Usage:    $bytesWritten = $obj->bwrite($content, $start, $length, $offset );

    my $self    = shift;
    my $content = shift;
    my $start   = shift;
    my $length  = shift;
    my $offset  = shift;
    my $file    = $$self{file};
    my $bsize   = $$self{blockSize};
    my $minp    = $$self{minPos};
    my $maxp    = $$self{maxPos};
    my $rv      = '0 but true';
    my $cdata   = defined $content ? ( length $content ) . ' bytes' : undef;
    my $blkLeft;

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL3, $cdata, $start, $length, $offset );
    pIn();

    # NOTE:  This method intentionally allows writes of a length greater than
    # the block size, but it will only write content from within the block
    # boundaries.

    # Error out if we were not given a valid scalar ref
    unless ( defined $content and length $content ) {
        $rv = undef;
        pdebug( 'invalid argument for content', PDLEVEL1 );
    }

    # Set start to beginning of block if not specified
    $start = 0 unless defined $start;

    # Set offset to zero if not specified
    $offset = 0 unless defined $offset;

    # Set length to max content length available if not defined
    $length  = length($content) - $offset unless defined $length;
    $blkLeft = $bsize - $start;
    $length  = $blkLeft if $blkLeft < $length;

    # Make sure start is in range
    if ( $minp + $start > $maxp ) {
        pdebug( 'starting position is out of range', PDLEVEL1 );
        $rv = undef;
    }

    if ($rv) {

        # Perform the write
        if ( pseek( $file, $minp + $start, SEEK_SET ) ) {
            $rv = pwrite( $file, $content, $length, $offset );
        } else {
            $rv = undef;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub has64bInt {

    # Purpose:  Returns whether the current platform supports 64b integers
    # Returns:  Boolean
    # Usage:    $rv = $obj->has64bInt;

    return TEST32INT == 1 ? 0 : 1;
}

sub splitInt {

    # Purpose:  Splits the passed integer into two 32b integers
    # Returns:  Two integers (lower, upper)
    # Usage:    @split = $obj->splitInt($num);

    my $self = shift;
    my $num  = shift;
    my ( $upper, $lower );

    # Extract lower 32 bits
    $lower = $num & MAX32VAL;

    # Extract upper 32 bits
    $upper = $self->has64bInt ? ( $num & ~MAX32VAL ) >> 32 : 0;

    return ( $lower, $upper );
}

sub joinInt {

    # Purpose:  Joins to 32b integers into a single 64b integer
    # Returns:  Integer/undef
    # Usage:    $i = $obj->joinInt($lower, $upper);

    my $self  = shift;
    my $lower = shift;
    my $upper = shift;
    my $rv;

    if ( $self->has64bInt ) {
        $rv = $lower | ( $upper << 32 );
    } else {
        $rv = $lower if $upper == 0;
    }

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::IO::FileMultiplexer::Block - Block-level Allocator/Accessor

=head1 VERSION

$Id: lib/Paranoid/IO/FileMultiplexer/Block.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::IO::FileMultiplexer::Block->new(
            $filename, $bnum, $bsize);
    $rv  = $obj->allocate;

    $bn   = $obj->blockNum;
    $bs   = $obj->blockSize;
    $minp = $obj->minPos;
    $maxp = $obj->maxPos;

    $bytesWritten = $obj->bwrite($content);
    $bytesWritten = $obj->bwrite($content, $start );
    $bytesWritten = $obj->bwrite($content, $start, $length );
    $bytesWritten = $obj->bwrite($content, $start, $length, $offset );
    $bytesRead    = $obj->bread(\$content);
    $bytesRead    = $obj->bread(\$content, $start, $bytes);
    $bytesRead    = $obj->bread(\$content, undef, $bytes);
    $bytesRead    = $obj->bread(\$content, $start, $bytes);

    $support64 = $obj->test64;

    $rv = $obj->recalibrate;

=head1 DESCRIPTION

This class is not meant to be used directly, but as part of the
L<Paranoid::IO::FileMultiplexer> functionality.  It is primarily a base class
from which other critical classes are derived.

This module does presume that whatever file it is being used on has already
been opened in the appropriate mode, and that the L<Paranoid::IO> flock stack
has been enabled.  For the purposes of L<Paranoid::IO::FileMultiplexer>, this
is done in that class.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj = Paranoid::IO::FileMultiplexer::Block->new(
            $filename, $bnum, $bsize);

This creates a new instance of a block object.  It requires the filename in
order to retrieve the cached file handle from L<Paranoid::IO>, the number of
the block (using zero-based indexing), and the size of the block.  It will
block size and the block number to calculate its actual position within the
file.

=head2 blockNum

    $bn = $obj->blockNum;

This method returns the object's assigned block number.

=head2 blockSize

    $bs = $obj->blockSize;

This method returns the object's assigned block size.

=head2 minPos

    $minp = $obj->minPos;

This method returns the minimum file position for the block.

=head2 maxPos

    $maxp = $obj->maxPos;

This method returns the maximum file position for the block.

=head2 allocate

    $rv = $obj->allocate;

This method attempts to allocate the block on the file system, and returns a
boolean indicating its success.  This method will fail if you attempt to
allocate a block that's already been allocated, or a block whose file position
is beyond the current end of the file.  In other words, blocks must be
allocated in sequence.

=head2 recalibrate

    $rv = $obj->recalibrate;

This method recalculates minimum/maximum file position based on the currently
set block size.  This should always be called after any change to blockSize.

=head2 bwrite

    $bytesWritten = $obj->bwrite($content);
    $bytesWritten = $obj->bwrite($content, $start );
    $bytesWritten = $obj->bwrite($content, $start, $length );
    $bytesWritten = $obj->bwrite($content, $start, $length, $offset );

This method writes the passed content to the block, while making sure that the
content does not overflow the block boundaries.  If the I<start> position of
the write is omitted, it writes from the beginning of the block.  If the
I<start> position is provided, note that this is the position relative to the
block, not the file.  That means you would specify values from a range of
B<o> to B<(blockSize - 1)>.

This method is intentionally designed to allow you to pass more content than
will fit inside of a block, and yet only write as much as will fit within the
block.  The calling code should use the return value to figure out what
remains to be written in other blocks, as needed.

=head2 bread

    $bytesRead = $obj->bread(\$content);
    $bytesRead = $obj->bread(\$content, $start);
    $bytesRead = $obj->bread(\$content, undef, $bytes);
    $bytesRead = $obj->bread(\$content, $start, $bytes);

This method reads the content of the block, while making sure that the content
read does not go beyond the borders of the block.  If the I<start> position of
the read is omitted, it reads from the beginning of the block.  Like
B<bwrite>, this position is relative to the beginning of the block, not the
file.

This method is also intentionally designed to allow you to request more data
than can fit within the block, yet returning only what the block contains.
The calling code should use the return value to figure out what remains to be
read from other blocks, as needed.

=head2 has64bInt

    $rv = $obj->has64bInt;

this method returns a boolean value denoting whether the running platform 
supports 64b integers.

=head2 splitInt

    ($lower, $upper) = $obj->splitInt($num);

This method splits an integer into two 32b values, the first being the lower 
32b, and the second being the upper 32b.  The second value will always be zero 
if the running platform does not support 64b integers.

=head2 joinInt

    $i = $obj->joinInt($lower, $upper);

This method takes two 32b integers and joins them into a single 64b integer.
If the running platform only supports 32b integers and the upper value is
non-zero, this method will return undef.

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

