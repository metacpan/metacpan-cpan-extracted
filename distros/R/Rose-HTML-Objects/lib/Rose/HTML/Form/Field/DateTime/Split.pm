package Rose::HTML::Form::Field::DateTime::Split;

use strict;

use base qw(Rose::HTML::Form::Field::Compound Rose::HTML::Form::Field::DateTime);

our $VERSION = '0.606';

# Multiple inheritence never quite works out the way I want it to...
Rose::HTML::Form::Field::DateTime->import_methods
(
  'inflate_value',
);

Rose::HTML::Form::Field::Compound->import_methods
(
  'name',
);

sub validate
{
  my($self) = shift;

  my $ok = $self->Rose::HTML::Form::Field::Compound::validate(@_);
  return $ok  unless($ok);

  return $self->Rose::HTML::Form::Field::DateTime::validate(@_);
}

1;
