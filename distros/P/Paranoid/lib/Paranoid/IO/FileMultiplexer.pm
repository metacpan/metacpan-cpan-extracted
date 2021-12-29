# Paranoid::IO::FileMultiplexer -- File Multiplexer Object
#
# $Id: lib/Paranoid/IO/FileMultiplexer.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
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

package Paranoid::IO::FileMultiplexer;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);
use base qw(Exporter);
use Paranoid;
use Paranoid::IO qw(:all);
use Paranoid::Debug qw(:all);
use Carp;
use Fcntl qw(:DEFAULT :flock :mode :seek);
use Paranoid::IO::FileMultiplexer::Block::FileHeader;
use Paranoid::IO::FileMultiplexer::Block::StreamHeader;
use Paranoid::IO::FileMultiplexer::Block::BATHeader;

($VERSION) = ( q$Revision: 2.09 $ =~ /(\d+(?:\.\d+)+)/sm );

use constant PIOFMVER => '1.0';
use constant PERMMASK => 0666;
use constant DEFBSIZE => 4096;

use constant ADDR_BAT => 0;
use constant ADDR_BLK => 1;
use constant ADDR_OFT => 2;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

    # Purpose:  Creates a PIOFM object for manipulation
    # Returns:  Object reference or undef
    # Usage:    $obj = Paranoid::IO::FileMultiplexer->new(
    #               file        => $fn,
    #               readOnly    => 0,
    #               perms       => $perms,
    #               blockSize   => $bsize,
    #               );

    my $class = shift;
    my %args  = @_;
    my $self  = {
        file      => undef,
        readOnly  => 0,
        perms     => PERMMASK ^ umask,
        header    => undef,
        streams   => {},
        streamPos => {},
        blockSize => DEFBSIZE,
        corrupted => 0,
        %args
        };

    pdebug( 'entering w/f: %s bs: %s p: %s ro: %s',
        PDLEVEL1, @args{qw(file blockSize perms readOnly)} );
    pIn();

    bless $self, $class;

    # Mandatory file name required
    $self = undef
        unless defined $args{file} and length $args{file};

    if ( defined $self ) {

        # Enable the lock stack
        PIOLOCKSTACK = 1;

        # Attempt to open the file
        if ( $$self{ro} ) {
            $self = undef unless $self->_oldFile;
        } else {
            $self = undef unless $self->_newFile or $self->_oldFile;
        }

    } else {
        pdebug( 'invalid file name: %s', PDLEVEL1, $args{file} );
    }

    pOut();
    pdebug( 'leaving w/%s', PDLEVEL1, $self );

    return $self;
}

