package Rose::HTML::Object::Message::Localized;

use strict;

use Carp;
use Rose::HTML::Object::Message::Localizer;

use base 'Rose::HTML::Object::Message';

our $VERSION = '0.600';

#our $Debug = 0;

use overload
(
  '""'   => sub { shift->localized_text },
  'bool' => sub { 1 },
  '0+'   => sub { 1 },
   fallback => 1,
);

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    '_default_localizer',
    'default_locale',
  ],
);

__PACKAGE__->default_locale('en');

sub generic_object_class { 'Rose::HTML::Object' }

sub localized_text
{
  my($self) = shift;

  my $localizer = $self->localizer;

  return $localizer->localize_message(
           message => $self, 
           parent  => $self->parent,
           locale  => $self->locale, 
           variant => $self->variant,
           args    => scalar $self->args);
}

sub localizer
{
  my($invocant) = shift;

  # Called as object method
  if(my $class = ref $invocant)
  {
    if(@_)
    {
      return $invocant->{'localizer'} = shift;
    }

    my $localizer = $invocant->{'localizer'};

    unless($localizer)
    {
      if(my $parent = $invocant->parent)
      {
        if(my $localizer = $parent->localizer)
        {
          return $localizer;
        }
      }
      else { return $class->default_localizer }
    }

    return $localizer || $class->default_localizer;
  }
  else # Called as class method
  {
    if(@_)
    {
      return $invocant->default_localizer(shift);
    }

    return $invocant->default_localizer;
  }
}

sub default_localizer
{
  my($class) = shift;

  if(@_)
  {
    return $class->_default_localizer(@_);
  }

  if(my $localizer = $class->_default_localizer)
  {
    return $localizer;
  }

  return $class->_default_localizer($class->generic_object_class->localizer);
}

sub locale
{
  my($invocant) = shift;

  # Called as object method
  if(my $class = ref $invocant)
  {
    if(@_)
    {
      return $invocant->{'locale'} = shift;
    }

    my $locale = $invocant->{'locale'};

    unless($locale)
    {
      if(my $parent = $invocant->parent)
      {
        if(my $locale = $parent->locale)
        {
          return $locale;
        }
      }
      else { return $class->default_locale }
    }

    return $locale || $class->default_locale;
  }
  else # Called as class method
  {
    if(@_)
    {
      return $invocant->default_locale(shift);
    }

    return $invocant->default_locale;
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Rose::HTML::Object::Message::Localized - Localized message object.

=head1 SYNOPSIS

  use Rose::HTML::Form::Field::Integer;
  Rose::HTML::Form::Field::Integer->load_all_messages;

  use Rose::HTML::Object::Messages qw(NUM_INVALID_INTEGER);

  $localizer = Rose::HTML::Object->default_localizer;

  $msg = 
    Rose::HTML::Object::Message::Localized->new(
      localizer => $localizer,
      id        => NUM_INVALID_INTEGER,
      args      => { label => 'XYZ' });

  print $msg->localized_text; # XYZ must be an integer.

  $msg->locale('fr');

  print $msg->localized_text; # XYZ doit être un entier.

=head1 DESCRIPTION

L<Rose::HTML::Object::Message::Localized> objects encapsulate a localized text message with an integer L<id|/id> and an optional set of name/value pairs to be used to fill in any placeholders in the message text.

This class inherits from L<Rose::HTML::Object::Message>.  See the L<Rose::HTML::Object::Message> documentation for more information.

=head1 OVERLOADING

Stringification is overloaded to call the L<localized_text|/localized_text> method.  In numeric and boolean contexts, L<Rose::HTML::Object::Message::Localized> objects always evaluate to true.

=head1 CLASS METHODS

=over 4

=item B<default_locale [LOCALE]>

Get or set the default L<locale|Rose::HTML::Object::Message::Localizer/LOCALES>.  Defaults to C<en>.

=item B<default_localizer [LOCALIZER]>

Get or set the default L<Rose::HTML::Object::Message::Localizer>-derived localizer object.  Defaults to the L<default_localizer|Rose::HTML::Object/default_localizer> of the generic object class for this HTML object class hierarchy (L<Rose::HTML::Object>, by default).

=back

=head1 CONSTRUCTOR

=over 4

=item B<new [ PARAMS | TEXT ]>

Constructs a new L<Rose::HTML::Object::Message::Localized> object.  If a single argument is passed, it is taken as the value for the L<text|Rose::HTML::Object::Message/text> parameter.  Otherwise, PARAMS name/value pairs are expected.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<args [ PARAMS | HASHREF ]>

Get or set the name/value pairs to be used to fill in any placeholders in the localized message text.  To set, pass a list of name/value pairs or a reference to a hash of name/value pairs.  Values must be strings, code references, or references to arrays of strings or code references.  Code references are evaluated each time a message with placeholders is constructed.

See the L<LOCALIZED TEXT|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT"> section of the L<Rose::HTML::Object::Message::Localizer> documentation for more information on message text placeholders.

=item B<id [INT]>

Get or set the message's integer identifier.

=item B<locale [LOCALE]>

Get or set the L<locale string|Rose::HTML::Object::Message::Localizer/LOCALES> for this message.  If no locale is set but a L<parent|/parent> is defined and has a locale, then the L<parent|/parent>'s C<locale()> is returned.  If the L<parent|/parent> doesn't exist or has no locale set, the L<default_locale|/default_locale> is returned.

=item B<localizer [LOCALIZER]>

Get or set the L<Rose::HTML::Object::Message::Localizer>-derived object used to localize message text.  If no localizer is set but a L<parent|/parent> is defined, then the L<parent|/parent>'s C<localizer()> is returned.  Otherwise, the L<default_localizer|/default_localizer> is returned.

=item B<localized_text>

Asks the L<localizer|/localizer> to produce the localized version of the message text for the current L<locale|/locale> and L<args|/args>.  The localized text is returned.

=item B<parent [OBJECT]>

Get or set a L<weakened|Scalar::Util/weaken> reference to a parent object.  This parent must have a C<localizer()> method that returns a L<Rose::HTML::Object::Message::Localizer>-derived object and a C<locale()> method that returns a L<locale string|Rose::HTML::Object::Message::Localizer/LOCALES>.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
