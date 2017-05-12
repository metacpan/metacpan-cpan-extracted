#!/usr/bin/perl -w
# -*- Mode: perl -*-
#======================================================================
#
# This package is free software and is provided "as is" without
# express or implied warranty.  It may be used, redistributed and/or
# modified under the same terms as perl itself. ( Either the Artistic
# License or the GPL. )
#
# $Id: Component.pm,v 1.48 2001/08/04 04:59:36 srl Exp $
#
# (C) COPYRIGHT 2000-2001, Reefknot developers.
#
# See the AUTHORS file included in the distribution for a full list.
#======================================================================

=head1 NAME

Net::ICal::Component -- the base class for ICalender components

=cut

package Net::ICal::Component;
use strict;

use UNIVERSAL;
use base qw(Class::MethodMapper);

use Net::ICal::Util qw(add_validation_error);
=head1 SYNOPSIS

You never create an instance of this class directly, so we'll assume
$c is an already created component.

  # returns an ICal string for this component.
  $c->as_ical;

=head1 DESCRIPTION

This is the base class we derive specific ICal components from.
It contains a map of properties which can be set and accessed at will;
see the docs for Class::MethodMapper for more on how it works.

=begin testing
use lib "./lib";
use Net::ICal;

$comp = new Net::ICal::Alarm(
    action => 'DISPLAY',
    trigger => "20000101T073000",
    description => "Wake Up!"
);

=end testing

=head1 CONSTRUCTORS

=head2 new($name, $map, %args)

Creates a new ICal component of type C<$name>, with Class::MethodMapper
map C<$map> and arguments C<%args>. You never call this directly, but
you use the specific component's new constructor instead, which in turn
calls this.

=begin testing
TODO: {
    local $TODO = "write tests for the new method, please";
    ok(0, "need tests here");
};
=end testing
=cut

sub _param_set {
   #TODO: allow things like $foo->description ("blah blah", altrep => 'foo');
   my ($self, $key, $val) = @_;
   my ($class) = $self =~ /^(.*?)=/g;

   my @params = @{$self->get_meta ('options', $key)};
   if (ref($val) eq 'HASH') {
      foreach my $param (keys %$val) {
	 unless (grep { $_ eq lc($param) } ('content', @params)) {
	    warn "${class}->$key has no $param parameter. skipping.\n";
	    delete $val->{$param};
	 }
      }
      $self->{$key}->{value} = $val;
   } else {
      $self->{$key}->{value} = { content => $val };
   }
}

sub new {
   my ($classname, $name, $map, %args) = @_;

   #TODO: WTF is a type 'volatile' and why are we using it?
   #       The Class::MethodMapper docs say that "Generally, a 
   #       `parameter' is something that can be saved and restored, 
   #       whereas a `volatile' is not serialized at save-time."
   #       Can someone clarify this? --srl
   #BUG: 424107
   $map->{'type'} = {
      type => 'volatile',
      doc => 'type of the component',
      value => $name
   };
    # So we can keep a list of validation errors for Net::ITIP
    $map->{'errlog'} = {
	type => 'volatile', # we don't want to see this in serialized data
	doc => 'list of (ITIP) validation errors',
	domain => 'ref',
	options => 'ARRAY',
	value => [],
    };


   # FIXME: handle X-properties here.
   # BUG: 411196

   my $self = new Class::MethodMapper;
   bless $self, $classname;
   $self->set_map (%$map);
   $self->set (%args);

   return $self;
}


=head2 new_from_ical($icaldata)
   
Creates a new Net::ICal::Component from a string containing iCalendar
data.  Use this to read in a new object before you do things with it. 

Returns a Net::ICal::Component object on success, or undef on failure.

=cut

sub new_from_ical {
   my ($class, $ical) = @_;

   # put the string into something for the callback function below to use
   my @lines = split (/\015?\012/, $ical);		# portability

   #FIXME: this should return undef if the ical is invalid
   #BUG: 424109
   return _parse_lines (\@lines);
}

