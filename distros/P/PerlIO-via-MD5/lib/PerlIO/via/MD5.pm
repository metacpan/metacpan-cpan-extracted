package PerlIO::via::MD5;

$VERSION= '0.07';

# be as strict as possible
use strict;

# modules that we need
use Digest::MD5 (); # no need to pollute this namespace

# initializations
my %allowed= ( digest => 1, hexdigest => 1, b64digest => 1 );
my $method=  'hexdigest';

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Methods for settings that will be used by the objects
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new setting for method
# OUT: 1 current setting for eol

sub method {
    shift;

    # set new value if given
    if (@_) {
        die "Invalid digest method '$_[0]'" unless $allowed{$_[0]};
        $method= shift;
    }

    return $method;
} #method

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

  # not reading
  return -1 if $_[1] ne 'r';

  return bless [ Digest::MD5->new, $method ], $_[0];
} #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 empty string (when still busy) or the digest string (when done)

sub FILL {

    # still reading file
    my $line= readline( $_[1] );
    if ( defined($line) ) {
        $_[0]->[0]->add($line);

        # nothing to be returned yet
	return '';
    }

    # end of data reached, we have MD5 object still
    elsif ( $_[0]->[0] ) {
        my ( $object, $method )= @{ $_[0] };
        $_[0]->[0]= '';

        # return result of digest
        return $object->$method;
    }

    # huh?, end of data without MD5 object, empty file?
    return undef;
} #FILL

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::MD5 - PerlIO layer for creating an MD5 digest of a file

=head1 SYNOPSIS

 use PerlIO::via::MD5;

 PerlIO::via::MD5->method( 'hexdigest' ); # default, return 32 hex digits
 PerlIO::via::MD5->method( 'digest' );    # return 16-byte binary value
 PerlIO::via::MD5->method( 'b64digest' ); # return 22-byte base64 (MIME) value

 open( my $in,'<:via(MD5)','file' )
  or die "Can't open file for digesting: $!\n";
 my $digest = <$in>;

=head1 VERSION

This documentation describes version 0.07.

=head1 DESCRIPTION

This module implements a PerlIO layer that can only read files and return an
MD5 digest of the contents of the file.

=head1 CLASS METHODS

There is one class method.

=head2 method

 $method = PerlIO::via::MD5->method;  # obtain current setting
 PerlIO::via::MD5->method( $method ); # set new digest method

Calling this class method with a new value will cause all subsequently opened
files to assume that new setting.  The method however is remembered within
the layer, so that it becomes part of the information that is associated with
that file.

If it were possible to pass parameters such as this to the layer while opening
the file, that would have been the approach taken.  Since that is not possible
yet, this way of doing it seems to be the next best thing.

=head1 REQUIRED MODULES

 Digest::MD5 (any)

=head1 SEE ALSO

L<PerlIO::via>, L<Digest::MD5>, L<PerlIO::via::StripHTML>,
L<PerlIO::via::QuotedPrint>, L<PerlIO::via::Base64>, L<PerlIO::via::Rotate>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
