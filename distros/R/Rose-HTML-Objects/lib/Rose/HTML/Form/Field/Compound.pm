package Rose::HTML::Form::Field::Compound;

use strict;

use Carp();

use Rose::HTML::Object::Errors qw(:field);
use Rose::HTML::Object::Messages qw(:field);

use base qw(Rose::HTML::Form::Field Rose::HTML::Form::Field::Collection);

use Rose::HTML::Form::Constants qw(FF_SEPARATOR);

our $VERSION = '0.611';

# Multiple inheritence never quite works out the way I want it to...
Rose::HTML::Form::Field::Collection->import_methods
(
  'hidden_field',
  'hidden_fields',
  'html_hidden_field',
  'xhtml_hidden_field',
  'html_hidden_fields',
  'xhtml_hidden_fields',
);

our $Debug = undef;

sub init
{
  my($self) = shift;
  my(%args) = @_;

  if(exists $args{'name'})
  {
    $self->name(delete $args{'name'});
  }
  else
  {
    Carp::croak __PACKAGE__, "-derived fields require a 'name' parameter in the constructor";
  }

  $self->{'fields'} ||= {};

  $self->build_field();

  local $self->{'in_init'} = 1;
  $self->SUPER::init(@_);
}

sub is_flat_group { 0 }

sub children 
{
  Carp::croak "Cannot set children() for a pseudo-group ($_[0])"  if(@_ > 1);
  return wantarray ? () : [];
}

sub value { shift->input_value(@_) }

sub build_field { }

sub init_fields
{
  my($self, %fields) = @_;

  foreach my $field_name (keys %fields)
  {
    my $field = $self->field($field_name) || 
      Carp::croak "No such field: $field_name";

    if($field->isa('Rose::HTML::Form::Field::Group'))
    {
      $Debug && warn "$self $field_name(s) = $fields{$field_name}\n";
      $field->_set_input_value($fields{$field_name});
    }
    else
    {
      $Debug && warn "$self $field_name = $fields{$field_name}\n";
      $field->_set_input_value($fields{$field_name});
    }
  }
}

sub html_field  { join('', map { $_->html_field } shift->fields)  }
sub xhtml_field { join('', map { $_->xhtml_field } shift->fields) }

sub resync_name
{
  my($self) = shift;

  $self->SUPER::resync_name();
  $self->resync_field_names;
}

sub name
{
  my($self) = shift;

  if(@_)
  {
    $self->local_name(shift);
    $self->resync_field_names;
    return $self->fq_name;
  }

  return $self->fq_name;
}

sub clear
{
  my $self = shift;

  $self->_set_input_value(undef);
  $self->clear_fields();
  $self->error(undef);
  $self->SUPER::clear();
}

sub reset
{
  my($self) = shift;

  $self->reset_fields();  
  $self->SUPER::reset();
  $self->is_cleared(0);
}

sub decompose_value { {} }

# Evil hash grab for efficiency.  May change to shift->input_value()
# if it becomes a problem someday...
sub coalesce_value  { shift->{'input_value'} }

sub distribute_value
{
  my($self, $value, $type) = @_;

  #$type ||= 'input_value';

  my $method = ((!$type || $type eq 'input_value')) ? '_set_input_value' : $type;

  if(my $split = $self->decompose_value($value))
  {
    while(my($name, $val) = each(%$split))
    {
      #$self->field($name)->$type($val);
      $self->field($name)->$method($val);
    }
  }
}

sub default_value
{
  my($self) = shift;

  if(@_)
  {
    my $value = $self->SUPER::default_value(@_);
    $self->distribute_value($value, 'default_value');
  }

  return $self->SUPER::default_value;
}

*auto_invalidate_parents = \&Rose::HTML::Form::Field::auto_invalidate_parents;

