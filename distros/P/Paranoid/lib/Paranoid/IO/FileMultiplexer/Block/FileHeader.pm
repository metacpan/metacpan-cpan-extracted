# Paranoid::IO::FileMultiplexer::Block::FileHeader -- File Header Block
#
# $Id: lib/Paranoid/IO/FileMultiplexer/Block/FileHeader.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $
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

package Paranoid::IO::FileMultiplexer::Block::FileHeader;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid qw(:all);
use Paranoid::IO qw(:all);
use Paranoid::Debug qw(:all);
use Paranoid::Data;
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Paranoid::IO::FileMultiplexer::Block;
use Paranoid::IO::FileMultiplexer::Block::StreamHeader;
use Paranoid::IO::FileMultiplexer::Block::BATHeader;

($VERSION) = ( q$Revision: 2.10 $ =~ /(\d+(?:\.\d+)+)/sm );

use base qw(Paranoid::IO::FileMultiplexer::Block);

use constant PIOFMVER => '1.0';

# Signature format:
#   PIOFM VER BS  BC
#   Z6    Z4  NNx NNx
#     28 bytes
#
# Stream record format:
#   String BN
#   Z21    NNx
#     30 bytes
use constant SIGNATURE   => 'Z6Z4NNxNNx';
use constant SIG_LEN     => 28;
use constant SIG_TYPE    => 'PIOFM';
use constant BLOCKS_POS  => 10;
use constant BLOCKC_POS  => 19;
use constant STREAMS_POS => 28;
use constant STRMIDX     => 'Z21NNx';
use constant STRM_LEN    => 30;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

# Purpose:  Creates a new file header object
# Returns:  Object reference/undef
# Usage:    $obj =
#             Paranoid::IO::FileMultiplexer::Block::FileHeader->new($file, $blockSize);

    my $class = shift;
    my $file  = shift;
    my $bsize = shift;
    my $self;

    subPreamble( PDLEVEL3, '$$', $file, $bsize );

    $self = __PACKAGE__->SUPER::new( $file, 0, $bsize );

    if ( defined $self ) {
        $$self{version}   = PIOFMVER;
        $$self{blocks}    = 1;
        $$self{streamidx} = {};         # name => idx of rec in streams
        $$self{streams}   = [];         # array of [ name, blockNum ]
        $$self{maxStreams} = int( ( $bsize - SIG_LEN ) / STRM_LEN );
    }

    subPostamble( PDLEVEL3, '$', $self );

    return $self;
}

sub blocks {

    # Purpose:  Returns the number of blocks recorded in the signature
    # Returns:  Integer
    # Usage:    $count = $obj->blocks;

    my $self = shift;
    return $$self{blocks};
}

sub version {

    # Purpose:  Returns the version of the file format
    # Returns:  String
    # Usage:    $ver = $obj->version;

    my $self = shift;
    return $$self{version};
}

sub streams {

    # Purpose:  Returns a hash of stream names => blockNums
    # Returns:  Hash
    # Usage:    %streams = $obj->streams;

    my $self    = shift;
    my @streams = @{ $$self{streams} };
    my ( %rv, $stream );

    foreach $stream (@streams) {
        $rv{ $$stream[0] } = $$stream[1];
    }

    return %rv;
}

sub maxStreams {

    # Purpose:  Returns the maximum number of streams supported by this file
    # Returns:  Integer
    # Usage:    $max = $obj->maxStreams;

    my $self = shift;

    return $$self{maxStreams};
}

sub _transHuman {

    # Purpose:  Translates raw integers into human-readable values
    # Returns:  String
    # Usage:    $rv = _transHuman($n);

    my $n = shift;
    my $u = 'B';

    while ( $n > 1024 ) {
        $u =
              $u eq 'B'  ? 'KB'
            : $u eq 'KB' ? 'MB'
            : $u eq 'MB' ? 'GB'
            : $u eq 'GB' ? 'TB'
            : $u eq 'TB' ? 'PB'
            :              'EX';
        $n /= 1024;
        last if $u eq 'EX';
    }
    $n = sprintf( '%0.2f', $n );

    return "$n$u";
}

