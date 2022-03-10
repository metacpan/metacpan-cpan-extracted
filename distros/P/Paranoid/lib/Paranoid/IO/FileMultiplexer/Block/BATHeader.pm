# Paranoid::IO::FileMultiplexer::Block::BATHeader -- BAT Header Block
#
# $Id: lib/Paranoid/IO/FileMultiplexer/Block/BATHeader.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
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

package Paranoid::IO::FileMultiplexer::Block::BATHeader;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid;
use Paranoid::IO qw(:all);
use Paranoid::Debug qw(:all);
use Paranoid::Data;
use Fcntl qw(:DEFAULT :flock :mode :seek);

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

use base qw(Paranoid::IO::FileMultiplexer::Block);

# Signature format:
#   PIOFMBAT Name Sequence
#   Z9       Z21  NNxx
#     40 bytes
#
# Data record format:
#   BlockNum
#   NN
#     8 bytes
use constant SIGNATURE => 'Z9Z21NNxx';
use constant SIG_LEN   => 40;
use constant SIG_TYPE  => 'PIOFMBAT';
use constant SEQ_POS   => 30;
use constant DATA_POS  => 40;
use constant DATAIDX   => 'NN';
use constant DATA_LEN  => 8;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

    # Purpose:  Creates a new BAT header object
    # Returns:  Object reference/undef
    # Usage:    $obj =
    #             Paranoid::IO::FileMultiplexer::Block::BATHeader->new($file,
    #             $blockNo, $blockSize, $strmName, $sequenceNo);

    my $class = shift;
    my $file  = shift;
    my $bnum  = shift;
    my $bsize = shift;
    my $sname = shift;
    my $seq   = shift;
    my $self;

    subPreamble( PDLEVEL3, '$$$$$', $file, $bnum, $bsize, $sname, $seq );

    $self = __PACKAGE__->SUPER::new( $file, $bnum, $bsize );
    if ( defined $self ) {
        $$self{streamName} = $sname;
        $$self{data}       = [];       # array of data blockNums
        $$self{sequence}   = 0;        # sequence no of BAT
        $$self{maxData} = int( ( $$self{blockSize} - SIG_LEN ) / DATA_LEN );
    }

    subPostamble( PDLEVEL3, '$', $self );

    return $self;
}

sub maxData {

    # Purpose:  Returns the max data blocks for the BAT
    # Returns:  Integer
    # Usage:    $max = $obj->maxData;

    my $self = shift;

    return $$self{maxData};
}

sub sequence {

    # Purpose:  Returns the current BAT sequence number
    # Returns:  Integer
    # Usage:    $seq = $obj->sequence;

    my $self = shift;

    return $$self{sequence};
}

sub dataBlocks {

    # Purpose:  Returns an array of data block nums
    # Returns:  Array
    # Usage:    @data = $obj->dataBlocks;

    my $self = shift;

    return @{ $$self{data} };
}

sub full {

    # Purpose:  Returns whether the BAT's array of data blocks is full
    # Returns:  Boolean
    # Usage:    $rv = $obj->full;

    my $self = shift;

    return $self->maxData == scalar $self->dataBlocks;
}

