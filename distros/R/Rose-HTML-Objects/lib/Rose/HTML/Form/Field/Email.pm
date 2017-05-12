package Rose::HTML::Form::Field::Email;

use strict;

use Email::Valid;

use Rose::HTML::Object::Errors qw(:email);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

sub validate
{
  my($self) = shift;

  my $ok = $self->SUPER::validate(@_);
  return $ok  unless($ok);

  my $value = $self->internal_value;
  return 1  unless(length $value);

  $ok = Email::Valid->address($value);

  unless($ok)
  {
    $self->add_error_id(EMAIL_INVALID);
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

EMAIL_INVALID = "Invalid email address."

[% LOCALE de %]

# oder "Ungültige Email."
EMAIL_INVALID = "Ungültige Email-Adresse."

[% LOCALE fr %]

EMAIL_INVALID = "Adresse e-mail invalide."

[% LOCALE bg %]

EMAIL_INVALID = "Невалиден email адрес."

__END__

=head1 NAME

Rose::HTML::Form::Field::Email - Text field that only accepts valid email addresses.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Email->new(
        label     => 'Email', 
        name      => 'email',
        size      => 30,
        maxlength => 255);

    if($field->validate)
    {
      $email = $field->internal_value;
    }
    else
    {
      # Handle invalid email addresses
    }

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Email> is a subclass of L<Rose::HTML::Form::Field::Text> that uses L<Email::Valid> to allow only valid email addresses as input.  It overrides the L<validate()|Rose::HTML::Form::Field/validate> method of its parent class, returning true if the L<internal_value()|Rose::HTML::Form::Field/internal_value> is a valid email address, or setting an error message and returning false otherwise.

This is a good example of a custom field class that simply constrains the kinds of inputs that it accepts, but does not inflate/deflate values or aggregate other fields.

=head1 SEE ALSO

Other examples of custom fields:

=over 4

=item L<Rose::HTML::Form::Field::Time>

Uses inflate/deflate to coerce input into a fixed format.

=item L<Rose::HTML::Form::Field::DateTime>

Uses inflate/deflate to convert input to a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Range>

A compound field whose internal value consists of more than one object.

=item L<Rose::HTML::Form::Field::PhoneNumber::US::Split>

A simple compound field that coalesces multiple subfields into a single value.

=item L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear>

A compound field that uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS>

A compound field that includes other compound fields and uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
