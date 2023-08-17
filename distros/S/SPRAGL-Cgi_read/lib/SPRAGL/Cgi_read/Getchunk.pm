# SPRAGL::Cgi_read::Getchunk.pm
# Getchunk. Helper routines for the Cgi_read module. Get input chunk by chunk.
# Use a list of strings for chunk separators.
# (c) 2022-2023 Bjørn Hee
# Licensed under the Apache License, version 2.0
# https://www.apache.org/licenses/LICENSE-2.0.txt

package SPRAGL::Cgi_read::Getchunk;

use experimental qw(signatures);
use strict;
use Exporter qw(import);

use List::Util qw(max);
use Scalar::Util qw(openhandle);

my sub qwac( $s ) {grep{/./} map{split /\s+/} map{s/#.*//r} split/\v+/ , $s;};

our @EXPORT = qwac '
    readchunk  # Read chunk from input non-destructively.
    takechunk  # Read chunk and remove it from input.
    ';

our @EXPORT_OK = qwac '
    $bufsize  # Buffer size when reading from filehandle.
    ';

our $bufsize = 4096;

# --------------------------------------------------------------------------- #
# Initialization and import.

my $buffer = {}; # per input buffer
my $bufindex = {}; # per input index

# --------------------------------------------------------------------------- #
# Helper methods.

my sub eocfind( $rs , $p , $elist ) {
# Find first index for eoc strings after position.
    my ($i,$s) = (length($rs->$*),undef);
    for my $st ( $elist->@* ) {
        my $it = index( $rs->$* , $st , $p );
        next if $it == -1;
        ($i,$s) = ($it,$st) if $it < $i;
        };
    $i = -1 if not defined $s;
    return ($i,$s);
    };

# --------------------------------------------------------------------------- #

1;

# --------------------------------------------------------------------------- #
# Exportable methods.

sub readchunk( $input , @eoc ) {
#
# Read the first chunk from $input, non-destructively.
#
# Parameters:
# $input is a reference to a string.
# @eoc is a list of strings used for ending chunks.
#
# Return values:
# A reference to the first chunk.
# The eoc string that ended that particular chunk.
#
# Repeated calls will return subsequent chunks.
#
# Calling with an empty list of eoc strings, will slurp all.
#
# If you have started reading an input with readchunk, dont use any other read
# functions for that input.
#
# It is okay to mix reading from multiple inputs, readchunk will sort it out
# and keep separate indexes.
#
    map { die 'Empty eoc strings are not supported.' if $_ eq '' } @eoc;

    die 'readchunk called with an input that is not a reference to a string'
        if ref($input) ne 'SCALAR';

    return if not defined $input->$*;
    return if exists $bufindex->{$input} && not defined $bufindex->{$input};

    my ($chunk,$eoc);
    my $maxlen = max( map { length($_) } @eoc );

    $bufindex->{$input} //= 0;

    my $i;
    ($i,$eoc) = eocfind( $input , $bufindex->{$input} , [@eoc] );

    if ( $i != -1 ) {
        $chunk->$* = substr( $input->$* , $bufindex->{$input} , $i - $bufindex->{$input} );
        $bufindex->{$input} = $i + length($eoc);
        }
    else {
        $chunk->$* = substr( $input->$* , $bufindex->{$input} );
        $bufindex->{$input} = undef;
        };

    return ($chunk,$eoc);
    }; # end sub readchunk

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

sub takechunk( $input , @eoc ) {
#
# Take the first chunk from $input.
#
# Parameters:
# $input is a reference to either a filehandle or a string.
# @eoc is a list of strings used for ending chunks.
#
# Return values:
# A reference to the first chunk.
# The eoc string that ended that particular chunk.
# 
# Repeated calls will return subsequent chunks. As chunks are read, the read
# status of the given filehandle will be changed, or the given string will be
# changed. When all input has been consumed, the filehandle will be closed, or
# the string will have the value undefined.
#
# Calling with an empty list of eoc strings, will slurp all.
#
# If you have started reading an input with takechunk, dont use any other read
# functions for that input.
#
# It is okay to mix reading from multiple inputs, takechunk will sort it out
# and keep separate buffers.
#
    map { die 'Empty eoc strings are not supported.' if $_ eq '' } @eoc;

    return if not defined $input->$*;

    my ($chunk,$eoc);
    my $maxlen = max( map { length($_) } @eoc );

    if ( ref($input) eq 'GLOB' ) {
        return if not defined openhandle($input);
        $buffer->{$input} //= '';
        $bufindex->{$input} //= 0;
        while (1) {
            my $i;
            ($i,$eoc) = eocfind( \($buffer->{$input}) , max( 0 , $bufindex->{$input} - $maxlen ) , [@eoc] );
            if ( $i != -1 ) {
                $chunk->$* = substr( $buffer->{$input} , 0 , $i );
                $buffer->{$input} = substr( $buffer->{$input} , $i + length($eoc) );
                $bufindex->{$input} = 0;
                last;
                }
            else {
                $bufindex->{$input} = length($buffer->{$input});
                my $retval = sysread( $input , $buffer->{$input} , $bufsize , $bufindex->{$input} );
                die $! if not defined($retval);

                if ( $retval == 0 ) {
                    $chunk->$* = $buffer->{$input};
                    close($input);
                    $buffer->{$input} = undef;
                    $bufindex->{$input} = undef;
                    last;
                    };
                };
            }; # end while
        }

    elsif( ref($input) eq 'SCALAR' ) {
        my $i;
        ($i,$eoc) = eocfind( $input , 0 , [@eoc] );
        if ( $i != -1 ) {
            $chunk->$* = substr( $input->$* , 0 , $i );
            $input->$* = substr( $input->$* , $i + length($eoc) );
            }
        else {
            $chunk->$* = $input->$*;
            $input->$* = undef;
            };
        }
    else {
        die 'takechunk called with an input that is not a reference to a string or a filehandle';
        };

    return ($chunk,$eoc);
    }; # end sub takechunk

# --------------------------------------------------------------------------- #

__END__
