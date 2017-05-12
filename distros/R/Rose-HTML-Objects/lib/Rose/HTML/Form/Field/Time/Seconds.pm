package Rose::HTML::Form::Field::Time::Seconds;

use strict;

use Rose::HTML::Object::Errors qw(:time);
use Rose::HTML::Object::Messages qw(:time);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  size => 2,
});

sub init
{
  my($self) = shift;
  $self->label_id(FIELD_LABEL_SECOND);
  $self->SUPER::init(@_);
}

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->internal_value;

  unless($value =~ /^\d\d?$/ && $value >= 0 && $value <= 59)
  {
    $self->add_error_id(TIME_INVALID_SECONDS);
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

FIELD_LABEL_SECOND       = "Second"
FIELD_ERROR_LABEL_SECOND = "second"
TIME_INVALID_SECONDS     = "Invalid seconds."

[% LOCALE de %]

TIME_INVALID_SECONDS     = "Ungültige Sekunden."
FIELD_LABEL_SECOND       = "Sekunden"
FIELD_ERROR_LABEL_SECOND = "Sekunden"

[% LOCALE fr %]

TIME_INVALID_SECONDS     = "Secondes invalides."
FIELD_LABEL_SECOND       = "Second"
FIELD_ERROR_LABEL_SECOND = "Second"

[% LOCALE bg %]

FIELD_LABEL_SECOND       = "Секунда"
FIELD_ERROR_LABEL_SECOND = "секунда"
TIME_INVALID_SECONDS     = "Невалидни секунди."

__END__

=head1 NAME

Rose::HTML::Form::Field::Time::Seconds - Text field that only accepts valid seconds.

=head1 SYNOPSIS

    $field =
       Rose::HTML::Form::Field::Time::Seconds->new(
        label => 'Seconds', 
        name  => 'secs');

    $field->input_value(99);
    $field->validate; # 0

    $field->input_value(20);
    $field->validate; # 1

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Time::Seconds> is a subclass of L<Rose::HTML::Form::Field::Text> that only accepts valid seconds: numbers between 0 and 59, inclusive, with or without leading zeros.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
