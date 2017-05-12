package REST::Consumer::PermissiveResolver;

use strict;
use warnings;

sub new {
  my $class = shift;
  return bless {}, $class;
}

# We don't know any addresses, and we don't have any errors.
sub resolve {
  return [], undef;
}

1;
