package CatalystLike::Controller::Moose::MethodModifiers;
use Moose;
use namespace::autoclean;
BEGIN { extends qw/CatalystLike::Controller::Moose/; }

our $GET_ATTRIBUTE_CALLED = 0;
after get_attribute => sub { $GET_ATTRIBUTE_CALLED++; }; # Wrapped only, should show up

sub other : Local {}
after other => sub {}; # Wrapped, wrapped should show up.

1;

