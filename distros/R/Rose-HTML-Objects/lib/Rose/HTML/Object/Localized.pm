package Rose::HTML::Object::Localized;

use strict;

use Carp;
use Rose::HTML::Object::Message::Localizer;

use base 'Rose::Object';

our $VERSION = '0.600';

#our $Debug = 0;

use Rose::HTML::Object::MakeMethods::Localization
(
  localized_errors =>
  [
    'errors',
  ],
);

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    'default_localizer',
    'default_locale',
  ],
);

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

    return $invocant->{'localizer'} || $class->default_localizer;
  }
  else # Called as class method
  {
    if(@_)
    {
      return $invocant->default_localizer(@_);
    }

    return $invocant->default_localizer
  }
}

sub locale
{
  my($invocant) = shift;

  # Called as an object method
  if(my $class = ref $invocant)
  {
    if(@_)
    {
      return $invocant->{'locale'} = shift;
    }

    return $invocant->{'locale'}  if($invocant->{'locale'});

    foreach my $parent_name (qw(parent_group parent_field parent_form parent))
    {
      if($invocant->can($parent_name) && (my $parent = $invocant->$parent_name()))
      {
        my $locale = $parent->locale;
        return $locale  if(defined $locale);
      }
    }

    return $invocant->localizer->locale ||  $invocant->localizer->default_locale;
  }
  else # Called as a class method
  {
    if(@_)
    {
      return $invocant->default_locale(shift);
    }

    return $invocant->localizer->locale || $invocant->default_locale;
  }
}

1;
