use strict;
use warnings;

package Pad::Tie::Plugin::Self;

sub provides { 'self' }

sub self {
  my ($plugin, $ctx, $self, $arg) = @_;
  $ctx->{'$self'} = $self;
}

1;
