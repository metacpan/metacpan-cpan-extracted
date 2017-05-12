package Rose::HTML::Form::Field::Integer;

use strict;

use Rose::HTML::Object::Errors qw(:number);

use base 'Rose::HTML::Form::Field::Numeric';

our $VERSION = '0.606';

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->internal_value;
  return 1  unless(defined $value && length $value);

  my $name = sub { $self->error_label || $self->name };

  unless($value =~ /^-?\d+$/)
  {
    $self->add_error_id(NUM_INVALID_INTEGER, { label => $name });
    return 0;
  }

  return 1;
}

my %Error_Map =
(
  NUM_INVALID_NUMBER()          => NUM_INVALID_INTEGER,
  NUM_INVALID_NUMBER_POSITIVE() => NUM_INVALID_INTEGER_POSITIVE,
  NUM_NOT_POSITIVE_NUMBER()     => NUM_NOT_POSITIVE_INTEGER,
);

sub add_error_id
{
  my($self) = shift;
  my $error_id = shift;
  my $new_error_id = $Error_Map{$error_id} || $error_id;
  return $self->SUPER::add_error_id($new_error_id, @_);
}

sub error_id
{
  my($self) = shift;

  if(@_)
  {
    my $error_id = shift;
    my $new_error_id = $Error_Map{$error_id} || $error_id;
    return $self->SUPER::error_id($new_error_id, @_);
  }
  else
  {
    my $error_id = $self->SUPER::error_id;
    my $new_error_id = $Error_Map{$error_id} || $error_id;
    return $new_error_id;
  }
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

NUM_INVALID_INTEGER          = "[label] must be an integer."
NUM_INVALID_INTEGER_POSITIVE = "[label] must be a positive integer."
NUM_NOT_POSITIVE_INTEGER     = "[label] must be a positive integer."

[% LOCALE de %]

NUM_INVALID_INTEGER          = "[label] muß eine Ganzzahl sein."
NUM_INVALID_INTEGER_POSITIVE = "[label] muß eine positive Ganzzahl sein."
NUM_NOT_POSITIVE_INTEGER     = "[label] muß eine positive Ganzzahl sein."

[% LOCALE fr %]

NUM_INVALID_INTEGER          = "[label] doit être un entier."
NUM_INVALID_INTEGER_POSITIVE = "[label] doit être un entier positif."
NUM_NOT_POSITIVE_INTEGER     = "[label] doit être un entier positif."

[% LOCALE bg %]

NUM_INVALID_INTEGER          = "Полето '[label]' трябва да бъде цяло число."
NUM_INVALID_INTEGER_POSITIVE = "Полето '[label]' трябва да бъде цяло положително число."
NUM_NOT_POSITIVE_INTEGER     = "Полето '[label]' трябва да бъде цяло положително число."

__END__

=head1 NAME

Rose::HTML::Form::Field::Integer - Text field that only accepts integer values.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Integer->new(
        label     => 'Count', 
        name      => 'count',
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

    $field->input_value(5);
    $field->validate; # true

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Integer> is a subclass of L<Rose::HTML::Form::Field::Numeric> that only accepts integer values.  It overrides the L<validate()|Rose::HTML::Form::Field/validate> method of its parent class, returning true if the L<internal_value()|Rose::HTML::Form::Field/internal_value> is a valid integer, or setting an error message and returning false otherwise.

Use the L<min|/min> and :<max|/max> attributes to control whether the range of valid values.

=head1 OBJECT METHODS

=over 4

=item B<max [INT]>

Get or set the maximum acceptable value.  If the field's L<internal_value()|Rose::HTML::Form::Field/internal_value> is B<greater than> this value, then the L<validate()|Rose::HTML::Form::Field/validate> method will return false.  If undefined, then no limit on the maximum value is enforced.

=item B<min [INT]>

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
