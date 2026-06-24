# Prefer numeric version for backwards compatibility
BEGIN { require 5.016000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Mojo::Log::Role::Formattable;

$Mojo::Log::Role::Formattable::VERSION = 'v1.0.0';

use Mojo::Base qw( -role );
use Sub::Util  qw( set_subname );

my @levels = qw( fatal error warn info debug trace );

requires @levels;

for my $level ( @levels ) {
  my $name = "${level}f";
  # Note that $format has nothing to do with the "format" attribute of the $self
  # Mojo::Log object
  my $sub = set_subname $name => sub {
    my ( $self, $format, @msgs ) = @_;
    $self->$level( sprintf( $format, @msgs ) )
  };
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  *{ $name } = $sub
}

1