sub invalidate_value
{
  my($self) = shift;

  $self->SUPER::invalidate_value();

  if($self->_is_full)
  {
    $self->_set_input_value($self->coalesce_value);
  }
  else
  {
    if($self->is_empty)
    {
      $self->has_partial_value(0);
    }
    else
    {
      $self->has_partial_value(1);
    }

    $self->_set_input_value(undef);
  }

  my $parent = $self->parent_field;

  if($parent)
  {
    $parent->invalidate_value();
  }

  return;
}

sub subfield_input_value
{
  my($self, $name) = (shift, shift);
  my $field = $self->field($name) or Carp::croak "No such subfield '$name'";
  $field->_set_input_value(@_);
}

sub input_value
{
  my($self) = shift;

  if(@_)
  {
    my $value = $self->SUPER::input_value(@_);

    if((my $parent = $self->parent_field) && $self->auto_invalidate_parent)
    {
      $parent->invalidate_value;
    }

    $self->distribute_value($value, 'input_value');
  }

  my $ret = $self->SUPER::input_value;

  if(defined $ret || $self->is_empty || $self->has_partial_value)
  {
    return $ret;
  }

  return $self->coalesce_value;
}

sub is_empty
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    return 0  unless($field->is_empty);
  }

  return 1;
}

sub is_full
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    return 0  if($field->is_empty);
  }

  return 1;
}

sub validate
{
  my($self) = shift;

  if($self->required)
  {
    my @missing;

    foreach my $field ($self->fields)
    {
      no warnings 'uninitialized';
      unless(length $field->input_value_filtered)
      {
        push(@missing, sub { $field->error_label || $field->local_name });
      }
    }

    if(@missing)
    {
      if(@missing == $self->num_fields)
      {
        return $self->SUPER::validate(@_);
      }

      $self->error_id(FIELD_REQUIRED, { missing => \@missing });
      return 0;
    }
  }

  return $self->SUPER::validate(@_);
}

sub disabled
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    $field->disabled(@_)  if($field->can('disabled'));
  }
}

