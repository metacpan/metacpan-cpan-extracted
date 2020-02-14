package Test::Auto::Plugin::ShortDescription;

use Test::More;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Signatures;

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
