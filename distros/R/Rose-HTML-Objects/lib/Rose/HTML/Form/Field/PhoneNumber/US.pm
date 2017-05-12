package Rose::HTML::Form::Field::PhoneNumber::US;

use strict;

use Rose::HTML::Object::Errors qw(:phone);

use base 'Rose::HTML::Form::Field::Text';

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  maxlength => 14,
});

sub validate
{
  my($self) = shift;

  my $number = $self->internal_value;

  return 1  if($number !~ /\S/);

  $number =~ s/\D+//g;

  return 1  if(length $number == 10);

  $self->add_error_id(PHONE_INVALID);

  return;
}

sub inflate_value
{
  my($self, $value) = @_;

  return  unless(defined $value);

  $value =~ s/\D+//g;

  if($value =~ /^(\d{3})(\d{3})(\d{4})$/)
  {
    return "$1-$2-$3";
  }

  return $_[1];
}

*deflate_value = \&inflate_value;

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

PHONE_INVALID = "Phone number must be 10 digits, including area code."

[% LOCALE de %]

PHONE_INVALID = "Die Telefon-Nummer muß 10 Stellen enthalten (einschließlich Vorwahl)."

[% LOCALE fr %]

PHONE_INVALID = "Le numéro de téléphone, indicatif compris, doit avoir 10 chiffres."

[% LOCALE bg %]

PHONE_INVALID = "Телефонния номер (вкл. кода на областта) не трябва да надвишава 10 цифри."

__END__

=head1 NAME

Rose::HTML::Form::Field::PhoneNumber::US - Text field that accepts only input that contains exactly 10 digits, and coerces valid input into US phone numbers in the form: 123-456-7890

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::PhoneNumber::US->new(
        label => 'Phone', 
        name  => 'phone',
        size  => 20);

    $field->input_value('555-5555');

    # "Phone number must be 10 digits, including area code"
    $field->validate or warn $field->error;

    $field->input_value('(123) 456-7890');

    print $field->internal_value; # "123-456-7890"

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::PhoneNumber::US> is a subclass of L<Rose::HTML::Form::Field::Text> that only allows values that contain exactly 10 digits, which it coerces into the form "123-456-7890".  It overrides the L<validate()|Rose::HTML::Form::Field/validate> and L<inflate_value()|Rose::HTML::Form::Field/inflate_value>, and L<deflate_value()|Rose::HTML::Form::Field/deflate_value> methods of its parent class.

This is a good example of a custom field class that constrains the kinds of inputs that it accepts and coerces all valid input and output to a particular format.  See L<Rose::HTML::Form::Field::Time> for another example, and a list of more complex examples.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
