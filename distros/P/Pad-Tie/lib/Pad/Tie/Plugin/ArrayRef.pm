use strict;
use warnings;

package Pad::Tie::Plugin::ArrayRef;

use base 'Pad::Tie::Plugin';

sub provides { 'array_ref' }

sub array_ref {
  my ($plugin, $ctx, $self, $args) = @_;

  $args = $plugin->canon_args($args);

  for my $method (keys %$args) {
    # no tie needed because it is a basic arrayref
    $ctx->{'@' . $args->{$method}} = $self->$method;
  }
}

1;
