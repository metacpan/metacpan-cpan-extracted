package Rose::HTML::Object::Error;

use strict;

use Carp;
use Clone::PP();
use Scalar::Util();

use base 'Rose::Object';

use Rose::HTML::Object::Errors qw(CUSTOM_ERROR);

our $VERSION = '0.606';

#our $Debug = 0;

use overload
(
  '""'   => sub { no warnings 'uninitialized'; shift->message . '' },
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

use Rose::HTML::Object::MakeMethods::Localization
(
  localized_message =>
  [
    'message',
  ],
);

__PACKAGE__->default_locale('en');

sub generic_object_class { 'Rose::HTML::Object' }

sub as_string { no warnings 'uninitialized'; "$_[0]" }

sub parent
{
  my($self) = shift; 
  return Scalar::Util::weaken($self->{'parent'} = shift)  if(@_);
  return $self->{'parent'};
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

sub clone
{
  my($self) = shift;
  my $clone = Clone::PP::clone($self);
  $clone->parent(undef);
  return $clone;
}

sub id
{
  my($self) = shift;

  if(@_)
  {
    return $self->{'id'} = shift;
  }

  my $id = $self->{'id'};

  return $id  if(defined $id);

  my $msg = $self->message;
  return CUSTOM_ERROR  if($msg && $msg->is_custom);
  return undef;
}

sub is_custom
{
  my($self) = shift;

  my $id = $self->id;

  unless(defined $id)
  {
    my $msg = $self->message;

    return 1  if($msg && $msg->is_custom);
    return undef;
  }

  return $id == CUSTOM_ERROR;
}

1;

__END__

=head1 NAME

Rose::HTML::Object::Error - Error object.

=head1 SYNOPSIS

  $error = Rose::HTML::Object::Error->new(id => MY_ERROR);

=head1 DESCRIPTION

L<Rose::HTML::Object::Error> objects encapsulate an error with integer L<id|/id> and an optional associated L<message|/message> object.

This class inherits from, and follows the conventions of, L<Rose::Object>. See the L<Rose::Object> documentation for more information.

=head1 OVERLOADING

Stringification is overloaded to the stringification of the L<message|/message> object.  In numeric and boolean contexts, L<Rose::HTML::Object::Error> objects always evaluate to true.

=head1 CONSTRUCTOR

=over 4

=item B<new [PARAMS]>

Constructs a new L<Rose::HTML::Object::Error> object based on PARAMS name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<id [INT]>

Get or set the error's integer identifier.

=item L<message [MESSAGE]>

Get or set the L<Rose::HTML::Object::Message>-derived message object associated with this error.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
