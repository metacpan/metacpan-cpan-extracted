package PerlIO::via::LineNumber;

$VERSION= '0.04';

# be as strict as possible
use strict;
use warnings;

# defaults
my $line=      1;
my $format=    '%4d %s';
my $increment= 1;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class methods
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default initial line number
# OUT: 1 current default initial line number

sub line {

    # set new default initial line number if one specified
    $line= $_[1] if @_ >1;

    return $line;
} #line

#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default format
# OUT: 1 current default format

sub format {

    # set new default format if one specified
    $format= $_[1] if @_ >1;

    return $format;
} #format

#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default increment and default line number
# OUT: 1 current default increment

sub increment {

    # set new default increment if one specified
    $line= $increment= $_[1] if @_ >1;

    return $increment;
} #increment

#-------------------------------------------------------------------------------
#
# Subroutines for standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

    return bless {
      line      => $line,
      format    => $format,
      increment => $increment,
    }, $_[0];
} #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string

sub FILL {

    # prefix line number
    if ( defined( my $line= readline( $_[1] ) ) ) {
        my $number= $_[0]->{line};
        $_[0]->{line} += $_[0]->{increment};
        return sprintf $_[0]->{format}, $number, $line;
    }

    # nothing to do
    return undef;
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

    # local copies of format and increment
    my ( $format, $increment )= @{ $_[0] }{ qw(format increment ) };

    # print all lines with line number, die if print fails
    foreach ( split m#(?<=$/)#, $_[1] ) {
        return -1
          if !print { $_[2] } sprintf( $format, $_[0]->{line}, $_ );
        $_[0]->{line} += $increment;
    }

    return length( $_[1] );
} #WRITE

#-------------------------------------------------------------------------------
#  IN: 1 class for which to import
#      2..N parameters passed with -use-

sub import {
    my ( $class, %param )= @_;

    # store parameters using mutators
    $class->$_( $param{$_} ) foreach keys %param;
} #import

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::LineNumber - PerlIO layer for prefixing line numbers

=head1 VERSION

This documentation describes version 0.04.

=head1 SYNOPSIS

 use PerlIO::via::LineNumber;
 PerlIO::via::LineNumber->line( 1 );
 PerlIO::via::LineNumber->format( '%4d %s' );
 PerlIO::via::LineNumber->increment( 1 );

 use PerlIO::via::LineNumber line => 1, format => '%4d %s', increment => 1;

 open( my $in,'<:via(LineNumber)','file.ln' )
  or die "Can't open file.ln for reading: $!\n";
 
 open( my $out,'>:via(LineNumber)','file.ln' )
  or die "Can't open file.ln for writing: $!\n";

=head1 DESCRIPTION

This module implements a PerlIO layer that prefixes line numbers on input
B<and> on output.  It is intended as a development tool only, but may have
uses outside of development.

=head1 CLASS METHODS

The following class methods allow you to alter certain characteristics of
the line numbering process.  Ordinarily, you would expect these to be
specified as parameters during the process of opening a file.  Unfortunately,
it is not yet possible to pass parameters with the PerlIO::via module.

Therefore an approach with class methods was chosen.  Class methods that can
also be called as key-value pairs in the C<use> statement.

Please note that the new value of the class methods that are specified, only
apply to the file handles that are opened (or to which the layer is assigned
using C<binmode()>) B<after> they have been changed.

=head2 line

 use PerlIO::via::LineNumber line => 1;
 
 PerlIO::via::LineNumber->line( 1 );
 my $line= PerlIO::via::LineNumber->line;

The class method "line" returns the initial line number that will be used for
adding line numbers.  The optional input parameter specifies the initial line
number that will be used for any files that are opened in the future.  The
default is 1.

=head2 format

 use PerlIO::via::LineNumber format => '%4d %s';
 
 PerlIO::via::LineNumber->format( '%4d %s' );
 my $format= PerlIO::via::LineNumber->format;

The class method "format" returns the format that will be used for adding
line numbers.  The optional input parameter specifies the format that will
be used for any files that are opened in the future.  The default is '%4d %s'.

=head2 increment

 use PerlIO::via::LineNumber increment => 1;
 
 PerlIO::via::LineNumber->increment( 1 );
 my $increment= PerlIO::via::LineNumber->increment;

The class method "increment" returns the increment that will be used for
adding line numbers.  The optional input parameter specifies the increment
that will be used for any files that are opened in the future.  Setting the
increment will also cause the L<line> to be set to the same value.  The
default is 1.

=head1 REQUIRED MODULES

 (none)

=head1 EXAMPLES

Here are some examples, some may even be useful.

=head2 Write line numbers to a file

The following code creates a file handle that prefixes linenumbers while
writing to a file.

 use PerlIO::via::LineNumber;
 open( my $out,'>via(LineNumber)','numbered' ) or die $!;
 print $out <<EOD;
 These lines with
 text will have
 line numbers
 prefixed
 automagically.
 EOD

will end up as

    1 These lines with
    2 text will have
    3 line numbers
    4 prefixed
    5 automagically.

in the file called "numbered".

=head2 BASICfy filter

A script that adds linenumbers to a file in good old BASIC style.

 #!/usr/bin/perl
 use PerlIO::via::LineNumber format => '%04d %s', increment => 10;
 binmode( STDIN,':via(LineNumber)' ); # could also be STDOUT
 print while <STDIN>;

would output the following when called upon itself:

 0010 #!/usr/bin/perl
 0020 use PerlIO::via::LineNumber format => '%04d %s', increment => 10;
 0030 binmode( STDIN,':via(LineNumber)' );
 0040 print while <STDIN>;

=head1 SEE ALSO

L<PerlIO::via> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2009, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