sub _newFile {

    # Purpose:  Attempts to open the file as a new file
    # Returns:  Boolean
    # Usage:    $rv = $obj->_newFile;

    my $self  = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my $rv    = 0;
    my $header;

    pdebug( 'entering', PDLEVEL2 );
    pIn();

    if ( !$$self{readOnly} ) {

        # Allocate the header object (it will fail on invalid block sizes)
        $header =
            Paranoid::IO::FileMultiplexer::Block::FileHeader->new( $file,
            $bsize );
        if ( defined $header ) {

            # Open the file exclusively and get an flock
            $rv = popen( $file, O_CREAT | O_RDWR | O_EXCL, $$self{perms} );
            if ($rv) {

                # Lock file
                pflock( $file, LOCK_EX );

                # Allocate the block and write the initial signature
                $rv = $header->allocate and $header->writeSig;
                $$self{header} = $header if $rv;

                # Release the lock
                pflock( $file, LOCK_UN );
            }
        }
    } else {
        pdebug( 'cannot create a new file in readOnly mode', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _oldFile {

    # Purpose:  Attempts to open the file as a new file
    # Returns:  Boolean
    # Usage:    $rv = $obj->_newFile;

    my $self  = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my $rv    = 0;
    my $header;

    pdebug( 'entering', PDLEVEL2 );
    pIn();

    # Allocate the header object (it will fail on invalid block sizes)
    $header = Paranoid::IO::FileMultiplexer::Block::FileHeader->new( $file,
        $bsize );
    if ( defined $header ) {

        # Open the file exclusively and get an flock
        $rv = popen( $file, ( $$self{readOnly} ? O_RDONLY : O_RDWR ),
            $$self{perms} );
        if ($rv) {

            # Lock file
            pflock( $file, LOCK_SH );

            # Read an existing signature
            $rv = $header->readSig && $header->readStreams;
            if ($rv) {
                $$self{header}    = $header;
                $$self{blockSize} = $header->blockSize;
            }

            # Release the lock
            pflock( $file, LOCK_UN );
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub header {

    # Purpose:  Returns a reference to the header object
    # Returns:  Ref
    # Usage:    $header = $obj->header;

    my $self = shift;
    return $$self{header};
}

sub _reload {

    # Purpose:  Reloads the file header information and purges the stream
    #           cache
    # Returns:  Boolean
    # Usage:    $rv = $obj->_reload;

    my $self   = shift;
    my $file   = $$self{file};
    my $header = $$self{header};
    my $rv     = 1;

    pdebug( 'entering', PDLEVEL4 );
    pIn();

    if ( pflock( $file, LOCK_SH ) ) {
        if ( $header->readSig && $header->readStreams ) {
            $$self{streams} = {};
        } else {
            $$self{corrupt} = 1;
            $rv = 0;
        }
        pflock( $file, LOCK_UN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _getStream {

    # Purpose:  Retrieves or creates a stream header object
    # Returns:  Ref
    # Usage:    $ref = $obj->_getStream($name);

    my $self   = shift;
    my $sname  = shift;
    my $header = $$self{header};
    my $file   = $$self{file};
    my ( $rv, %streams, $stream );

    pdebug( 'entering w/%s', PDLEVEL2, $sname );
    pIn();

    if ( defined $sname and length $sname ) {

        # Reload if header fails validation
        $self->_reload unless $header->validateBlocks;

        # Create the stream object if we don't have one cached
        unless ( exists $$self{streams}{$sname} ) {
            %streams = $header->streams;
            if ( exists $streams{$sname} ) {
                $stream =
                    Paranoid::IO::FileMultiplexer::Block::StreamHeader->new(
                    $$self{file}, $streams{$sname}, $header->blockSize,
                    $sname );
                if ( pflock( $file, LOCK_SH ) ) {
                    $$self{streams}{$sname} = $stream
                        if $stream->readSig
                            and $stream->readBATs;
                    pflock( $file, LOCK_UN );
                }
                unless ( exists $$self{streams}{$sname} ) {
                    pdebug( 'stream \'%s\' failed consistency checks',
                        PDLEVEL1, $sname );
                    $$self{corrupt} = 1;
                }
            } else {
                pdebug( 'attempted to access a non-existent stream (%s)',
                    PDLEVEL1, $sname );
            }
        }

        # Retrieve a reference to the stream object
        $stream =
            exists $$self{streams}{$sname}
            ? $$self{streams}{$sname}
            : undef;

        # Reload stream signature if EOS has changed outside of this process
        if ( defined $stream ) {
            unless ( $stream->validateEOS ) {
                unless ( $stream->readSig and $stream->readBATs ) {
                    $stream = undef;
                    pdebug( 'stream \'%s\' failed consistency checks',
                        PDLEVEL1, $sname );
                    $$self{corrupt} = 1;
                }
            }

            # Return the stream reference
            $rv = $stream;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _getBAT {

    # Purpose:  Returns a BAT which has been loaded and validated
    # Returns:  Ref
    # Usage:    $ref = $obj->_getBAT($sname, $seq);

    my $self  = shift;
    my $sname = shift;
    my $seq   = shift;
    my $file  = $$self{file};
    my ( $rv, $stream, @bats, $bat );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL4, $sname, $seq );
    pIn();

    $stream = $self->_getStream($sname);
    if ( defined $stream ) {

        # Get the list of BATs
        @bats = $stream->bats;

        if ( $seq <= $#bats ) {
            $bat = Paranoid::IO::FileMultiplexer::Block::BATHeader->new(
                $$self{file}, $bats[$seq], $$self{blockSize}, $sname, $seq );
            if ( pflock( $file, LOCK_SH ) ) {
                $rv = $bat
                    if defined $bat
                        and $bat->readSig
                        and $bat->readData;
                pflock( $file, LOCK_UN );
            }
            pdebug( 'BAT %s for stream \'%s\' failed consistency checks',
                PDLEVEL1, $seq, $sname )
                unless $rv;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _chkData {

    # Purpose:  Checks that a data block appears to be present
    # Returns:  Boolean
    # Usage:    $rv = $obj->_chkData;

    my $self  = shift;
    my $bn    = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my ( $rv, $block, $raw );

    pdebug( 'entering w/%s', PDLEVEL4, $bn );
    pIn();

    $block = Paranoid::IO::FileMultiplexer::Block->new( $file, $bn, $bsize );
    $rv = ( defined $block and $block->bread( \$raw, 0, 1 ) == 1 );

    unless ($rv) {
        pdebug( 'data block list at dn %s but cannot be read', PDLEVEL1,
            $bn );
        $rv = 0;
        $$self{corrupted} = 1;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _chkBAT {

    # Purpose:  Checks that a BAT appears consistent
    # Returns:  Boolean
    # Usage:    $rv = $obj->_chkBAT($bn, $snmae, $seq);

    my $self  = shift;
    my $bn    = shift;
    my $sname = shift;
    my $seq   = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my ( $rv, $block, @data );

    pdebug( 'entering w/%s', PDLEVEL4, $bn );
    pIn();

    $block = Paranoid::IO::FileMultiplexer::Block::BATHeader->new( $file, $bn,
        $bsize, $sname, $seq );
    $rv = ( defined $block and $block->readSig and $block->readData );

    unless ($rv) {
        pdebug( 'BAT at bn %s fails consistency checks', PDLEVEL1, $bn );
        $rv = 0;
        $$self{corrupted} = 1;
    }

    if ($rv) {
        @data = $block->dataBlocks;
        foreach (@data) { $rv = 0 unless $self->_chkData($_) }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub _chkStream {

    # Purpose:  Checks that a stream appears consistent
    # Returns:  Boolean
    # Usage:    $rv = $obj->_chkStream($bn, $sname);

    my $self  = shift;
    my $bn    = shift;
    my $sname = shift;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my ( $rv, $i, $block, @bats );

    pdebug( 'entering w/%s', PDLEVEL4, $bn );
    pIn();

    $block =
        Paranoid::IO::FileMultiplexer::Block::StreamHeader->new( $file, $bn,
        $bsize, $sname );
    $rv = ( defined $block and $block->readSig and $block->readBATs );

    unless ($rv) {
        pdebug( 'Stream at bn %s (%s) fails consistency checks',
            PDLEVEL1, $bn, $sname, $sname, $sname );
        $rv = 0;
        $$self{corrupted} = 1;
    }

    if ($rv) {
        @bats = $block->bats;
        $i    = 0;
        foreach (@bats) {
            $rv = 0 unless $self->_chkBAT( $_, $sname, $i );
            $i++;
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL4, $rv );

    return $rv;
}

sub chkConsistency {

    # Purpose:  Checks the file for consistency
    # Returns:  Boolean
    # Usage:    $rv = $obj->chkConsistency;

    my $self   = shift;
    my $file   = $$self{file};
    my $header = $$self{header};
    my $bsize  = $$self{blockSize};
    my $rv     = 1;
    my %streams;

    pdebug( 'entering', PDLEVEL1 );
    pIn();

    # TODO:  There is one major flaw in this consistency check, in that is
    # TODO:  possible to list a header block as a data block in a BAT.
    # TODO:  Writes to said block will obviously introduce consistency errors
    # TODO:  and corruption in the future.  Depending on the size of the file,
    # TODO:  however, doing an exhaustive search on all data blocks and making
    # TODO:  sure they're not in use as a header block could be memory
    # TODO:  intensive.  We might have to bite the bullet, though.
    #
    # Possible solution (which isn't perfect):  look for signatures and see if
    # they load error free.  I.e., any block that starts with PIOFM.  If we've
    # already passed the rest of the consistency checks, anything pointing to
    # what looks like a header block, but doesn't pass consistency checks, we
    # really don't care about.  We might warn if it does pass, though, and
    # then brute-force check each data block number against a full list of
    # stream/BAT block numbers.

    # Apply a read lock for the duration
    if ( pflock( $file, LOCK_SH ) ) {

        # Check header
        if ( $header->readSig && $header->readStreams ) {

            # Check streams
            %streams = $header->streams;
            foreach ( sort keys %streams ) {
                $rv = 0 unless $self->_chkStream( $streams{$_}, $_ );
            }

        } else {
            pdebug( 'file header failed consistency checks', PDLEVEL1 );
            $$self{corrupted} = 1;
            $rv = 0;
        }

        pflock( $file, LOCK_UN );

    } else {
        pdebug( 'failed to get a read lock', PDLEVEL1 );
        $rv = 0;
    }

    if ($rv) {
        $$self{corrupted} = 0;
    } else {
        $$self{corrupted} = 1;
        pdebug( 'error - setting corrupted flag to true', PDLEVEL1 );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub _addBlock {

    # Purpose:  Adds a data block to the file and updates the file header
    # Returns:  Integer (block number of new block)
    # Usage:    $bn = $self->_addBlock;

    my $self   = shift;
    my $header = $$self{header};
    my ( $rv, $bn, $data );

    pdebug( 'entering', PDLEVEL2 );
    pIn();

    $bn = $header->blocks;
    $data =
        Paranoid::IO::FileMultiplexer::Block->new( $$self{file}, $bn,
        $$self{blockSize} );
    $rv = $bn if defined $data and $data->allocate and $header->incrBlocks;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _addBAT {

    # Purpose:  Adds a BAT to the file and updates the file header, and calls
    #           _addBlock
    # Returns:  Integer (block number of new BAT)
    # Usage:    $bn = $self->_addBAT($sname, $seq);

    my $self   = shift;
    my $sname  = shift;
    my $seq    = shift;
    my $header = $$self{header};
    my ( $rv, $bn, $bat );

    pdebug( 'entering', PDLEVEL2 );
    pIn();

    $bn = $header->blocks;
    $bat =
        Paranoid::IO::FileMultiplexer::Block::BATHeader->new( $$self{file},
        $bn, $$self{blockSize}, $sname, $seq );
    $rv = $bn
        if defined $bat
            and $bat->allocate
            and $bat->writeSig
            and $header->incrBlocks;

    $bat->addData( $self->_addBlock ) if defined $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub _addStream {

  # Purpose:  Adds a Stream to the file and updates the file header, and calls
  #           _addBAT
  # Returns:  Integer (block number of new stream)
  # Usage:    $bn = $self->_addStream($sname);

    my $self   = shift;
    my $sname  = shift;
    my $header = $$self{header};
    my ( $rv, $bn, $stream );

    pdebug( 'entering', PDLEVEL2 );
    pIn();

    $bn = $header->blocks;
    $stream =
        Paranoid::IO::FileMultiplexer::Block::StreamHeader->new( $$self{file},
        $bn, $$self{blockSize}, $sname );
    $rv = $bn
        if defined $stream
            and $stream->allocate
            and $stream->writeSig
            and $header->incrBlocks;

    $stream->addBAT( $self->_addBAT( $sname, 0 ) ) if defined $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub addStream {

    # Purpose:  Adds the requested stream
    # Returns:  Boolean
    # Usage:    $rv = $obj->addStream($name);

    my $self   = shift;
    my $sname  = shift;
    my $file   = $$self{file};
    my $header = $$self{header};
    my $bypass = $$self{readOnly} || $$self{corrupted};
    my $rv     = 0;

    pdebug( 'entering w/(%s)', PDLEVEL1, $sname );
    pIn();

    unless ($bypass) {

        # Get an exclusive lock
        if ( pflock( $file, LOCK_EX ) ) {

            # Validate file header block count
            $rv = 1;
            $rv = $self->_reload unless $header->validateBlocks;

            # Add the stream
            $rv = $header->addStream( $sname, $header->blocks )
                and $self->_addStream($sname)
                if $rv;

            # Release the lock
            pflock( $file, LOCK_UN );

        } else {
            pdebug( 'failed to get an exclusive lock', PDLEVEL1 );
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub _calcAddr {

    # Purpose:  Calculates the (BAT, Data, offset) address of the stream
    #           position
    # Returns:  Array (BAT #, Data #, offset)
    # Usage:    @addr = $self->_calcAddr($pos);

    my $self  = shift;
    my $pos   = shift;
    my $bsize = $$self{blockSize};
    my ( @rv, $bat, $max );

    if ( $pos < $bsize ) {
        @rv = ( 0, 0, $pos );
    } else {

        $bat = Paranoid::IO::FileMultiplexer::Block::BATHeader->new(
            $$self{file}, 0, $bsize );
        if ( defined $bat ) {
            $max = $bat->maxData;

            $rv[ADDR_BAT] = int( $pos / ( $max * $bsize ) );
            $rv[ADDR_BLK] =
                int( ( $pos - ( $rv[ADDR_BAT] * $max * $bsize ) ) / $bsize );
            $rv[ADDR_OFT] = $pos -
                ( $rv[ADDR_BAT] * $max * $bsize + $rv[ADDR_BLK] * $bsize );

        }
    }

    return @rv;
}

sub strmSeek {

    # Purpose:  Updates the stream cursor position
    # Returns:  Integer/undef on error
    # Usage:    $rv = $obj->_strmSeek($sname, $pos, $whence);

    my $self   = shift;
    my $sname  = shift;
    my $pos    = shift;
    my $whence = shift;
    my $cur    = 0;
    my $rv     = 1;

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL2, $sname, $pos, $whence );
    pIn();

    $whence = SEEK_SET unless defined $whence;
    $pos    = 0        unless defined $whence;

    if ( $whence == SEEK_SET ) {
        $$self{streamPos}{$sname} = $pos;
    } else {
        $cur = $$self{streamPos}{$sname} if exists $$self{streamPos}{$sname};

        if ( $whence == SEEK_CUR ) {
            $cur += $pos;
        } elsif ( $whence == SEEK_END ) {
            $cur = $$self{streams}{$sname}->eos + $pos;
        } else {
            pdebug( 'invalid value for whence in seek (%s)',
                PDLEVEL1, $whence );
            $rv = undef;
        }
        $$self{streamPos}{$sname} = $cur;
    }
    $$self{streamPos}{$sname} = 0 if $$self{streamPos}{$sname} < 0;

    $rv = $$self{streamPos}{$sname} if defined $rv;
    $rv = '0 but true' if $rv == 0;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL2, $rv );

    return $rv;
}

sub strmTell {

    # Purpose:  Returns the current stream cursor position
    # Returns:  Integer
    # Usage:    $rv = $obj->_strmTell($sname);

    my $self  = shift;
    my $sname = shift;
    my $rv;

    $$self{streamPos}{$sname} = 0 unless exists $$self{streamPos}{$sname};

    return $$self{streamPos}{$sname};
}

sub _growStream {

    # Purpose:  Grows the stream as needed to accomodate the upcoming write
    #           based on the address of the write's starting position
    # Returns:  Boolean/Integer (bn of last block added)
    # Usage:    $rv = $obj->_growStream($sname, @addr);

    my $self  = shift;
    my $sname = shift;
    my @addr  = @_;
    my $file  = $$self{file};
    my $rv    = 1;
    my ( $max, $stream, $bat, @bats, @blocks );

    pdebug( 'entering w/(%s)(%s, %s, %s)', PDLEVEL3, $sname, @addr );
    pIn();

    # Get the stream and list of bats
    $stream = $self->_getStream($sname);
    @bats   = $stream->bats;

    # Start padding BATs
    while ( $#bats <= $addr[ADDR_BAT] ) {

        # Add a BAT
        if ( $#bats < $addr[ADDR_BAT] ) {

            # Only add a BAT if we're still below the BAT address
            $rv = $self->_addBAT( $sname, scalar @bats );
            if ($rv) {
                $stream->addBAT($rv);
                @bats = $stream->bats;
            } else {
                last;
            }
        }

        # Add data blocks as needed
        $bat = $self->_getBAT( $sname, $#bats );
        @blocks = $bat->dataBlocks;
        while (
              $#bats == $addr[ADDR_BAT]
            ? $#blocks < $addr[ADDR_BLK]
            : !$bat->full
            ) {

            $rv = $self->_addBlock;
            if ($rv) {
                $bat->addData($rv);
                @blocks = $bat->dataBlocks;
            } else {
                last;
            }
        }

        last if $#bats == $addr[ADDR_BAT];
    }

    pdebug( 'failed to grow the stream (%s)', PDLEVEL1, $sname ) unless $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub _strmWrite {

    # Purpose:  Writes to the specified stream
    # Returns:  Integer/undef (bytes written/error)
    # Usage:    $bytes = $obj->_strmWrite($sname, $content);

    my $self    = shift;
    my $sname   = shift;
    my $content = shift;
    my $file    = $$self{file};
    my $bsize   = $$self{blockSize};
    my ( $rv, $stream, $bat, $block, $pos );
    my ( @addr, @blocks, $bn, $blkLeft, $offset, $clength, $chunk, $bw );

    pdebug(
        'entering w/(%s)(%s)',
        PDLEVEL2, $sname,
        ( defined $content ? "@{[ length $content ]} bytes" : $content ),
        );
    pIn();

    if ( pflock( $file, LOCK_EX ) ) {

        $stream = $self->_getStream($sname);
        if ( defined $stream and defined $content and length $content ) {

            # Get the current position
            $pos = $self->strmTell($sname);

            # Get the address
            @addr = $self->_calcAddr( $pos + length $content );

            # Allocate blocks as needed
            if ( $self->_growStream( $sname, @addr ) ) {
                @addr = $self->_calcAddr($pos);

                # Get the specified BAT and data block
                $bat = $self->_getBAT( $sname, $addr[ADDR_BAT] );
                @blocks = $bat->dataBlocks;

                # Get the specified block
                $block =
                    Paranoid::IO::FileMultiplexer::Block->new( $file,
                    $blocks[ $addr[ADDR_BLK] ], $bsize );

                if ( defined $bat and defined $block ) {

                    # Start writing
                    $offset = $rv = 0;
                    while ( $rv < length $content ) {

                        # We need to know how much room is left in the block
                        $blkLeft = $bsize - $addr[ADDR_OFT];

                        # We need to know if the remaining content will fit in
                        #   that block
                        $clength = length($content) - $offset;
                        $chunk = $clength <= $blkLeft ? $clength : $blkLeft;

                        # Write the chunk
                        $bw =
                            $block->bwrite( $content, $addr[ADDR_OFT], $chunk,
                            $offset );
                        $rv     += $bw;
                        $offset += $bw;
                        $pos    += $bw;

                        # Exit if we couldn't write the full chunk
                        unless ( $bw == $chunk ) {
                            pdebug(
                                'failed to write entire contents: %s bytes',
                                PDLEVEL1, $rv );
                            last;
                        }

                        # Get the next block if we have bytes left
                        if ( $rv < length $content ) {
                            @addr = $self->_calcAddr($pos);
                            unless ( $bat->sequence == $addr[ADDR_BAT] ) {
                                $bat =
                                    $self->_getBAT( $sname, $addr[ADDR_BAT] );
                                @blocks = $bat->dataBlocks;
                            }

                            # Get the specified block
                            $block =
                                Paranoid::IO::FileMultiplexer::Block->new(
                                $file, $blocks[ $addr[ADDR_BLK] ], $bsize );
                        }
                    }
                }

                # Update stream position and EOS
                if ($rv) {
                    $self->strmSeek( $sname, $pos, SEEK_SET );
                    $stream->writeEOS($pos) if $stream->eos < $pos;
                }

            }

        }
        pflock( $file, LOCK_UN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub strmWrite {

    # Purpose:  Calls _strmWrite after making sure the file can be written to
    # Returns:  Integer/undef
    # Usage:    $bw = $obj->strmWrite($sname, $content);

    my $self   = shift;
    my @args   = @_;
    my $bypass = $$self{readOnly} || $$self{corrupted};

    pdebug( 'can\'t write to files that are corrupted or read-only',
        PDLEVEL1 )
        if $bypass;

    return $bypass ? undef : $self->_strmWrite(@args);
}

sub _strmRead {

    # Purpose:  Reads from the specified stream
    # Returns:  Integer/undef (bytes read/error)
    # Usage:    $bytes = $obj->_strmRead($sname, $content, $bytes);

    my $self  = shift;
    my $sname = shift;
    my $cref  = shift;
    my $btr   = shift || 0;
    my $file  = $$self{file};
    my $bsize = $$self{blockSize};
    my $rv    = 0;
    my ( $stream, $pos, $eos, @addr, $content );
    my ( $bat, @blocks, $block, $ctr, $br, $offset );

    pdebug( 'entering w/(%s)(%s)(%s)', PDLEVEL2, $sname, $cref, $btr );
    pIn();

    if ( pflock( $file, LOCK_SH ) ) {

        $stream = $self->_getStream($sname);
        if ( defined $stream and defined $cref and ref $cref eq 'SCALAR' ) {

            # Get the current position
            $pos = $self->strmTell($sname);

            # Get the address
            @addr = $self->_calcAddr($pos);

            # Get the End Of Stream position
            $eos = $stream->eos;

            # Start reading
            $$cref = '';
            while ( $pos < $eos and $rv < $btr ) {

                # Get the specified BAT
                $bat = $self->_getBAT( $sname, $addr[ADDR_BAT] );
                if ( defined $bat ) {

                    # Get the specified data block
                    @blocks = $bat->dataBlocks;
                    $block =
                        Paranoid::IO::FileMultiplexer::Block->new( $file,
                        $blocks[ $addr[ADDR_BLK] ], $bsize );
                    if ( defined $block ) {

                        # Take and early out if pos equals eos
                        last unless $pos < $eos;

                        # Figure out how much of the block we have left to
                        # read
                        $ctr = $bsize - $addr[ADDR_OFT];

                        # Reduce it if the read finishes in this block
                        $ctr = $btr - $rv if $ctr > $btr - $rv;

                        # Reduce it further if EOS is even closer
                        $ctr = $eos - $pos if $ctr > $eos - $pos;

                        # Read the chunk
                        $br =
                            $block->bread( \$content, $addr[ADDR_OFT], $ctr );
                        $rv  += $br;
                        $pos += $br;
                        @addr = $self->_calcAddr($pos);
                        $$cref .= $content;

                        unless ( $br == $ctr ) {
                            pdebug(
                                'failed to read entire chunk: %s/%s bytes',
                                PDLEVEL1, $br, $ctr );
                            last;
                        }

                    }
                }
            }

            # Update stream pointer
            $self->strmSeek( $sname, $pos, SEEK_SET );

        } else {
            if ( defined $stream ) {
                pdebug( 'invalid value passed for the content reference: %s',
                    PDLEVEL1, $cref );
                $rv = undef;
            }
        }

        pflock( $file, LOCK_UN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub strmRead {

    # Purpose:  Calls _strmRead after making sure the file can be read from
    # Returns:  Integer/undef
    # Usage:    $br = $obj->strmRead($stream, \$content, $bytes);

    my $self   = shift;
    my @args   = @_;
    my $bypass = $$self{corrupted};

    pdebug( 'can\'t read from files that are corrupted', PDLEVEL1 )
        if $bypass;

    return $bypass ? undef : $self->_strmRead(@args);
}

sub strmAppend {

    # Purpose:  Seeks to the end of the stream and writes new content there
    # Returns:  Integer/undef (bytes written/error)
    # Usage:    $bytes = $obj->_strmAppend($sname, $content);

    my $self    = shift;
    my $sname   = shift;
    my $content = shift;
    my $file    = $$self{file};
    my ( $rv, $stream, $pos );

    pdebug( 'entering w/(%s)(%s)',
        PDLEVEL1, $sname,
        ( defined $content ? "@{[ length $content ]} bytes" : $content ) );
    pIn();

    if ( pflock( $file, LOCK_EX ) ) {
        $stream = $self->_getStream($sname);
        if ( defined $stream ) {
            $pos = $self->strmTell($sname);
            if ( $self->strmSeek( $sname, 0, SEEK_END ) ) {
                $rv = $self->strmWrite( $sname, $content );
                $self->strmSeek( $sname, $pos, SEEK_SET );
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub _strmTruncate {

    # Purpose:  Truncates the stream to the specified length.  This will zero
    #           out any data written past the new EOS.
    # Returns:  Boolean
    # Usage:    $rv = $obj->_strmTruncate($sname, $neos);

    my $self  = shift;
    my $sname = shift;
    my $neos  = shift;
    my $file  = $$self{file};
    my ( $rv, $stream, $eos, $zeroes, $zl );

    pdebug( 'entering w/(%s)(%s)', PDLEVEL1, $sname, $neos );
    pIn();

    if ( pflock( $file, LOCK_EX ) ) {
        $stream = $self->_getStream($sname);
        if ( defined $stream ) {
            $eos = $stream->eos;

            if ( $neos < $eos ) {

                # Zero out old data beyond the new EOS
                $zl     = $eos - $neos;
                $zeroes = pack "x$zl";
                $rv =
                        $self->strmSeek( $sname, $neos, SEEK_SET )
                    and $self->strmWrite( $sname, $zeroes )
                    and $stream->writeEOS($neos);
            }
        }
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub strmTruncate {

  # Purpose:  Calls _strmTruncate after making sure the file can be written to
  # Returns:  Integer/undef
  # Usage:    $bw = $obj->strmTruncate($sname, $neos);

    my $self   = shift;
    my @args   = @_;
    my $bypass = $$self{readOnly} || $$self{corrupted};

    pdebug( 'can\'t write to files that are corrupted or read-only',
        PDLEVEL1 )
        if $bypass;

    return $bypass ? undef : $self->_strmTruncate(@args);
}

sub DESTROY {

    my $self = shift;

    pclose( $$self{file} )
        if defined $$self{file} and length $$self{file};

    return 1;
}

1;

__END__

=head1 NAME

Paranoid::IO::FileMultiplexer - File Multiplexer

=head1 VERSION

$Id: lib/Paranoid/IO/FileMultiplexer.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::IO::FileMultiplexer->new(
        file        => $fn,
        readOnly    => 0,
        perms       => $perms,
        blockSize   => $bsize,
        );

    $header = $obj->header;

    $rv = $obj->chkConsistency;
    $rv = $obj->addStream($name);

    $rv = $obj->strmSeek($sname, $pos, $whence);
    $rv = $obj->strmTell($sname);
    $bw = $obj->strmWrite($sname, $content);
    $br = $obj->strmRead($stream, \$content, $bytes);
    $bw = $obj->strmAppend($sname, $content);
    $bw = $obj->strmTruncate($sname, $neos);

=head1 DESCRIPTION

This class produces file multiplexer objects that multiplex I/O streams into a
single file.  This allows I/O patterns that would normally be applied to
multiple files to be applied to one, with full support for concurrent access
by multiple processes on the same system.

At its most basic, one could use these objects as an archive format for
multiple files.  At its most complex, this could be a database backend file,
similar to sqlite or Berkeley DB.

This does require flock support for the file.

=head2 CAVEATS FOR USAGE

This class is built essentially as a block allocation tool, which does have
some side effects that must be anticipated.  Full support is available for
both 32-bit and 64-bit file systems, and files produced can be exchange across
both types of platforms with no special handling, at least until the point the
file grows beyond the capabilities of a 32 bit platform.  Similarly,
portability should work fine across both endian platforms.

That said, the simplicity of this design did require some compromises, the
first being the number of supported "streams" that can be stored inside a
single file.  That is a function of the block size chosen for the file.  All
allocated streams are tracked in the file header block, so the number of
streams is constrained by the number that can be recorded in that block.

Likewise, the maximum size of a stream is also limited by the block size,
since the stream head block can only track so many block allocation tables,
and each block allocation table can only track so many data blocks.

Practically speaking, for many use cases this should not be an issue, but you
can get an idea of the impact on both 32-bit and 64-bit systems like so:

                        32b/4KB                 64b/4KB
    --------------------------------------------------------------------------
    Max File Size:      4294967295 (4.00GB)     18446744073709551615 (16.00EX)
    Max Streams:        135                     135
    Max Stream Size:    1052872704 (1004.10MB)  1052872704 (1004.10MB)

                        32b/8KB                 64b/8KB
    --------------------------------------------------------------------------
    Max File Size:      4294967295 (4.00GB)     18446744073709551615 (16.00EX)
    Max Streams:        272                     272
    Max Stream Size:    4294967295 (4.00GB)     8506253312 (7.92GB)

As you can see, 8KB blocks will provide full utilization of your file system
capabilities on a 32-bit platform, but on a 64-bit platform, you are still
artificially capped on how much data can be stored in an individual stream.
The number of streams will always limited identically on both platforms based
on the block size.

One final caveat should be noted regarding I/O performance.  The supported
block sizes are intentionally limited in hopes of avoiding double-write
penalties due to block alignment issues on the underlying file system.  At the
same time, the block size also serves as a kind of crude tuning capability for
the size of I/O operations.  No individual I/O, whether read or write, will
exceed the size of a block.  You, as the developer, can call the class API
with reads of any size you wish, of course, but behind the scenes it will be
broken up into block-sized reads at most.

For those reasons, when choosing your block size one should choose based on
the best compromise between I/O performance and the minimum number of streams
(or maximum stream size) anticipated.

As a final note, one should also remember that space is allocated to the file
in block sized chunks.  That means creating a new file w/1MB block size,
containing one stream, but with nothing written to the stream, will create a
file 4MB in size.  That's due to the preallocation of the file header, a
stream header, the stream's first block allocation table, and an initial data
block.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj = Paranoid::IO::FileMultiplexer->new(
        file        => $fn,
        readOnly    => 0,
        perms       => $perms,
        blockSize   => $bsize,
        );

This class method creates new objects for accessing the contents of the pass
file.  It will create a new file if missing, or open an existing file and
retrieve the metadata for tuning.

Only the file name is mandatory.  Block size defaults to 4KB, but if
specified, can support from 4KB to 1MB block sizes, as long as the block size
is a multiple of 4KB.

=head2 header

    $header = $obj->header;

This method returns a reference to the file header block object.  Typically,
this has no practical value to the developer, but the file header does provide
a L<model> method that returns a hash with some predicted sizing limitations.
if you want to know the maximum number of supported streams or the maximum
size of an individual stream, this could be useful.  Calling any other method
for that class, however, could cause corruption of your file.

=head2 chkConsistency

    $rv = $obj->chkConsistency;

This method performs a high-level consistency check of the file structure.  At
this time it is limited to ensuring that every header block (file, stream, and
BAT) has a viable signature, and all records inside those blocks are allocated
and match signatures where appropriate.

If this method detects any inconsistencies it will mark the object as
corrupted, which will prevent any further writes to the file in hopes that
further corruption can be avoided.

The file format of this multiplexer is such that a good deal of data can be
recovered even with the complete loss of the file header.  Corruption in a
stream header can even be recovered from.  Only the loss of a BAT header can
prevent data from being recovered, but even then that will only impact the
stream it belongs to.  It should not impact other streams.

Take this with a grain of salt, of course.  There are always caveats to that
rule, depending on whether the corruption has been detected prior to dangerous
writes.  Every read and write to a stream triggers a few basic consistency
checks prior to progressing, but they are not as thorough as this method's
process, lest it have and adverse impact on performance.

This returns a boolean value.

=head2 addStream

    $rv = $obj->addStream($name);

This method adds a stream to the file, triggering the automatic allocation of
three blocks (a stream header, the first stream BAT, and the first data
block).  It returns a boolean value, denoting success or failure.

=head2  strmSeek

    $rv = $obj->strmSeek($sname, $pos, $whence);

This method acts the same as the core L<sysseek>, taking the same arguments,
but with the substitution of the stream name for the file handle.  It's return
value is also the same.

Note that the position returned is relative to the data stream, not the file
itself.

=head2  strmTell

    $rv = $obj->strmTell($sname);

This method acts the same as the core L<tell>, taking the same arguments, but
with the substitution of the stream name for the file handle.  Like
L<strmSeek>, the position returned is relative to the data stream, not the
file itself.

=head2 strmWrite

    $bw = $obj->strmWrite($sname, $content);

This method acts similarly to a very simplifed L<syswrite>.  It does not
support length and offset arguments, only the content itself.  It will presume
that the stream position has been adjusted as needed prior to invocation.

This returns the number of bytes written.  If everything is working
appropriately, that should match the byte length of the content itself.

=head2 strmRead

    $br = $obj->strmRead($stream, \$content, $bytes);

This method acts similarly to a very simplified L<sysread>.  It does not
support offset arguments, only a scalar reference and the number of bytes to
read.  It also presumes that the stream position has been adjusted as needed
prior to invocation.

This returns the number of bytes read.  Unless you've asked for more data than
has been written to the stream, this should match the number of bytes
requested.

=head2 strmAppend

    $bw = $obj->strmAppend($sname, $content);

This method acts similarly to L<Paranoid::IO>'s L<pappend>.  It always seeks
to the end of the written data stream before appending the requested content.
Like L<strmWrite>, it will return the number of bytes written.  Like
L<pappend>, it does not move the stream position, should you perform
additional writes or reads.

=head2 strmTruncate

    $bw = $obj->strmTruncate($sname, $neos);

This method acts similarly to L<truncate>.  It returns a boolean value
denoting failure or success.

=head2 DESTROY

Obviously, one would never need to call this directly, but it is documented
here to inform the developer that once an object goes out of scope, it will
call L<pclose> on the file, explicitly closing and purging any cached file
handles from L<Paranoid::IO>'s internal cache.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Fcntl>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=item o

L<Paranoid::IO>

=item o

L<Paranoid::IOFileMultiplexer::Block::FileHeader>

=item o

L<Paranoid::IOFileMultiplexer::Block::StreamHeader>

=item o

L<Paranoid::IOFileMultiplexer::Block::BATHeader>

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

