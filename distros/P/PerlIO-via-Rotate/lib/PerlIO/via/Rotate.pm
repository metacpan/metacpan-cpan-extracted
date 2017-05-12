package PerlIO::via::Rotate;

$VERSION= '0.08';

# be strict and do everything on octets
use strict;
use bytes;

# initialize the base rotational strings
my @rotate= ( '', qw(
 b-za
 c-zab
 d-za-c
 e-za-d
 f-za-e
 g-za-f
 h-za-g
 i-za-h
 j-za-i
 k-za-j
 l-za-k
 m-za-l
 n-za-m
 o-za-n
 p-za-o
 q-za-p
 r-za-q
 s-za-r
 t-za-s
 u-za-t
 v-za-u
 w-za-v
 x-za-w
 yza-x
 za-y
), '' );

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2..N parameters passed in -use-

sub import {
    shift;

    # set up defaults
    @_= 0..26 if @_ == 1 and $_[0] eq ':all';
    @_= 13 if !@_;

    # process all rotations
    my @huh;
  ROTATION:
    foreach (@_) {

        # huh?
        push( @huh, "Invalid rotational value: $_" ), next ROTATION
          if !m#^[0-9]+$# or $_ < 0 or $_ > 26;

        # we've already done this one
	my $module= "PerlIO/via/rot$_.pm";
        next ROTATION if $INC{$module};

        # source for the module
        my $source= <<"SRC";
package PerlIO::via::rot$_;
use bytes;
\@PerlIO::via::rot$_\::ISA=     'PerlIO::via::Rotate';
\$PerlIO::via::rot$_\::VERSION= '$PerlIO::via::Rotate::VERSION';
SRC

        # we can do encoding for this
        if ( my $encode= $rotate[$_] . uc( $rotate[$_] ) ) {
            my $other=  26 - $_;
            my $decode= $rotate[$other] . uc( $rotate[$other] );

            # add the source code for this rotation (PUSHED is inherited)
            $source .= <<"SRC";
sub FILL {
    local \$_= readline( \$_[1] );
    return if !defined \$_;
    tr/a-zA-Z/$decode/;
    return \$_;
} #FILL
sub WRITE {
    local \$_= \$_[1];
    tr/a-zA-Z/$encode/;
    return ( print { \$_[2] } \$_ ) ? length() : -1;
} #WRITE
SRC
        }

        # make the module available and mark as loaded
        if ( eval "$source; 1" ) {
            $INC{$module}= $INC{'PerlIO/via/Rotate.pm'};
        }

        # huh?
        else {
            push @huh, "Could not create module for $_: $@";
        }
    }

    # sorry, can't go on
    die join "\n", "These errors were found:", @huh if @huh;

    return;
} #import

#-------------------------------------------------------------------------------
#  IN: 1 class
#      2 numeric value to check

sub VERSION { 1 } #VERSION

#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { bless \*PUSHED, $_[0] } #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 handle to read from
# OUT: 1 decoded string

sub FILL { 

    # huh?
    local( $_ )= ref( $_[0] );
    die "Class $_ was not activated" if !m#::rot(?:0|26)$#;

    return readline( $_[1] );
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

    # huh?
    local( $_ ) = ref( $_[0] );
    die "Class $_ was not activated" unless m#::rot(?:0|26)$#;

    return ( print { $_[2] } $_[1] ) ? length( $_[1] ) : -1;
} #WRITE

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Rotate - PerlIO layer for encoding using rotational deviation

=head1 SYNOPSIS

 use PerlIO::via::Rotate;                 # assume rot13 only
 use PerlIO::via::Rotate 17;              # only a single rotation
 use PerlIO::via::Rotate qw( 13 14 15 );  # list rotations (rotxx) to be used
 use PerlIO::via::Rotate ':all';          # allow for all rotations 0..26

 open( my $in, '<:via(rot13)', 'file.rotated' )
   or die "Can't open file.rotated for reading: $!\n";
 
 open( my $out, '>:via(rot14)', 'file.rotated' )
   or die "Can't open file.rotated for writing: $!\n";

=head1 VERSION

This documentation describes version 0.08.

=head1 DESCRIPTION

This module implements a PerlIO layer that works on files encoded using
rotational deviation.  This is a simple manner of encoding in which
pure alphabetical letters (a-z and A-Z) are moved up a number of places in the
alphabet.

The default rotation is "13".  Commonly this type of encoding is referred to
as "rot13" encoding.  However, any rotation between 0 and 26 inclusive are
allowed (albeit that rotation 0 and 26 don't change anything).  You can
specify the rotations you would like to use B<as strings> in the -use-
statement

The special keyword ":all" can be specified in the -use- statement to indicate
that all rotations between 0 and 26 inclusive should be allowed.

=head1 REQUIRED MODULES

 (none)

=head1 CAVEATS

This module is special insofar it serves as a front-end for 27 modules that
are named "PerlIO::via::rot0" through "PerlIO::via::rot26" that are eval'd as
appropriate when the module is -use-d.  The reason for this approach is that
it is currently impossible to pass parameters to a PerlIO layer when opening
a file.  The name of the module is the implicit parameter being passed to the
PerlIO::via::Rotate module.

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::Base64>, L<PerlIO::via::MD5>,
L<PerlIO::via::QuotedPrint>, L<PerlIO::via::StripHTML>.

=head1 ACKNOWLEDGEMENTS

Inspired by Crypt::Rot13.pm by Julian Fondren.

Also thanks to Ribasushi for pointing out at the first Niederrhein PM meeting
in 10 years, that the module version check is done by UNIVERSAL::VERSION, and
that you can bypass this by providing your own VERSION class method.

=head1 COPYRIGHT

Copyright (C) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
