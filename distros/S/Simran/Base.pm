##################################################################################################################
# 
# Source       : $Source: /home/simran/cvs/cpan/Simran/Base.pm,v $
# Revision     : $Revision: 1.1.1.1 $
# Modified By  : $Author: simran $
# Last Modified: $Date: 2002/12/04 03:46:29 $
#
##################################################################################################################

package Simran::Base;

##################################################################################################################
#
# load modules as required...
#
#
use 5.008;
use strict;
use warnings;

##################################################################################################################
#
# 
#

=pod

=head1 NAME

Simran::Base - This is the base class for all modules in the Simran:: area.

=head1 SYNOPSIS

 use base qw(Simran::Base);

=head1 DESCRIPTION

This class should never be instantiated directly.  

You should only be inheriting from it.

=head1 METHODS

=cut

##################################################################################################################
#
# GLOBALS
#
our $VERSION = '0.01';

##################################################################################################################
#
# PUBLIC METHODS
#

####################################
#
# new
#

=head2 new

=over

=item Description

 Provide a standard "new" method for all classes that inherit from this class.

=item Input

  * A HASH of name/value pairs you want to set as properties
    A property can be referenced as such (after being set):
      $object->{property_name};
      (the properties are set via the _init method)

    Note: This new method calls $self->_init(@_) and expects '1' or 'undef' depending on if the _init was successful

=item Return

 * An Object - if all was well
   undef     - otherwise

=item Method Type

 * This method should be used as a class method only

=back

=cut

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = {};

   bless $self, $class;
   $self->_init(@_) || return $self->setError("Could not initlalise object: ".$self->getError());
   return $self;
}

####################################
#
# setError
#

=head2 setError

=over

=item Description

This method sets the error to the message that you provide for the calling module.

=item Input

 * @errors   - Error Messages

=item Return

 * undef - This function returns undef so you can do things like:

           return $self->setError("No User Specified");

           in your code. 

=item Note

 * Sets the variable Your::Class::Name::_ErrorMessages although this variable
   should never be used directly. 

=item Method Type

 * This method can be used as a class or object method

=back

=cut

sub setError {
  my $self  = shift;
  my $class = ref($self) || $self;
  my @error = @_;

  {
    no strict qw(refs);
    ${$class.'::_ErrorMessages'} = \@error;
    use strict;
  }

  return;
}

####################################
#
# getError
#

=head2 getError

=over

=item Description

This method returns the last error message for the calling module... 

=item Input

 * None

=item Return

 * @errors   - Errors as set by setError

=item Method Type

 * This method can be used as a class or object method

=back

=cut

sub getError {
  my $self  = shift;
  my $class = ref($self) || $self;

  my $error;
  {
    no strict qw(refs);
    $error = ${$class.'::_ErrorMessages'};
    use strict;
  }

  if ($error && ref($error)) { return @$error; }
  else                       { return $error; }
}

############################################
# strip
#

=head2 strip

=over

=item Description

Strips out leading and training whitespaces from references... 

=item Input

  * Reference to an array, hash or string
    or
    A string

=item Return

  * If input was a reference then, None - The reference passed as input is modified... 
    Else, the stripped string

=item Method Type

 * This method can be used as a class or object method

=back

=cut


sub strip {
  my $self = shift;
  my $ref  = shift;

  if (! ref($ref)) {
    $ref =~ s/(^[\s\t]*)|([\s\t]*$)//g;
    return $ref;
  }
  elsif (ref($ref) =~ /^ARRAY$/i) {
    foreach my $i (0 .. $#$ref) {
      $ref->[$i] =~ s/(^[\s\t]*)|([\s\t]*$)//g;
    }
  }
  elsif (ref($ref) =~ /^HASH$/i) {
    while (my ($key, $value) = each %$ref) {
      delete $ref->{$key};
      $key         =~ s/(^[\s\t]*)|([\s\t]*$)//g;
      $value       =~ s/(^[\s\t]*)|([\s\t]*$)//g;
      $ref->{$key} = $value;
    }
  }
  elsif (ref($ref) =~ /^SCALAR$/i) {
    $$ref =~ s/(^[\s\t]*)|([\s\t]*$)//g;
  }
  else {
    die "Unknown reference type";
  }
}

##################################################################################################################
#
# PRIVATE METHODS
#

####################################
# _init
#
# Initialize the class
#
# Input: A Hash
#        eg.  $self->_init(carp=>1, logfile=>"/tmp/log.txt")
#        Note: All properties passed are set
#
# Return Values: 1
#
#
sub _init {
  my $self       = shift;
  my %properties = @_;

  foreach (keys %properties) {
    my $property = $_;
    $self->{$property} = $properties{$_};
  }

  return 1;
}


1;

=head1 AUTHOR

Simran, E<lt>simran@cse.unsw.edu.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by simran

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