sub message_for_error_id
{
  my($self, %args) = @_;

  my $error_id  = $args{'error_id'};
  my $msg_class = $args{'msg_class'};
  my $args      = $args{'args'} || [];

  no warnings 'uninitialized';
  if($error_id == FIELD_REQUIRED)
  {
    my $msg = $msg_class->new(args => $args);

    if(ref $args eq 'HASH' && keys %$args)
    {
      if($args->{'missing'})
      {
        if(@{$args->{'missing'}} > 1)
        {
          $msg->id(FIELD_REQUIRED_SUBFIELDS);
        }
        else
        {
          $msg->id(FIELD_REQUIRED_SUBFIELD);
        }
      }
      else
      {
        $msg->id(FIELD_REQUIRED_LABELLED);
      }
    }
    else
    {
      $msg->id(FIELD_REQUIRED_GENERIC);
    }

    return $msg;
  }

  return undef;
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

FIELD_REQUIRED_SUBFIELD  = "Missing [@missing]."
FIELD_REQUIRED_SUBFIELDS = "Missing [@missing]."

[% LOCALE de %]

FIELD_REQUIRED_SUBFIELD  = "[@missing] fehlt."
FIELD_REQUIRED_SUBFIELDS = "[@missing] fehlen."

[% LOCALE fr %]

FIELD_REQUIRED_SUBFIELD  = "Le champ [@missing] manque."
FIELD_REQUIRED_SUBFIELDS = "Les champs [@missing] manquent."

[% LOCALE bg %]

FIELD_REQUIRED_SUBFIELD  = "Непопълнени поле [@missing]."
FIELD_REQUIRED_SUBFIELDS = "Непопълнени полета [@missing]."

__END__

=head1 NAME

Rose::HTML::Form::Field::Compound - Base class for field objects that contain other field objects.

=head1 SYNOPSIS

    package MyFullNameField;

    use base qw(Rose::HTML::Form::Field::Compound
                Rose::HTML::Form::Field::Text);

    sub build_field
    {
      my($self) = shift;

      $self->add_fields
      (
        first  => { type => 'text', size => 15, maxlength => 50 },
        middle => { type => 'text', size => 15, maxlength => 50 },
        last   => { type => 'text', size => 20, maxlength => 50 },
      );
    }

    sub coalesce_value
    {
      my($self) = shift;
      return join(' ', map { defined($_) ? $_ : '' } 
                       map { $self->field($_)->internal_value } 
                       qw(first middle last));
    }

    sub decompose_value
    {
      my($self, $value) = @_;

      return undef  unless(defined $value);

      if($value =~ /^(\S+)\s+(\S+)\s+(\S+)$/)
      {
        return
        {
          first  => $1,
          middle => $2,
          last   => $3,
        };
      }

      my @parts = split(/\s+/, $value);

      if(@parts == 2)
      {
        return
        {
          first  => $parts[0],
          middle => undef,
          last   => $parts[1],
        };
      }

      return
      {
        first  => $parts[0],
        middle => $parts[1],
        last   => join(' ', @parts[2 .. $#parts]),
      };      
    }

    # Override these methods to determine how sub-fields are arranged
    sub html_field  { ... }
    sub xhtml_field { ... }
    ...


    use MyFullNameField;

    $field =
      MyFullNameField->new(
        label   => 'Full Name', 
        name    => 'name',
        default => 'John Doe');

    print $field->internal_value; # "John Doe"

    $field->input_value('Steven Paul Jobs');

    print $field->field('middle')->internal_value; # "Paul"

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Compound> is a base class for compound fields. A compound field is one that contains other fields.  The example in the L<SYNOPSIS> is a full name field made up of three separate text fields, one each for first, middle, and last name.  Compound fields can also contain other compound fields.

Externally, a compound field must field look and behave as if it is a single, simple field.  Although this can be done in many ways, it is important for all compound fields to actually inherit from L<Rose::HTML::Form::Field::Compound>. L<Rose::HTML::Form> uses this relationship in order to identify compound fields and handle them correctly.  Any compound field that does not inherit from L<Rose::HTML::Form::Field::Compound> will not work correctly with L<Rose::HTML::Form>.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HIERARCHY

A L<Rose::HTML::Form::Field::Compound>-derived object behaves as if it is a single L<field|Rose::HTML::Form::Field> made up of a group of sibling elements.  These siblings are available through the L<fields|/fields> method.

See the "hierarchy" sections of the L<Rose::HTML::Form::Field/HIERARCHY> and L<Rose::HTML::Form/HIERARCHY> documentation for more information about how field objects that are really "groups of siblings" behave with respect to the the child-related methods inherited from L<Rose::HTML::Object>.

=head1 SUBCLASSING

Actual compound fields must override the following methods: L<build_field()|/build_field>, L<decompose_value()|/decompose_value>, and L<coalesce_value()|/coalesce_value>.  The required semantics of those methods are described in the L<OBJECT METHODS> section below.

=head1 SUBFIELD ADDRESSING

Subfields are fields that are contained within another field.  A field that has sub-fields is called a compound field.  It is important to HTML form initialization that sub-fields be addressable from the top level.  Since fields can be arbitrarily nested, some form of hierarchy must also exist in the field addressing scheme.

To that end, compound fields use the "." character to partition the namespace. For example, the "month" sub-field of a compound field named "date" could be addressed from the L<form|Rose::HTML::Form> that contains the field using the name "date.month".  As a consequence of this convention, I<field names may not contain periods>.

Subfields are addressed by their "relative" names from the perspective of the caller.  For example, the L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS> custom field class contains a two compound fields: one for the time (split into hours, minutes, seconds, and AM/PM) and one for the date (split into month, day, and year). Here are a few ways to address the various sub-fields.

    $datetime_field = 
      Rose::HTML::Form::Field::DateTime::Split::MDYHMS->new(
        name => 'datetime');

    ## Get the (compound) sub-field containing the month, day, and year
    $mdy_field = $datetime_field->field('date');


    ## Get the year sub-field of the month/day/year sub-field 
    ## in two different ways:

    # Fully-qualified sub-field access
    $year_field = $datetime_field->field('date.year');

    # Relative sub-field access
    $year_field = $datetime_field->field('date')->field('year');

See the L<Rose::HTML::Form> documentation for more information on how forms address and initialize fields based on query parameter names.

=head1 VALIDATION

It is not the job of the L<coalesce_value()|/coalesce_value> or L<decompose_value()|/decompose_value> methods to validate input.  That's the job of the L<validate()|Rose::HTML::Form::Field/validate> method in L<Rose::HTML::Form::Field>.

But as you'll see when you start to write your own L<decompose_value()|/decompose_value> methods, it's often nice to know whether the input is valid before you try to decompose it into sub-field values.  Valid input can usually be divided up very easily, whereas invalid input requires some hard decisions to be made. Consequently, most L<decompose_value()|/decompose_value> methods have one section for handling valid input, and another that makes a best-effort to handle invalid input.

There are several ways to determine whether or not a value passed to L<decompose_value()|/decompose_value> is valid.  You could actually call L<validate()|Rose::HTML::Form::Field/validate>, but that is technically a violation of the API since L<decompose_value()|/decompose_value> only knows that it's supposed to divvy up the value that it is passed.  It is merely assuming that this value is also the current value of the field. In short, don't do that.

The L<decompose_value()|/decompose_value> method could try to validate the input directly, of course.  But that seems like a duplication of code.  It might work, but it is more effort.

The recommended solution is to rely on the fact that most overridden L<inflate_value()|Rose::HTML::Form::Field/inflate_value> methods serve as an alternate form of validation.  Really, the L<decompose_value()|/decompose_value> method doesn't I<want> to "validate" in the same way that L<validate()|Rose::HTML::Form::Field/validate> does. Imagine a month/day/year compound field that only accepts dates in the 1990s.  As far as L<validate()|Rose::HTML::Form::Field/validate> is concerned, 12/31/2002 is an invalid value.  But as far as L<decompose_value()|/decompose_value> is concerned, it's perfectly fine and can be parsed and divided up into sub-field values easily.

This is exactly the determination that many overridden L<inflate_value()|Rose::HTML::Form::Field/inflate_value> methods must also make.  For example, that month/day/year compound field may use a L<DateTime> object as its internal value.  The L<inflate_value()|Rose::HTML::Form::Field/inflate_value> method must parse a date string and produce a L<DateTime> value.  The L<decompose_value()|/decompose_value> method can use that to its advantage.  Example:

    sub decompose_value
    {
      my($self, $value) = @_;

      return undef  unless(defined $value);

      # Use inflate_value() to do the dirty work of
      # sanity checking the value for us
      my $date = $self->SUPER::inflate_value($value);

      # Garbage input: try to do something sensible
      unless($date) 
      {
        my($month, $day, $year) = split('/', $value);

        return
        {
          month => $month || '',
          day   => $day   || '',
          year  => $year  || '',
        }
      }

      # Valid input: divide up appropriately
      return
      {
        month => $date->month,
        day   => $date->day,
        year  => $date->year,
      };
    }

This technique is sound because both L<decompose_value()|/decompose_value> and L<inflate_value()|Rose::HTML::Form::Field/inflate_value> work only with the input they are given, and have no reliance on the state of the field object itself (unlike L<validate()|Rose::HTML::Form::Field/validate>).

If the L<inflate_value()|Rose::HTML::Form::Field/inflate_value> method is not being used, then L<decompose_value()|/decompose_value> must sanity check its own input.  But this code is not necessarily the same as the code in L<validate()|Rose::HTML::Form::Field/validate>, so there is no real duplication.

=head1 OBJECT METHODS

=over 4

=item B<add_field ARGS>

Convenience alias for L<add_fields()|/add_fields>.

=item B<add_fields ARGS>

Add the fields specified by ARGS to the list of sub-fields in this compound field.

If an argument is "isa" L<Rose::HTML::Form::Field>, then it is added to the list of fields, stored under the name returned by the field's L<name()|Rose::HTML::Form::Field/name> method.

If an argument is anything else, it is used as the field name, and the next argument is used as the field object to store under that name.  If the next argument is not an object derived from L<Rose::HTML::Form::Field>, then a fatal error occurs.

The field object's L<name()|Rose::HTML::Form::Field/name> is set to the name that it is stored under, and its L<parent_field()|Rose::HTML::Form::Field/parent_field> is set to the form object.

Returns the full list of field objects, sorted by field name, in list context, or a reference to a list of the same in scalar context.

Examples:

    $name_field = 
      Rose::HTML::Form::Field::Text->new(name => 'name',
                                         size => 25);

    $email_field = 
      Rose::HTML::Form::Field::Text->new(name => 'email',
                                         size => 50);

    # Field arguments
    $compound_field->add_fields($name_field, $email_field);

    # Name/field pairs
    $compound_field2->add_fields(name  => $name_field, 
                                 email => $email_field);

    # Mixed
    $compound_field3->add_fields($name_field, 
                                 email => $email_field);

=item B<auto_invalidate_parents [BOOL]>

Get or set a boolean value that indicates whether or not the internal value of any parent fields are automatically invalidated when the input value of this field is set.  The default is true.

=item B<build_field>

This method must be overridden by subclasses.  Its job is to build the compound field by creating and then adding the sub-fields.  Example:

    sub build_field
    {
      my($self) = shift;

      $self->add_fields
      (
        first  => { type => 'text', size => 15, maxlength => 50 },
        middle => { type => 'text', size => 15, maxlength => 50 },
        last   => { type => 'text', size => 20, maxlength => 50 },
      );
    }

See the documentation for L<add_fields()|/add_fields> for a full description of the arguments it accepts.

=item B<coalesce_value>

This method must be overridden by subclasses.  It is responsible for combining the values of the sub-fields into a single value.  Example:

    sub coalesce_value
    {
      my($self) = shift;
      return join(' ', map { defined($_) ? $_ : '' } 
                       map { $self->field($_)->internal_value } 
                       qw(first middle last));
    }

The value returned must be suitable as an input value.  See the L<Rose::HTML::Form::Field> documentation for more information on input values.

=item B<decompose_value VALUE>

This method must be overridden by subclasses.  It is responsible for distributing the input value VALUE amongst the various sub-fields.  This is harder than you might expect, given the possibility of invalid input. Nevertheless, subclasses must try to divvy up even garbage values such that they eventually produce output values that are equivalent to the original input value when fed back through the system.

The method should return a reference to a hash of sub-field-name/value pairs.

In the example below, the method's job is to decompose a full name into first, middle, and last names.  It is not very heroic in its efforts to parse the name, but it at least tries to ensure that every significant piece of the value ends up back in one of the sub-fields.

    sub decompose_value
    {
      my($self, $value) = @_;

      return undef  unless(defined $value);

      # First, middle, and last names all present
      if($value =~ /^(\S+)\s+(\S+)\s+(\S+)$/)
      {
        return
        {
          first  => $1,
          middle => $2,
          last   => $3,
        };
      }

      my @parts = split(/\s+/, $value);

      # First and last?
      if(@parts == 2)
      {
        return
        {
          first  => $parts[0],
          middle => undef,
          last   => $parts[1],
        };
      }

      # Oh well, at least try to make sure all the non-whitespace
      # characters get fed back into the field
      return
      {
        first  => $parts[0],
        middle => $parts[1],
        last   => join(' ', @parts[2 .. $#parts]),
      };      
    }

=item B<disabled [BOOL]>

This method calls the C<disabled()> method on all L<fields|/fields> that possess such a method, passing all arguments.  Set to true to disable all eligible sub-fields, false to enable them.

=item B<field NAME [, VALUE]>

Get or set the field specified by NAME.  If only a NAME argument is passed, then the field stored under the name NAME is returned.  If no field exists under that name exists, then undef is returned.

If both NAME and VALUE arguments are passed, then the field VALUE is stored under the name NAME.  If VALUE is not an object derived from L<Rose::HTML::Form::Field>, a fatal error occurs.

=item B<fields>

Returns the full list of field objects, sorted by field name, in list context, or a reference to a list of the same in scalar context.

=item B<field_value NAME>

Returns the L<internal_value|Rose::HTML::Form::Field/internal_value> of the sub-field named NAME.  In other words, this:

    $val = $field->field_value('zip_code');

is just a shorter way to write this:

    $val = $field->field('zip_code')->internal_value;

=item B<html_field>

Returns the HTML serialization of the field.  The default implementation calls L<html_field|Rose::HTML::Form::Field/html_field> on each of the L<fields|/fields> and then concatenates and the results.  Override this method in your compound field subclass to lay out your sub-fields as desired.

=item B<invalidate_value>

Invalidates the field's value, and the value of all of its parent fields, and so on.  This will cause the field's values to be recreated the next time they are retrieved.

=item B<is_empty>

Returns true if all of the sub-fields are empty, false otherwise.

=item B<is_full>

Returns false if any of the sub-fields are empty, true otherwise.  Subclasses can override this method to indicate that a valid value does not require all sub-fields to be non-empty.

For example, consider a compound time field with sub-fields for hours, minutes, seconds, and AM/PM.  It may only require the hour and AM/PM sub-fields to be filled in.  It could then assume values of zero for all of the empty sub-fields.

Note that this behavior is different than making "00" the default values of the minutes and seconds sub-fields.  Default values are shown in the HTML serializations of fields, so the minutes and seconds fields would be pre-filled with "00" (unless the field is cleared--see L<Rose::HTML::Form::Field>'s L<reset|Rose::HTML::Form::Field/reset> and L<clear|Rose::HTML::Form::Field/clear> methods for more information).

If a subclass does override the C<is_full> method in order to allow one or more empty sub-fields while still considering the field "full," the subclass must also be sure that its L<coalesce_value|/coalesce_value> method accounts for and handles the possibility of empty fields.

See the L<Rose::HTML::Form::Field::Time::Split::HourMinuteSecond> source code for an actual implementation of the behavior described above.  In particular, look at the implementation of the C<is_full> and C<coalesce_value> methods.

=item B<subfield_input_value NAME [, VALUE]>

Get or set the input value of the sub-field named NAME.  If there is no sub-field by that name, a fatal error will occur.

This method has the same effect as fetching the sub-field using the L<field|/field> method and then calling L<input_value|Rose::HTML::Form::Field/input_value> directly on it, but with one important exception.  Setting a sub-field input value using the L<subfield_input_value|/subfield_input_value> method will B<not> invalidate the value of the parent field.

This method is therefore essential for implementing compound fields that need to set their sub-field values directly.  Without it, any attempt to do so would cause the compound field to invalidate itself.

See the source code for  L<Rose::HTML::Form::Field::DateTime::Range>'s L<inflate_value|Rose::HTML::Form::Field::DateTime::Range/inflate_value> method for a real-world usage example of the L<subfield_input_value|/subfield_input_value> method.

=item B<xhtml_field>

Returns the XHTML serialization of the field.  The default implementation calls L<xhtml_field|Rose::HTML::Form::Field/xhtml_field> on each of the L<fields|/fields> and then concatenates and the results.  Override this method in your compound field subclass to lay out your sub-fields as desired.

=back

=head1 SUPPORT

Any L<Rose::HTML::Objects> questions or problems can be posted to the L<Rose::HTML::Objects> mailing list.  To subscribe to the list or search the archives, go here:

L<http://groups.google.com/group/rose-html-objects>

Although the mailing list is the preferred support mechanism, you can also email the author (see below) or file bugs using the CPAN bug tracking system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTML-Objects>

There's also a wiki and other resources linked from the Rose project home page:

L<http://rosecode.org>

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