sub model {

    # Purpose:  Returns a hash of file statistics
    # Returns:  Hash
    # Usage:    $stats = $obj->model;

    my $self  = shift;
    my $bs    = $$self{blockSize};
    my $blks  = $$self{blocks};
    my $strms = scalar keys %{ $$self{streamidx} };
    my ( $block, $maxBATs, $maxData, %rv );

    # Get reference max values
    $block =
        Paranoid::IO::FileMultiplexer::Block::StreamHeader->new( $$self{file},
        1, $bs, 'foo' );
    $maxBATs = $block->maxBATs;
    $block =
        Paranoid::IO::FileMultiplexer::Block::BATHeader->new( $$self{file}, 1,
        $bs, 'foo', 0 );
    $maxData = $block->maxData;

    # Current stats
    $rv{intSize}     = ( 1 << 32 ) == 1 ? 32 : 64;
    $rv{curFileSize} = $bs * $blks;
    $rv{curFSHuman}  = _transHuman( $rv{curFileSize} );
    $rv{curStreams}  = $strms;

    # Predicted max
    $rv{maxFileSize} = 0b11111111_11111111_11111111_11111111;
    $rv{maxFileSize} = $rv{maxFileSize} | ( $rv{maxFileSize} << 32 )
        if $rv{intSize} == 64;
    $rv{maxStreams}    = $$self{maxStreams};
    $rv{maxStreamSize} = $bs * $maxBATs * $maxData;
    $rv{maxStreamSize} = $rv{maxFileSize}
        if $rv{maxStreamSize} > $rv{maxFileSize};
    $rv{maxSSHuman} = _transHuman( $rv{maxStreamSize} );

    # Provide human-readable values
    $rv{maxFSHuman} = _transHuman( $rv{maxFileSize} );

    return %rv;
}

