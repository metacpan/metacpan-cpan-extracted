use Data::Structure::Util qw();
our @ISA = qw(Perlmazing::Listable);

sub main {
  Data::Structure::Util::unbless($_[0]);
}

1;