use strict;
use warnings;

package Pad::Tie::Plugin::HashRef;

use base 'Pad::Tie::Plugin';

sub provides { 'hash_ref' }

sub hash_ref {
  my ($plugin, $ctx, $self, $args) = @_;

  $args = $plugin->canon_args($args);

  for my $method (keys %$args) {
    # no tie needed because it is a basic hashref
    $ctx->{'%' . $args->{$method}} = $self->$method;
  }
}

1;