sub writeSig {

    # Purpose:  Writes the file signature to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeSig;

    my $self = shift;
    my $file = $$self{file};
    my $ver  = $$self{version};
    my $rv   = 0;
    my $sig  = pack SIGNATURE, SIG_TYPE, PIOFMVER,
        quad2Longs( $$self{blockSize} ),
        quad2Longs( $$self{blocks} );

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    $rv = $self->bwrite($sig);

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub readSig {

    # Purpose:  Reads the block signature from the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->readSig;

    my $self = shift;
    my $file = $$self{file};
    my $rv   = 0;
    my ( $raw, $type, $ver, $bs, $bc, $tblock );
    my ( $lbs, $ubs, $lbc, $ubc );

    subPreamble(PDLEVEL3);

    if ( pflock( $file, LOCK_SH ) ) {
        if ( $self->bread( \$raw, 0, SIG_LEN ) == SIG_LEN ) {
            $rv = 1;

            # Unpack the signature
            ( $type, $ver, $lbs, $ubs, $lbc, $ubc ) = unpack SIGNATURE, $raw;

            # Validate contents
            #
            # Start with file type
            unless ( $type eq SIG_TYPE ) {
                $rv = 0;
                pdebug( 'Invalid file header type (%s)', PDLEVEL1, $type );
            }

            # format version
            unless ( $ver eq PIOFMVER ) {
                $rv = 0;
                pdebug( 'Invalid file header version (%s)', PDLEVEL1, $ver );
            }

            # Make sure block size is legitimate
            $bs = longs2Quad( $lbs, $ubs );
            if ( defined $bs ) {
                $tblock = __PACKAGE__->new( $file, $bs );
                unless ( defined $tblock ) {
                    $rv = 0;
                    pdebug( 'blockSize error in file header: %s',
                        PDLEVEL1, $bs );
                }
            } else {
                pdebug(
                    'this platform does not support 64b values for block size',
                    PDLEVEL1
                    );
                $rv = 0;
            }

            # Validate end of file matches block count
            $bc = longs2Quad( $lbc, $ubc );
            if ( defined $bc ) {
                pseek( $file, 0, SEEK_END );
                unless ( ptell($file) == $bc * $bs ) {
                    $rv = 0;
                    pdebug(
                        'incorrect file size based on block count (%s * %s = %s)',
                        PDLEVEL1, $bc, $bs, $bc * $bs
                        );
                }
            } else {
                pdebug(
                    'this platform does not support 64b values for block count',
                    PDLEVEL1
                    );
                $rv = 0;
            }

            # Update internal values
            if ($rv) {
                $$self{version}   = $ver;
                $$self{blockSize} = $bs;
                $$self{blocks}    = $bc;
                $self->recalibrate;
            } else {
                pdebug( 'file signature verification failure', PDLEVEL1 );
            }

        } else {
            pdebug( 'failed to read file header signature', PDLEVEL1 );
        }

        pflock( $file, LOCK_UN );
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub writeBlocks {

    # Purpose:  Updates the blocks counter and writes it to disk
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeBlocks($count);

    my $self   = shift;
    my $bcount = shift;
    my ( $raw, $rv );

    subPreamble( PDLEVEL3, '$', $bcount );

    if ( defined $bcount and $bcount > 0 ) {
        $raw = pack 'NN', quad2Longs($bcount);
        if ( $self->bwrite( $raw, BLOCKC_POS ) == 8 ) {
            $$self{blocks} = $bcount;
            $rv = 1;
        }
    } else {
        pdebug( 'invalid value for blocks (%s)', PDLEVEL1, $bcount );
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub readBlocks {

    # Purpose:  Reads the blocks counter from disk
    # Returns:  Integer/undef on error
    # Usage:    $count = $obj->readBlocks;

    my $self = shift;
    my ( $rv, $raw );

    subPreamble(PDLEVEL3);

    if ( $self->bread( \$raw, BLOCKC_POS, 8 ) == 8 ) {
        $rv = longs2Quad( unpack 'NN', $raw );
        $rv = PTRUE_ZERO if defined $rv and $rv == 0;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub incrBlocks {

    # Purpose:  Increments the block count and writes the field to disk
    # Returns:  Boolean
    # Usage:    $rv = $obj->incrBlocks;

    my $self = shift;

    return $self->writeBlocks( $$self{blocks} + 1 );
}

sub validateBlocks {

    # Purpose:  Compares in-memory block counter to what's stored in the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->validateBlocks;

    my $self = shift;
    my $rv   = 0;

    subPreamble(PDLEVEL3);

    $rv = 1 if $$self{blocks} == $self->readBlocks;

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub writeStreams {

    # Purpose:  Writes all the stream index records to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeStreams;

    my $self = shift;
    my $file = $$self{file};
    my $rv   = 0;
    my ( $rec, $i, $pos );

    subPreamble(PDLEVEL3);

    # Hold an exclusive lock for the entire transaction
    if ( pflock( $file, LOCK_EX ) ) {
        $rv = 1;
        $i  = 0;
        foreach $rec ( @{ $$self{streams} } ) {
            @$rec = ( $$rec[0], quad2Longs( $$rec[1] ) );
            $pos  = STREAMS_POS + $i * STRM_LEN;
            $rv   = 0
                unless $self->bwrite( pack( STRMIDX, @$rec ), $pos ) ==
                    STRM_LEN;
            $i++;
            last unless $rv;
        }

        pflock( $file, LOCK_UN );
    }

    pdebug( 'failed to write all stream records to the file header',
        PDLEVEL1 )
        unless $rv;

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub readStreams {

    # Purpose:  Reads the stream records from the file header
    # Returns:  Boolean
    # Usage:    $rv = $obj->readStreams;

    my $self = shift;
    my $rv   = 1;
    my ( $raw, $sname, $bn, @sraw, $prev );
    my ( %sidx, @streams, %model, $maxstreams );

    subPreamble(PDLEVEL3);

    # Read the streams section of the block
    if ( $self->bread( \$raw, STREAMS_POS ) ) {

        # Get the model so we know how many streams we can support
        %model      = $self->model;
        $maxstreams = $model{maxStreams};

        @sraw = unpack '(' . STRMIDX . ")$maxstreams", $raw;
        while (@sraw) {
            $sname = shift @sraw;
            $bn = longs2Quad( shift @sraw, shift @sraw );

            # Stop processing when it looks like we're not getting legitmate
            # values
            last unless defined $sname and length $sname and $bn > 0;

            # Make sure we're not getting repeated streams
            if ( exists $sidx{$sname} ) {
                pdebug( 'stream (%s) listed more than once',
                    PDLEVEL1, $sname );
                $rv = 0;
                last;
            }

            # Error out if stream block numbers aren't ascending
            unless ( !defined $prev or $bn > $prev ) {
                pdebug( 'stream block number appearing out of sequence',
                    PDLEVEL1 );
                $rv = 0;
                last;
            }

            # Save entry
            push @streams, [ $sname, $bn ];
            $sidx{$sname} = $#streams;
            $prev = $bn;
        }

        # Save everything extracted
        $$self{streamidx} = {%sidx};
        $$self{streams}   = [@streams];
        pdebug( 'found %s streams', PDLEVEL4, scalar @streams );

    } else {
        pdebug( 'failed to read list of streams from file header', PDLEVEL1 );
        $rv = 0;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

sub addStream {

    # Purpose:  Adds a stream record to the file header
    # Returns:  Boolean
    # Usage:    $rv = $obj->addStream($sname, $bn);

    my $self  = shift;
    my $sname = shift;
    my $bn    = shift;
    my %sidx  = %{ $$self{streamidx} };
    my $rv    = 1;

    subPreamble( PDLEVEL3, '$$', $sname, $bn );

    if ( defined $sname and length $sname ) {
        if ( exists $sidx{$sname} ) {
            pdebug( 'stream already exists (%s)', PDLEVEL1, $sname );
            $rv = 0;
        }

        if ( length $sname > 20 ) {
            pdebug( 'stream name is too long (%s)', PDLEVEL1, $sname );
            $rv = 0;
        }

        if ( !defined $bn or $bn < 1 ) {
            pdebug( 'invalid stream block number (%s)', PDLEVEL1, $bn );
            $rv = 0;
        }

        if ($rv) {
            push @{ $$self{streams} }, [ $sname, $bn ];
            ${ $$self{streamidx} }{$sname} = $#{ $$self{streams} };
            $rv = 0
                unless $self->bwrite( pack( STRMIDX, $sname, $bn ),
                STREAMS_POS + STRM_LEN * $#{ $$self{streams} } ) == STRM_LEN;
        }

    } else {
        pdebug( 'invalid stream name (%s)', PDLEVEL1, $sname );
        $rv = 0;
    }

    subPostamble( PDLEVEL3, '$', $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::IO::FileMultiplexer::Block::FileHeader - File Header Block

=head1 VERSION

$Id: lib/Paranoid/IO/FileMultiplexer/Block/FileHeader.pm, 2.10 2022/03/08 00:01:04 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::IO::FileMultiplexer::Block::FileHeader->new(
            $filename, $bsize);

    $count   = $obj->blocks;
    $version = $obj->version;
    %streams = $obj->streams;
    $max     = $obj->maxStreams;
    %model   = $obj->model;

    $rv = $obj->writeSig;
    $rv = $obj->readSig;
    $rv = $obj->writeBlocks;
    $count = $obj->readBlocks;
    $rv = $obj->incrBlocks;
    $rv = $obj->validateBlocks;

    $rv = $obj->writeStreams;
    $rv = $obj->readStreams;
    $rv = $obj->addStream($sname, $bn);

=head1 DESCRIPTION

This class is not meant to be used directly, but as part of the
L<Paranoid::IO::FileMultiplexer> functionality.  This provides functionality
necessary for manipulation of the file header block.

This module does presume that whatever file it is being used on has already
been opened in the appropriate mode, and that the L<Paranoid::IO> flock stack
has been enabled.  For the purposes of L<Paranoid::IO::FileMultiplexer>, this
is done in that class.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj =
        Paranoid::IO::FileMultiplexer::Block::FileHeader->new($file, $blockSize);

This creates a new instance of a file header block object.  It requires the 
filename in order to retrieve the cached file handle from L<Paranoid::IO>, 
and the size of the block.  This always writes to the first block of the file.

B<NOTE:> creating an object does not automatically create the file and/or
write a signature.  That must be done using the methods below.

=head2 blocks

    $count = $obj->blocks;

This method returns the value of the blocks field in the file header.  This is
the total number of blocks allocated in the file to date.  Note that this is
only the cached value stored in the object.  Other methods are provided for
writing and reading the value from the file.

=head2 version

    $ver = $obj->version;

This method returns the file format version as a string.

=head2 streams

    %streams = $obj->streams;

This method returns a hash of streams allocated in the file, in the format of
I<stream name> => I<block number>.

=head2 maxStreams

    $max = $obj->maxStreams;

This method returns the maximum number of streams supported by this file
header.

=head2 model

    $stats = $obj->model;

This method returns a hash with some basic statistical information on the
file, in both raw and human-friendly values.  The information provided is as
follows:

    Key             Description
    ---------------------------------------------------------------
    intSize         Size of Perl's native integers in bits
    curFileSize     Current file size in bytes
    curFSHuman      Current file size expressed w/unit suffixes
    curStreams      Current number of streams allocated
    maxFileSize     Maximum file size supported with Perl
    maxFSHuman      Maximum file size expressed w/unit suffixes
    maxStreams      Maximum number of streams that can be allocated
    maxStreamSize   Maximum stream size
    maxSSHuman      Maximum stream size expressed w/unit suffixes

=head2 writeSig

    $rv = $obj->writeSig;

This method writes the file header signature to disk, returning a boolean
value denoting its success.  Note that the signature contains the file format,
version, block size, and number of allocated blocks, but not the list of
allocated streams.

=head2 readSig

    $rv = $obj->readSig;

This method reads the file header signature from disk and performs basic
validation that the information in it is acceptable.  It validates that the
file size matches the block size * block count, that the block size is an
acceptable value, and the file format and version are supported.

If the method call was successful it will update the cached values in the
object.  Note that this is only the signature values, not the stream index
records.

=head2 writeBlocks

    $rv = $obj->writeBlocks($count);

This method writes the passed block count value to disk, and returns a boolean
value denoting success.

=head2 readBlocks

    $count = $obj->readBlocks;

This method reads the block count field from disk and returns it.  If there
are any errors reading or extracting the value, it will return undef.

=head2 incrBlocks

    $rv = $obj->incrBlocks;

This method calls L<writeBlocks> with a value of one greater that what's
currently cached.

=head2 validateBlocks

    $rv = $obj->validateBlocks;

This method compares the cached block count value to what's actually written
in the file.  This is useful for determining whether an external process has
potentially modified the file.

=head2 writeStreams

    $rv = $obj->writeStreams;

This method writes the stream index records to the header block, and returns a
boolean denoting success.

=head2 readStreams

    $rv = $obj->readStreams;

This method reads the stream index records from the file, and returns a
boolean value denoting success.  If the read is successful, this will update
the cached streams information in the object.

=head2 addStream

    $rv = $obj->addStream($sname, $bn);

This method does some basic validation of the requested stream, and if it
passes, updates the stream indices on the disk.

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

L<Paranoid::IO::FileMultiplexer::Block>

=item o

L<Paranoid::IO::FileMultiplexer::Block::BATHeader>

=item o

L<Paranoid::IO::FileMultiplexer::Block::StreamHeader>

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

