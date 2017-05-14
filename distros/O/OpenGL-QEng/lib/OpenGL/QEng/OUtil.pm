###  $Id: OUtil.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------

## @file
# Implements OUtil class
#

## @class OUtil
# Base class that provides two useful capabilities for objects:<br>
# 1. passegArgs - Ensure that passed attributes exist for the class<br>
# 2. create_accessors - create accessor methods for each class attribute

package OpenGL::QEng::OUtil;

use strict;
use warnings;
use Carp;

#---------------------------------------
## @method new($class);
# Unused new for the base class, no base class objects should exist
sub new {
  warn 'totally boring class: ',$_[0];
  bless({}, shift);
}

#---------------------------------------
## @method passedArgs($self,$propHash);
# Verify that this hash contains the passed keys and set the key values
sub passedArgs {
  my ($self, $argHashRef) = @_;

  foreach my $k (keys %$argHashRef)  {
    unless (exists($self->{$k})) {
      confess "No $k in class ",ref $self;
    }
    $self->{$k} = $argHashRef->{$k};
  }
  return;
}

#---------------------------------------
## @method $ create_accessors($self)
#  add accessor methods for each instance attribute
sub create_accessors {
  my ($self) = @_;

  my $wrap_class = 0;
  for my $attribute (keys %$self) {
    if ($attribute eq 'wrap_class') {
      $wrap_class = (defined $self->{wrap_class}) ? 1 : 0;
      next;
    }
    unless ($self->can($attribute)) {
      no strict 'refs';
      my $attr = $attribute;
      *{$attr} = sub {
	die "$_[0] has no $attr in hash ",join(':',caller)
	  unless exists $_[0]->{$attr};
	return unless exists $_[0]->{$attr};
	$_[0]->{$attr} = $_[1] if defined $_[1];
	$_[0]->{$attr};
      };
    }
  }
  $self = $self->wrap_class if $wrap_class;
}

#---------------------------------------
{;
 my $classname = 'XAAAAA';

 sub wrap_class {
   my ($self) = @_;

   my $class = $classname++;
   {
     no strict 'refs';
     push @{"$class\::ISA"}, ref($self);

     unless (ref $self->{wrap_class} eq 'HASH') {
       my $cmdTxt = '$self->{wrap_class} = ' .$self->{wrap_class};
       eval $cmdTxt;
       if ($@) {
	 print STDERR "EVAL ($cmdTxt) FAILED: $@\n";
	 print STDERR "wrap_class failed for $self\n";
	 return;
       }
     }
     for my $method (keys %{$self->{wrap_class}}) {
       *{$class.'::'.$method} = $self->{wrap_class}{$method};
     }
   }
   return bless($self, $class);
 }
}

#==============================================================================
1;

=head1 NAME

OUtil -- Base class that provides useful capabilities for objects

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