=pod

=head1 METHODS

=head2 type ([$string])

   Get or set the type of this component. You aren't supposed to ever
   set this directly. To create a component of a specific type, use
   the new method of the corresponding class.


=head2 validate

Returns 1 if the component is valid according to RFC 2445. If it isn't
undef is returned, and $@ contains a listref of errors

=cut

sub validate {
    my ($self) = @_;

    if (@{$self->errlog}) {
	$@ = $self->errlog;
	return undef;
    } else {
	return 1;
    }
}

=head2 as_ical

Returns an ICal string that represents this component

=begin testing
TODO: {
    local $TODO = 'write tests for as_ical';
    ok(0, "need tests here");
};
=end testing
=cut

sub as_ical {
   my ($self) = @_;

   # make the BEGIN: VALARM line, or whatever
   my $ical = "BEGIN:" . $self->type . "\015\012";

   # this is a callback that Class::MethodMapper will use
   # to generate the ical text.
   my $cb = sub {
      my ($self, $key, $value) = @_;
      my $line;

      $key =~ s/_/-/g;
      $key = uc ($key);

      return unless $value->{value};

      # if this object is just a reference to something, look at that object.
      if (not defined $value->{domain}) {
	 $line .= $key . ":" . $value->{value} . "\015\012";
      } elsif ($value->{domain} eq 'ref') {
	 if ($value->{options} eq 'ARRAY') {
	    # for every line in this array, if it's a ref, call the
	    # referenced object's as_ical method; otherwise output a
	    # key:value pair.
	    foreach my $val (@{$value->{value}}) {
	       if (ref ($val)) {
		  if (UNIVERSAL::isa ($val, 'Net::ICal::Property')) {
		     $line .= $key . $val->as_ical . "\015\012";
		  } else {
		     $line .= $val->as_ical();
		  }
	       } else {
		  $line .= $key . ":$val\015\012";
	       }
	    }
	 } elsif ($value->{options} eq 'HASH') {
	 } else {
	    # assume it's a class, and call its as_ical method
	    $line .= $key . $value->{value}->as_ical . "\015\012";
	 }

     # if this is a thing without its own subclass, it's a hashref.
     # output the key value (DESCRIPTION, for example) and then
     # the hash's keys and values like ";key=value".

      } elsif ($value->{domain} eq 'param') {
	 my $xhash = $value->{value};
	 $line = $key;
		 
	 # the 'content' key is the name of this property.
	 foreach my $xkey (keys %$xhash) {
	    next if ($xkey eq 'content');
	    $line .= ';' . uc ($xkey) . "=" . $xhash->{$xkey};
	 }
	 $line .= ":" . $xhash->{content} . "\015\012";

     # otherwise just output a key-value pair.
      } else {
	 $line .= $key . ":" . $value->{value} . "\015\012";
      }
      $ical .= $line;
   };
   
  # call the Class::MethodMapper callback.
  $self->save ('parameter', $cb);

  # OUTPUT END:VALARM or whatever.
  $ical .= "END:" . $self->type . "\015\012";
  return $ical;
}

=head2 has_one_of (@propertynames)

returns a true value if one of the listed property names is present
on the component and undef if not

=for testing
ok($comp->has_one_of ('action', 'attendee'), "we have action, so pass");
ok(not($comp->has_one_of ('summary', 'attendee')), "we have neither summary nor attendee so fail");

=cut

sub has_one_of {
    my ($self, @props) = @_;

    foreach my $prop (@props) {
	return 1 if defined ($self->get ($prop));
    }
    return undef;
}

=head2 has_required_property (name, [value])

checks whether the component has a value for property 'name' and
optionally checks whether it is value 'value'

=for testing
ok($comp->has_required_property ('action'), "we have action, so pass");
ok(not($comp->has_required_property ('summary')), "we don't have summary so fail");
ok($comp->has_required_property ('action','DISPLAY'), "action contains 'DISPLAY', so pass");
ok(not($comp->has_required_property ('action','nonsense')), "action doesn't contain 'nonsense', so fail");

