package Rose::HTML::Form::Field::Time::Split;

use strict;

use base qw(Rose::HTML::Form::Field::Compound Rose::HTML::Form::Field::Time);

our $VERSION = '0.606';

# Multiple inheritence never quite works out the way I want it to...
Rose::HTML::Form::Field::Time->import_methods
(
  'inflate_value',
  'validate',
);

Rose::HTML::Form::Field::Compound->import_methods
(
  'name',
);

1;
