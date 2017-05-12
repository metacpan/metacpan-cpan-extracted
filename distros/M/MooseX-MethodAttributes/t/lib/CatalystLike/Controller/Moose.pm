package CatalystLike::Controller::Moose;
use Moose;
use namespace::autoclean;
BEGIN { extends qw/CatalystLike::Controller/; }

our $GET_ATTRIBUTE_CALLED = 0;
sub get_attribute : Local { $GET_ATTRIBUTE_CALLED++ }

our $GET_FOO_CALLED = 0;
our $BEFORE_GET_FOO_CALLED = 0;
sub get_foo : Local { $GET_FOO_CALLED++ }
# Exactly the same as last test except for modifier here
before 'get_foo' => sub { $BEFORE_GET_FOO_CALLED++ };

sub other : Local {}

1;