sub writeSig {

    # Purpose:  Writes the BAT signature to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeSig;

    my $self  = shift;
    my $file  = $$self{file};
    my $sname = $$self{streamName};
    my $seq   = $$self{sequence};
    my $rv    = 0;
    my $sig   = pack SIGNATURE, SIG_TYPE, $sname, quad2Longs($seq);

    subPreamble(PDLEVEL3);

    $rv = $self->bwrite($sig);

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub readSig {

    # Purpose:  Reads the block signature from the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->readSig;

    my $self = shift;
    my $file = $$self{file};
    my $rv   = 0;
    my ( $raw, $type, $sname, $seq, $lseq, $useq );

    subPreamble(PDLEVEL3);

    if ( pflock( $file, LOCK_SH ) ) {
        if ( $self->bread( \$raw, 0, SIG_LEN ) == SIG_LEN ) {
            $rv = 1;

            # Unpack the signature
            ( $type, $sname, $lseq, $useq ) = unpack SIGNATURE, $raw;

            # Validate contents
            #
            # Start with file type
            unless ( $type eq SIG_TYPE ) {
                $rv = 0;
                pdebug( 'Invalid BAT header type (%s)', PDLEVEL1, $type );
            }

            # stream name
            unless ( $sname eq $$self{streamName} ) {
                $rv = 0;
                pdebug( 'Invalid stream name (%s)', PDLEVEL1, $sname );
            }

            # Make sure seq is legitimate
            $seq = longs2Quad( $lseq, $useq );
            unless ( defined $seq ) {
                pdebug(
                    'this platform does not support 64b values for sequence',
                    PDLEVEL1
                    );
                $rv = 0;
            }
            unless ( $seq == $$self{sequence} ) {
                pdebug( 'Invalid sequence number for BAT (%s)',
                    PDLEVEL1, $seq );
                $rv = 0;
            }

            # Update internal values
            pdebug( 'BAT signature verification failure', PDLEVEL1 )
                unless $rv;

        } else {
            pdebug( 'failed to read BAT header signature', PDLEVEL1 );
        }

        pflock( $file, LOCK_UN );
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub writeData {

    # Purpose:  Writes all the data block numbers to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeData;

    my $self = shift;
    my $file = $$self{file};
    my $rv   = 0;
    my ( $rec, $i, $pos, $maxbats );

    subPreamble(PDLEVEL3);

    # Hold an exclusive lock for the entire transaction
    if ( pflock( $file, LOCK_EX ) ) {

        # Calculate the maximum possible number of BATs
        $maxbats = int( ( $$self{blockSize} - SIG_LEN ) / DATA_LEN );

        $rv = 1;
        $i  = 0;
        foreach $rec ( @{ $$self{data} } ) {
            $pos = DATA_POS + $i * DATA_LEN;
            $rv  = 0
                unless $self->bwrite( pack( DATAIDX, quad2Longs($rec) ),
                $pos ) == DATA_LEN;
            $i++;
            last unless $rv;
        }

        pflock( $file, LOCK_UN );
    }

    pdebug( 'failed to write all data block numbers to the BAT header',
        PDLEVEL1 )
        unless $rv;

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub readData {

    # Purpose:  Reads the data block numbers from the BAT header
    # Returns:  Boolean
    # Usage:    $rv = $obj->readData;

    my $self = shift;
    my $rv   = 1;
    my ( $raw, @sraw, $bn, $lbn, $ubn, $prev );
    my @data;

    subPreamble(PDLEVEL3);

    # Read the BATs section of the block
    if ( $self->bread( \$raw, DATA_POS ) ) {

        @sraw = unpack '(' . DATAIDX . ")$$self{maxData}", $raw;
        while (@sraw) {

            $lbn = shift @sraw;
            $ubn = shift @sraw;
            $bn  = longs2Quad( $lbn, $ubn );

            # Stop processing when it looks like we're not getting legitmate
            # values
            last unless defined $bn and $bn > $$self{blockNum};

            # Error out if block numbers aren't ascending
            unless ( !defined $prev or $bn > $prev ) {
                pdebug( 'data block number appearing out of sequence',
                    PDLEVEL1 );
                $rv = 0;
                last;
            }

            # Save entry
            push @data, $bn;
            $prev = $bn;
        }

        # Save everything extracted
        $$self{data} = [@data];
        pdebug( 'found %s data blocks', PDLEVEL4, scalar @data );

    } else {
        pdebug( 'failed to read list of data blocks from BAT header',
            PDLEVEL1 );
        $rv = 0;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub addData {

    # Purpose:  Adds a data block number to the BAT header
    # Returns:  Boolean
    # Usage:    $rv = $obj->addData($bn);

    my $self = shift;
    my $bn   = shift;
    my $rv   = 1;
    my $n;

    subPreamble( PDLEVEL3, '$', $bn );

    if ( defined $bn and $bn > $$self{blockNum} ) {

        # Make sure we're not adding redundant entries
        if ( scalar grep { $_ eq $bn } @{ $$self{data} } ) {
            $rv = 0;
            pdebug( 'redundant entry for an existing data block', PDLEVEL1 );
        }

        # Make sure new data block is a higher block number than all previous
        # data blocks
        if ( scalar grep { $_ > $bn } @{ $$self{data} } ) {
            $rv = 0;
            pdebug( 'data block number is lower than previous blocks',
                PDLEVEL1 );
        }

        if ($rv) {

            # Write the block to the header
            push @{ $$self{data} }, $bn;
            $rv = 0
                unless $self->bwrite(
                pack( DATAIDX, quad2Longs($bn) ),
                DATA_POS + DATA_LEN * $#{ $$self{data} } ) == DATA_LEN;
        }

    } else {
        pdebug( 'invalid data block number (%s)', PDLEVEL1, $bn );
        $rv = 0;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::IO::FileMultiplexer::Block::BATHeader - BAT Header Block

=head1 VERSION

$Id: lib/Paranoid/IO/FileMultiplexer/Block/BATHeader.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::IO::FileMultiplexer::Block::BATHeader->new($file,
        $blockNo, $blockSize, $strmName, $sequenceNo);

    $max  = $obj->maxData;
    $seq  = $obj->sequence;
    @data = $obj->dataBlocks;
    $rv   = $obj->full;

    $rv = $obj->writeSig;
    $rv = $obj->readSig;
    $rv = $obj->writeData;
    $rv = $obj->readData;
    $rv = $obj->addData($bn);

=head1 DESCRIPTION

This class is not meant to be used directly, but as part of the
L<Paranoid::IO::FileMultiplexer> functionality.  This provides functionality
necessary for manipulation of the stream header block.

This module does presume that whatever file it is being used on has already
been opened in the appropriate mode, and that the L<Paranoid::IO> flock stack
has been enabled.  For the purposes of L<Paranoid::IO::FileMultiplexer>, this
is done in that class.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj = Paranoid::IO::FileMultiplexer::Block::BATHeader->new($file,
        $blockNo, $blockSize, $strmName, $sequenceNo);

This creates a new instance of a BAT header block object.  It requires the 
filename in order to retrieve the cached file handle from L<Paranoid::IO>, 
the block number of the block, the size of the block, the name of the
stream, and the block sequence number.

B<NOTE:> creating an object does not automatically create the file and/or
write a signature.  That must be done using the methods below.

=head2 maxData

    $max = $obj->maxData;

This method returns the maximum number of data blocks that can be tracked in a
single BAT block.

=head2 sequence

    $seq = $obj->sequence;

This method returns the sequence number of the BAT.  In essence, this is the
ordinal index of the BAT in a stream's array of BATs.

=head2 dataBlocks

    @data = $obj->dataBlocks;

This method returns the list of data blocks being tracked by this BAT.

=head2 full

    $rv   = $obj->full;

This method returns a boolean value denoting whether this BAT's array of data
blocks is at maximum capacity or not.

=head2 writeSig

    $rv = $obj->writeSig;

This method writes the BAT header signature to disk, returning a boolean
value denoting its success.  Note that the signature contains the file format,
stream name, and the BAT sequence number.  This does not include the allocated
data block numbers.

=head2 readSig

    $rv = $obj->readSig;

This method reads the BAT header signature from disk and performs basic
validation that the information in it is acceptable.  It validates that the
stream name and sequence number matches what is expected and the block 
format is correct.

If the method call was successful it will update the cached values in the
object.  Note that this is only the signature values, not the data block
numbers.

=head2 writeData

    $rv = $obj->writeData;

This method writes the data block numbers to the header block, and returns a
boolean denoting success.

=head2 readData

    $rv = $obj->readData;

This method reads the data block numbers from the file, and returns a
boolean value denoting success.  If the read is successful, this will update
the cached data blocks in the object.

=head2 addData

    $rv = $obj->addData($bn);

This method does some basic validation of the requested BAT, and if it
passes, updates the data block number list on the disk.

=head1 DEPENDENCIES

=over

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::Data>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IOFileMultiplexer::Block>

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

