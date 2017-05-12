use strict;
use warnings;

package Pad::Tie::LP;

use base 'Lexical::Persistence';

sub parse_variable {
  my ($self, $var) = @_;

  my ($sigil, $context, $member) = $self->SUPER::parse_variable($var);

  if ($context eq '_' and not exists $self->{context}{_}{$member}) {
    return; # don't auto-vivify _
  }

  return ($sigil, $context, $member);
}

# don't actually ever push arg context
sub push_arg_context { shift->get_context("arg") }

# no-op, since we never changed it to begin with
sub pop_arg_context { () }

1;