=cut

sub has_required_property {
    my ($self, $property, $value) = @_;

    do {
	$@ = $self->type . " needs a " .
	     $property . " property for this method";
	return undef;
    } unless (defined $self->get ($property));

    if (defined $value) {
	do {
	    $@ = "$property needs to be set to $value for this method";
	    return undef;
	} unless ($self->get ($property) eq $value);
    }

    return 1;
}

=head2 has_illegal_property (name)

checks whether the component has a value for property 'name' and
returns a true value if it has, and undef if it doesn't

=for testing
ok($comp->has_illegal_property ('action'), "we have action, so fail");
ok(not($comp->has_illegal_property ('attendee')), "we don't have attendee so pass");

=cut

sub has_illegal_property {
    my ($self, $property) = @_;

    do {
	$@ = "$property not allowed for this method";
	return 1;
    } if defined ($self->get ($property));
	
    return undef;
}

=head2 has_only_one_of (name1, name2)

returns undef if both the properties name1 and name2 are present. Otherwise,
it returns a true value. On error, it sets $@.

=for testing
ok($comp->has_only_one_of ('action', 'summary'), "we have action, and not summary, so pass");
ok(not($comp->has_only_one_of ('action', 'trigger')), "we have both action and trigger, so fail");
ok($comp->as_only_one_of ('foo', 'bar'), "we have neither, so pass");

=cut

sub has_only_one_of {
    my ($self, $prop1, $prop2) = @_;

    my $val1 = $self->get ($prop1);
    my $val2 = $self->get ($prop2);
    do {
	$@ = "Properties $prop1 and $prop2 are mutually exclusive for this method";
	return undef;
    } if (defined ($val1) and defined ($val2));

    #return (defined ($val1) or defined ($val2));
    return 1;
}

=pod

=head1 INTERNAL METHODS

These are for internal use only, and are included here for the benefit
of Net::ICal developers.


=head2 _identify_component($line)

the first line of the iCal will look like BEGIN:VALARM or something.
we need to know what comes after the V, because that's what
sort of component we'll be creating.

Returns ALARM, EVENT, TODO, JOURNAL, FREEBUSY, etc, or undef for
failure.

=for testing
ok(&Net::ICal::Component::_identify_component("BEGIN:VTODO") eq "TODO", "Identify TODO component");
ok(Net::ICal::Component::_identify_component("BeGiN:vToDo") eq "TODO", "Identify mixed case component");
ok(not(Net::ICal::Component::_identify_component("BEGIN:xyzzy")), "can't identify nonsense component");
ok(not(Net::ICal::Component::_identify_component("")), "can't identify component in empty string");
ok(not(Net::ICal::Component::_identify_component()), "can't identify component in undef");
ok(not(Net::ICal::Component::_identify_component(123)), "can't identify component in number");
=cut

sub _identify_component {
   my ($line) = @_;

   my ($bogus, $comp) = $line =~ /^BEGIN:(V)?(\w+)$/gi;

   return uc($comp) || undef;
}

=pod

=head2 _create_component($comp)

$comp is "ALARM" or something. We generate the name of a type of object
we want to create, and call the _create method on that object. 

=for testing
ok(Net::ICal::Event::_create_component("TODO"), "Create TODO component");
ok(not(Net::ICal::Event::_create_component("xyzzy")), "Can't create nonsense component");
ok(not(Net::ICal::Event::_create_component("")), "Can't create component from empty string");
ok(not(Net::ICal::Event::_create_component()), "Can't create component from undef");

=cut

sub _create_component {
   my ($comp) = @_;

   $comp = "Net::ICal::" . ucfirst (lc ($comp));
   eval "require $comp";
   if ($@) {
      $@ = "Unknown component $comp";
      return undef;
   }

   return $comp->_create;
}


