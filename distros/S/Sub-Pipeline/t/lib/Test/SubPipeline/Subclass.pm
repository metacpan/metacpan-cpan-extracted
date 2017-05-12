
use strict;
use warnings;

package Test::SubPipeline::Subclass;
use base qw(Test::SubPipeline::Class);

sub second {
  my ($self, $arg) = @_;

  die unless $arg->{first};
  $arg->{second} = 'two';
}

1;
