package Test::Auto::Plugin::ShortDescription;

use strict;
use warnings;

use Moo;
use Test::More;

extends 'Test::Auto::Plugin';

sub tests {
  my ($self, %args) = @_;

  my $length = $args{length} || 160;
  my $parser = $self->subtests->parser;

  subtest "testing description length ($length)", sub {
    my $description = $parser->render('description')
      or plan skip_all => 'no description';

    ok length($description) < $length;
  };

  return $self;
}

1;