=pod

=head2 _unfold(@lines)

Handle multiline fields; see "unfolding" in RFC 2445.  Make all the
multiple fields we've been handed into single-line fields.

=for testing
my $unfoldlines = [];
ok(Net::ICal::Event::_unfold($unfoldlines), "Unfold valid iCal lines");
ok(not(Net::ICal::Event::_unfold("x\ny\nz\n")), "Can't unfold invalid iCal lines");

=cut

sub _unfold {
    my ($lines) = @_;

    my $line = shift @$lines;
    while (@$lines and $lines->[0] =~ /^ /) {
        chomp $line;
        $line .= substr (shift @$lines, 1);
    }
    return $line;
}

=pod

=head2 _fold($line)

=cut

sub _fold {
   my ($line) = @_;
   my $folded;

   while (length $line > 76) {
      # don't break lines in the middle of words
      $line =~ s/(.{1,76}\W)//;
      # when we wrap a line, use this as a newline
      $folded .= $1 . "\015\012 ";
   }
   return $folded;
}

=pod

=head2 _parse_lines(\@lines)

Parse and validate the lines of iCalendar data we got to make sure it 
looks iCal-like.

=cut

sub _parse_lines {
   my ($lines) = @_;

   my $comp = _identify_component(shift @$lines);
   unless ($comp) {
      warn "Not a valid ical stream\n";
      return undef;
   }

   my $self = _create_component($comp);
   unless ($self) {
      while (shift @$lines) {
	 last if /^END/;
      }
      return undef;
   }

   # give a callback for Class::MethodMaker to call when it
   # restores the data from @lines.

   my $cb = sub {
      return undef unless @$lines;

      my $line = _unfold($lines);    

      if ($line =~ /^BEGIN:/) {
	 unshift (@$lines, $line);
	 my $foo = _parse_lines ($lines);

	 # Calendar.pm has alarms/todos/etc methods, so add the s
	 my $name = lc (_identify_component ($line)) . 's';

	 # see if there's already an existing list
	 my $ref = $self->get ($name) || ();

	 # move to parse errors from child components to our log
	 if ($foo) {
	    push (@{$self->errlog}, @{$foo->errlog});
	    push (@$ref, $foo);
	 } else {
	    if (ref ($@)) {
	       push (@{$self->errlog}, @{$@});
	    } else {
	       add_validation_error ($self, $@);
	    }
	 }
	 return ($name, $ref);

      } elsif ($line =~ /^END:(\w+)$/) {
	 return undef;
      } else {
	 # parse out the iCalendar lines.
	 my ($key, $value)      = _parse_property($line);
	 my ($class, $paramstr) = _parse_parameter($key);

	 $class = lc ($class);
	 # make sure we have a valid function name
	 $class =~ s/-/_/g;

	# FIXME: handle X-properties here.
	# BUG: 411196

	 if (not defined $self->get_meta ('type', $class)) {
	    add_validation_error ($self, "There is no $class method");
	    return ('type', $self->get_meta ('value', 'type'));
	 }
	 # avoid warnings for doing eq with undef below
	 # no domain means simple string/integer, so only
	 # one of them is allowed
	 if (not defined $self->get_meta ('domain', $class)) {
	    my $old = $self->get_meta ('value', lc($key));
	    if ($old) {
		add_validation_error ($self, "Only one $key allowed; skipping");
		return ($class, $old);
	    }
	    return ($class, $value);
	 # we either have an array of values, or a class for the
	 # property
	 } elsif ($self->get_meta ('domain', $class) eq 'ref') {
	    
	    # set up the array to refer to. It may be an array of objects
	    # or just an array of values; _load_property will do either.
	    if ($self->get_meta ('options', $class) eq 'ARRAY') {
	       # the array elements can be refs too
	       my $prop = _load_property ($class, $value, $line);
	       unless (defined $prop) {
		  add_validation_error ($self, "Error loading property $key");
	       }
	       my $val = $self->get_meta ('value', $class);
	       if (defined $val) {
		  push (@$val, $prop);
		  return ($class, $val);
	       } else {
		  return ($class, [$prop]);
	       }
	    } else {
	       # if this thing we're looking at needs to be made a
	       # Net::ICal::subclass object, load that module and call that
	       # subclass's new_from_ical method on this line of ical text.
	       my $prop = _load_property ($self->get_meta ('options', $class),
	                                  $value, $line);
	       unless (defined $prop) {
		  add_validation_error ($self, "Error loading property $key");
	       }
	       return ($class, $prop);
	    }

      # if there are parameters for this thing, but not an actual subclass,
      # build a hash and return a reference to it. See, for example,
      # DESCRIPTION fields, which can have an ALTREP (like a URL) or a
      # LANGUAGE. We don't need a separate class for it; a hash will suffice.

	 } elsif ($self->get_meta ('domain', $class) eq 'param') {
	    my @params = $paramstr ? split (/;/, $paramstr) : ();
	    my %foo = (content => $value);

	    foreach my $keyvalue (@params) {
	       my ($pkey, $pvalue) = split (/=/, $keyvalue);
	       $foo{$pkey} = $pvalue;
	    }
	    return ($class, \%foo);
	 }
      }
   };
   $self->restore($cb);

   my $warnings;
   if (@{$self->errlog}) {
      # save parse errors
      $warnings = $self->errlog;
      # empty the errlog, since parse errors don't have to be fatal
      $self->errlog ([]);
   }

   if ($self->validate) {
      # if we passed, put back the parse errors, which apparently
      # really were non-fatal
      $self->errlog ($warnings) if (defined $warnings);
      return $self;
   } else {
      # oops, we didn't validate. Might be because of those parse
      # errors. put those at the start.
      unshift (@{$@}, @$warnings) if (defined $warnings);
      return undef;
   }
}

