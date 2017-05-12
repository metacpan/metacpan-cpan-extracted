# O b j e c t : : I n t e r f a c e
#
# Perl Module List Entry:
#
# Name           DSLI  Description                                  Info
# -------------  ----  -------------------------------------------- -----
# Object::
# ::Interface    adpn  Specificy pure virtual base classes ala C++  GWELCH
#
#
# Author:	Gerad Welch <gwelch@computer.org>
#			    <welch.119@osu.edu> for development issues
#
# Contributors:
#   [STH] Shay Harding <sharding@geocities.com>
#
# Copyright:
#   Copyright (c) 1999-2000 Gerad Welch.  All rights reserved.
#   This program may be freely redistributed, though all useful
#   modifications must be sent back to the author for examination and
#   and possible incorporation into future versions. =)
#
# Revision Log:
#
# 2000.07.16 GMW  A version that really works....  Unfortunately, this
#		  only runs under versions of Perl which support CHECK
#                 and the warning pragma (I think only 5.6 or better).
# 2000.05.11 STH  Added output of all missing methods at program
#		  termination, as well as some other miscellaneous useful
#		  stuff.
# 1999.09.18 GMW  Removed 'require' interface for simplicity.  Cleaned up
#		  things a /little/ bit....
# 1999.09.02 GMW  Finished preliminary version.
#
# Note:
# Someday it might be nice to have an 'object' pragma, so one could say
# 'use object interface qw( required symbols )' instead of the current
# usage.  Maybe someday....

package Object::Interface;

use strict;

use vars qw( $VERSION $DEBUG $list );

$VERSION = '1.1';
$DEBUG = 0;

BEGIN
{

  $list = [];

}

sub import
{

  # Get rid of our package name
  shift;

  my @required = @_;

  # Find out what module called us (the last require'd or use'd module)
  my @caller;
  my $i = 0;

  while ( 1  ) {
    @caller = caller $i++;
    die "Unable to find derived class!\n" if ! @caller;
    # This must be compared explicitly to 1, as sometimes caller() returns
    # non-null values that aren't 1.  Think that's a bug.  Seems that this
    # changed between Perl 5.00x and 5.6.
    if ( defined $caller[7] ) {
      last if "$caller[7]" eq "1";
    }
  }

print STDERR <<"EOS" if $DEBUG;

use Object::Interface called from $caller[0]
( @caller )
Interface methods: @required

EOS

  # Save the frame information for later checking
  push @$list, [ \@caller, \@required ];

}

CHECK
{

  my @caller;
  my @required;

  my @syms;

  my @present;
  my $is_sub;

  my ( $sym, $flag );
  my @errors;

  my $error = 0;

  foreach my $frame ( @$list ) {

    @caller = @{$frame->[0]};
    @required = @{$frame->[1]};

    # Extract all sub names from the calling module
    eval '@syms = keys %' . $caller[0] . '::';

do {
  map { print STDERR "$_ " } @syms;
  print "\n";
} if $DEBUG;

    # Check to see if the symbol's defined in the package's symbol table

    no warnings;

    @present = map {
                     eval "\$is_sub = defined \$${caller[0]}::{$_}";
                     $is_sub ? ( $_ ) : ( );
                   } @syms;

    use warnings;

print STDERR "Derived class's methods: @present\n\n" if $DEBUG;

    # Check to see what's there and what's not

    @errors = ();
    foreach my $sym ( @required ) {
      @present = map { ( $sym eq $_ ) ? ( $flag = $sym, () )[1] : ( $_ ) } @present;
      push @errors, $sym if ! defined $flag;
      undef $flag;
    }

    if ( @errors ) {
      print STDERR sprintf "Pure virtual function%s < " . join( ', ', @errors ) . " > not defined in $caller[1].\n",
        ( @errors == 1 ? '' : 's' );
      $error = 1;
    }

  }

  die "Execution aborted.\n" if $error;

}

# Codesong: Plastic Tree, "Trance Orange"
# Yo to Yohei, Tomi, and Yasu -- party animals of my own nature.

1;

__END__

=head1 NAME

Object::Interface - allows specification of an abstract base class

=head1 SUMMARY

    package abstract;

    use strict;
    use Object::Interface qw( func1 func2 func3 );

    1;

    # Any classes derived from abstract must now contain the functions
    # specified in the 'use' statement, e.g. func1, func2, and func3.

=head1 DESCRIPTION

C<Object::Interface> allows class modules to be declared as abstract base
classes, or in C++ parlance, pure virtual classes.  That is to say, any
class derived from a module using Object::Interface must implement the
specified routines from that module.  C<Object::Interface> differs from
C++'s pure virtual functions in that functions may be defined and coded in
the abstract base for the derived class to call (via C<SUPER>).  This
allows common code to be written in the base class.  For example:

    package IO::Base;

    use strict;
    use Object::Interface qw( open close read print eof ); # etc.

    sub open
    {
      return open @_;
    }

    # etc.

C<Object::Interface> simply specifies a signature of functions that any
derived class must implement, not what the derived class can or cannot
do with the methods.

=cut
