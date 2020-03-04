package Test::Auto::Plugin::ShortDescription;

use strict;
use warnings;
use routines;

use Test::More;
use Data::Object::Class;
use Data::Object::Attributes;

extends 'Test::Auto::Plugin';

method tests(:$length = 160) {
  my $parser = $self->subtests->parser;

  subtest "testing description length ($length)", fun () {
    my $description = $parser->render('description')
      or plan skip_all => 'no description';

    ok length($description) < $length;
  };

  return $self;
}

1;