=pod

=head2 _parse_property($property)

Given a property line from an iCalendar file, parses it and returns the
name and the value of that property.

=for testing
ok(0, "need tests here");

=cut


#FIXME: these will break if there's a : in a parameter value.  We're also 
#       not handling FOO:value1,value2 properly. 
#BUG: 233739
sub _parse_property {
   my ($prop) = @_;

   my ($name, $value) = $prop =~ /^(.*?):(.*)$/g;

   return ($name, $value);
}

=pod

=head2 _parse_parameter($propname)

Given a property name/key section, parses it and returns the param name and
the parameter string.

=for testing
ok(0, "need tests here");

=cut

sub _parse_parameter {
   my ($propname) = @_;

   my ($paramname, $paramstr) = $propname =~ /^(.*?)(?:;(.*)|$)/g;
   return ($paramname, $paramstr);
}

=pod

=head2 _load_property($class, $value, $line)

If a new ICal subclass object needs to be created, load the module
and return a new instance of it. Otherwise, just return the value
of the property.

=for testing
ok(0, "need tests here");

=cut 

sub _load_property {
   my ($class, $value, $line) = @_;

   #FIXME: How do we want to handle this?  Do we really want
   #       separate packages for Rrule and Exrule, and subclass them?
   $class =~ s/\b(?:rrule|exrule)$/recurrence/i;
   unless ($class =~ /::/) {
      $class = "Net::ICal::" . ucfirst (lc ($class));
   }
   my $prop;
   eval "require $class";
   unless ($@) {
      if ($class->can ('new_from_ical')) {
	 return $class->new_from_ical($line);
      } else {
	 # for things like Time, which are just a value, not a Property,
	 # so they don't have new_from_ical
	 return $class->new (ical => $value);
      }
   } else {
      return $value;
   }
}

1;

=head1 SEE ALSO

=head2 Net::ICal

    More documentation pointers can be found in L<Net::ICal>.

=head2 Class::MethodMapper

    Most of the internals of this code are built on C::MM. You need to
    understand what it does first.

=cut
