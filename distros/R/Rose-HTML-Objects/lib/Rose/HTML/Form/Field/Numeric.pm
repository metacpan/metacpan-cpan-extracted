package Rose::HTML::Form::Field::Numeric;

use strict;

use Rose::HTML::Object::Errors qw(:number);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

# use Rose::Object::MakeMethods::Generic
# (
#   scalar => [ qw(min max) ],
# );

__PACKAGE__->default_html_attr_value(size  => 6);

sub positive
{
  my($self) = shift;

  if(!@_ || $_[0])
  {
    $self->min(0);
    $self->max(undef);
  }
  elsif(@_)
  {
    $self->min(undef);
  }
}

sub negative
{
  my($self) = shift;

  if(!@_ || $_[0])
  {
    $self->max(0);
    $self->min(undef);
  }
  elsif(@_)
  {
    $self->max(undef);
  }
}

sub internal_value
{
  my($self) = shift;

  my $value = $self->SUPER::internal_value(@_);

  if(defined $value)
  {
    for($value)
    {
      s/-\s+/-/ || s/\+\s+//;
    }
  }

  return (defined $value && $value =~ /\S/) ? $value : undef;
}

# This is $RE{num}{dec} from Regexp::Common::number
my $Match = qr{^(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$};

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->internal_value;
  return 1  unless(defined $value && length $value);

  my $min = $self->min;
  my $max = $self->max;

  my $name = sub { $self->error_label || $self->name };

  unless($value =~ $Match)
  {
    if(defined $min && $min >= 0)
    {
      $self->add_error_id(NUM_INVALID_NUMBER_POSITIVE, { label => $name });
    }
    else
    {
      $self->add_error_id(NUM_INVALID_NUMBER, { label => $name });
    }

    return 0;
  }

  if(defined $min && $value < $min)
  {
    if($min == 0)
    {
      $self->add_error_id(NUM_NOT_POSITIVE_NUMBER, { label => $name });
    }
    else
    {
      $self->add_error_id(NUM_BELOW_MIN, { label => $name, value => $min });
    }
    return 0;
  }

  if(defined $max && $value > $max)
  {
    $self->add_error_id(NUM_ABOVE_MAX, { label => $name, value => $max });
    return 0;
  }

  return 1;
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

NUM_INVALID_NUMBER          = "[label] must be a number."
NUM_INVALID_NUMBER_POSITIVE = "[label] must be a positive number."
NUM_NOT_POSITIVE_NUMBER     = "[label] must be a positive number."
NUM_BELOW_MIN               = "[label] must be greater than or equal to [value]."
NUM_ABOVE_MAX               = "[label] must be less than or equal to [value]."

[% LOCALE de %]

NUM_INVALID_NUMBER          = "[label] muß eine Zahl sein."
NUM_INVALID_NUMBER_POSITIVE = "[label] muß eine positive Zahl sein."
NUM_NOT_POSITIVE_NUMBER     = "[label] muß eine positive Zahl sein."
NUM_BELOW_MIN               = "[label] muß größer als oder gleich [value] sein."
NUM_ABOVE_MAX               = "[label] muß kleiner oder gleich [value] sein."

[% LOCALE fr %]

NUM_INVALID_NUMBER          = "[label] doit être un nombre."
NUM_INVALID_NUMBER_POSITIVE = "[label] doit être un nombre positif."
NUM_NOT_POSITIVE_NUMBER     = "[label] doit être un nombre positif."
NUM_BELOW_MIN               = "[label] doit être plus grand ou égal à [value]."
NUM_ABOVE_MAX               = "[label] doit être plus petit ou égal à [value]."

[% LOCALE bg %]

NUM_INVALID_NUMBER          = "Полето '[label]' трябва да бъде цяло число."
NUM_INVALID_NUMBER_POSITIVE = "Полето '[label]' трябва да бъде цяло положително число."
NUM_NOT_POSITIVE_NUMBER     = "Полето '[label]' трябва да бъде цяло положително число."
NUM_BELOW_MIN               = "Стойността в '[label]' трябва да бъде по-голяма от [value]."
NUM_ABOVE_MAX               = "Стойността в '[label]' трябва да бъде по-малка или равна на [value]."

__END__

=head1 NAME

Rose::HTML::Form::Field::Numeric - Text field that only accepts numeric values.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Numeric->new(
        label     => 'Distance', 
        name      => 'distance',
        maxlength => 6);

    $field->input_value('abc');
    $field->validate; # false

    $field->input_value(123);
    $field->validate; # true

    # Set minimum and maximum values
    $field->min(2);
    $field->max(100);

    $field->input_value(123);
    $field->validate; # false

    $field->input_value(1);
    $field->validate; # false

    $field->input_value(5.5);
    $field->validate; # true

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Numeric> is a subclass of L<Rose::HTML::Form::Field::Text> that only accepts numeric values.  It overrides the L<validate()|Rose::HTML::Form::Field/validate> method of its parent class, returning true if the L<internal_value()|Rose::HTML::Form::Field/internal_value> is a valid number, or setting an error message and returning false otherwise.

Use the L<min|/min> and :<max|/max> attributes to control whether the range of valid values.

=head1 OBJECT METHODS

=over 4

=item B<max [NUMERIC]>

Get or set the maximum acceptable value.  If the field's L<internal_value()|Rose::HTML::Form::Field/internal_value> is B<greater than> this value, then the L<validate()|Rose::HTML::Form::Field/validate> method will return false.  If undefined, then no limit on the maximum value is enforced.

=item B<min [NUMERIC]>

Get or set the minimum acceptable value.  If the field's L<internal_value()|Rose::HTML::Form::Field/internal_value> is B<less than> this value, then the L<validate()|Rose::HTML::Form::Field/validate> method will return false.  If undefined, then no limit on the minimum value is enforced.

=item B<negative [BOOL]>

If BOOL is true or omitted, sets L<max|/max> to C<0>.  If BOOL is false, sets L<max|/max> to undef.

=item B<positive [BOOL]>

If BOOL is true or omitted, sets L<min|/min> to C<0>.  If BOOL is false, sets L<min|/min> to undef.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
