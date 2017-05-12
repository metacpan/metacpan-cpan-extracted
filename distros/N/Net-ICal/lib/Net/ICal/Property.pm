#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Property.pm,v 1.16 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

# eek. 44 subclasses

=head1 NAME

Net::ICal::Property -- base class for ICalender properties

=cut

package Net::ICal::Property;
use strict;

use UNIVERSAL;
use base qw(Class::MethodMapper);

=head1 SYNOPSIS

Creating a property from a ical string:
    $p = Net::ICal::Property->new_from_ical ($str);

print out an ical string
    print $p->as_ical;

=head1 DESCRIPTION

This is the base class from which you derive specific ICal properties.

=head1 CONSTRUCTORS

=head2 new ($name, $map, %args)

You never call this directly. Instead you call the new constructor for
a specific property type, which in turn calls this:

    $p = Net::ICal::Trigger (300);

=begin testing

TODO: {
    local $TODO = "We need to write tests here";

    ok(0, 'write tests for new()');

}
=end testing

=cut

sub new {
   my ($classname, $name, $map, %args) = @_;

   if (not defined $map->{content}) {
      warn "not a proper property\n";
      return undef;
   }

   $map->{name} = {
      type => 'volatile',
      doc => 'the ICalendar name of the property',
      value => $name,
   };

   my $self = new Class::MethodMapper;
   bless $self, $classname;
   $self->set_map (%$map);
   $self->set (%args);

   return $self;
}

=begin testing

# TODO: write tests
TODO: {
    local $TODO = "write tests here, please; patches welcome";
    ok(0, 'write tests for _reclass_set()');
}
=end testing

=cut
sub _reclass_set {
   my ($self, $key, $val) = @_;

   my ($class) = $self =~ /^(.*?)=/g;

   foreach my $pclass (values %{$self->get_meta ('options', $key)}) {
      if (UNIVERSAL::isa ($val, $pclass)) {
	 $self->{$key}->{value} = $val;
	 return;
      }
   }
   warn "${class}->$key: '$val' is not a type of class. "
      . "using 'undef' instead.\n";
   $self->{$key}->{value} = undef;
}

=head2 new_from_ical ($ical)

Creates a new Net::ICal property from a string in ICal format

=begin testing

# TODO: write tests
TODO: {
    local $TODO = 'write tests here please';
    ok(0, 'write tests for new_from_ical()');
}
=end testing

=cut

sub new_from_ical {
   my ($class, $ical) = @_;

   my ($prop) = $ical =~ /^(\w+)[;:]/g;
   unless ($prop) {
      warn "Not a valid ical stream\n";
      return undef;
   }
   my $self = $class->_create;

   my $cb = sub {
      return undef if $ical eq "";
      if ($ical =~ /^;/) {
	 #FIXME: make this more robust (; in "" inside a field is possible
	 #BUG: 133739
	 $ical =~ s/;(.*?)\=(.*?)(;|$)/$3/;
	 #FIXME: make sure we definitely don't need anything but plain
	 #       key/value
	 my ($name, $value) = ($1, $2);
	 $name =~ s/\W/_/g;
	 return (lc($name), $value);
      } else {
	 $ical =~ s/^.*?([;:])/$1/;
	 # this too
	 $ical =~ s/:(.*?)$//;
	 my $value = $1;

	 # Check if this is a property that can be one of several
	 # classes. determine what class with regexps
	 if ($self->get_meta ('domain', 'content')) {
	    if ($self->get_meta ('domain', 'content') eq 'reclass') {
	       my %rehash = %{$self->get_meta ('options', 'content')};
	       my $default = delete $rehash{'default'};
	       foreach my $re (keys %rehash) {
		  if ($value =~ /$re/) {
		     my $class = $rehash{$re};
		     eval "require $class";
		     my $param = $class->new ($value);
		     return ('content', $param);
		  }
	       }
	       eval "require $default";
	       my $param = $default->new ("$value");
	       return ('content', $param);
	    }
	 #FIXME: we may need to handle 'ref' and 'enum' domains too
	 } else {
	    return ('content', $value);
	 }
      }
   };
   $self->restore ($cb);
   return $self;
}

=head1 METHODS

=head2 name([$name])

Get or set the name of the property. You're not supposed to actually
ever set this manually. It will be set by the new method of the
property type you are creating.

=head2 as_ical

returns an ICal string describing the property

=begin testing

# TODO: write tests
TODO: {
    local $TODO = "write these tests";
    ok(0, 'write tests for as_ical()');
}
=end testing

=cut

sub as_ical {
   my ($self) = @_;
   my $ical;

   my $cb = sub {
      my ($self, $key, $value) = @_;
      $key =~ s/_/-/g;
      $key = uc ($key);

      return unless defined $value->{value};
      if ($value->{domain} eq 'ref') {
	 if ($value->{options} eq 'ARRAY') {
	    foreach my $val (@{$value->{value}}) {
	       if (ref ($val)) {
		  $ical .= ";" . $key . "=" . $val->as_ical_value();
	       } else {
		  $ical .= ";" . $key . "=$val";
	       }
	    }
	 } elsif ($value->{options} eq 'HASH') {
	    # hash param (FIXME: will this ever be used?)
	 } else {
	    # assume it's a class
	    $ical .= ";" . $key . "=" . $value->{value}->as_ical_value;
	 }
      } else {
	 $ical .= ";" . $key . "=" . $value->{value};
      }
   };

   $self->save ('parameter', $cb);

   if (ref ($self->content)) {
      $ical .= ":" . $self->content->as_ical_value;
   } else {
      $ical .= ":" . $self->content;
   }
   return $ical;
}

1;

=head1 SEE ALSO

L<Net::ICal>, L<Class::MethodMapper>

=cut
