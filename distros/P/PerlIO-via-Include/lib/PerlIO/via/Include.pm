package PerlIO::via::Include;

$VERSION= '0.04';

# be as strict as possible
use strict;

# initializations
my $before= '^#include ';
my $after=  $/;
my $regexp;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class methods
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default before string
# OUT: 1 current default before string

sub before {

    # set before string
    if ( @_ > 1 ) {
        $before= $_[1];
        $regexp= undef;
    }

    return $before;
} #before

#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default after string
# OUT: 1 current default after string

sub after {

    # set after string
    if ( @_ > 1 ) {
        $after=  $_[1];
        $regexp= undef;
    }

    return $after;
} #after

#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for default regular expression string
# OUT: 1 current default regular expression string

sub regexp {

    # set new regexp
    if ( @_ > 1 ) {
        $regexp= $_[1];
        $before= $after= undef;
    }

    return $regexp;
} #regexp

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

    # create the object with the right attributes
    return bless {
      regexp => $regexp ? $regexp : qr/$before(.*?)$after/,
    } ,$_[0];
} #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string or undef

sub FILL {

    # process line if there is one
    my $regexp= $_[0]->{'regexp'};
    if ( defined( my $line= readline( $_[1] ) ) ) {
        $line =~ s#$regexp#_include( $1 )#gse;
	return $line;
    }

    return undef;
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

    # process lines, return if failure
    my $regexp= $_[0]->{'regexp'};
    foreach ( split( m#(?<=$/)#, $_[1] ) ) {
	s#$regexp#_include($1)#gse;

        return -1 if !print { $_[2] } $_;
    }

    return length( $_[1] );
} #WRITE

#-------------------------------------------------------------------------------
#  IN: 1 class for which to import
#      2..N parameters passed with -use-

sub import {
    my ( $class, %param )= @_;

    # set using mutators
    $class->$_( $param{$_} ) foreach keys %param;

    return;
} #import

#-------------------------------------------------------------------------------
#
# Internal Subroutines
#
#-------------------------------------------------------------------------------
#  IN: 1 filename to open and include
# OUT: 1 contents of the whole file

sub _include {

    # huh?
    open( my $handle,"<:via(Include)",$_[0] )
     or return "*** Could not open '$_[0]': $! ***";

    # get the contents
    my $contents= '';
    local($_);
    $contents .= $_ while readline( $handle );

    return $contents;
} #_include

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Include - PerlIO layer for including other files

=head1 SYNOPSIS

 use PerlIO::via::Include;
 PerlIO::via::Include->before( "^#include " );
 PerlIO::via::Include->after( "\n" );
 PerlIO::via::Include->regexp( qr/^#include(.*?)\n/ );

 use PerlIO::via::Include before => "^#include ", after => "\n";

 open( my $in,'<:via(Include)','file' )
  or die "Can't open file for reading: $!\n";
 
 open( my $out,'>:via(Include)','file' )
  or die "Can't open file for writing: $!\n";

=head1 VERSION

This documentation describes version 0.04.

=head1 DESCRIPTION

This module implements a PerlIO layer that includes other files, as indicated
by a special string, on input B<and> on output.  It is intended as a
development tool only, but may have uses outside of development.

The regular expression indicating the filename of a file to be included, can
be specified either with the L<before> and L<after> class methods, or as a
regular expression with the L<regexp> class method.

=head1 CLASS METHODS

The following class methods allow you to alter certain characteristics of
the file inclusion process.  Ordinarily, you would expect these to be
specified as parameters during the process of opening a file.  Unfortunately,
it is not yet possible to pass parameters with the PerlIO::via module.

Therefore an approach with class methods was chosen.  Class methods that can
also be called as key-value pairs in the C<use> statement.

Please note that the new value of the class methods that are specified, only
apply to the file handles that are opened (or to which the layer is assigned
using C<binmode()>) B<after> they have been changed.

=head2 before

 use PerlIO::via::Include before => "^#include ";
 
 PerlIO::via::Include->before( "^#include " );
 my $before = PerlIO::via::Include->before;

The class method "before" returns the string that should be before the file
specification in the regular expression that will be used to include other
files.  The optional input parameter specifies the string that should be
before the file specification in the regular expression that will be used
for any files that are opened in the future.  The default is '^#include '.

See the L<after> method for specifying the string after the filename
specification.  See the L<regexp> method for specifying the regular
expression as a regular expression.

=head2 after

 use PerlIO::via::Include after => "\n";
 
 PerlIO::via::Include->after( "\n" );
 my $after = PerlIO::via::Include->after;

The class method "after" returns the string that should be after the file
specification in the regular expression that will be used to include other
files.  The optional input parameter specifies the string that should be
after the file specification in the regular expression that will be used
for any files that are opened in the future.  The default is "\n" (indicating
the end of the line).

See the L<before> method for specifying the string before the filename
specification.  See the L<regexp> method for specifying the regular
expression as a regular expression.

=head2 regexp

 use PerlIO::via::Include regexp => qr/^#include(.*?)\n/;
 
 PerlIO::via::Include->regexp( qr/^#include(.*?)\n/ );
 my $regexp = PerlIO::via::Include->regexp;

The class method "regexp" returns the regular expression that will be used
to include other files.  The optional input parameter specifies the regular
expression that will be used for any files that are opened in the future.
The default is to use what is (implicitely) specified with L<before> and
L<after>.

=head1 REQUIRED MODULES

 (none)

=head1 EXAMPLES

Here will be some examples, some might even be useful.

=head1 SEE ALSO

L<PerlIO::via> and any other PerlIO::via modules on CPAN.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
