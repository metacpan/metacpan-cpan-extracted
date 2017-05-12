package Rose::HTML::Form::Field::Time::Hours;

use strict;

use Rose::HTML::Object::Errors qw(:time);
use Rose::HTML::Object::Messages qw(:time);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

use Rose::Object::MakeMethods::Generic
(
  boolean => 'military',
);

__PACKAGE__->add_required_html_attrs(
{
  size => 2,
});

sub init
{
  my($self) = shift;
  $self->label_id(FIELD_LABEL_HOUR);
  $self->SUPER::init(@_);
}

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->internal_value;

  unless($value =~ /^\d\d?$/)
  {
    $self->add_error_id(TIME_INVALID_HOUR);
    return 0;
  }

  if($self->military)
  {
    return 1  if($value >= 0 && $value <= 23);
    $self->add_error_id(TIME_INVALID_HOUR);
    return 0;
  }
  else
  {
    return 1  if($value >= 0 && $value <= 12);
    $self->add_error_id(TIME_INVALID_HOUR);
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

TIME_INVALID_HOUR      = "Invalid hour."
FIELD_LABEL_HOUR       = "Hour"
FIELD_ERROR_LABEL_HOUR = "hour"

[% LOCALE de %]

TIME_INVALID_HOUR = "Ungültige Stunde."
FIELD_LABEL_HOUR       = "Stunde"
FIELD_ERROR_LABEL_HOUR = "Stunde"

[% LOCALE fr %]

TIME_INVALID_HOUR      = "Heure invalide."
FIELD_LABEL_HOUR       = "Heure"
FIELD_ERROR_LABEL_HOUR = "heure"

[% LOCALE bg %]

TIME_INVALID_HOUR      = "Невалиден час."
FIELD_LABEL_HOUR       = "Час"
FIELD_ERROR_LABEL_HOUR = "час"

__END__

=head1 NAME

Rose::HTML::Form::Field::Time::Hours - Text field that only accepts valid hours.

=head1 SYNOPSIS

    $field =
       Rose::HTML::Form::Field::Time::Hours->new(
        label => 'Hours', 
        name  => 'hrs');

    $field->input_value(99);
    $field->validate; # 0

    $field->input_value(20);
    $field->validate; # 0

    $field->military(1);
    $field->validate; # 1

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Time::Hours> is a subclass of L<Rose::HTML::Form::Field::Text> that only accepts valid hours.  It supports normal (0-12) and military (0-23) time.  The behavior is toggled via the L<military|/military> object method.  Leading zeros are optional.

=head1 OBJECT METHODS

=over 4

=item B<military [BOOL]>

Get or set the boolean flag that indicates whether or not the field will accept "military time."  If true, the hours 0-23 are valid.  If false, only 0-12 are valid.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
