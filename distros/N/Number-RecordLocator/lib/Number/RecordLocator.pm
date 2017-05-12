package Number::RecordLocator;

our $VERSION = '0.005';

use warnings;
use strict;
use Carp;
use bigint;

use vars qw/%CHAR_TO_INT %INT_TO_CHAR $INITIALIZED %CHAR_REMAP/;

=head1 NAME

Number::RecordLocator - Encodes integers into a short and easy to read and pronounce "locator string"


=head1 SYNOPSIS

    use Number::RecordLocator;

    my $generator = Number::RecordLocator->new();
    my $string = $generator->encode("123456");

    # $string = "5RL2";

    my $number = $generator->decode($string);
  
    # $number = "123456";

    
=head1 DESCRIPTION

C<Number::RecordLocator> encodes integers into a 32 character "alphabet" 
designed to be short and easy to read and pronounce.  The encoding maps:
    
    0 to O
    1 to I
    S to F 
    B to P

With a 32 bit encoding, you can map 33.5 million unique ids into a 5 character
code.
 
This certainly isn't an exact science and I'm not yet 100% sure of the encoding.
Feedback is much appreciated.


=cut


=head2 new 

Instantiate a new C<Number::RecordLocator> object. Right now, we don't
actually store any object-specific data, but in the future, we might.


=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self => $class;
    $self->init unless ($INITIALIZED); 
    return $self;
}


=head2 init

Initializes our integer to character and character to integer mapping tables.

=cut

sub init {

  my $counter = 0;
  for ( 2 .. 9, 'A', 'C' .. 'R', 'T' .. 'Z' ) {
    $CHAR_TO_INT{$_}       = $counter;
    $INT_TO_CHAR{$counter} = $_;
    $counter++;
  }

  $CHAR_REMAP{'0'} = 'O';
  $CHAR_REMAP{'1'} = 'I';
  $CHAR_REMAP{'S'} = 'F';
  $CHAR_REMAP{'B'} = 'P';

  while (my ($from, $to) = each %CHAR_REMAP) {
      $CHAR_TO_INT{$from} = $CHAR_TO_INT{$to};
  }
  $INITIALIZED      = 1;
}

=head2 encode INTEGER

Takes an integer. Returns a Record Locator string.

=cut

sub encode {
  my $self    = shift;
  my $integer = shift;
  return undef unless ($integer =~ /^\d+$/);
  my @numbers;
  while ( $integer != 0 ) {
    unshift @numbers, $integer % 32;
    $integer = int( $integer / 32 );
  }

  my $str = join( '', map { $INT_TO_CHAR{$_} } @numbers );
  return $str;
}

=head2 decode STRING

Takes a record locator string and returns an integer. If you pass in 
a string containing an invalid character, it returns undef.

=cut

sub decode {
    my $self = shift;
    my $str = uc(shift);
    my $integer = 0;
    foreach my $char (split(//,$str)){
       my $char = $CHAR_TO_INT{$char};
       return undef unless defined $char;
       $integer = ($integer * 32) +   $char;
        }
    return $integer;
}

=head2 canonicalize STRING

To compare a Record Locator string with another you can do:

  print "ALWAYS TRUE\n" if $generator->decode("B0") == $generator->decode("PO");

However, this method provides an alternative:

  my $rl_string = $generator->encode(725);
  print "ALWAYS TRUE\n" if $generator->canonicalize("b0") eq $rl_string;
  print "ALWAYS TRUE\n" if $generator->canonicalize("BO") eq $rl_string;
  print "ALWAYS TRUE\n" if $generator->canonicalize("P0") eq $rl_string;
  print "ALWAYS TRUE\n" if $generator->canonicalize("po") eq $rl_string;

This is primarily useful if you store the record locator rather than just the
original integer and don't want to have to decode your strings to do
comparisons.

Takes a general Record Locator string and returns one with character mappings
listed in L</DESCRIPTION> applied to it. This allows string comparisons to work.
This returns C<undef> if a non-alphanumeric character is found in the string.

=cut

sub canonicalize {
    my $self = shift;
    my $str  = uc(shift);
    my $result = '';
    for my $char (split(//,$str)) { # Would tr/// be better?
        return undef unless defined $CHAR_TO_INT{$char};
        my $char = defined $CHAR_REMAP{$char} ? $CHAR_REMAP{$char} : $char;
        $result .= $char;
    }
    return $result;
}

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-number-recordlocator@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Jesse Vincent  C<< <jesse@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;
