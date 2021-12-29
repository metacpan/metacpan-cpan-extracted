# Paranoid::IO::FileMultiplexer::Block::StreamHeader -- Stream Header Block
#
# $Id: lib/Paranoid/IO/FileMultiplexer/Block/StreamHeader.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $
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

package Paranoid::IO::FileMultiplexer::Block::StreamHeader;

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

use base qw(Paranoid::IO::FileMultiplexer::Block);

# Signature format:
#   PIOFMSTRM Name EOS
#   Z10       Z21  NNx
#     40 bytes
#
# BAT record format:
#   BlockNum
#   NN
#     8 bytes
use constant SIGNATURE => 'Z10Z21NNx';
use constant SIG_LEN   => 40;
use constant SIG_TYPE  => 'PIOFMSTRM';
use constant EOS_POS   => 31;
use constant BATS_POS  => 40;
use constant BATIDX    => 'NN';
use constant BAT_LEN   => 8;

#####################################################################
#
# Module code follows
#
#####################################################################

sub new {

  # Purpose:  Creates a new stream header object
  # Returns:  Object reference/undef
  # Usage:    $obj =
  #             Paranoid::IO::FileMultiplexer::Block::StreamHeader->new($file,
  #             $blockNo, $blockSize, $strmName);

    my $class = shift;
    my $file  = shift;
    my $bnum  = shift;
    my $bsize = shift;
    my $sname = shift;
    my $self;

    pdebug( 'entering w/(%s)(%s)(%s)(%s)',
        PDLEVEL3, $file, $bnum, $bsize, $sname );
    pIn();

    if ( defined $sname and length $sname and length $sname <= 20 ) {
        $self = __PACKAGE__->SUPER::new( $file, $bnum, $bsize );
    } else {
        pdebug( 'invalid stream name (%s)', PDLEVEL1, $sname );
    }

    if ( defined $self ) {
        $$self{streamName} = $sname;
        $$self{bats}       = [];       # array of blockNum
        $$self{eos}        = 0;        # address of stream EOF
        $$self{maxBATs} = int( ( $$self{blockSize} - SIG_LEN ) / BAT_LEN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $self );

    return $self;
}

sub streamName {

    # Purpose:  Returns the current stream name
    # Returns:  String
    # Usage:    $name = $obj->streamName;

    my $self = shift;

    return $$self{streamName};
}

sub maxBATs {

    # Purpose:  Returns the max BAT blocks for the stream
    # Returns:  Integer
    # Usage:    $max = $obj->maxBATs;

    my $self = shift;

    return $$self{maxBATs};
}

sub eos {

    # Purpose:  Returns the current stream EOS
    # Returns:  Integer
    # Usage:    $eos = $obj->eos;

    my $self = shift;

    return $$self{eos};
}

sub bats {

    # Purpose:  Returns an array of bat nums
    # Returns:  Hash
    # Usage:    @bats = $obj->bats;

    my $self = shift;

    return @{ $$self{bats} };
}

sub full {

    # Purpose:  Returns whether the streams's array of BAT blocks is full
    # Returns:  Boolean
    # Usage:    $rv = $obj->full;

    my $self = shift;

    return $self->maxBATs == scalar $self->bats;
}

sub writeSig {

    # Purpose:  Writes the stream signature to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeSig;

    my $self  = shift;
    my $file  = $$self{file};
    my $sname = $$self{streamName};
    my $eos   = $$self{eos};
    my $rv    = 0;
    my $sig   = pack SIGNATURE, SIG_TYPE, $sname, $self->splitInt($eos);

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
    my ( $raw, $type, $sname, $eos, $leos, $ueos );

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    if ( pflock( $file, LOCK_SH ) ) {
        if ( $self->bread( \$raw, 0, SIG_LEN ) == SIG_LEN ) {
            $rv = 1;

            # Unpack the signature
            ( $type, $sname, $leos, $ueos ) = unpack SIGNATURE, $raw;

            # Validate contents
            #
            # Start with file type
            unless ( $type eq SIG_TYPE ) {
                $rv = 0;
                pdebug( 'Invalid stream header type (%s)', PDLEVEL1, $type );
            }

            # stream name
            unless ( $sname eq $$self{streamName} ) {
                $rv = 0;
                pdebug( 'Invalid stream name (%s)', PDLEVEL1, $sname );
            }

            # Make sure eos is legitimate
            $eos = $self->joinInt( $leos, $ueos );
            unless ( defined $eos ) {
                pdebug( 'this platform does not support 64b values for eos',
                    PDLEVEL1 );
                $rv = 0;
            }

            # Update internal values
            if ($rv) {
                $$self{eos} = $eos;
            } else {
                pdebug( 'stream signature verification failure', PDLEVEL1 );
            }

        } else {
            pdebug( 'failed to read stream header signature', PDLEVEL1 );
        }

        pflock( $file, LOCK_UN );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub writeEOS {

    # Purpose:  Updates the EOS counter and writes it to disk
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeEOS($pos);

    my $self = shift;
    my $eos  = shift;
    my ( $raw, $rv );

    pdebug( 'entering w/%s', PDLEVEL3, $eos );
    pIn();

    if ( defined $eos ) {
        $raw = pack 'NN', $self->splitInt($eos);
        if ( $self->bwrite( $raw, EOS_POS ) == 8 ) {
            $$self{eos} = $eos;
            $rv = 1;
        }
    } else {
        pdebug( 'invalid value for eos (%s)', PDLEVEL1, $eos );
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub readEOS {

    # Purpose:  Reads the EOS counter from disk
    # Returns:  Integer/undef on error
    # Usage:    $pos = $obj->readEOS;

    my $self = shift;
    my ( $rv, $raw );

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    if ( $self->bread( \$raw, EOS_POS, 8 ) == 8 ) {
        $rv = $self->joinInt( unpack 'NN', $raw );
        $rv = '0 but true' if defined $rv and $rv == 0;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub validateEOS {

    # Purpose:  Compares in-memory EOS counter to what's stored in the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->validateBlocks;

    my $self = shift;
    my $rv   = 0;

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    $rv = 1 if $$self{eos} == $self->readEOS;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub writeBATs {

    # Purpose:  Writes all the BAT block numbers to the file
    # Returns:  Boolean
    # Usage:    $rv = $obj->writeBATs;

    my $self = shift;
    my $file = $$self{file};
    my $rv   = 0;
    my ( $rec, $i, $pos );

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    # Hold an exclusive lock for the entire transaction
    if ( pflock( $file, LOCK_EX ) ) {

        $rv = 1;
        $i  = 0;
        foreach $rec ( @{ $$self{bats} } ) {
            $pos = BATS_POS + $i * BAT_LEN;
            $rv  = 0
                unless $self->bwrite( pack( BATIDX, $self->splitInt($rec) ),
                $pos ) == BAT_LEN;
            $i++;
            last unless $rv;
        }

        pflock( $file, LOCK_UN );
    }

    pdebug( 'failed to write all BAT block numbers to the stream header',
        PDLEVEL1 )
        unless $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub readBATs {

    # Purpose:  Reads the BAT records from the stream header
    # Returns:  Boolean
    # Usage:    $rv = $obj->readBATs;

    my $self = shift;
    my $rv   = 1;
    my ( $raw, @sraw, $bn, $lbn, $ubn, $prev );
    my @bats;

    pdebug( 'entering', PDLEVEL3 );
    pIn();

    # Read the BATs section of the block
    if ( $self->bread( \$raw, BATS_POS ) ) {

        @sraw = unpack '(' . BATIDX . ")$$self{maxBATs}", $raw;
        while (@sraw) {

            $lbn = shift @sraw;
            $ubn = shift @sraw;
            $bn  = $self->joinInt( $lbn, $ubn );

            # Stop processing when it looks like we're not getting legitmate
            # values
            last unless defined $bn and $bn > $$self{blockNum};

            # Error out if block numbers aren't ascending
            unless ( !defined $prev or $bn > $prev ) {
                pdebug( 'BAT block number appearing out of sequence',
                    PDLEVEL1 );
                $rv = 0;
                last;
            }

            # Save entry
            push @bats, $bn;
            $prev = $bn;
        }

        # Save everything extracted
        $$self{bats} = [@bats];
        pdebug( 'found %s bats', PDLEVEL4, scalar @bats );

    } else {
        pdebug( 'failed to read list of BATs from stream header', PDLEVEL1 );
        $rv = 0;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

sub addBAT {

    # Purpose:  Adds a BAT block number to the stream header
    # Returns:  Boolean
    # Usage:    $rv = $obj->addBAT($bn);

    my $self = shift;
    my $bn   = shift;
    my $rv   = 1;

    pdebug( 'entering w/(%s)', PDLEVEL3, $bn );
    pIn();

    if ( defined $bn and $bn > $$self{blockNum} ) {

        # Make sure we're not adding redundant entries
        if ( scalar grep { $_ eq $bn } @{ $$self{bats} } ) {
            $rv = 0;
            pdebug( 'redundant entry for an existing BAT', PDLEVEL1 );
        }

        # Make sure new BAT is a higher block number than all previous BATs
        if ( scalar grep { $_ > $bn } @{ $$self{bats} } ) {
            $rv = 0;
            pdebug( 'BAT block number is lower than previous BATs',
                PDLEVEL1 );
        }

        if ($rv) {
            push @{ $$self{bats} }, $bn;
            $rv = 0
                unless $self->bwrite(
                pack( BATIDX, $self->splitInt($bn) ),
                BATS_POS + BAT_LEN * $#{ $$self{bats} } ) == BAT_LEN;
        }

    } else {
        pdebug( 'invalid BAT block number (%s)', PDLEVEL1, $bn );
        $rv = 0;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL3, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::IO::FileMultiplexer::Block::StreamHeader - Stream Header Block

=head1 VERSION

$Id: lib/Paranoid/IO/FileMultiplexer/Block/StreamHeader.pm, 2.09 2021/12/28 15:46:49 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::IO::FileMultiplexer::Block::StreamHeader->new($file,
            $blockNo, $blockSize, $strmName);

    $name   = $obj->streamName;
    $max    = $obj->maxBATs;
    $eos    = $obj->eos;
    @bats   = $obj->bats;
    $rv     = $obj->full;

    $rv     = $obj->writeSig;
    $rv     = $obj->readSig;
    $rv     = $obj->writeEOS($pos);
    $pos    = $obj->readEOS;
    $rv     = $obj->validateBlocks;
    $rv     = $obj->writeBATs;
    $rv     = $obj->readBATs;
    $rv     = $obj->addBAT($bn);

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

    $obj = Paranoid::IO::FileMultiplexer::Block::StreamHeader->new($file,
            $blockNo, $blockSize, $strmName);

This creates a new instance of a stream header block object.  It requires the 
filename in order to retrieve the cached file handle from L<Paranoid::IO>, 
the block number of the block, the size of the block, and the name of the
stream.

B<NOTE:> creating an object does not automatically create the file and/or
write a signature.  That must be done using the methods below.

=head2 streamName

    $name = $obj->streamName;

This method returns the stream name.

=head2 maxBATs

    $max = $obj->maxBATs;

This method returns the maximum number of BATs supported by the stream.

=head2 eos

    $eos = $obj->eos;

This method returns the current EOS of the stream.  Note that this is just the
last cached value, which may be out of sync with the contents of the file.

=head2 bats

    %bats = $obj->bats;

This method returns an array of BAT block numbers allocated to the stream.

=head2 full

    $rv     = $obj->full;

This method returns a boolean value denoting whether this streams's array 
of BAT blocks is at maximum capacity or not.

=head2 writeSig

    $rv = $obj->writeSig;

This method writes the stream header signature to disk, returning a boolean
value denoting its success.  Note that the signature contains the file format,
stream name, and current EOS position.  This does not include the allocated
BAT block numbers.

=head2 readSig

    $rv = $obj->readSig;

This method reads the stream header signature from disk and performs basic
validation that the information in it is acceptable.  It validates that the
stream name matches what is expected and the block format is correct.

If the method call was successful it will update the cached values in the
object.  Note that this is only the signature values, not the BAT block
numbers.

=head2 writeEOS

    $rv = $obj->writeEOS($pos);

This method writes the passed stream EOS position to disk, and returns a 
boolean value denoting success.

=head2 readEOS

    $pos = $obj->readEOS;

This method reads the stream EOS postiong from disk and returns it.  If there
are any errors reading or extracting the value, it will return undef.

=head2 validateEOS

    $rv = $obj->validateEOS;

This method compares the cached EOS position to what's actually written
in the file.  This is useful for determining whether an external process has
potentially modified the file.

=head2 writeBATs

    $rv = $obj->writeBATs;

This method writes the BAT block numbers to the header block, and returns a
boolean denoting success.

=head2 readBATs

    $rv = $obj->readBATs;

This method reads the BAT block numbers from the file, and returns a
boolean value denoting success.  If the read is successful, this will update
the cached BATs in the object.

=head2 addBAT

    $rv = $obj->addBAT($bn);

This method does some basic validation of the requested BAT, and if it
passes, updates the BAT block number list on the disk.

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

=item o

L<Paranoid::IO::FileMultiplexer::Block>

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

